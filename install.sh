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

    install_main_dependencies
    if [ $? -ne 0 ]; then
        write_error "Failed to install main dependencies"
        return 1
    fi

    install_docker
    install_node
    install_python
    install_java
    install_rust

    install_docker_files
    install_tmux_sessions

    # Always this last
    install_dotfiles
    source ~/.bashrc

    tmux_start
}

main