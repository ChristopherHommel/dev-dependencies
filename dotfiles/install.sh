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
LOG_FILE="./install-dotfiles-log.txt"

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
        write_error "Do not run this installer with sudo; run it as your normal user. It uses sudo only when it needs to repair managed clone ownership."
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

        write_log "Updating existing dotfiles clone"
        if [ -n "$(git -C "$repo_dir" status --porcelain)" ]; then
            backup_dir="$repo_dir.backup-$(date +%Y%m%d-%H%M%S)"
            write_log "Moving modified dotfiles clone to $backup_dir"
            mv "$repo_dir" "$backup_dir" || return 1
            write_log "Cloning dotfiles"
            git clone "$repo_url" "$repo_dir"
            return $?
        fi

        git -C "$repo_dir" pull --ff-only
        return $?
    fi

    if [ -e "$repo_dir" ]; then
        backup_dir="$repo_dir.backup-$(date +%Y%m%d-%H%M%S)"
        write_log "Moving non-git dotfiles directory to $backup_dir"
        mv "$repo_dir" "$backup_dir"
    fi

    write_log "Cloning dotfiles"
    git clone "$repo_url" "$repo_dir"
}

install_dotfiles_from_repo(){
    local repo_dir="$1"

    write_log "Installing dotfiles from $repo_dir"

    cp "$repo_dir/.profile" "$HOME/.profile" || return 1
    cp "$repo_dir/.bashrc" "$HOME/.bashrc" || return 1
    cp "$repo_dir/.gitconfig" "$HOME/.gitconfig" || return 1
    cp "$repo_dir/.tmux.conf" "$HOME/.tmux.conf" || return 1

    if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
        write_log "Reloading tmux config"
        if ! tmux source-file "$HOME/.tmux.conf"; then
            write_log "Could not reload tmux config; it will apply to new sessions"
        fi
    fi

    return 0
}

main() {
    local script_dir
    local parent_dir
    local repo_dir

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    parent_dir="$script_dir/repo"
    repo_dir="$parent_dir/dotfiles"

    if ! ensure_not_root; then
        return 1
    fi

    if ! clone_or_update_repo "$parent_dir" "$repo_dir" "https://github.com/ChristopherHommel/dotfiles.git"; then
        return 1
    fi

    install_dotfiles_from_repo "$repo_dir"
}

main
