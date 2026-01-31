FROM rust:1.76-slim AS build

WORKDIR /app
COPY Cargo.toml .
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /app/target/release/yaok-relay /app/yaok-relay

ENV RELAY_PORT=40100
ENV MAX_PACKET_SIZE=64000
ENV RATE_LIMIT_PPS=200
ENV PEER_TTL_SECS=300
ENV METRICS_INTERVAL_SECS=60

EXPOSE 40100/udp
CMD ["/app/yaok-relay"]
