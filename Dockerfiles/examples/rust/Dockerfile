FROM rust:latest

WORKDIR /usr/src/app

COPY Cargo.toml Cargo.lock ./

RUN cargo build --release
RUN rm src/*.rs

COPY . .

RUN cargo build --release

CMD ["./target/release/your_app"]
