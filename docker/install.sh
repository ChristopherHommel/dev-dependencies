#!/bin/bash
#
# Installs Docker and Docker Compose
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
LOG_FILE="./install-docker-log.txt"

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


main(){
    write_log "Setting up Docker and Docker Compose"

    sudo apt update

    write_log "Installing required dependencies"
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    write_log "Adding Docker's official GPG key"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    write_log "Setting up Docker repository"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update

    write_log "Installing Docker"
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    write_log "Installing Docker Compose"
    sudo apt install -y docker-compose-plugin

    write_log "Adding current user to docker group"
    sudo usermod -aG docker $USER

    write_log "Verifying Docker installation"
    docker --version

    write_log "Verifying Docker Compose installation"
    docker compose version

    write_log "Running test container"
    docker run --rm hello-world

    write_log "Docker and Docker Compose setup complete"

    return 0
}

main