#!/bin/bash
#
# Installs TypeScript tooling through npm
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
LOG_FILE="./install-typescript-log.txt"

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
    write_log "Setting up TypeScript tooling"

    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
    fi

    if ! command -v npm >/dev/null 2>&1; then
        write_error "npm is required for TypeScript tooling; install Node.js first"
        return 1
    fi

    if ! npm install -g typescript ts-node eslint prettier; then
        write_error "Failed to install TypeScript npm packages"
        return 1
    fi

    if ! command -v tsc >/dev/null 2>&1; then
        write_error "TypeScript compiler was not found after installation"
        return 1
    fi

    tsc --version

    write_log "TypeScript tooling setup complete"

    return 0
}

main
