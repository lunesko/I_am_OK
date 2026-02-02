FROM rust:1.84-slim AS builder
WORKDIR /app

# Кеширование зависимостей
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf target/release/deps/*yaok*

# Копируем реальный код (включая admin_panel.html)
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y ca-certificates netcat-openbsd procps && \
    rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m -u 1000 relay
WORKDIR /app

COPY --from=builder /app/target/release/yaok-relay /app/yaok-relay
RUN chown relay:relay /app/yaok-relay

USER relay

ENV RELAY_PORT=40100
ENV MAX_PACKET_SIZE=64000
ENV RATE_LIMIT_PPS=200
ENV PEER_TTL_SECS=300
ENV METRICS_INTERVAL_SECS=60

EXPOSE 40100/udp

# Enhanced healthcheck: verify process running AND UDP socket listening
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD pgrep -f yaok-relay > /dev/null && \
      nc -uzv -w 2 127.0.0.1 ${RELAY_PORT} 2>&1 | grep -q succeeded || exit 1

CMD ["/app/yaok-relay"]
