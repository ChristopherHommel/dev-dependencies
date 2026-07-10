#!/bin/bash
#
# Installs Ghostty and a minimal terminal configuration
#
# Usage:
#     ./install.sh <-t> <-?>
#
# Options:
#     -t Pipe output logs to a file (tee)
#
# +------------------------------------------------------+
# | Who          | Date       | Version | Comments       |
# | Chris Hommel | 10-07-2026 | 1       | Initial set up |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# +------------------------------------------------------+

PIPE_TO_FILE=0
LOG_FILE="./install-ghostty-log.txt"

write_options(){
    write_log "Options:"
    write_log "    <-t> Pipe output to file"
    write_log "    <-?> Print options"
}

write_log(){
    if [ $PIPE_TO_FILE -eq 1 ]; then
        echo "$1" >> "$LOG_FILE"
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
            PIPE_TO_FILE=1
            write_log "Pipe to file turned on, writing to $LOG_FILE"
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
    if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        echo "$SUDO_USER"
        return 0
    fi

    id -un
}

target_home(){
    local home_dir
    local user

    user=$(target_user)
    home_dir=$(getent passwd "$user" | cut -d: -f6)
    if [ -n "$home_dir" ]; then
        echo "$home_dir"
        return 0
    fi

    echo "$HOME"
}

chown_target_user(){
    local path="$1"

    if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$path"
    fi
}

install_from_apt_if_available(){
    if ! command -v apt-cache >/dev/null 2>&1; then
        return 1
    fi

    if ! apt-cache policy ghostty 2>/dev/null | grep -q 'Candidate: [^(]'; then
        return 1
    fi

    write_log "Installing Ghostty from apt"
    sudo apt install -y ghostty
}

install_from_snap_if_available(){
    if ! command -v snap >/dev/null 2>&1; then
        return 1
    fi

    write_log "Installing Ghostty from Snap"
    sudo snap install ghostty --classic
}

install_from_debian_community_repo(){
    local codename
    local keyring="/etc/apt/keyrings/debian.griffo.io.gpg"
    local source_list="/etc/apt/sources.list.d/debian.griffo.io.list"

    if [ "${ID:-}" != "debian" ]; then
        return 1
    fi

    codename="${VERSION_CODENAME:-}"
    if [ -z "$codename" ] && command -v lsb_release >/dev/null 2>&1; then
        codename=$(lsb_release -sc 2>/dev/null)
    fi

    if [ -z "$codename" ]; then
        write_error "Unable to detect Debian codename for Ghostty repository"
        return 1
    fi

    case "$codename" in
        bookworm|trixie|forky|sid)
            ;;
        *)
            write_error "Debian Ghostty community repository does not list support for $codename"
            return 1
            ;;
    esac

    write_log "Adding Debian Ghostty community repository for $codename"
    if ! sudo install -d -m 0755 /etc/apt/keyrings; then
        write_error "Failed to create apt keyring directory"
        return 1
    fi

    if ! curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o "$keyring"; then
        write_error "Failed to install Debian Ghostty repository key"
        return 1
    fi

    if ! echo "deb [signed-by=$keyring] https://debian.griffo.io/apt $codename main" | sudo tee "$source_list" >/dev/null; then
        write_error "Failed to add Debian Ghostty repository source"
        return 1
    fi

    if ! sudo apt update; then
        write_error "Failed to update apt package lists after adding Debian Ghostty repository"
        return 1
    fi

    write_log "Installing Ghostty from Debian community repository"
    sudo apt install -y ghostty
}

install_from_ubuntu_community_package(){
    local temp_dir
    local installer_url="https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh"

    if [ "${ID:-}" != "ubuntu" ]; then
        return 1
    fi

    temp_dir=$(mktemp -d)
    if [ -z "$temp_dir" ]; then
        write_error "Failed to create temporary directory for Ghostty installer"
        return 1
    fi

    write_log "Installing Ghostty from the documented Ubuntu community package installer"
    if ! curl -fsSL "$installer_url" -o "$temp_dir/install-ghostty-ubuntu.sh"; then
        write_error "Failed to download Ubuntu Ghostty installer"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! bash "$temp_dir/install-ghostty-ubuntu.sh"; then
        write_error "Ubuntu Ghostty installer failed"
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    return 0
}

install_ghostty(){
    if command -v ghostty >/dev/null 2>&1; then
        write_log "Ghostty is already installed"
        return 0
    fi

    if install_from_apt_if_available; then
        return 0
    fi

    if install_from_debian_community_repo; then
        return 0
    fi

    if install_from_snap_if_available; then
        return 0
    fi

    if install_from_ubuntu_community_package; then
        return 0
    fi

    write_error "Failed to install Ghostty with apt, the Debian community repository, snap, or the Ubuntu community installer"
    return 1
}

install_config(){
    local script_dir
    local source_dir
    local target_dir
    local backup_file

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source_dir="$script_dir/config"
    target_dir="$(target_home)/.config/ghostty"

    if [ ! -d "$source_dir" ]; then
        write_error "Ghostty config source not found at $source_dir"
        return 1
    fi

    mkdir -p "$target_dir"

    if [ -f "$target_dir/config" ] && [ ! -f "$target_dir/.dev-dependencies-ghostty" ]; then
        backup_file="$target_dir/config.backup-$(date +%Y%m%d-%H%M%S)"
        write_log "Backing up existing Ghostty config to $backup_file"
        mv "$target_dir/config" "$backup_file"
    fi

    cp "$source_dir/config" "$target_dir/config"
    cp "$source_dir/.dev-dependencies-ghostty" "$target_dir/.dev-dependencies-ghostty"
    chown_target_user "$target_dir"

    write_log "Ghostty config installed to $target_dir/config"
    return 0
}

set_preferred_terminal(){
    local ghostty_bin
    local settings_user
    local settings_uid
    local dbus_address

    ghostty_bin=$(command -v ghostty)
    if [ -z "$ghostty_bin" ]; then
        write_error "Cannot set preferred terminal because ghostty is not on PATH"
        return 1
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        if sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$ghostty_bin" 100; then
            sudo update-alternatives --set x-terminal-emulator "$ghostty_bin" || true
        else
            write_error "Failed to register Ghostty with update-alternatives"
        fi
    fi

    if command -v gsettings >/dev/null 2>&1; then
        if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            settings_user=$(target_user)
            settings_uid=$(id -u "$settings_user" 2>/dev/null || true)
            dbus_address="unix:path=/run/user/$settings_uid/bus"

            if [ -n "$settings_uid" ] && [ -S "/run/user/$settings_uid/bus" ]; then
                if sudo -u "$settings_user" env DBUS_SESSION_BUS_ADDRESS="$dbus_address" gsettings writable org.gnome.desktop.default-applications.terminal exec >/dev/null 2>&1; then
                    sudo -u "$settings_user" env DBUS_SESSION_BUS_ADDRESS="$dbus_address" gsettings set org.gnome.desktop.default-applications.terminal exec "$ghostty_bin" || true
                fi
            else
                write_log "Skipping GNOME terminal preference because no DBus session was found for $settings_user"
            fi
        elif gsettings writable org.gnome.desktop.default-applications.terminal exec >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.default-applications.terminal exec "$ghostty_bin" || true
        fi
    fi

    write_log "Ghostty is installed and configured as preferred where supported"
    return 0
}

main(){
    write_log "Setting up Ghostty terminal"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    if ! sudo apt install -y curl ca-certificates gnupg; then
        write_error "Failed to install Ghostty prerequisites"
        return 1
    fi

    if ! install_ghostty; then
        return 1
    fi

    if ! command -v ghostty >/dev/null 2>&1; then
        write_error "Ghostty was not found after installation"
        return 1
    fi

    ghostty --version

    if ! install_config; then
        return 1
    fi

    set_preferred_terminal

    write_log "Ghostty setup complete"
    return 0
}

main
