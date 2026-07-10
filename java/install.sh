#!/bin/bash
#
# Installs java
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
LOG_FILE="./install-java-log.txt"

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
    write_log "Setting up Java and Spring development environment"

    sudo apt update

    write_log "Installing Java 17 (LTS)"
    sudo apt install -y openjdk-17-jdk

    java -version

    write_log "Installing Maven"
    sudo apt install -y maven
    mvn -version

    write_log "Installing Gradle"
    sudo apt install -y gradle
    gradle -version

    write_log "Installing Spring Boot CLI"
    curl -s https://get.sdkman.io | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install springboot

    write_log "Setting up environment variables"
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc


    if [ -d "$HOME/spring-projects" ]; then
        rm -rf "$HOME/spring-projects"
    fi

    mkdir -p ~/spring-projects
    cd ~/spring-projects
    spring init --dependencies=web,data-jpa,security,devtools sample-project

    write_log "Java with Spring development environment setup complete"
    write_log "You may need to restart your terminal or run 'source ~/.bashrc' to apply all changes"

    return 0
}

main