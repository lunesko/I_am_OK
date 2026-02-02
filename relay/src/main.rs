use std::collections::HashMap;
use std::env;
use std::net::{IpAddr, SocketAddr, UdpSocket};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tracing::{info, warn, error, debug};
use serde::Serialize;

// Security limits to prevent memory exhaustion attacks
const MAX_PEERS: usize = 10_000;
const MAX_RATE_ENTRIES: usize = 50_000;
const CLEANUP_INTERVAL: u32 = 1_000; // Cleanup every N packets

struct RateEntry {
    window_start: Instant,
    count: u32,
}

#[derive(Default, Clone, Serialize)]
struct Stats {
    received: u64,
    forwarded: u64,
    dropped_rate: u64,
    dropped_size: u64,
    dropped_peer_limit: u64,
    active_peers: usize,
    rate_entries: usize,
    uptime_secs: u64,
}

#[derive(Serialize)]
struct HealthStatus {
    status: String,
    uptime_secs: u64,
    version: String,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info"))
        )
        .init();

    let start_time = Instant::now();

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

    let metrics_port = env::var("METRICS_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(9090);

    let fallback_relay = env::var("FALLBACK_RELAY").ok();

    // IMPORTANT:
    // Bind to a local interface address (0.0.0.0) by default.
    // Using a DNS name here (e.g. "fly-global-services") can fail on some platforms/providers
    // and cause crash-restart loops.
    let bind_addr = env::var("RELAY_BIND").unwrap_or_else(|_| format!("0.0.0.0:{}", port));

    let socket = match UdpSocket::bind(&bind_addr) {
        Ok(s) => s,
        Err(err) => {
            error!("Failed to bind relay socket on {}: {}", bind_addr, err);
            return Err(err);
        }
    };
    socket.set_nonblocking(true)?;
    socket.set_read_timeout(Some(Duration::from_millis(500)))?;

    info!(
        "yaok-relay listening on {}, max_packet={}, rate_limit_pps={}, peer_ttl={}s, metrics_interval={}s",
        bind_addr, max_packet, rate_limit, peer_ttl, metrics_interval_secs
    );
    info!("Security limits: MAX_PEERS={}, MAX_RATE_ENTRIES={}", MAX_PEERS, MAX_RATE_ENTRIES);
    info!("Metrics HTTP endpoint: http://0.0.0.0:{}", metrics_port);
    if let Some(ref fallback) = fallback_relay {
        info!("Fallback relay configured: {}", fallback);
    }

    let mut peers: HashMap<SocketAddr, Instant> = HashMap::new();
    let mut rate: HashMap<IpAddr, RateEntry> = HashMap::new();
    let mut buf = vec![0u8; max_packet];
    let mut stats = Stats::default();
    let metrics_interval = Duration::from_secs(metrics_interval_secs);
    let mut last_metrics = Instant::now();
    let mut cleanup_counter: u32 = 0;

    // Shared stats for HTTP endpoint
    let shared_stats = Arc::new(Mutex::new(Stats::default()));
    let stats_clone = shared_stats.clone();
    let start_clone = start_time;

    // Spawn HTTP metrics server
    tokio::spawn(async move {
        if let Err(e) = run_metrics_server(metrics_port, stats_clone, start_clone).await {
            error!("Metrics server error: {}", e);
        }
    });

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

                // Check peer limit before adding
                if peers.len() >= MAX_PEERS && !peers.contains_key(&src) {
                    stats.dropped_peer_limit += 1;
                    debug!("Peer limit reached, dropping packet from {}", src);
                    continue;
                }

                peers.insert(src, Instant::now());

                // Periodic cleanup to prevent unbounded growth
                cleanup_counter += 1;
                if cleanup_counter >= CLEANUP_INTERVAL {
                    cleanup_peers(&mut peers, peer_ttl);
                    cleanup_rate_entries(&mut rate);
                    cleanup_counter = 0;
                }

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
                cleanup_rate_entries(&mut rate);
                std::thread::sleep(Duration::from_millis(20));
                continue;
            }
            Err(err) => {
                error!("recv error: {}", err);
            }
        }

        if last_metrics.elapsed() >= metrics_interval {
            stats.active_peers = peers.len();
            stats.rate_entries = rate.len();
            stats.uptime_secs = start_time.elapsed().as_secs();

            info!(
                "metrics: received={}, forwarded={}, dropped_rate={}, dropped_size={}, dropped_peer_limit={}, peers={}, rate_entries={}, uptime={}s",
                stats.received,
                stats.forwarded,
                stats.dropped_rate,
                stats.dropped_size,
                stats.dropped_peer_limit,
                stats.active_peers,
                stats.rate_entries,
                stats.uptime_secs
            );

            // Update shared stats for HTTP endpoint
            if let Ok(mut shared) = shared_stats.lock() {
                *shared = stats.clone();
            }

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

/// Clean up rate limiting entries older than 60 seconds
fn cleanup_rate_entries(rate: &mut HashMap<IpAddr, RateEntry>) {
    let now = Instant::now();
    rate.retain(|_, entry| now.duration_since(entry.window_start).as_secs() < 60);
    
    // If still over MAX_RATE_ENTRIES, remove oldest 10%
    if rate.len() > MAX_RATE_ENTRIES {
        let to_remove = rate.len() / 10;
        let mut entries: Vec<_> = rate.iter().map(|(ip, entry)| (*ip, entry.window_start)).collect();
        entries.sort_by_key(|(_, time)| *time);
        
        for (ip, _) in entries.iter().take(to_remove) {
            rate.remove(ip);
        }
        warn!("Rate entries cleanup: removed {} oldest entries", to_remove);
    }
}

/// Run HTTP metrics server for monitoring
async fn run_metrics_server(
    port: u16,
    stats: Arc<Mutex<Stats>>,
    start_time: Instant,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    use hyper::server::conn::http1;
    use hyper::service::service_fn;
    use hyper::{Request, Response, Method, StatusCode};
    use hyper_util::rt::TokioIo;
    use http_body_util::Full;
    use hyper::body::Bytes;
    use tokio::net::TcpListener;

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = TcpListener::bind(addr).await?;
    info!("Metrics server listening on http://{}", addr);

    loop {
        let (stream, _) = listener.accept().await?;
        let io = TokioIo::new(stream);
        let stats = stats.clone();
        let start_time = start_time;

        let service = service_fn(move |req: Request<hyper::body::Incoming>| {
            let stats = stats.clone();
            async move {
                match (req.method(), req.uri().path()) {
                    (&Method::GET, "/") => {
                        // Admin panel HTML
                        let html = include_str!("admin_panel.html");
                        let mut response = Response::new(Full::new(Bytes::from(html)));
                        response.headers_mut().insert(
                            hyper::header::CONTENT_TYPE,
                            hyper::header::HeaderValue::from_static("text/html; charset=utf-8")
                        );
                        Ok::<_, hyper::Error>(response)
                    }
                    (&Method::GET, "/health") => {
                        let health = HealthStatus {
                            status: "healthy".to_string(),
                            uptime_secs: start_time.elapsed().as_secs(),
                            version: env!("CARGO_PKG_VERSION").to_string(),
                        };
                        let json = serde_json::to_string(&health).unwrap_or_else(|_| "{}".to_string());
                        let mut response = Response::new(Full::new(Bytes::from(json)));
                        response.headers_mut().insert(
                            hyper::header::CONTENT_TYPE,
                            hyper::header::HeaderValue::from_static("application/json")
                        );
                        Ok::<_, hyper::Error>(response)
                    }
                    (&Method::GET, "/metrics") => {
                        let stats_snapshot = stats.lock().unwrap().clone();
                        
                        // Prometheus format
                        let metrics = format!(
                            "# HELP yaok_relay_received_total Total packets received\\n\
                             # TYPE yaok_relay_received_total counter\\n\
                             yaok_relay_received_total {}\\n\
                             # HELP yaok_relay_forwarded_total Total packets forwarded\\n\
                             # TYPE yaok_relay_forwarded_total counter\\n\
                             yaok_relay_forwarded_total {}\\n\
                             # HELP yaok_relay_dropped_rate_total Packets dropped due to rate limit\\n\
                             # TYPE yaok_relay_dropped_rate_total counter\\n\
                             yaok_relay_dropped_rate_total {}\\n\
                             # HELP yaok_relay_dropped_size_total Packets dropped due to size\\n\
                             # TYPE yaok_relay_dropped_size_total counter\\n\
                             yaok_relay_dropped_size_total {}\\n\
                             # HELP yaok_relay_dropped_peer_limit_total Packets dropped due to peer limit\\n\
                             # TYPE yaok_relay_dropped_peer_limit_total counter\\n\
                             yaok_relay_dropped_peer_limit_total {}\\n\
                             # HELP yaok_relay_active_peers Active peer count\\n\
                             # TYPE yaok_relay_active_peers gauge\\n\
                             yaok_relay_active_peers {}\\n\
                             # HELP yaok_relay_rate_entries Rate limiting entries\\n\
                             # TYPE yaok_relay_rate_entries gauge\\n\
                             yaok_relay_rate_entries {}\\n\
                             # HELP yaok_relay_uptime_seconds Server uptime\\n\
                             # TYPE yaok_relay_uptime_seconds gauge\\n\
                             yaok_relay_uptime_seconds {}\\n",
                            stats_snapshot.received,
                            stats_snapshot.forwarded,
                            stats_snapshot.dropped_rate,
                            stats_snapshot.dropped_size,
                            stats_snapshot.dropped_peer_limit,
                            stats_snapshot.active_peers,
                            stats_snapshot.rate_entries,
                            stats_snapshot.uptime_secs
                        );
                        let mut response = Response::new(Full::new(Bytes::from(metrics)));
                        response.headers_mut().insert(
                            hyper::header::CONTENT_TYPE,
                            hyper::header::HeaderValue::from_static("text/plain; charset=utf-8")
                        );
                        Ok::<_, hyper::Error>(response)
                    }
                    (&Method::GET, "/metrics/json") => {
                        let stats_snapshot = stats.lock().unwrap().clone();
                        let json = serde_json::to_string(&stats_snapshot).unwrap_or_else(|_| "{}".to_string());
                        let mut response = Response::new(Full::new(Bytes::from(json)));
                        response.headers_mut().insert(
                            hyper::header::CONTENT_TYPE,
                            hyper::header::HeaderValue::from_static("application/json")
                        );
                        Ok::<_, hyper::Error>(response)
                    }
                    _ => {
                        let mut response = Response::new(Full::new(Bytes::from("Not Found")));
                        *response.status_mut() = StatusCode::NOT_FOUND;
                        Ok::<_, hyper::Error>(response)
                    }
                }
            }
        });

        tokio::task::spawn(async move {
            if let Err(err) = http1::Builder::new().serve_connection(io, service).await {
                error!("Metrics connection error: {}", err);
            }
        });
    }
}
