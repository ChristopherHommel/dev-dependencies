#!/bin/bash
#
# Installs Samba and configures a default projects share
#
# Usage:
#     ./install.sh <-t> <-?>
#
# Options:
#     -t Pipe output logs to a file (tee)
#

PIPE_TO_FILE=0
LOG_FILE="./install-samba-log.txt"
SHARE_NAME="projects"
SMB_CONF="/etc/samba/smb.conf"

write_options(){
    write_log "Options:"
    write_log "    <-t> Pipe output to file"
    write_log "    <-?> Print options"
}

write_log(){
    if [ $PIPE_TO_FILE -eq 1 ]; then
        echo "$1" | tee -a "$LOG_FILE"
    else
        echo "$1"
    fi
}

write_error(){
    local message="$1"
    write_log "$message"
    local length=${#message}
    local line=$(printf '%*s' "$length" '' | tr ' ' '^')
    write_log "$line"
}

parse_args(){
    for arg in "$@"; do
        case "$arg" in
            -t)
            write_log "Pipe to file turned on, writing to $LOG_FILE"
            PIPE_TO_FILE=1
            ;;
            -?)
            write_options
            ;;
            *)
            write_options
            ;;
        esac
    done

    write_log "Starting install"
    return 0
}

parse_args "$@"

target_user(){
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        echo "$SUDO_USER"
        return 0
    fi

    id -un
}

target_home(){
    local user="$1"
    local home_dir

    home_dir=$(getent passwd "$user" | cut -d: -f6)
    if [ -n "$home_dir" ]; then
        echo "$home_dir"
        return 0
    fi

    echo "$HOME"
}

install_samba_packages(){
    write_log "Installing Samba packages"

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    if ! sudo apt install -y samba samba-common-bin; then
        write_error "Failed to install Samba packages"
        return 1
    fi

    return 0
}

prompt_samba_password(){
    local password
    local password_confirm

    if [ ! -t 0 ]; then
        write_error "Cannot prompt for Samba password without an interactive terminal"
        return 1
    fi

    read -r -s -p "Enter Samba password for $1: " password
    printf '\n'
    read -r -s -p "Confirm Samba password for $1: " password_confirm
    printf '\n'

    if [ -z "$password" ]; then
        write_error "Samba password cannot be empty"
        return 1
    fi

    if [ "$password" != "$password_confirm" ]; then
        write_error "Samba passwords do not match"
        return 1
    fi

    SAMBA_PASSWORD="$password"
    return 0
}

configure_samba_user(){
    local user="$1"

    if ! id "$user" >/dev/null 2>&1; then
        write_error "System user does not exist: $user"
        return 1
    fi

    if sudo pdbedit -L -u "$user" >/dev/null 2>&1; then
        write_log "Updating Samba password for existing Samba user $user"
        if ! printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | sudo smbpasswd -s "$user"; then
            write_error "Failed to update Samba password for $user"
            return 1
        fi
    else
        write_log "Creating Samba user $user"
        if ! printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | sudo smbpasswd -s -a "$user"; then
            write_error "Failed to create Samba user $user"
            return 1
        fi
    fi

    return 0
}

share_exists(){
    sudo awk -v share="$SHARE_NAME" '
        BEGIN { target = tolower(share) }
        /^[[:space:]]*\[/ {
            section = $0
            sub(/^[[:space:]]*\[/, "", section)
            sub(/\][[:space:]]*$/, "", section)
            if (tolower(section) == target) {
                found = 1
            }
        }
        END { exit found ? 0 : 1 }
    ' "$SMB_CONF"
}

append_share_config(){
    local user="$1"
    local share_path="$2"
    local backup_file

    if [ ! -f "$SMB_CONF" ]; then
        write_error "Samba config not found at $SMB_CONF"
        return 1
    fi

    if share_exists; then
        write_log "Samba share [$SHARE_NAME] already exists in $SMB_CONF; skipping config append"
        return 0
    fi

    backup_file="$SMB_CONF.backup-$(date +%Y%m%d-%H%M%S)"
    write_log "Backing up $SMB_CONF to $backup_file"
    if ! sudo cp "$SMB_CONF" "$backup_file"; then
        write_error "Failed to back up Samba config"
        return 1
    fi

    write_log "Appending [$SHARE_NAME] share to $SMB_CONF"
    if ! sudo tee -a "$SMB_CONF" >/dev/null <<EOF

[$SHARE_NAME]
   path = $share_path
   browseable = yes
   read only = no
   guest ok = no
   valid users = $user
   create mask = 0664
   directory mask = 0775
EOF
    then
        write_error "Failed to append Samba share config"
        sudo cp "$backup_file" "$SMB_CONF" || true
        return 1
    fi

    if ! sudo testparm -s >/dev/null; then
        write_error "Samba config validation failed; restoring backup"
        sudo cp "$backup_file" "$SMB_CONF" || true
        return 1
    fi

    return 0
}

prepare_share_directory(){
    local user="$1"
    local share_path="$2"

    mkdir -p "$share_path"
    chmod 775 "$share_path"

    if ! sudo chown "$user:$user" "$share_path"; then
        write_error "Failed to set owner on $share_path"
        return 1
    fi

    if getent group sambashare >/dev/null 2>&1; then
        sudo usermod -aG sambashare "$user" || true
    fi

    return 0
}

restart_samba_services(){
    if command -v systemctl >/dev/null 2>&1; then
        if ! sudo systemctl enable --now smbd; then
            write_error "Failed to enable/start smbd"
            return 1
        fi

        if systemctl list-unit-files nmbd.service >/dev/null 2>&1; then
            sudo systemctl enable --now nmbd || true
        fi
    else
        sudo service smbd restart || return 1
    fi

    if command -v ufw >/dev/null 2>&1 && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        sudo ufw allow Samba || true
    fi

    return 0
}

main(){
    local user
    local home_dir
    local share_path

    user=$(target_user)
    home_dir=$(target_home "$user")
    share_path="$home_dir/projects"

    write_log "Setting up Samba share [$SHARE_NAME] at $share_path for $user"

    if ! install_samba_packages; then
        return 1
    fi

    if ! prepare_share_directory "$user" "$share_path"; then
        return 1
    fi

    if ! prompt_samba_password "$user"; then
        return 1
    fi

    if ! configure_samba_user "$user"; then
        return 1
    fi

    if ! append_share_config "$user" "$share_path"; then
        return 1
    fi

    if ! restart_samba_services; then
        return 1
    fi

    write_log "Samba setup complete. Share: //$HOSTNAME/$SHARE_NAME"
    return 0
}

main
