#!/bin/bash
#
# Installs rust
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
LOG_FILE="./install-rust-log.txt"

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
    write_log "Setting up Rust development environment"

    sudo apt update

    write_log "Installing Rust using rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    source $HOME/.cargo/env

    rustc --version
    cargo --version

    write_log "Installing essential Rust tools"
    cargo install cargo-update
    cargo install cargo-edit
    cargo install cargo-watch
    cargo install cargo-clippy
    cargo install cargo-audit
    cargo install cargo-expand
    cargo install cargo-bloat
    cargo install cargo-outdated
    cargo install cargo-generate
    cargo install flamegraph
    cargo install bat
    cargo install exa
    cargo install tokei
    cargo install wasm-pack
    cargo install cross
    cargo install sccache

    rustup component add rust-analyzer
    rustup component add rust-src
    rustup component add rust-analysis

    rustup component add rustfmt
    rustup component add clippy
    rustup component add rls

    write_log "Installing additional Rust toolchains"
    rustup install stable
    rustup default stable

    write_log "Installing common targets for cross-compilation"
    rustup target add wasm32-unknown-unknown
    rustup target add x86_64-unknown-linux-musl
    rustup target add aarch64-unknown-linux-gnu

    if [ -d "$HOME/rust-projects" ]; then
        rm -rf "$HOME/rust-projects"
    fi

    mkdir -p ~/rust-projects
    cd ~/rust-projects
    cargo new sample-project
    cd sample-project
    cargo build
    cargo init

    write_log "Rust development environment setup complete!"
    write_log "You may need to restart your terminal or run 'source ~/.cargo/env' to apply all changes"

    return 0
}

main