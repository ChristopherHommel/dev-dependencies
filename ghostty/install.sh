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

    if install_from_snap_if_available; then
        return 0
    fi

    if install_from_ubuntu_community_package; then
        return 0
    fi

    write_error "Failed to install Ghostty with apt, snap, or the Ubuntu community installer"
    return 1
}

install_config(){
    local script_dir
    local source_dir
    local target_dir
    local backup_file

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source_dir="$script_dir/config"
    target_dir="$HOME/.config/ghostty"

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

    write_log "Ghostty config installed to $target_dir/config"
    return 0
}

set_preferred_terminal(){
    local ghostty_bin

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

    if command -v gsettings >/dev/null 2>&1 && gsettings writable org.gnome.desktop.default-applications.terminal exec >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.default-applications.terminal exec "$ghostty_bin" || true
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

    if ! sudo apt install -y curl ca-certificates; then
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
