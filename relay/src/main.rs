use std::collections::HashMap;
use std::env;
use std::net::{IpAddr, SocketAddr, UdpSocket};
use std::time::{Duration, Instant};

struct RateEntry {
    window_start: Instant,
    count: u32,
}

fn main() -> std::io::Result<()> {
    let port = env::var("RELAY_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(40000);

    let max_packet = env::var("MAX_PACKET_SIZE")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(65_507); // UDP safe max

    let rate_limit = env::var("RATE_LIMIT_PPS")
        .ok()
        .and_then(|v| v.parse::<u32>().ok())
        .unwrap_or(100);

    let peer_ttl = env::var("PEER_TTL_SECS")
        .ok()
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or(300);

    let bind_addr = env::var("RELAY_BIND").unwrap_or_else(|_| {
        if env::var("FLY_APP_NAME").is_ok() {
            format!("fly-global-services:{}", port)
        } else {
            format!("0.0.0.0:{}", port)
        }
    });

    let socket = UdpSocket::bind(&bind_addr)?;
    socket.set_nonblocking(true)?;
    socket.set_read_timeout(Some(Duration::from_millis(500)))?;

    println!(
        "yaok-relay listening on {}, max_packet={}, rate_limit_pps={}, peer_ttl={}s",
        bind_addr, max_packet, rate_limit, peer_ttl
    );

    let mut peers: HashMap<SocketAddr, Instant> = HashMap::new();
    let mut rate: HashMap<IpAddr, RateEntry> = HashMap::new();
    let mut buf = vec![0u8; max_packet];

    loop {
        match socket.recv_from(&mut buf) {
            Ok((len, src)) => {
                if len == 0 || len > max_packet {
                    continue;
                }

                if !allow_packet(&mut rate, src.ip(), rate_limit) {
                    continue;
                }

                peers.insert(src, Instant::now());
                cleanup_peers(&mut peers, peer_ttl);

                for (peer, _) in peers.iter() {
                    if *peer == src {
                        continue;
                    }
                    let _ = socket.send_to(&buf[..len], peer);
                }
            }
            Err(err) if err.kind() == std::io::ErrorKind::WouldBlock => {
                cleanup_peers(&mut peers, peer_ttl);
                continue;
            }
            Err(err) => {
                eprintln!("recv error: {}", err);
            }
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
