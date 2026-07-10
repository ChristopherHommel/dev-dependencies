#!/bin/bash
#
# Installs dependencies for my development environment
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

INSTALL_FAILURES=0

ensure_not_root(){
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        write_error "Do not run this installer with sudo; run 'bash install.sh' as your normal user. The script uses sudo only for system-level steps."
        return 1
    fi

    return 0
}

ensure_group(){
    local group="$1"

    if getent group "$group" >/dev/null 2>&1; then
        return 0
    fi

    write_log "Creating group $group"
    if ! sudo groupadd "$group"; then
        write_error "Failed to create group $group"
        return 1
    fi

    return 0
}

ensure_user_in_group(){
    local user="$1"
    local group="$2"

    if id -nG "$user" | tr ' ' '\n' | grep -Fxq "$group"; then
        return 0
    fi

    write_log "Adding $user to group $group"
    if ! sudo usermod -aG "$group" "$user"; then
        write_error "Failed to add $user to group $group"
        return 1
    fi

    return 0
}

configure_user_group(){
    local user

    user=$(id -un)

    if ! ensure_group "$user"; then
        return 1
    fi

    if ! ensure_user_in_group "$user" "$user"; then
        return 1
    fi

    return 0
}

run_install_step(){
    local step_name="$1"
    local step_function="$2"

    write_log "-------- $step_name --------"

    "$step_function"
    if [ $? -eq 0 ]; then
        write_log "$step_name completed"
        return 0
    fi

    write_error "$step_name failed; continuing with next install"
    INSTALL_FAILURES=$((INSTALL_FAILURES + 1))
    return 1
}

run_child_installer(){
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        write_error "Installer script not found: $script_path"
        return 1
    fi

    if ! chmod +x "$script_path"; then
        write_error "Failed to make installer executable: $script_path"
        return 1
    fi

    if [ $PIPE_TO_FILE -eq 1 ]; then
        "$script_path" -t
    else
        "$script_path"
    fi
}

install_main_dependencies(){
    write_log "Installing main dependencies"

    sudo dpkg --configure -a

    sudo apt update -y
    sudo apt full-upgrade -y

    sudo apt install -y parallel \
        git \
        curl \
        wget \
        jq \
        build-essential \
        pkg-config \
        libssl-dev \
        cmake \
        libclang-dev \
        llvm \
        valgrind \
        gdb \
        lldb \
        tree \
        ripgrep \
        fzf \
        bat \
        nmap \
        zip \
        htop \
        sed \
        gawk \
        xargs \
	bat \
        openssh-server \
        openssh-client


    sudo systemctl enable ssh
    sudo systemctl start ssh

    sudo apt update
    sudo apt full-upgrade

    write_log "Main dependencies done"

    return 0
}

install_docker(){
    write_log "Installing Docker"

    if run_child_installer "./docker/install.sh"; then
        write_log "Docker installed"
        return 0
    fi

    write_error "Failed to install Docker"
    return 1
}

install_node(){
    write_log "Installing Node.js environment"

    if run_child_installer "./node/install.sh"; then
        write_log "Node.js environment installed"
        return 0
    fi

    write_error "Failed to install Node.js environment"
    return 1
}

install_python(){
    write_log "Installing a Python environment"

    if run_child_installer "./python/install.sh"; then
        write_log "Python environment installed"
        return 0
    fi

    write_error "Failed to install a Python environment"
    return 1
}

install_rust(){
    write_log "Installing Rust environment"

    if run_child_installer "./rust/install.sh"; then
        write_log "Rust environment installed"
        return 0
    fi

    write_error "Failed to install Rust environment"
    return 1
}

install_java(){
    write_log "Installing Java environment"

    if run_child_installer "./java/install.sh"; then
        write_log "Java environment installed"
        return 0
    fi

    write_error "Failed to install Java environment"
    return 1
}

install_nvim(){
    write_log "Installing Neovim environment"

    if run_child_installer "./nvim/install.sh"; then
        write_log "Neovim environment installed"
        return 0
    fi

    write_error "Failed to install Neovim environment"
    return 1
}

install_ghostty(){
    write_log "Installing Ghostty terminal"

    if run_child_installer "./ghostty/install.sh"; then
        write_log "Ghostty terminal installed"
        return 0
    fi

    write_error "Failed to install Ghostty terminal"
    return 1
}

install_samba(){
    write_log "Installing Samba share"

    if run_child_installer "./samba/install.sh"; then
        write_log "Samba share installed"
        return 0
    fi

    write_error "Failed to install Samba share"
    return 1
}

install_zig(){
    write_log "Installing Zig environment"

    if run_child_installer "./zig/install.sh"; then
        write_log "Zig environment installed"
        return 0
    fi

    write_error "Failed to install Zig environment"
    return 1
}

install_bun(){
    write_log "Installing Bun environment"

    if run_child_installer "./bun/install.sh"; then
        write_log "Bun environment installed"
        return 0
    fi

    write_error "Failed to install Bun environment"
    return 1
}

install_typescript(){
    write_log "Installing TypeScript environment"

    if run_child_installer "./typescript/install.sh"; then
        write_log "TypeScript environment installed"
        return 0
    fi

    write_error "Failed to install TypeScript environment"
    return 1
}

install_docker_files(){
    write_log "Copying docker files"

    if run_child_installer "./Dockerfiles/install.sh"; then
        write_log "Copying docker files done"
        return 0
    fi

    write_error "Failed to copy docker files done"
    return 1
}

install_tmux_sessions(){
    write_log "Installing tmux sessions"

    if run_child_installer "./tmux_sessions/install.sh"; then
        write_log "Tmux sessions done"
        return 0
    fi

    write_error "Failed to load tmux sessions"
    return 1
}

install_dotfiles(){
    write_log "Installing dotfiles"

    if run_child_installer "./dotfiles/install.sh"; then
        write_log "Dotfiles done"
        return 0
    fi

    write_error "Failed to load dotfiles"
    return 1
}

remove_script_execute_permissions(){
    local script

    write_log "Removing execute permissions from shell scripts"

    shopt -s globstar nullglob
    for script in ./*.sh ./**/*.sh; do
        case "$script" in
            */repo/*)
                continue
                ;;
        esac

        if [ -f "$script" ]; then
            if ! chmod -x "$script"; then
                write_error "Failed to remove execute permission from $script"
                shopt -u globstar nullglob
                return 1
            fi
        fi
    done
    shopt -u globstar nullglob

    write_log "Removed execute permissions from shell scripts"
    return 0
}

launch_ghostty(){
    if ! command -v ghostty >/dev/null 2>&1; then
        write_log "Ghostty is not available on PATH; skipping terminal launch"
        return 0
    fi

    if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        write_log "No graphical session detected; skipping Ghostty launch"
        return 0
    fi

    write_log "Launching Ghostty"
    if command -v setsid >/dev/null 2>&1; then
        setsid ghostty >/dev/null 2>&1 &
    else
        nohup ghostty >/dev/null 2>&1 &
    fi

    return 0
}

main(){
    if ! ensure_not_root; then
        return 1
    fi

    write_log "======== Starting Dev Environment Setup ========"
    write_log "Date: $(date)"
    write_log "User: $(whoami)"
    write_log "System: $(uname -a)"
    write_log "================================================"

    run_install_step "User group" configure_user_group
    run_install_step "Main dependencies" install_main_dependencies
    run_install_step "Docker" install_docker
    run_install_step "Node.js" install_node
    run_install_step "TypeScript" install_typescript
    run_install_step "Bun" install_bun
    run_install_step "Python" install_python
    run_install_step "Java" install_java
    run_install_step "Rust" install_rust
    run_install_step "Zig" install_zig
    run_install_step "Neovim" install_nvim
    run_install_step "Ghostty" install_ghostty
    run_install_step "Samba" install_samba

    run_install_step "Dockerfile examples" install_docker_files
    run_install_step "Tmux sessions" install_tmux_sessions

    # Always this last
    run_install_step "Dotfiles" install_dotfiles
    run_install_step "Remove shell script execute permissions" remove_script_execute_permissions

    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi

    launch_ghostty

    if [ $INSTALL_FAILURES -ne 0 ]; then
        write_error "$INSTALL_FAILURES install step(s) failed"
        return 1
    fi

    write_log "All install steps completed successfully"
    return 0
}

main
