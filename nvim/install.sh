#!/bin/bash
#
# Installs the latest official Neovim release and a Lua-based development configuration
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

    if ! command -v nvim >/dev/null 2>&1; then
        return 1
    fi

    current_version=$(nvim --version | sed -n 's/^NVIM v//p' | head -n 1)
    if [ -z "$current_version" ]; then
        write_error "Unable to detect Neovim version"
        return 1
    fi

    lowest_version=$(printf '%s\n%s\n' "$required_version" "$current_version" | sort -V | head -n 1)

    if [ "$lowest_version" != "$required_version" ]; then
        write_error "Neovim $required_version or newer is required, but found $current_version"
        return 1
    fi

    return 0
}

check_nvim_binary_version(){
    local nvim_binary="$1"
    local required_version="0.9.0"
    local current_version
    local lowest_version

    if [ ! -x "$nvim_binary" ]; then
        return 1
    fi

    current_version=$("$nvim_binary" --version | sed -n 's/^NVIM v//p' | head -n 1)
    if [ -z "$current_version" ]; then
        return 1
    fi

    lowest_version=$(printf '%s\n%s\n' "$required_version" "$current_version" | sort -V | head -n 1)
    [ "$lowest_version" = "$required_version" ]
}

link_user_nvim(){
    local nvim_binary

    if [ -x /usr/local/bin/nvim ] && check_nvim_binary_version /usr/local/bin/nvim; then
        nvim_binary="/usr/local/bin/nvim"
    else
        nvim_binary=$(command -v nvim)
    fi

    if [ -z "$nvim_binary" ]; then
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    ln -sfn "$nvim_binary" "$HOME/.local/bin/nvim"

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
}

warn_about_stale_system_nvim(){
    if [ -x /usr/bin/nvim ] && ! check_nvim_binary_version /usr/bin/nvim; then
        write_log "/usr/bin/nvim is older than this config supports; use $(command -v nvim) or ensure /usr/local/bin or ~/.local/bin appears before /usr/bin in PATH"
    fi
}

install_official_nvim(){
    local arch
    local asset_name
    local install_dir
    local backup_dir
    local temp_dir
    local url

    case "$(uname -m)" in
        x86_64)
            asset_name="nvim-linux-x86_64"
            ;;
        aarch64|arm64)
            asset_name="nvim-linux-arm64"
            ;;
        *)
            write_error "Unsupported CPU architecture for official Neovim install: $(uname -m)"
            return 1
            ;;
    esac

    install_dir="/opt/$asset_name"
    url="https://github.com/neovim/neovim/releases/latest/download/$asset_name.tar.gz"
    temp_dir=$(mktemp -d)

    if [ -z "$temp_dir" ]; then
        write_error "Failed to create temporary directory for Neovim download"
        return 1
    fi

    write_log "Installing official Neovim release from $url"
    if ! curl -fL "$url" -o "$temp_dir/nvim.tar.gz"; then
        write_error "Failed to download official Neovim release"
        rm -rf "$temp_dir"
        return 1
    fi

    if [ -e "$install_dir" ]; then
        backup_dir="$install_dir.backup-$(date +%Y%m%d-%H%M%S)"

        if [ -d "$install_dir" ] && [ -z "$(sudo find "$install_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
            if ! sudo rmdir "$install_dir"; then
                write_error "Failed to remove empty previous Neovim install at $install_dir"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            write_log "Backing up previous Neovim install to $backup_dir"
            if ! sudo mv "$install_dir" "$backup_dir"; then
                write_error "Failed to back up previous Neovim install at $install_dir"
                rm -rf "$temp_dir"
                return 1
            fi
        fi
    fi

    if ! sudo tar -C /opt -xzf "$temp_dir/nvim.tar.gz"; then
        write_error "Failed to extract official Neovim release"
        rm -rf "$temp_dir"
        return 1
    fi

    if [ ! -x "$install_dir/bin/nvim" ]; then
        write_error "Official Neovim binary was not found at $install_dir/bin/nvim"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! sudo ln -sfn "$install_dir/bin/nvim" /usr/local/bin/nvim; then
        write_error "Failed to link official Neovim to /usr/local/bin/nvim"
        rm -rf "$temp_dir"
        return 1
    fi

    hash -r
    rm -rf "$temp_dir"
    return 0
}

sync_lazy_plugins(){
    write_log "Installing and updating Neovim plugins with lazy.nvim"

    if ! nvim --headless "+Lazy! sync" "+qa"; then
        write_error "Failed to install or update Neovim plugins"
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

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    write_log "Installing Neovim supporting tools"
    if ! sudo apt install -y \
        git \
        curl \
        ca-certificates \
        tar \
        gzip \
        unzip \
        ripgrep \
        fd-find \
        build-essential; then
        write_error "Failed to install Neovim supporting tools"
        return 1
    fi

    if ! install_official_nvim; then
        return 1
    fi

    if ! check_nvim_version; then
        return 1
    fi

    if ! link_user_nvim; then
        write_error "Failed to link Neovim into ~/.local/bin"
        return 1
    fi

    warn_about_stale_system_nvim

    mkdir -p "$HOME/.config"

    if [ -e "$target_dir" ]; then
        backup_dir="$target_dir.backup-$(date +%Y%m%d-%H%M%S)"

        if [ -d "$target_dir" ] && [ -z "$(find "$target_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
            if ! rmdir "$target_dir"; then
                write_error "Failed to remove empty Neovim config directory at $target_dir"
                return 1
            fi
        else
            write_log "Backing up existing Neovim config to $backup_dir"
            if ! mv "$target_dir" "$backup_dir"; then
                write_error "Failed to back up existing Neovim config at $target_dir"
                return 1
            fi
        fi
    fi

    mkdir -p "$target_dir"
    cp -R "$source_dir"/. "$target_dir"/

    if ! sync_lazy_plugins; then
        return 1
    fi

    write_log "Neovim config installed to $target_dir"

    return 0
}

main
