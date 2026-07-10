#!/bin/bash
#
# Installs Neovim and a Lua-based development configuration
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
LOG_FILE="./install-nvim-log.txt"

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

check_nvim_version(){
    local required_version="0.9.0"
    local current_version
    local lowest_version

    current_version=$(nvim --version | sed -n 's/^NVIM v//p' | head -n 1)
    lowest_version=$(printf '%s\n%s\n' "$required_version" "$current_version" | sort -V | head -n 1)

    if [ "$lowest_version" != "$required_version" ]; then
        write_error "Neovim $required_version or newer is required, but found $current_version"
        return 1
    fi

    return 0
}

main(){
    local script_dir
    local source_dir
    local target_dir
    local backup_dir

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source_dir="$script_dir/config"
    target_dir="$HOME/.config/nvim"

    write_log "Setting up Neovim development environment"

    if [ ! -d "$source_dir" ]; then
        write_error "Neovim config source not found at $source_dir"
        return 1
    fi

    sudo apt update

    write_log "Installing Neovim and supporting tools"
    sudo apt install -y \
        neovim \
        git \
        curl \
        unzip \
        ripgrep \
        fd-find \
        build-essential

    if ! command -v nvim >/dev/null 2>&1; then
        write_error "Neovim was not found after installation"
        return 1
    fi

    check_nvim_version
    if [ $? -ne 0 ]; then
        return 1
    fi

    mkdir -p "$HOME/.config"

    if [ -e "$target_dir" ] && [ ! -f "$target_dir/.dev-dependencies-nvim" ]; then
        backup_dir="$target_dir.backup-$(date +%Y%m%d-%H%M%S)"
        write_log "Backing up existing Neovim config to $backup_dir"
        mv "$target_dir" "$backup_dir"
    fi

    if [ -e "$target_dir" ]; then
        rm -rf "$target_dir"
    fi

    mkdir -p "$target_dir"
    cp -R "$source_dir"/. "$target_dir"/

    write_log "Neovim config installed to $target_dir"
    write_log "Open Neovim and run ':Lazy sync' if plugins do not install automatically"

    return 0
}

main
