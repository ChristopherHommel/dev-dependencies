#!/bin/bash
#
# Installs node
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
LOG_FILE="./install-node-log.txt"

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

main(){

    write_log "Setting up Node.js development environment"

    sudo apt update

    write_log "Installing Node Version Manager (nvm)"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    write_log "Installing Node.js LTS version"
    nvm install --lts
    nvm use --lts
    nvm alias default node

    node --version
    npm --version

    write_log "Installing npm global packages"
    npm install -g yarn
    npm install -g pnpm
    npm install -g npm@latest
    npm install -g nodemon
    npm install -g ts-node
    npm install -g typescript
    npm install -g eslint
    npm install -g prettier
    npm install -g jest
    npm install -g nx
    npm install -g serve
    npm install -g http-server
    npm install -g pm2
    npm install -g webpack
    npm install -g @nestjs/cli
    npm install -g @angular/cli
    npm install -g create-react-app
    npm install -g express-generator

    if [ -d "$HOME/node-projects" ]; then
        rm -rf "$HOME/node-projects"
    fi

    mkdir -p ~/node-projects/sample-project
    cd ~/node-projects/sample-project
    npm init -y
    npm install express dotenv cors

    write_log "Node.js development environment setup complete"
    write_log "You may need to restart your terminal or run 'source ~/.bashrc' to apply all changes"

    return 0
}

main