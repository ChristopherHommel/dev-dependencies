#!/bin/bash
#
# Installs Zig from the official Zig download index
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
LOG_FILE="./install-zig-log.txt"

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

main(){
    local arch
    local zig_target
    local zig_version
    local tarball_url
    local shasum
    local install_root="$HOME/.local/zig"
    local bin_dir="$HOME/.local/bin"
    local temp_dir

    write_log "Setting up Zig development environment"

    case "$(uname -m)" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            write_error "Unsupported CPU architecture for Zig: $(uname -m)"
            return 1
            ;;
    esac

    zig_target="$arch-linux"

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    if ! sudo apt install -y curl jq xz-utils tar coreutils; then
        write_error "Failed to install Zig prerequisites"
        return 1
    fi

    temp_dir=$(mktemp -d)
    if [ -z "$temp_dir" ]; then
        write_error "Failed to create temporary directory"
        return 1
    fi

    if ! curl -fsSL "https://ziglang.org/download/index.json" -o "$temp_dir/index.json"; then
        write_error "Failed to download Zig release index"
        rm -rf "$temp_dir"
        return 1
    fi

    zig_version=$(jq -r 'to_entries | map(select(.key != "master")) | .[0].key' "$temp_dir/index.json")
    tarball_url=$(jq -r --arg version "$zig_version" --arg target "$zig_target" '.[$version][$target].tarball // empty' "$temp_dir/index.json")
    shasum=$(jq -r --arg version "$zig_version" --arg target "$zig_target" '.[$version][$target].shasum // empty' "$temp_dir/index.json")

    if [ -z "$zig_version" ] || [ -z "$tarball_url" ] || [ -z "$shasum" ]; then
        write_error "Failed to find a Zig release for $zig_target"
        rm -rf "$temp_dir"
        return 1
    fi

    if command -v zig >/dev/null 2>&1 && zig version | grep -qx "$zig_version"; then
        write_log "Zig $zig_version is already installed"
        rm -rf "$temp_dir"
        return 0
    fi

    write_log "Downloading Zig $zig_version for $zig_target"
    if ! curl -fL "$tarball_url" -o "$temp_dir/zig.tar.xz"; then
        write_error "Failed to download Zig $zig_version"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! printf '%s  %s\n' "$shasum" "$temp_dir/zig.tar.xz" | sha256sum -c -; then
        write_error "Zig download checksum verification failed"
        rm -rf "$temp_dir"
        return 1
    fi

    mkdir -p "$install_root" "$bin_dir"

    if ! tar -xJf "$temp_dir/zig.tar.xz" -C "$temp_dir"; then
        write_error "Failed to extract Zig archive"
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$install_root/$zig_version"
    if ! mv "$temp_dir"/zig-* "$install_root/$zig_version"; then
        write_error "Failed to install Zig into $install_root/$zig_version"
        rm -rf "$temp_dir"
        return 1
    fi

    ln -sfn "$install_root/$zig_version/zig" "$bin_dir/zig"

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    rm -rf "$temp_dir"
    write_log "Zig $zig_version installed to $install_root/$zig_version"
    write_log "You may need to restart your terminal or run 'source ~/.bashrc' to use zig"

    return 0
}

main
