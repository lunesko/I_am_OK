FROM rust:1.76-slim AS build

WORKDIR /app
COPY Cargo.toml .
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /app/target/release/yaok-relay /app/yaok-relay

ENV RELAY_PORT=40000
ENV MAX_PACKET_SIZE=65507
ENV RATE_LIMIT_PPS=100
ENV PEER_TTL_SECS=300

EXPOSE 40000/udp
CMD ["/app/yaok-relay"]
