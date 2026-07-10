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
    local os_id
    local os_codename
    local docker_repo_os

    write_log "Setting up Docker and Docker Compose"

    if [ ! -f /etc/os-release ]; then
        write_error "Cannot detect operating system: /etc/os-release not found"
        return 1
    fi

    . /etc/os-release
    os_id="$ID"
    os_codename="${VERSION_CODENAME:-}"

    if [ -z "$os_codename" ]; then
        os_codename=$(lsb_release -cs 2>/dev/null)
    fi

    case "$os_id" in
        ubuntu|debian)
            docker_repo_os="$os_id"
            ;;
        *)
            write_error "Docker installer supports Ubuntu and Debian, but detected $os_id"
            return 1
            ;;
    esac

    if [ -z "$os_codename" ]; then
        write_error "Cannot detect distro codename for Docker apt repository"
        return 1
    fi

    if ! sudo apt update; then
        write_error "Failed to update apt package lists"
        return 1
    fi

    write_log "Installing required dependencies"
    if ! sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release; then
        write_error "Failed to install Docker apt prerequisites"
        return 1
    fi

    write_log "Adding Docker's official GPG key"
    if ! sudo install -m 0755 -d /etc/apt/keyrings; then
        write_error "Failed to create /etc/apt/keyrings"
        return 1
    fi

    if ! curl -fsSL "https://download.docker.com/linux/$docker_repo_os/gpg" | sudo tee /etc/apt/keyrings/docker.asc > /dev/null; then
        write_error "Failed to download Docker GPG key"
        return 1
    fi

    if ! sudo chmod a+r /etc/apt/keyrings/docker.asc; then
        write_error "Failed to set Docker GPG key permissions"
        return 1
    fi

    write_log "Setting up Docker repository"
    if ! echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$docker_repo_os \
      $os_codename stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
        write_error "Failed to write Docker apt source list"
        return 1
    fi

    if ! sudo apt update; then
        write_error "Failed to update apt package lists after adding Docker repository"
        return 1
    fi

    write_log "Installing Docker"
    if ! sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        write_error "Failed to install Docker packages"
        return 1
    fi

    if command -v systemctl >/dev/null 2>&1; then
        write_log "Enabling Docker service"
        sudo systemctl enable docker
        sudo systemctl start docker
    fi

    write_log "Adding current user to docker group"
    if getent group docker >/dev/null 2>&1; then
        sudo usermod -aG docker "$USER"
    else
        write_error "Docker group does not exist after package installation"
        return 1
    fi

    write_log "Verifying Docker installation"
    if ! docker --version; then
        write_error "Docker CLI verification failed"
        return 1
    fi

    write_log "Verifying Docker Compose installation"
    if ! docker compose version; then
        write_error "Docker Compose verification failed"
        return 1
    fi

    write_log "Running test container"
    if ! sudo docker run --rm hello-world; then
        write_error "Docker hello-world test failed"
        return 1
    fi

    write_log "Docker and Docker Compose setup complete"
    write_log "You may need to log out and back in before Docker works without sudo"

    return 0
}

main
