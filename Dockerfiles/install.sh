#!/bin/bash
#
# Pulls down default docker files for different environments
#
# Usage:
#     ./install.sh <-t> <-?>
#
# Options:
#     -t Pipe output logs to a file (tee)
#
# +------------------------------------------------------+
# | Who          | Date       | Version | Comments       |
# | Chris Hommel | 23-03-2025 | 1       | Initial set up |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# |              |            |         |                |
# +------------------------------------------------------+

PIPE_TO_FILE=0
LOG_FILE="./install-log.txt"

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

target_home(){
    local home_dir

    if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        home_dir=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        if [ -n "$home_dir" ]; then
            echo "$home_dir"
            return 0
        fi
    fi

    echo "$HOME"
}

chown_target_user(){
    local path="$1"

    if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$path"
    fi
}

main(){
    local script_dir
    local source_dir
    local target_dir

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source_dir="$script_dir/examples"
    target_dir="$(target_home)/Dockerfiles"

    if [ ! -d "$source_dir" ]; then
        write_error "Dockerfile examples not found at $source_dir"
        return 1
    fi

    mkdir -p "$target_dir"

    if ! cp -Rn "$source_dir"/. "$target_dir"/; then
        write_error "Failed to copy Dockerfile examples to $target_dir"
        return 1
    fi

    chown_target_user "$target_dir"

    write_log "Dockerfile examples copied to $target_dir without overwriting existing files"

    return 0
}

main
