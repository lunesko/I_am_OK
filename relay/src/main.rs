use std::collections::HashMap;
use std::env;
use std::net::{IpAddr, SocketAddr, UdpSocket};
use std::time::{Duration, Instant};

struct RateEntry {
    window_start: Instant,
    count: u32,
}

#[derive(Default)]
struct Stats {
    received: u64,
    forwarded: u64,
    dropped_rate: u64,
    dropped_size: u64,
}

fn main() -> std::io::Result<()> {
    let port = env::var("RELAY_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(40100);

    let max_packet = env::var("MAX_PACKET_SIZE")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(64_000);

    let rate_limit = env::var("RATE_LIMIT_PPS")
        .ok()
        .and_then(|v| v.parse::<u32>().ok())
        .unwrap_or(200);

    let peer_ttl = env::var("PEER_TTL_SECS")
        .ok()
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or(300);

    let metrics_interval_secs = env::var("METRICS_INTERVAL_SECS")
        .ok()
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or(60);

    // IMPORTANT:
    // Bind to a local interface address (0.0.0.0) by default.
    // Using a DNS name here (e.g. "fly-global-services") can fail on some platforms/providers
    // and cause crash-restart loops.
    let bind_addr = env::var("RELAY_BIND").unwrap_or_else(|_| format!("0.0.0.0:{}", port));

    let socket = match UdpSocket::bind(&bind_addr) {
        Ok(s) => s,
        Err(err) => {
            eprintln!("failed to bind relay socket on {}: {}", bind_addr, err);
            return Err(err);
        }
    };
    socket.set_nonblocking(true)?;
    socket.set_read_timeout(Some(Duration::from_millis(500)))?;

    println!(
        "yaok-relay listening on {}, max_packet={}, rate_limit_pps={}, peer_ttl={}s, metrics_interval={}s",
        bind_addr, max_packet, rate_limit, peer_ttl, metrics_interval_secs
    );

    let mut peers: HashMap<SocketAddr, Instant> = HashMap::new();
    let mut rate: HashMap<IpAddr, RateEntry> = HashMap::new();
    let mut buf = vec![0u8; max_packet];
    let mut stats = Stats::default();
    let metrics_interval = Duration::from_secs(metrics_interval_secs);
    let mut last_metrics = Instant::now();

    loop {
        match socket.recv_from(&mut buf) {
            Ok((len, src)) => {
                stats.received += 1;
                if len == 0 || len > max_packet {
                    stats.dropped_size += 1;
                    continue;
                }

                if !allow_packet(&mut rate, src.ip(), rate_limit) {
                    stats.dropped_rate += 1;
                    continue;
                }

                peers.insert(src, Instant::now());
                cleanup_peers(&mut peers, peer_ttl);

                for (peer, _) in peers.iter() {
                    if *peer == src {
                        continue;
                    }
                    if socket.send_to(&buf[..len], peer).is_ok() {
                        stats.forwarded += 1;
                    }
                }
            }
            Err(err) if err.kind() == std::io::ErrorKind::WouldBlock => {
                cleanup_peers(&mut peers, peer_ttl);
                std::thread::sleep(Duration::from_millis(20));
                continue;
            }
            Err(err) => {
                eprintln!("recv error: {}", err);
            }
        }

        if last_metrics.elapsed() >= metrics_interval {
            println!(
                "metrics: received={}, forwarded={}, dropped_rate={}, dropped_size={}, peers={}",
                stats.received,
                stats.forwarded,
                stats.dropped_rate,
                stats.dropped_size,
                peers.len()
            );
            stats = Stats::default();
            last_metrics = Instant::now();
        }
    }
}

fn allow_packet(rate: &mut HashMap<IpAddr, RateEntry>, ip: IpAddr, limit: u32) -> bool {
    let now = Instant::now();
    let entry = rate.entry(ip).or_insert(RateEntry {
        window_start: now,
        count: 0,
    });

    if now.duration_since(entry.window_start) >= Duration::from_secs(1) {
        entry.window_start = now;
        entry.count = 0;
    }

    if entry.count >= limit {
        return false;
    }

    entry.count += 1;
    true
}

fn cleanup_peers(peers: &mut HashMap<SocketAddr, Instant>, ttl_secs: u64) {
    let ttl = Duration::from_secs(ttl_secs);
    let now = Instant::now();
    peers.retain(|_, last_seen| now.duration_since(*last_seen) <= ttl);
}
