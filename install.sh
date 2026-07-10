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
        awk \
        xargs \
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

    chmod +x ./docker/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./docker/install.sh -t
    else
        ./docker/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Docker installed"
        return 0
    else
        write_error "Failed to install Docker"
        return 1
    fi
}

install_node(){
    write_log "Installing Node.js environment"

    chmod +x ./node/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./node/install.sh -t
    else
        ./node/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Node.js environment installed"
        return 0
    else
        write_error "Failed to install Node.js environment"
        return 1
    fi
}

install_python(){
    write_log "Installing a Python environment"

    chmod +x ./python/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./python/install.sh -t
    else
        ./python/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Python environment installed"
        return 0
    else
        write_error "Failed to install a Python environment"
        return 1
    fi
}

install_rust(){
    write_log "Installing Rust environment"

    chmod +x ./rust/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./rust/install.sh -t
    else
        ./rust/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Rust environment installed"
        return 0
    else
        write_error "Failed to install Rust environment"
        return 1
    fi
}

install_java(){
    write_log "Installing Java environment"

    chmod +x ./java/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./java/install.sh -t
    else
        ./java/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Java environment installed"
        return 0
    else
        write_error "Failed to install Java environment"
        return 1
    fi
}

install_nvim(){
    write_log "Installing Neovim environment"

    chmod +x ./nvim/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./nvim/install.sh -t
    else
        ./nvim/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Neovim environment installed"
        return 0
    else
        write_error "Failed to install Neovim environment"
        return 1
    fi
}

install_zig(){
    write_log "Installing Zig environment"

    chmod +x ./zig/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./zig/install.sh -t
    else
        ./zig/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Zig environment installed"
        return 0
    else
        write_error "Failed to install Zig environment"
        return 1
    fi
}

install_bun(){
    write_log "Installing Bun environment"

    chmod +x ./bun/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./bun/install.sh -t
    else
        ./bun/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Bun environment installed"
        return 0
    else
        write_error "Failed to install Bun environment"
        return 1
    fi
}

install_typescript(){
    write_log "Installing TypeScript environment"

    chmod +x ./typescript/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./typescript/install.sh -t
    else
        ./typescript/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "TypeScript environment installed"
        return 0
    else
        write_error "Failed to install TypeScript environment"
        return 1
    fi
}

install_docker_files(){
    write_log "Copying docker files"

    chmod +x ./Dockerfiles/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./Dockerfiles/install.sh -t
    else
        ./Dockerfiles/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Copying docker files done"
        return 0
    else
        write_error "Failed to copy docker files done"
        return 1
    fi
}

install_tmux_sessions(){
    write_log "Installing tmux sessions"

    chmod +x ./tmux_sessions/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./tmux_sessions/install.sh -t
    else
        ./tmux_sessions/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Tmux sessions done"
        return 0
    else
        write_error "Failed to load tmux sessions"
        return 1
    fi
}

install_dotfiles(){
    write_log "Installing dotfiles"

    chmod +x ./dotfiles/install.sh

    if [ $PIPE_TO_FILE -eq 1 ]; then
        ./dotfiles/install.sh -t
    else
        ./dotfiles/install.sh
    fi

    if [ $? -eq 0 ]; then
        write_log "Dotfiles done"
        return 0
    else
        write_error "Failed to load dotfiles"
        return 1
    fi
}

remove_script_execute_permissions(){
    local script

    write_log "Removing execute permissions from shell scripts"

    shopt -s globstar nullglob
    for script in ./*.sh ./**/*.sh; do
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

tmux_start(){
    # Load tmux if it exists
    # Yes this will run it twice, the first time is without dotfiles loaded
    if [ -f ~/dev-dependencies/tmux_sessions/repo/tmux-sessions/run.sh ]; then

        cd ~/dev-dependencies/tmux_sessions/repo/tmux-sessions/
        chmod +x ./run.sh
        ./run.sh

        cd $HOME

        tmux a
    fi
}

main(){
    write_log "======== Starting Dev Environment Setup ========"
    write_log "Date: $(date)"
    write_log "User: $(whoami)"
    write_log "System: $(uname -a)"
    write_log "================================================"

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

    run_install_step "Dockerfile examples" install_docker_files
    run_install_step "Tmux sessions" install_tmux_sessions

    # Always this last
    run_install_step "Dotfiles" install_dotfiles
    run_install_step "Remove shell script execute permissions" remove_script_execute_permissions

    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi

    tmux_start

    if [ $INSTALL_FAILURES -ne 0 ]; then
        write_error "$INSTALL_FAILURES install step(s) failed"
        return 1
    fi

    write_log "All install steps completed successfully"
    return 0
}

main
