#!/bin/bash
#
# Installs tmux sessions
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
LOG_FILE="./install-tmux-sessions-log.txt"

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

ensure_not_root(){
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        write_error "Do not run this installer with sudo; run it as your normal user. It uses sudo only when it needs to repair managed clone ownership or install packages."
        return 1
    fi

    return 0
}

repair_owned_path(){
    local path="$1"

    if [ -e "$path" ] && [ ! -w "$path" ]; then
        write_log "Repairing ownership for $path"
        if ! sudo chown -R "$(id -u):$(id -g)" "$path"; then
            write_error "Failed to repair ownership for $path"
            return 1
        fi
    fi

    return 0
}

clone_or_update_repo(){
    local parent_dir="$1"
    local repo_dir="$2"
    local repo_url="$3"
    local backup_dir

    mkdir -p "$parent_dir"

    if ! repair_owned_path "$parent_dir"; then
        return 1
    fi

    if [ -d "$repo_dir/.git" ]; then
        if ! repair_owned_path "$repo_dir"; then
            return 1
        fi

        write_log "Updating existing tmux-sessions clone"
        if [ -n "$(git -C "$repo_dir" status --porcelain)" ]; then
            backup_dir="$repo_dir.backup-$(date +%Y%m%d-%H%M%S)"
            write_log "Moving modified tmux-sessions clone to $backup_dir"
            mv "$repo_dir" "$backup_dir" || return 1
            write_log "Cloning tmux-sessions"
            git clone "$repo_url" "$repo_dir"
            return $?
        fi

        git -C "$repo_dir" pull --ff-only
        return $?
    fi

    if [ -e "$repo_dir" ]; then
        backup_dir="$repo_dir.backup-$(date +%Y%m%d-%H%M%S)"
        write_log "Moving non-git tmux-sessions directory to $backup_dir"
        mv "$repo_dir" "$backup_dir"
    fi

    write_log "Cloning tmux-sessions"
    git clone "$repo_url" "$repo_dir"
}

ensure_python_venv_package(){
    if python3 -m venv --help >/dev/null 2>&1; then
        return 0
    fi

    write_log "Installing Python venv support"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update || true
        sudo apt-get install -y python3-venv
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3-venv
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3-venv
    else
        write_error "Could not find a package manager for Python venv support"
        return 1
    fi
}

install_tmux_if_needed(){
    if command -v tmux >/dev/null 2>&1; then
        write_log "Found $(tmux -V)"
        return 0
    fi

    write_log "Installing tmux"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update || true
        sudo apt-get install -y tmux
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y tmux
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y tmux
    else
        write_error "Could not find a package manager for tmux"
        return 1
    fi
}

run_tmux_builder(){
    local repo_dir="$1"
    local venv_dir="$HOME/.local/share/dev-dependencies/tmux-sessions/.venv"
    local current_dir

    if ! ensure_python_venv_package; then
        return 1
    fi

    mkdir -p "$(dirname "$venv_dir")"

    if [ ! -x "$venv_dir/bin/python" ]; then
        write_log "Creating tmux-sessions virtual environment at $venv_dir"
        if ! python3 -m venv "$venv_dir"; then
            write_error "Failed to create tmux-sessions virtual environment"
            return 1
        fi
    fi

    if [ -s "$repo_dir/requirements.txt" ]; then
        write_log "Installing tmux-sessions Python requirements"
        if ! "$venv_dir/bin/pip" install -r "$repo_dir/requirements.txt"; then
            write_error "Failed to install tmux-sessions Python requirements"
            return 1
        fi
    fi

    if ! install_tmux_if_needed; then
        return 1
    fi

    current_dir="$PWD"
    cd "$repo_dir" || return 1
    "$venv_dir/bin/python" build-dev-session.py
    local status=$?
    cd "$current_dir" || return 1

    return $status
}

main() {
    local script_dir
    local parent_dir
    local repo_dir

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    parent_dir="$script_dir/repo"
    repo_dir="$parent_dir/tmux-sessions"

    if ! ensure_not_root; then
        return 1
    fi

    if ! clone_or_update_repo "$parent_dir" "$repo_dir" "https://github.com/ChristopherHommel/tmux-sessions.git"; then
        return 1
    fi

    if ! run_tmux_builder "$repo_dir"; then
        write_error "Failed to build tmux sessions"
        return 1
    fi

    return 0
}

main
