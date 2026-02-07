# Ya OK Administrator Manual
## Relay Server Setup, Maintenance, and Operations

**Document ID:** YA-OK-ADMIN-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Classification:** INTERNAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | Operations Team | Initial administrator guide |

### Related Documents

- **YA-OK-DEPLOY-001**: Production Deployment Guide
- **YA-OK-OPS-001**: Operational Procedures
- **YA-OK-MON-001**: Monitoring & Alerting Setup
- **YA-OK-API-001**: API Contracts

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Architecture](#2-system-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Relay Server Installation](#4-relay-server-installation)
5. [Configuration](#5-configuration)
6. [Monitoring](#6-monitoring)
7. [Maintenance](#7-maintenance)
8. [Troubleshooting](#8-troubleshooting)
9. [Security](#9-security)
10. [Scaling](#10-scaling)

---

## 1. Introduction

### 1.1 Purpose

This manual provides administrators with instructions for:
- Installing and configuring Ya OK relay servers
- Monitoring system health
- Performing routine maintenance
- Troubleshooting common issues
- Scaling infrastructure

### 1.2 Target Audience

- System Administrators
- DevOps Engineers
- Site Reliability Engineers (SREs)
- Platform Engineers

### 1.3 Assumptions

Readers have:
- Linux/Unix administration experience
- Understanding of networking (TCP/UDP, DNS)
- Familiarity with Docker and containerization
- Basic knowledge of monitoring tools (Prometheus, Grafana)

### 1.4 System Overview

**Ya OK Relay Server:**
- Rust application
- UDP protocol (primary), HTTP endpoints (health, metrics)
- SQLite database for user registry and message queue
- Deployed on Fly.io (containerized)
- Multi-region deployment (Amsterdam, Virginia, Singapore)

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                 Mobile Apps                      │
│         (Android, iOS - End Users)               │
└────────────┬────────────────────┬────────────────┘
             │                    │
       [BLE/WiFi Direct]    [Internet - Relay]
             │                    │
             │         ┌──────────▼──────────┐
             │         │   Load Balancer     │
             │         │   (Fly.io Proxy)    │
             │         └──────────┬──────────┘
             │                    │
             │         ┌──────────▼──────────┐
             │         │  Relay Servers      │
             │         │  - Amsterdam (ams)  │
             │         │  - Virginia (iad)   │
             │         │  - Singapore (sin)  │
             │         └──────────┬──────────┘
             │                    │
             │         ┌──────────▼──────────┐
             │         │    SQLite DB        │
             │         │  (Fly.io Volume)    │
             │         └─────────────────────┘
             │
    [Direct P2P Communication]
```

### 2.2 Component Responsibilities

| Component | Responsibility | Technology |
|-----------|----------------|------------|
| **Mobile Apps** | User interface, encryption, BLE/WiFi | Kotlin (Android), Swift (iOS) |
| **Rust Core** | Cryptography, message routing | Rust (ya_ok_core) |
| **Relay Server** | Message relay for remote users | Rust (Tokio async runtime) |
| **Database** | User registry, message queue | SQLite (SQLCipher) |
| **Load Balancer** | Distribute connections | Fly.io Proxy (automatic) |
| **Monitoring** | Metrics, logs, alerts | Prometheus, Grafana, Loki |

### 2.3 Network Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| **41641** | UDP | Primary relay protocol |
| **8080** | HTTP | Health checks, metrics |
| **9090** | HTTP | Prometheus metrics (internal) |

---

## 3. Prerequisites

### 3.1 Required Accounts

- **Fly.io Account** (https://fly.io)
  - Credit card required for billing
  - Hobby plan sufficient for small deployments
- **GitHub Account** (for CI/CD)
- **Grafana Cloud Account** (optional, for hosted monitoring)

### 3.2 Required Tools

Install the following on your administrator workstation:

**Fly.io CLI:**

```bash
# macOS / Linux
curl -L https://fly.io/install.sh | sh

# Windows (PowerShell)
iwr https://fly.io/install.ps1 -useb | iex

# Verify installation
fly version
```

**Docker:**

```bash
# macOS (Homebrew)
brew install docker

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io

# Verify
docker --version
```

**Rust Toolchain (for local development):**

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update stable
cargo --version
```

**Additional Tools:**

```bash
# Git
sudo apt-get install git  # Linux
brew install git  # macOS

# jq (JSON processor)
sudo apt-get install jq  # Linux
brew install jq  # macOS

# SQLite (database client)
sudo apt-get install sqlite3  # Linux
brew install sqlite3  # macOS
```

### 3.3 Access Requirements

- **Fly.io Organization**: Create or join Ya OK organization
- **GitHub Repository**: Read/write access to `yaok/infrastructure`
- **Monitoring**: Access to Grafana dashboards
- **PagerDuty**: On-call rotation setup

---

## 4. Relay Server Installation

### 4.1 Initial Setup

**Step 1: Clone Repository**

```bash
git clone https://github.com/yaok/ya-ok.git
cd ya-ok/relay
```

**Step 2: Authenticate with Fly.io**

```bash
fly auth login
# Opens browser for authentication
```

**Step 3: Create Fly.io App**

```bash
# Choose region (ams, iad, or sin)
REGION=ams

# Create app
fly apps create yaok-relay-${REGION} --org yaok
```

**Step 4: Create Volume**

```bash
# Create persistent volume for database
fly volumes create vol_yaok_relay_${REGION}_data \
    --region ${REGION} \
    --size 10 \
    --app yaok-relay-${REGION}
```

**Step 5: Configure Secrets**

```bash
# Generate database encryption key
DB_KEY=$(openssl rand -base64 32)

# Set secrets
fly secrets set \
    DATABASE_URL="sqlite:///data/yaok_relay.db" \
    DATABASE_KEY="${DB_KEY}" \
    RUST_LOG="info" \
    RELAY_PORT="41641" \
    HTTP_PORT="8080" \
    MAX_CONNECTIONS="10000" \
    --app yaok-relay-${REGION}
```

**Step 6: Deploy**

```bash
# Build and deploy
fly deploy --app yaok-relay-${REGION} --region ${REGION}

# Verify deployment
fly status --app yaok-relay-${REGION}
```

**Step 7: Scale**

```bash
# Scale to 2 instances for HA
fly scale count 2 --app yaok-relay-${REGION}

# Verify
fly status --app yaok-relay-${REGION}
```

### 4.2 Multi-Region Deployment

Repeat steps for each region:

```bash
# Amsterdam (Europe)
REGION=ams ./deploy.sh

# Virginia (US East)
REGION=iad ./deploy.sh

# Singapore (Asia)
REGION=sin ./deploy.sh
```

**Automated Script:**

```bash
#!/bin/bash
# File: deploy.sh

set -euo pipefail

REGION=${1:-ams}
APP_NAME="yaok-relay-${REGION}"

echo "Deploying to ${REGION}..."

# Create app if doesn't exist
if ! fly apps list | grep -q ${APP_NAME}; then
    fly apps create ${APP_NAME} --org yaok
fi

# Create volume if doesn't exist
if ! fly volumes list --app ${APP_NAME} | grep -q vol_yaok_relay_${REGION}_data; then
    fly volumes create vol_yaok_relay_${REGION}_data \
        --region ${REGION} \
        --size 10 \
        --app ${APP_NAME}
fi

# Deploy
fly deploy --app ${APP_NAME} --region ${REGION}

# Scale
fly scale count 2 --app ${APP_NAME}

echo "Deployment complete: ${APP_NAME}"
```

### 4.3 DNS Configuration

**Configure DNS for custom domain:**

```bash
# Allocate IP addresses
fly ips allocate-v4 --app yaok-relay-ams
fly ips allocate-v6 --app yaok-relay-ams

# Get allocated IPs
fly ips list --app yaok-relay-ams
```

**Add DNS records (at your DNS provider):**

```
# A Records (IPv4)
relay-ams.yaok.app.  A  <ipv4_address>
relay-iad.yaok.app.  A  <ipv4_address>
relay-sin.yaok.app.  A  <ipv4_address>

# AAAA Records (IPv6)
relay-ams.yaok.app.  AAAA  <ipv6_address>
relay-iad.yaok.app.  AAAA  <ipv6_address>
relay-sin.yaok.app.  AAAA  <ipv6_address>

# Round-robin for load balancing (optional)
relay.yaok.app.  A  <ams_ipv4>
relay.yaok.app.  A  <iad_ipv4>
relay.yaok.app.  A  <sin_ipv4>
```

**Verify DNS:**

```bash
dig relay-ams.yaok.app
nslookup relay-ams.yaok.app
```

---

## 5. Configuration

### 5.1 fly.toml Configuration

**Location:** `relay/fly.toml`

```toml
# Fly.io application configuration
app = "yaok-relay-ams"
primary_region = "ams"

[build]
  dockerfile = "Dockerfile"

[env]
  RUST_LOG = "info"
  RELAY_PORT = "41641"
  HTTP_PORT = "8080"

[mounts]
  source = "vol_yaok_relay_ams_data"
  destination = "/data"

# UDP service for relay protocol
[[services]]
  internal_port = 41641
  protocol = "udp"

  [[services.ports]]
    port = 41641

# HTTP service for health checks
[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 2

  [[http_service.checks]]
    interval = 10000
    grace_period = "5s"
    method = "get"
    path = "/health"
    protocol = "http"
    timeout = 2000

# VM sizing
[vm]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256

# Metrics
[metrics]
  port = 9090
  path = "/metrics"
```

### 5.2 Environment Variables

**Available environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `sqlite:///data/yaok_relay.db` | SQLite database path |
| `DATABASE_KEY` | (required) | Database encryption key |
| `RUST_LOG` | `info` | Log level (error, warn, info, debug, trace) |
| `RELAY_PORT` | `41641` | UDP port for relay protocol |
| `HTTP_PORT` | `8080` | HTTP port for health/metrics |
| `MAX_CONNECTIONS` | `10000` | Max concurrent connections |
| `MESSAGE_QUEUE_SIZE` | `10000` | Max queued messages per user |
| `MESSAGE_TTL` | `604800` | Message TTL in seconds (7 days) |
| `RATE_LIMIT_REQUESTS` | `100` | Max requests per user per minute |
| `RATE_LIMIT_WINDOW` | `60` | Rate limit window in seconds |

**Update environment variables:**

```bash
fly secrets set RUST_LOG="debug" --app yaok-relay-ams
fly apps restart yaok-relay-ams
```

### 5.3 Database Configuration

**SQLite PRAGMA settings** (applied at startup):

```sql
-- Write-Ahead Logging (better concurrency)
PRAGMA journal_mode = WAL;

-- Cache size (10 MB)
PRAGMA cache_size = -10000;

-- Synchronous mode (balance safety/performance)
PRAGMA synchronous = NORMAL;

-- Memory-mapped I/O (faster reads)
PRAGMA mmap_size = 30000000000;

-- Temp storage in memory
PRAGMA temp_store = MEMORY;
```

**Adjust settings (requires code change + redeploy):**

Edit `relay/src/database.rs`:

```rust
pub fn init_database(path: &Path) -> Result<Connection> {
    let conn = Connection::open(path)?;
    
    conn.execute_batch("
        PRAGMA journal_mode = WAL;
        PRAGMA cache_size = -10000;
        PRAGMA synchronous = NORMAL;
        PRAGMA mmap_size = 30000000000;
        PRAGMA temp_store = MEMORY;
    ")?;
    
    Ok(conn)
}
```

---

## 6. Monitoring

### 6.1 Health Checks

**Manual health check:**

```bash
# Check relay server health
curl https://relay-ams.yaok.app/health

# Expected response:
{
  "status": "healthy",
  "version": "0.2.0",
  "uptime_seconds": 86400,
  "active_connections": 1234,
  "database_ok": true,
  "queue_size": 45
}
```

**Automated health checks:**

Fly.io automatically performs health checks (configured in `fly.toml`):
- Interval: 10 seconds
- Timeout: 2 seconds
- Path: `/health`
- Unhealthy threshold: 3 consecutive failures

**View health check status:**

```bash
fly checks list --app yaok-relay-ams
```

### 6.2 Metrics

**Prometheus metrics endpoint:**

```bash
curl https://relay-ams.yaok.app/metrics
```

**Key metrics:**

| Metric | Type | Description |
|--------|------|-------------|
| `relay_requests_total` | Counter | Total requests by type |
| `relay_request_duration_seconds` | Histogram | Request latency |
| `relay_active_connections` | Gauge | Current active connections |
| `relay_messages_queued` | Gauge | Messages in queue |
| `relay_error_rate` | Gauge | Error rate (%) |
| `relay_cpu_usage_percent` | Gauge | CPU usage |
| `relay_memory_usage_bytes` | Gauge | Memory usage |

**Example queries (PromQL):**

```promql
# Request rate
rate(relay_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, relay_request_duration_seconds)

# Error rate
sum(rate(relay_requests_total{status="error"}[5m])) / sum(rate(relay_requests_total[5m]))
```

### 6.3 Logging

**View logs:**

```bash
# Real-time logs
fly logs --app yaok-relay-ams

# Filter by level
fly logs --app yaok-relay-ams | grep ERROR

# Filter by time
fly logs --app yaok-relay-ams --since 1h
```

**Log format (structured JSON):**

```json
{
  "timestamp": "2026-02-06T10:30:45.123Z",
  "level": "INFO",
  "message": "Message relayed successfully",
  "service": "yaok-relay",
  "version": "0.2.0",
  "region": "ams",
  "trace_id": "abc123...",
  "user_id": "550e8400-...",
  "duration_ms": 45
}
```

**Log aggregation (Loki):**

If using Grafana Loki:

```bash
# Query logs
logcli query '{service="yaok-relay", level="ERROR"}' --since=1h --limit=100
```

### 6.4 Dashboards

**Access Grafana:**

URL: https://grafana.yaok.app (or your Grafana Cloud instance)

**Available dashboards:**

1. **Executive Dashboard**
   - Service uptime
   - Error rate
   - Active users
   - Messages sent (24h)

2. **Platform Health**
   - Per-region health (ams, iad, sin)
   - Connection counts
   - Latency (p50, p95, p99)
   - Error rates

3. **Performance Dashboard**
   - Request rate (req/s)
   - Latency distribution
   - Queue size
   - Resource usage (CPU, memory)

4. **Infrastructure Dashboard**
   - VM health
   - Disk usage
   - Network I/O
   - Database performance

**View dashboards:**

```bash
# Open in browser
open https://grafana.yaok.app/d/relay-health
```

### 6.5 Alerts

**Critical alerts (PagerDuty):**

- Service down (>1 minute)
- High error rate (>5% for 5 minutes)
- High crash rate (>0.5% for 10 minutes)
- High CPU (>80% for 15 minutes)

**Non-critical alerts (Slack):**

- High memory usage (>200 MB for 30 minutes)
- Message queue backup (>1000 messages)
- Certificate expiring (<30 days)

**Check active alerts:**

```bash
# Via Prometheus Alertmanager
curl https://alertmanager.yaok.app/api/v2/alerts | jq '.[] | select(.status.state=="active")'
```

---

## 7. Maintenance

### 7.1 Routine Tasks

**Daily:**
- [x] Check health dashboard
- [x] Review error logs
- [x] Verify backups completed

**Weekly:**
- [x] Review performance metrics
- [x] Check disk space
- [x] Run database maintenance (VACUUM)

**Monthly:**
- [x] Review security patches
- [x] Check certificate expiration
- [x] Capacity planning review
- [x] Disaster recovery test

**Quarterly:**
- [x] Security audit
- [x] Update dependencies
- [x] DR drill
- [x] Documentation review

### 7.2 Database Maintenance

**Run VACUUM (reclaim space):**

```bash
# SSH into VM
fly ssh console --app yaok-relay-ams

# Run VACUUM
sqlite3 /data/yaok_relay.db "VACUUM;"

# Check database size
du -h /data/yaok_relay.db
```

**Automated maintenance (weekly):**

```bash
#!/bin/bash
# File: /opt/yaok/scripts/db-maintenance.sh

DB_PATH="/data/yaok_relay.db"

# Integrity check
echo "Running integrity check..."
sqlite3 ${DB_PATH} "PRAGMA integrity_check;"

# Analyze (update statistics)
echo "Running ANALYZE..."
sqlite3 ${DB_PATH} "ANALYZE;"

# Vacuum (weekly only, Monday)
if [ "$(date +%u)" -eq 1 ]; then
    echo "Running VACUUM..."
    sqlite3 ${DB_PATH} "VACUUM;"
fi

# Report size
echo "Database size: $(du -h ${DB_PATH} | cut -f1)"
```

**Schedule via cron (or Fly.io release command):**

```toml
# fly.toml
[deploy]
  release_command = "/opt/yaok/scripts/db-maintenance.sh"
```

### 7.3 Log Rotation

**Logs are automatically managed by Fly.io** (7-day retention).

For longer retention, ship logs to Loki:

**Install Promtail (log shipper):**

```dockerfile
# Add to Dockerfile
FROM grafana/promtail:latest AS promtail

# Copy to final image
COPY --from=promtail /usr/bin/promtail /usr/bin/promtail
COPY promtail-config.yml /etc/promtail/config.yml
```

**Promtail configuration:**

```yaml
# promtail-config.yml
server:
  http_listen_port: 9080

clients:
  - url: https://logs.grafana.net/loki/api/v1/push
    basic_auth:
      username: ${LOKI_USERNAME}
      password: ${LOKI_API_KEY}

scrape_configs:
  - job_name: yaok-relay
    static_configs:
      - targets: [localhost]
        labels:
          job: yaok-relay
          region: ${FLY_REGION}
          __path__: /var/log/yaok-relay/*.log
```

### 7.4 Updates and Patches

**Check for updates:**

```bash
# Check Rust dependencies
cd relay
cargo outdated

# Check for security vulnerabilities
cargo audit
```

**Apply updates:**

```bash
# Update dependencies
cargo update

# Run tests
cargo test

# Build
cargo build --release

# Deploy
fly deploy --app yaok-relay-ams
```

**Security patches (critical):**

```bash
# Emergency hotfix
git checkout -b hotfix/CVE-YYYY-XXXXX
cargo update <vulnerable_crate>
cargo test
fly deploy --app yaok-relay-ams --strategy immediate
```

### 7.5 Backups

**Automated daily backups:**

See **Operational Procedures** document (YA-OK-OPS-001) for complete backup procedures.

**Verify backup:**

```bash
# Check latest backup exists
aws s3 ls s3://yaok-backups/relay/ams/ | tail -1

# Verify integrity
aws s3 cp s3://yaok-backups/relay/ams/$(date +%Y%m%d).tar.gz /tmp/
tar -tzf /tmp/$(date +%Y%m%d).tar.gz
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Service Not Responding

**Symptoms:**
- Health check failing
- Prometheus alert: `relay_up == 0`
- Users report "Cannot connect to relay"

**Diagnosis:**

```bash
# Check app status
fly status --app yaok-relay-ams

# Check logs
fly logs --app yaok-relay-ams | tail -50

# Check resource usage
fly ssh console --app yaok-relay-ams
top
df -h
```

**Solutions:**

**1. Restart app:**

```bash
fly apps restart yaok-relay-ams
```

**2. Scale up if resource-constrained:**

```bash
fly scale vm shared-cpu-2x --app yaok-relay-ams
```

**3. Check database:**

```bash
fly ssh console --app yaok-relay-ams
sqlite3 /data/yaok_relay.db "PRAGMA integrity_check;"
```

**4. Rollback if recent deployment:**

```bash
fly releases --app yaok-relay-ams
fly releases rollback --app yaok-relay-ams
```

#### High Error Rate

**Symptoms:**
- Prometheus alert: `relay_error_rate > 5%`
- Logs show repeated errors

**Diagnosis:**

```bash
# Check error logs
fly logs --app yaok-relay-ams | grep ERROR | head -20

# Identify error types
fly logs --app yaok-relay-ams | grep ERROR | awk '{print $5}' | sort | uniq -c | sort -rn
```

**Common errors:**

| Error | Cause | Solution |
|-------|-------|----------|
| `Database locked` | High concurrency | Increase connection pool, enable WAL |
| `Too many connections` | Connection limit reached | Increase `MAX_CONNECTIONS`, scale horizontally |
| `Invalid signature` | Client/server version mismatch | Update clients |
| `Timeout` | Network issues or overload | Check network, scale up |

**Solutions:**

**1. Database issues:**

```bash
# Enable WAL mode
fly ssh console --app yaok-relay-ams
sqlite3 /data/yaok_relay.db "PRAGMA journal_mode=WAL;"
```

**2. Connection limit:**

```bash
fly secrets set MAX_CONNECTIONS=15000 --app yaok-relay-ams
fly apps restart yaok-relay-ams
```

**3. Scale horizontally:**

```bash
fly scale count 3 --app yaok-relay-ams
```

#### Database Corruption

**Symptoms:**
- Health check: `database_ok: false`
- Logs: `database disk image is malformed`

**Diagnosis:**

```bash
fly ssh console --app yaok-relay-ams
sqlite3 /data/yaok_relay.db "PRAGMA integrity_check;"
```

**Solutions:**

**1. Attempt recovery:**

```bash
# Dump data
sqlite3 /data/yaok_relay.db ".dump" > /tmp/backup.sql

# Recreate database
mv /data/yaok_relay.db /data/yaok_relay.db.corrupt
sqlite3 /data/yaok_relay.db < /tmp/backup.sql
```

**2. Restore from backup:**

See **Incident Response Plan** (YA-OK-IRP-001) → Database Corruption Recovery

### 8.2 Performance Issues

**Slow response times:**

**Check:**
1. **Latency metrics:**

```bash
# PromQL
histogram_quantile(0.95, relay_request_duration_seconds) > 0.5
```

2. **Resource usage:**

```bash
fly ssh console --app yaok-relay-ams
top  # Check CPU
free -h  # Check memory
iostat  # Check disk I/O
```

3. **Database performance:**

```bash
sqlite3 /data/yaok_relay.db "PRAGMA optimize;"
```

**Solutions:**

- Vertical scaling: Increase VM size
- Horizontal scaling: Add instances
- Database tuning: Adjust cache size, enable WAL
- Code optimization: Profile and optimize hot paths

### 8.3 Debugging Tools

**Interactive shell:**

```bash
fly ssh console --app yaok-relay-ams
```

**View process list:**

```bash
ps auxww | grep yaok
```

**Check open connections:**

```bash
netstat -anp | grep 41641
ss -tunapl | grep 41641
```

**Trace system calls:**

```bash
strace -p <pid>
```

**Network packet capture:**

```bash
tcpdump -i any -w /tmp/capture.pcap port 41641
# Download and analyze with Wireshark
```

---

## 9. Security

### 9.1 Security Best Practices

**✅ Do:**
- Keep relay server updated
- Use strong database encryption keys
- Enable TLS for HTTP endpoints
- Rotate secrets regularly (90 days)
- Monitor for suspicious activity
- Implement rate limiting
- Follow principle of least privilege

**❌ Don't:**
- Expose database directly to internet
- Store secrets in version control
- Disable TLS/encryption
- Grant unnecessary permissions
- Ignore security alerts

### 9.2 Access Control

**Fly.io access:**

```bash
# List organization members
fly orgs members list yaok

# Invite member
fly orgs members invite user@example.com --role admin

# Revoke access
fly orgs members remove user@example.com
```

**SSH access:**

```bash
# SSH keys are managed per user
fly ssh keys list

# Add SSH key
fly ssh keys add ~/.ssh/id_rsa.pub

# Revoke SSH key
fly ssh keys remove <key_id>
```

### 9.3 Secrets Management

**Set secrets:**

```bash
fly secrets set SECRET_NAME=secret_value --app yaok-relay-ams
```

**List secrets (names only, values hidden):**

```bash
fly secrets list --app yaok-relay-ams
```

**Rotate secrets:**

```bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# Update
fly secrets set DATABASE_KEY=${NEW_SECRET} --app yaok-relay-ams

# Restart to apply
fly apps restart yaok-relay-ams
```

**Never commit secrets to Git:**

```bash
# Add to .gitignore
echo "*.key" >> .gitignore
echo "secrets.txt" >> .gitignore
echo ".env" >> .gitignore
```

### 9.4 Vulnerability Management

**Scan dependencies:**

```bash
cd relay
cargo audit
```

**Subscribe to security advisories:**

- RustSec Advisory Database: https://rustsec.org/
- GitHub Dependabot: Enabled in repository
- CVE feeds: https://cve.mitre.org/

**Response to vulnerabilities:**

See **Incident Response Plan** (YA-OK-IRP-001) → Security Incident Handling

---

## 10. Scaling

### 10.1 When to Scale

**Indicators:**

- CPU > 80% sustained
- Memory > 200 MB sustained
- Active connections > 8000
- Queue size > 5000
- Latency p95 > 200ms

### 10.2 Horizontal Scaling

**Add instances:**

```bash
# Scale from 2 to 3 instances
fly scale count 3 --app yaok-relay-ams

# Verify
fly status --app yaok-relay-ams
```

**Auto-scaling (future):**

```toml
# fly.toml
[[services.autoscaling]]
  min_instances = 2
  max_instances = 5
  target_cpu_percent = 70
```

### 10.3 Vertical Scaling

**Increase VM size:**

```toml
# fly.toml
[vm]
  cpu_kind = "shared"
  cpus = 2
  memory_mb = 512
```

**Deploy changes:**

```bash
fly deploy --app yaok-relay-ams --strategy bluegreen
```

### 10.4 Geographic Scaling

**Add new region:**

```bash
# Deploy to new region (e.g., Australia)
REGION=syd ./deploy.sh

# Update DNS
# Add A record: relay-syd.yaok.app → <new_ip>
```

**Update mobile apps:**

Mobile apps will automatically discover new regions via DNS.

---

## Appendix A: Command Reference

### Fly.io Commands

```bash
# Authentication
fly auth login
fly auth logout

# Apps
fly apps list
fly apps create <app-name>
fly apps destroy <app-name>
fly status --app <app-name>
fly restart --app <app-name>

# Deployment
fly deploy --app <app-name>
fly releases --app <app-name>
fly releases rollback --app <app-name>

# Scaling
fly scale count <N> --app <app-name>
fly scale vm <vm-size> --app <app-name>

# Logs
fly logs --app <app-name>
fly logs --app <app-name> --since 1h

# SSH
fly ssh console --app <app-name>
fly ssh keys list
fly ssh keys add <key-file>

# Secrets
fly secrets list --app <app-name>
fly secrets set KEY=VALUE --app <app-name>
fly secrets unset KEY --app <app-name>

# Volumes
fly volumes list --app <app-name>
fly volumes create <name> --region <region> --size <GB>
fly volumes snapshot create <vol-id>

# IPs
fly ips list --app <app-name>
fly ips allocate-v4 --app <app-name>
fly ips allocate-v6 --app <app-name>

# Health
fly checks list --app <app-name>
```

### Database Commands

```bash
# SQLite
sqlite3 /data/yaok_relay.db

# Common queries
.schema                     # Show tables
.tables                     # List tables
SELECT COUNT(*) FROM users; # Count users
PRAGMA integrity_check;     # Check integrity
PRAGMA optimize;            # Optimize
VACUUM;                     # Reclaim space
```

---

## Appendix B: Configuration Files

### Prometheus Scrape Config

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'yaok-relay'
    scrape_interval: 15s
    static_configs:
      - targets:
          - relay-ams.yaok.app:9090
          - relay-iad.yaok.app:9090
          - relay-sin.yaok.app:9090
    relabel_configs:
      - source_labels: [__address__]
        regex: 'relay-(.*).yaok.app:.*'
        target_label: region
        replacement: '$1'
```

### Grafana Dashboard JSON

(See Monitoring & Alerting Setup document for complete dashboards)

---

## Appendix C: Troubleshooting Checklist

**Service Down:**
- [ ] Check Fly.io status page: https://status.flyio.net
- [ ] Check health endpoint: `curl https://relay-ams.yaok.app/health`
- [ ] Check logs: `fly logs --app yaok-relay-ams`
- [ ] Check resources: CPU, memory, disk
- [ ] Restart service: `fly apps restart yaok-relay-ams`
- [ ] Rollback if recent deploy: `fly releases rollback`
- [ ] Check database integrity
- [ ] Scale up if resource constrained

**High Error Rate:**
- [ ] Identify error types in logs
- [ ] Check database status
- [ ] Check connection limits
- [ ] Review recent deployments
- [ ] Check external dependencies (DNS, network)
- [ ] Scale horizontally if overloaded
- [ ] Check for DDoS attack

**Poor Performance:**
- [ ] Check latency metrics (p95, p99)
- [ ] Check resource usage (CPU, memory, I/O)
- [ ] Run database optimization (VACUUM, ANALYZE)
- [ ] Check network latency (ping, traceroute)
- [ ] Profile application (identify hotspots)
- [ ] Scale vertically or horizontally

---

**Document Classification:** INTERNAL  
**Distribution:** Operations Team, SRE Team, Platform Engineers  
**Review Cycle:** Quarterly or after major infrastructure changes

**End of Administrator Manual**
