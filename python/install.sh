#!/bin/bash
#
# Installs Python
#
# Usage:
#     ./install-python.sh <-t> <-?>
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
LOG_FILE="./install-python-log.txt"

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
    write_log "Setting up Python development environment"

    sudo apt update

    write_log "Installing Python 3 and pip"
    sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential

    write_log "Verifying Python installation"
    python3 --version
    pip3 --version

    write_log "Installing Python tools"
    sudo apt install -y python3-setuptools python3-wheel

    write_log "Setting up pipx for isolated application installs"
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath

    write_log "Installing commonly used Python packages"
    pip3 install --user numpy pandas matplotlib jupyter requests pytest pytest-cov black flake8 mypy isort pylint poetry

    if [ -d "$HOME/python-projects" ]; then
        rm -rf "$HOME/python-projects"
    fi

    write_log "Setting up a virtual environment for projects"
    mkdir -p ~/python-projects
    cd ~/python-projects
    python3 -m venv venv
    write_log "Created virtual environment at ~/python-projects/venv"

    write_log "Creating an example project structure"
    mkdir -p ~/python-projects/example-project/{src,tests,docs}

    write_log "Python development environment setup complete"
    write_log "You may need to restart your terminal or run 'source ~/.bashrc' to apply all changes"

    return 0
}

main