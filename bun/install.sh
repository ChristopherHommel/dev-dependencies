#!/bin/bash
#
# Installs Bun
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
LOG_FILE="./install-bun-log.txt"

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
    write_log "Setting up Bun development environment"

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    if ! sudo apt install -y curl unzip; then
        write_error "Failed to install Bun prerequisites"
        return 1
    fi

    if ! curl -fsSL https://bun.sh/install | bash; then
        write_error "Bun install script failed"
        return 1
    fi

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    if ! command -v bun >/dev/null 2>&1; then
        write_error "Bun was not found after installation"
        return 1
    fi

    bun --version

    write_log "Bun setup complete"
    write_log "You may need to restart your terminal or run 'source ~/.bashrc' to use bun"

    return 0
}

main
