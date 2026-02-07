# Operational Procedures
## Ya OK - Standard Operating Procedures (SOPs)

**Document ID:** YA-OK-OPS-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** Draft  
**Classification:** INTERNAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | Operations Team | Initial version - Complete SOPs |

### Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Operations Lead | [TBD] | | |
| Technical Architect | [TBD] | | |
| Security Officer | [TBD] | | |

### Related Documents

- **YA-OK-DEPLOY-001**: Production Deployment Guide
- **YA-OK-MON-001**: Monitoring & Alerting Setup
- **YA-OK-IRP-001**: Incident Response Plan
- **YA-OK-ARCH-001**: C4 Architecture Diagrams

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Service Management Framework](#2-service-management-framework)
3. [Backup and Restore Procedures](#3-backup-and-restore-procedures)
4. [Database Maintenance](#4-database-maintenance)
5. [Log Management and Rotation](#5-log-management-and-rotation)
6. [Certificate Management](#6-certificate-management)
7. [Scaling Procedures](#7-scaling-procedures)
8. [Health Check Procedures](#8-health-check-procedures)
9. [Patch Management](#9-patch-management)
10. [Configuration Management](#10-configuration-management)
11. [Capacity Planning](#11-capacity-planning)
12. [Disaster Recovery](#12-disaster-recovery)

---

## 1. Introduction

### 1.1 Purpose

This document defines Standard Operating Procedures (SOPs) for Ya OK system operations, ensuring consistent, reliable, and secure service delivery per ITIL 4 Service Operations best practices.

### 1.2 Scope

**Services Covered:**
- Android mobile application
- iOS mobile application
- Relay server infrastructure (Fly.io)
- Monitoring systems (Prometheus, Grafana, Loki)
- Supporting infrastructure (databases, logs, certificates)

**Out of Scope:**
- Third-party services (Firebase, Sentry)
- Development environments
- Individual user devices

### 1.3 Operational Principles

1. **Reliability**: Maintain 99.9% uptime SLO
2. **Security**: Follow least privilege, defense in depth
3. **Automation**: Automate repetitive tasks
4. **Documentation**: Keep procedures current
5. **Monitoring**: Proactive issue detection
6. **Change Control**: Follow change management process

### 1.4 Roles and Responsibilities

| Role | Responsibilities | On-Call |
|------|------------------|---------|
| **Platform Engineer** | Relay server, infrastructure, scaling | 24/7 rotation |
| **Database Administrator** | Database maintenance, backups | Business hours |
| **Security Engineer** | Certificate renewal, security patches | On-demand |
| **DevOps Engineer** | CI/CD, deployments, automation | Business hours |
| **SRE** | Monitoring, incident response, capacity | 24/7 rotation |

---

## 2. Service Management Framework

### 2.1 ITIL 4 Service Operations

Ya OK operations follow ITIL 4 Service Value System:

```
┌─────────────────────────────────────────────────┐
│         ITIL 4 Service Value Chain              │
├─────────────────────────────────────────────────┤
│ Plan → Improve → Engage → Design & Transition  │
│           ↓                                      │
│    Obtain/Build → Deliver & Support             │
└─────────────────────────────────────────────────┘
```

**Key Practices Implemented:**
- **Incident Management**: Restore service quickly (see Incident Response Plan)
- **Problem Management**: Root cause analysis, prevent recurrence
- **Change Control**: Managed deployments, rollback capability
- **Service Desk**: User support (email, in-app)
- **Monitoring and Event Management**: Proactive monitoring (Prometheus, Grafana)
- **Availability Management**: 99.9% uptime target
- **Capacity Management**: Scaling procedures (section 7)

### 2.2 Service Catalog

| Service | Description | Availability Target | Support Hours |
|---------|-------------|---------------------|---------------|
| **Messaging** | P2P encrypted messaging | 99.9% | 24/7 |
| **Relay Server** | Message relay (offline users) | 99.9% | 24/7 |
| **User Registration** | Identity generation, QR export | 99.5% | 24/7 |
| **Contact Management** | Add/verify contacts | 99.5% | Business hours |
| **Mobile Apps** | Android/iOS apps | 99% | Business hours |

### 2.3 Operational Schedule

**Daily Tasks:**
- Health check monitoring (automated)
- Alert review and acknowledgment
- Backup verification (automated)
- Log review for errors/warnings

**Weekly Tasks:**
- Performance review (metrics dashboard)
- Capacity planning review
- Security patch assessment
- Incident postmortem reviews

**Monthly Tasks:**
- Certificate expiration checks
- Database maintenance (VACUUM, REINDEX)
- Disaster recovery drill
- Service review meeting

**Quarterly Tasks:**
- Capacity planning update
- Infrastructure cost review
- Security audit
- Documentation review

---

## 3. Backup and Restore Procedures

### 3.1 Backup Strategy

**Data Protection:**
- **Mobile App Data**: User devices (encrypted SQLCipher database)
- **Relay Server**: Fly.io volumes (message queue, user registry)
- **Configuration**: GitHub repository (IaC)

**Backup Objectives:**
- **RPO (Recovery Point Objective)**: 1 hour (relay server data)
- **RTO (Recovery Time Objective)**: 30 minutes (relay server restoration)
- **Retention**: 30 days daily, 12 months monthly

### 3.2 Relay Server Backup (Fly.io Volumes)

**Automated Daily Backup:**

```bash
#!/bin/bash
# File: backup-relay-volumes.sh
# Schedule: Daily at 02:00 UTC (cron)

set -euo pipefail

BACKUP_DIR="/backups/relay"
DATE=$(date +%Y%m%d)
RETENTION_DAYS=30

# Backup each region
for REGION in ams iad sin; do
    echo "Backing up relay-${REGION}..."
    
    # Create snapshot via Fly.io API
    fly volumes snapshot create \
        --region ${REGION} \
        --app yaok-relay-${REGION} \
        vol_yaok_relay_${REGION}_data \
        --tag "daily-backup-${DATE}"
    
    # Export snapshot to S3 (optional off-site backup)
    fly volumes snapshot export \
        vol_yaok_relay_${REGION}_data_${DATE} \
        --output ${BACKUP_DIR}/relay-${REGION}-${DATE}.tar.gz
    
    aws s3 cp ${BACKUP_DIR}/relay-${REGION}-${DATE}.tar.gz \
        s3://yaok-backups/relay/${REGION}/${DATE}.tar.gz \
        --storage-class STANDARD_IA
done

# Cleanup old local backups
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: $(date)"
```

**Cron Schedule:**

```cron
# /etc/cron.d/yaok-backups
0 2 * * * root /opt/yaok/scripts/backup-relay-volumes.sh >> /var/log/yaok-backup.log 2>&1
```

### 3.3 Backup Verification

**Automated Verification:**

```bash
#!/bin/bash
# File: verify-backup.sh
# Schedule: Daily at 03:00 UTC

set -euo pipefail

DATE=$(date +%Y%m%d)

for REGION in ams iad sin; do
    BACKUP_FILE="relay-${REGION}-${DATE}.tar.gz"
    
    # Check file exists
    if [ ! -f "/backups/relay/${BACKUP_FILE}" ]; then
        echo "ERROR: Backup file not found: ${BACKUP_FILE}"
        # Alert via monitoring
        curl -X POST https://alertmanager/api/v1/alerts \
            -d "[{\"labels\":{\"alertname\":\"BackupMissing\",\"severity\":\"high\",\"region\":\"${REGION}\"}}]"
        continue
    fi
    
    # Verify file integrity
    if ! tar -tzf "/backups/relay/${BACKUP_FILE}" > /dev/null 2>&1; then
        echo "ERROR: Backup file corrupted: ${BACKUP_FILE}"
        curl -X POST https://alertmanager/api/v1/alerts \
            -d "[{\"labels\":{\"alertname\":\"BackupCorrupted\",\"severity\":\"critical\",\"region\":\"${REGION}\"}}]"
        continue
    fi
    
    # Check file size (should be > 1MB)
    SIZE=$(stat -f%z "/backups/relay/${BACKUP_FILE}")
    if [ ${SIZE} -lt 1048576 ]; then
        echo "WARNING: Backup file suspiciously small: ${BACKUP_FILE} (${SIZE} bytes)"
    fi
    
    echo "OK: Backup verified: ${BACKUP_FILE}"
done
```

### 3.4 Restore Procedures

**Relay Server Data Restore:**

**Step 1: Identify Backup**

```bash
# List available backups
aws s3 ls s3://yaok-backups/relay/ams/ --recursive

# Select backup (e.g., 20260205.tar.gz for Feb 5, 2026)
BACKUP_DATE=20260205
REGION=ams
```

**Step 2: Download Backup**

```bash
aws s3 cp s3://yaok-backups/relay/${REGION}/${BACKUP_DATE}.tar.gz \
    /tmp/restore-${REGION}.tar.gz
```

**Step 3: Stop Relay Server**

```bash
# Scale down to 0 instances (temporarily)
fly scale count 0 --app yaok-relay-${REGION}

# Wait for graceful shutdown (30 seconds)
sleep 30
```

**Step 4: Restore Volume**

```bash
# Extract backup
tar -xzf /tmp/restore-${REGION}.tar.gz -C /tmp/restore-data

# Import to Fly.io volume
fly volumes restore vol_yaok_relay_${REGION}_data \
    --source /tmp/restore-data \
    --region ${REGION}
```

**Step 5: Restart Relay Server**

```bash
# Scale back to 2 instances
fly scale count 2 --app yaok-relay-${REGION}

# Verify health
sleep 10
curl https://relay-${REGION}.yaok.app/health
```

**Step 6: Verify Service**

```bash
# Check logs for errors
fly logs --app yaok-relay-${REGION}

# Check metrics dashboard
# Grafana: Platform Health → Relay Server (${REGION})

# Verify message delivery
# Send test message via mobile app
```

**Rollback:** If restore fails, redeploy from last known good state:

```bash
fly deploy --app yaok-relay-${REGION} --image-ref yaok-relay:last-known-good
```

### 3.5 Configuration Backup

**All configuration in version control (GitHub):**
- Infrastructure as Code (Terraform/Fly.toml)
- CI/CD pipelines (GitHub Actions)
- Monitoring configs (Prometheus, Grafana)

**Backup:** Automated GitHub repository backups

```bash
# Daily GitHub repo backup to S3
gh repo clone yaok/infrastructure /tmp/yaok-config
tar -czf /tmp/yaok-config-$(date +%Y%m%d).tar.gz /tmp/yaok-config
aws s3 cp /tmp/yaok-config-$(date +%Y%m%d).tar.gz s3://yaok-backups/config/
```

---

## 4. Database Maintenance

### 4.1 Mobile App Database (SQLCipher)

**User Responsibility:**
- Each user's data stored locally on device
- Encrypted with SQLCipher (user's device key)
- Users responsible for backups (cloud backup, device transfer)

**Maintenance Tasks (App-side):**

**Database Vacuum (reclaim space):**

```kotlin
// Android: Triggered monthly or when DB > 100MB
fun vacuumDatabase() {
    val db = writableDatabase
    db.execSQL("VACUUM")
    db.execSQL("PRAGMA optimize")
    Log.i(TAG, "Database vacuumed: ${db.path}")
}
```

**Database Integrity Check:**

```kotlin
fun checkDatabaseIntegrity(): Boolean {
    val db = readableDatabase
    val cursor = db.rawQuery("PRAGMA integrity_check", null)
    cursor.moveToFirst()
    val result = cursor.getString(0)
    cursor.close()
    return result == "ok"
}
```

### 4.2 Relay Server Database (SQLite)

**Database Location:** `/data/yaok_relay.db` (Fly.io volume)

**Maintenance Schedule:**

| Task | Frequency | Command |
|------|-----------|---------|
| **Vacuum** | Weekly | `VACUUM;` |
| **Analyze** | Daily | `ANALYZE;` |
| **Integrity Check** | Weekly | `PRAGMA integrity_check;` |
| **Reindex** | Monthly | `REINDEX;` |

**Automated Maintenance Script:**

```bash
#!/bin/bash
# File: /opt/yaok/scripts/db-maintenance.sh
# Run on relay server container

DB_PATH="/data/yaok_relay.db"
LOG_FILE="/var/log/yaok-db-maintenance.log"

echo "=== Database Maintenance: $(date) ===" >> ${LOG_FILE}

# Integrity check
echo "Running integrity check..." >> ${LOG_FILE}
sqlite3 ${DB_PATH} "PRAGMA integrity_check;" >> ${LOG_FILE}

# Analyze (update query planner statistics)
echo "Running ANALYZE..." >> ${LOG_FILE}
sqlite3 ${DB_PATH} "ANALYZE;" >> ${LOG_FILE}

# Vacuum (weekly only, via external cron)
if [ "$(date +%u)" -eq 1 ]; then  # Monday
    echo "Running VACUUM..." >> ${LOG_FILE}
    sqlite3 ${DB_PATH} "VACUUM;" >> ${LOG_FILE}
fi

# Reindex (first day of month)
if [ "$(date +%d)" -eq 01 ]; then
    echo "Running REINDEX..." >> ${LOG_FILE}
    sqlite3 ${DB_PATH} "REINDEX;" >> ${LOG_FILE}
fi

# Database size report
SIZE=$(du -h ${DB_PATH} | cut -f1)
echo "Database size: ${SIZE}" >> ${LOG_FILE}

echo "Maintenance completed: $(date)" >> ${LOG_FILE}
```

**Deploy via fly.toml:**

```toml
[deploy]
  release_command = "/opt/yaok/scripts/db-maintenance.sh"
```

### 4.3 Database Performance Tuning

**SQLite PRAGMA Settings:**

```sql
-- Enable WAL mode (better concurrency)
PRAGMA journal_mode = WAL;

-- Increase cache size (10MB)
PRAGMA cache_size = -10000;

-- Optimize for read-heavy workload
PRAGMA query_only = 0;
PRAGMA temp_store = MEMORY;
PRAGMA synchronous = NORMAL;  -- Balance safety/performance
```

**Applied at startup (Rust code):**

```rust
fn init_database(path: &Path) -> Result<Connection> {
    let conn = Connection::open(path)?;
    
    // Performance optimizations
    conn.execute_batch("
        PRAGMA journal_mode = WAL;
        PRAGMA cache_size = -10000;
        PRAGMA synchronous = NORMAL;
        PRAGMA temp_store = MEMORY;
        PRAGMA mmap_size = 30000000000;
    ")?;
    
    Ok(conn)
}
```

---

## 5. Log Management and Rotation

### 5.1 Log Sources

| Source | Type | Location | Retention |
|--------|------|----------|-----------|
| **Relay Server** | Application logs | Loki (Grafana Cloud) | 30 days |
| **Mobile Apps** | Crash logs | Firebase Crashlytics | 90 days |
| **Mobile Apps** | Error logs | Sentry | 90 days |
| **CI/CD** | Build logs | GitHub Actions | 30 days |
| **Infrastructure** | System logs | Fly.io logs | 7 days |

### 5.2 Relay Server Log Rotation

**Structured JSON Logging:**

```rust
// Log format (structured JSON)
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

**Log Levels:**

| Level | Retention | Use Case |
|-------|-----------|----------|
| **ERROR** | 90 days | Critical errors requiring investigation |
| **WARN** | 30 days | Warnings, degraded performance |
| **INFO** | 30 days | Normal operations, key events |
| **DEBUG** | 7 days | Detailed debugging (dev/staging only) |

**Logrotate Configuration:**

```bash
# /etc/logrotate.d/yaok-relay
/var/log/yaok-relay/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 yaok yaok
    sharedscripts
    postrotate
        /usr/bin/killall -SIGUSR1 yaok-relay || true
    endscript
}
```

### 5.3 Log Aggregation (Loki)

**Promtail Configuration (ships logs to Loki):**

```yaml
# /etc/promtail/config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: https://logs-prod-us-central1.grafana.net/loki/api/v1/push
    basic_auth:
      username: ${LOKI_USERNAME}
      password: ${LOKI_API_KEY}

scrape_configs:
  - job_name: yaok-relay
    static_configs:
      - targets:
          - localhost
        labels:
          job: yaok-relay
          service: relay
          region: ${FLY_REGION}
          __path__: /var/log/yaok-relay/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            timestamp: timestamp
            message: message
            trace_id: trace_id
      - labels:
          level:
          trace_id:
      - timestamp:
          source: timestamp
          format: RFC3339
```

### 5.4 Log Queries (Common Operations)

**Find all errors in last hour:**

```logql
{service="yaok-relay", level="ERROR"} |= "" | json | line_format "{{.timestamp}} {{.message}}"
```

**Find slow requests (>500ms):**

```logql
{service="yaok-relay"} | json | duration_ms > 500 | line_format "{{.message}} ({{.duration_ms}}ms)"
```

**Find logs for specific trace ID:**

```logql
{service="yaok-relay"} | json | trace_id="abc123..." | line_format "{{.timestamp}} {{.level}} {{.message}}"
```

---

## 6. Certificate Management

### 6.1 TLS Certificates

**Certificate Authorities:**
- **Relay Server**: Let's Encrypt (automated via Fly.io)
- **Mobile Apps**: Platform-managed (Google Play, App Store)

**Fly.io TLS Certificates (Automatic):**

```bash
# Fly.io automatically provisions Let's Encrypt certificates
# for custom domains via fly.toml:

[[services]]
  internal_port = 41641
  protocol = "udp"

[[services.ports]]
  port = 41641

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true

[[http_service.checks]]
  interval = 10000
  grace_period = "5s"
  method = "get"
  path = "/health"
  protocol = "http"
  timeout = 2000
```

**Certificate Expiration Monitoring:**

```bash
#!/bin/bash
# File: check-cert-expiry.sh
# Schedule: Daily

DOMAINS="relay.yaok.app relay-ams.yaok.app relay-iad.yaok.app relay-sin.yaok.app"
WARN_DAYS=30

for DOMAIN in ${DOMAINS}; do
    EXPIRY=$(echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null \
        | openssl x509 -noout -enddate | cut -d= -f2)
    
    EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    
    echo "${DOMAIN}: ${DAYS_LEFT} days until expiry"
    
    if [ ${DAYS_LEFT} -lt ${WARN_DAYS} ]; then
        echo "WARNING: Certificate for ${DOMAIN} expires in ${DAYS_LEFT} days"
        # Alert via monitoring
        curl -X POST https://alertmanager/api/v1/alerts \
            -d "[{\"labels\":{\"alertname\":\"CertificateExpiring\",\"severity\":\"high\",\"domain\":\"${DOMAIN}\",\"days_left\":\"${DAYS_LEFT}\"}}]"
    fi
done
```

### 6.2 Code Signing Certificates

**Android:**

**Certificate:** Google Play App Signing (managed by Google)  
**Keystore:** Upload keystore (local, encrypted)

**Keystore Backup:**

```bash
# Backup upload keystore (critical!)
KEYSTORE_PATH=/secrets/yaok-upload-keystore.jks
BACKUP_DIR=/secure-backups/keystores

# Encrypt keystore with GPG before backup
gpg --symmetric --cipher-algo AES256 ${KEYSTORE_PATH}
aws s3 cp ${KEYSTORE_PATH}.gpg s3://yaok-secrets/keystores/yaok-upload-keystore.jks.gpg \
    --storage-class GLACIER

# Verify backup
aws s3 ls s3://yaok-secrets/keystores/
```

**iOS:**

**Certificate:** Apple Developer Certificate (valid 1 year)  
**Renewal Process:**

1. **Check expiration** (Apple Developer Portal)
2. **Generate CSR** (Xcode → Preferences → Accounts → Manage Certificates)
3. **Request new certificate** (developer.apple.com → Certificates)
4. **Download and install** in Xcode
5. **Update provisioning profiles**
6. **Test build** with new certificate

**Automated Expiration Check:**

```bash
#!/bin/bash
# Check iOS certificate expiration

security find-identity -v -p codesigning | grep "Apple Distribution" | while read line; do
    CERT_NAME=$(echo ${line} | sed 's/.*"\(.*\)"/\1/')
    EXPIRY=$(security find-certificate -c "${CERT_NAME}" -p | openssl x509 -noout -enddate)
    echo "${CERT_NAME}: ${EXPIRY}"
done
```

---

## 7. Scaling Procedures

### 7.1 Relay Server Scaling

**Scaling Dimensions:**
1. **Vertical Scaling**: Increase VM resources (CPU, RAM)
2. **Horizontal Scaling**: Add more instances per region
3. **Geographic Scaling**: Add new regions

**Current Configuration:**

| Region | Location | Instances | VM Size | Max Capacity |
|--------|----------|-----------|---------|--------------|
| **ams** | Amsterdam | 2 | shared-cpu-1x (1 CPU, 256MB) | 10,000 users |
| **iad** | Virginia | 2 | shared-cpu-1x | 10,000 users |
| **sin** | Singapore | 2 | shared-cpu-1x | 10,000 users |

### 7.2 Horizontal Scaling (Add Instances)

**Trigger:** CPU > 80% sustained for 10 minutes OR Active connections > 8,000

**Procedure:**

```bash
# Step 1: Check current load
fly status --app yaok-relay-ams

# Step 2: Scale up (add 1 instance)
fly scale count 3 --app yaok-relay-ams --region ams

# Step 3: Verify new instance health
sleep 30
fly status --app yaok-relay-ams

# Step 4: Monitor metrics (Grafana)
# Check: relay_active_connections, relay_cpu_usage_percent

# Step 5: If load distributed, keep new instance
# If load still high, repeat (max 5 instances per region)
```

**Automated Scaling (Future):**

```yaml
# Fly.io autoscaling config
[services.concurrency]
  type = "connections"
  hard_limit = 10000
  soft_limit = 8000

[[services.autoscaling]]
  min_instances = 2
  max_instances = 5
  target_cpu_percent = 70
```

### 7.3 Vertical Scaling (Increase VM Resources)

**Trigger:** Memory > 200MB sustained OR need better single-core performance

**Procedure:**

```bash
# Step 1: Identify target VM size
fly platform vm-sizes

# Step 2: Update fly.toml
[vm]
  cpu_kind = "shared"
  cpus = 2
  memory_mb = 512

# Step 3: Deploy with Blue-Green
fly deploy --app yaok-relay-ams --strategy bluegreen

# Step 4: Monitor performance improvement
# Grafana: relay_memory_usage_bytes, relay_cpu_usage_percent

# Step 5: Rollback if issues
fly releases rollback --app yaok-relay-ams
```

**Cost Impact:**

| VM Size | CPU | RAM | Cost/Month | Instances | Total Cost |
|---------|-----|-----|------------|-----------|------------|
| shared-cpu-1x | 1 | 256MB | $2 | 6 (3 regions × 2) | $12 |
| shared-cpu-2x | 2 | 512MB | $4 | 6 | $24 |
| dedicated-cpu-1x | 1 | 2GB | $30 | 6 | $180 |

### 7.4 Geographic Scaling (Add Region)

**Trigger:** User growth in new geography OR latency > 200ms for users

**Procedure:**

**Step 1: Select Region**

```bash
# List available Fly.io regions
fly platform regions

# Select based on user location (e.g., syd for Australia)
NEW_REGION=syd
```

**Step 2: Create New App**

```bash
# Clone existing app to new region
fly apps create yaok-relay-${NEW_REGION}

# Create volume
fly volumes create vol_yaok_relay_${NEW_REGION}_data \
    --region ${NEW_REGION} \
    --size 10
```

**Step 3: Deploy**

```bash
# Deploy to new region
fly deploy --app yaok-relay-${NEW_REGION} --region ${NEW_REGION}

# Scale to 2 instances
fly scale count 2 --app yaok-relay-${NEW_REGION}
```

**Step 4: Update DNS**

```bash
# Add DNS record for new region
fly ips allocate-v4 --app yaok-relay-${NEW_REGION}
fly ips allocate-v6 --app yaok-relay-${NEW_REGION}

# Update DNS: relay-syd.yaok.app → <new_ip>
```

**Step 5: Configure Load Balancing**

Update mobile app configuration:

```kotlin
// Add new region to relay server list
val RELAY_SERVERS = listOf(
    "relay-ams.yaok.app:41641",  // Europe
    "relay-iad.yaok.app:41641",  // US East
    "relay-sin.yaok.app:41641",  // Asia
    "relay-syd.yaok.app:41641"   // Australia (NEW)
)

// Client selects closest based on latency test
```

**Step 6: Monitor**

```bash
# Check health
curl https://relay-syd.yaok.app/health

# Monitor metrics (Grafana)
# Add new dashboard panel for syd region
```

---

## 8. Health Check Procedures

### 8.1 Automated Health Checks

**Relay Server Health Endpoint:**

```rust
// /health endpoint implementation
#[get("/health")]
async fn health_check(state: web::Data<AppState>) -> impl Responder {
    let health = HealthStatus {
        status: "healthy",
        version: env!("CARGO_PKG_VERSION"),
        uptime_seconds: state.start_time.elapsed().as_secs(),
        active_connections: state.connection_count.load(Ordering::Relaxed),
        database_ok: check_database(&state.db).await.is_ok(),
        queue_size: state.message_queue.len().await,
    };
    
    if health.active_connections > 9000 || !health.database_ok {
        HttpResponse::ServiceUnavailable().json(health)
    } else {
        HttpResponse::Ok().json(health)
    }
}

async fn check_database(db: &Database) -> Result<()> {
    db.execute("SELECT 1", []).await?;
    Ok(())
}
```

**Monitoring via Prometheus:**

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'yaok-relay-health'
    scrape_interval: 15s
    metrics_path: /health
    static_configs:
      - targets:
          - relay-ams.yaok.app:8080
          - relay-iad.yaok.app:8080
          - relay-sin.yaok.app:8080
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'health_.*'
        action: keep
```

### 8.2 Manual Health Check Procedure

**Frequency:** Daily (automated), on-demand (during incidents)

**Checklist:**

```bash
#!/bin/bash
# File: health-check.sh

echo "=== Ya OK Health Check: $(date) ==="

# 1. Relay Server Health
echo "1. Checking relay servers..."
for REGION in ams iad sin; do
    RESPONSE=$(curl -s -w "\n%{http_code}" https://relay-${REGION}.yaok.app/health)
    HTTP_CODE=$(echo "${RESPONSE}" | tail -n1)
    BODY=$(echo "${RESPONSE}" | head -n-1)
    
    if [ "${HTTP_CODE}" -eq 200 ]; then
        echo "  ✓ relay-${REGION}: OK"
        echo "    $(echo ${BODY} | jq -r '.status, .active_connections')"
    else
        echo "  ✗ relay-${REGION}: FAILED (HTTP ${HTTP_CODE})"
    fi
done

# 2. Database Connectivity
echo "2. Checking database..."
for REGION in ams iad sin; do
    DB_OK=$(fly ssh console --app yaok-relay-${REGION} -C "sqlite3 /data/yaok_relay.db 'SELECT 1'" 2>&1)
    if [ "${DB_OK}" == "1" ]; then
        echo "  ✓ Database ${REGION}: OK"
    else
        echo "  ✗ Database ${REGION}: FAILED"
    fi
done

# 3. TLS Certificate Validity
echo "3. Checking TLS certificates..."
for DOMAIN in relay-ams.yaok.app relay-iad.yaok.app relay-sin.yaok.app; do
    EXPIRY=$(echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null \
        | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    echo "  ✓ ${DOMAIN}: Valid until ${EXPIRY}"
done

# 4. Monitoring Systems
echo "4. Checking monitoring..."
PROMETHEUS=$(curl -s -o /dev/null -w "%{http_code}" https://prometheus.yaok.app/-/healthy)
GRAFANA=$(curl -s -o /dev/null -w "%{http_code}" https://grafana.yaok.app/api/health)

if [ "${PROMETHEUS}" -eq 200 ]; then
    echo "  ✓ Prometheus: OK"
else
    echo "  ✗ Prometheus: FAILED"
fi

if [ "${GRAFANA}" -eq 200 ]; then
    echo "  ✓ Grafana: OK"
else
    echo "  ✗ Grafana: FAILED"
fi

# 5. Alert Summary
echo "5. Active alerts..."
ALERTS=$(curl -s https://alertmanager/api/v2/alerts | jq -r '.[] | select(.status.state=="active") | .labels.alertname')
if [ -z "${ALERTS}" ]; then
    echo "  ✓ No active alerts"
else
    echo "  ⚠ Active alerts:"
    echo "${ALERTS}" | sed 's/^/    - /'
fi

echo ""
echo "Health check completed: $(date)"
```

### 8.3 Mobile App Health (User-Facing)

**In-App Health Indicator:**

```kotlin
// Android: Display service status in settings
data class ServiceHealth(
    val messaging: Status,      // LOCAL, BLE, RELAY
    val relayServer: Status,    // CONNECTED, DISCONNECTED, DEGRADED
    val encryption: Status      // OK, ERROR
)

enum class Status {
    OK,          // Green indicator
    DEGRADED,    // Yellow indicator
    UNAVAILABLE  // Red indicator
}

// Display in UI
fun showHealthStatus(health: ServiceHealth) {
    binding.messagingStatus.setImageResource(health.messaging.icon())
    binding.relayStatus.setImageResource(health.relayServer.icon())
    binding.encryptionStatus.setImageResource(health.encryption.icon())
}
```

---

## 9. Patch Management

### 9.1 Patch Categories

| Category | Examples | Frequency | Urgency |
|----------|----------|-----------|---------|
| **Critical Security** | CVE fixes, zero-days | Immediate | <24 hours |
| **Security** | Dependency vulnerabilities | Weekly | <7 days |
| **Bug Fixes** | Application bugs | Bi-weekly | <14 days |
| **Feature Updates** | New features | Monthly | <30 days |
| **Infrastructure** | OS patches, library updates | Monthly | <30 days |

### 9.2 Dependency Scanning

**Automated Scanning (GitHub Dependabot):**

```yaml
# .github/dependabot.yml
version: 2
updates:
  # Rust dependencies
  - package-ecosystem: "cargo"
    directory: "/ya_ok_core"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
  
  # Android dependencies
  - package-ecosystem: "gradle"
    directory: "/android"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
  
  # iOS dependencies (CocoaPods)
  - package-ecosystem: "cocoapods"
    directory: "/ios"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
```

**Manual Audit:**

```bash
# Rust: Check for outdated dependencies
cd ya_ok_core
cargo outdated

# Check for security vulnerabilities
cargo audit

# Android: Check for outdated dependencies
cd android
./gradlew dependencyUpdates

# iOS: Check for outdated pods
cd ios
pod outdated
```

### 9.3 Patch Deployment Process

**Non-Critical Patches:**

1. **Review**: Security team reviews vulnerability report
2. **Test**: Update dependencies in staging environment
3. **Validate**: Run full test suite (unit, integration, security)
4. **Deploy**: Standard deployment process (staged rollout)
5. **Monitor**: Watch for regressions (24 hours)
6. **Close**: Mark vulnerability as resolved

**Critical Security Patches (Emergency):**

```bash
# 1. Identify vulnerability (CVE-YYYY-XXXXX)
# 2. Review impact assessment
# 3. Prepare hotfix branch
git checkout -b hotfix/CVE-YYYY-XXXXX main

# 4. Apply patch
cd ya_ok_core
cargo update <vulnerable_crate>

# 5. Build and test
cargo build --release
cargo test

# 6. Deploy immediately (skip staged rollout)
fly deploy --app yaok-relay-ams --strategy immediate
fly deploy --app yaok-relay-iad --strategy immediate
fly deploy --app yaok-relay-sin --strategy immediate

# 7. Monitor for 1 hour
# Watch error rates, latency, crash rates

# 8. Notify users (if client-side patch needed)
# Push app update to Google Play / App Store (expedited review)

# 9. Post-incident review
# Document in security advisory
```

---

## 10. Configuration Management

### 10.1 Configuration Strategy

**Principles:**
1. **Infrastructure as Code**: All config in Git
2. **Environment Separation**: Dev, Staging, Production
3. **Secret Management**: Encrypted secrets (Fly.io Secrets, GitHub Secrets)
4. **Version Control**: Track all changes
5. **Auditability**: Know who changed what, when

### 10.2 Configuration Sources

| Component | Source | Format | Example |
|-----------|--------|--------|---------|
| **Relay Server** | fly.toml | TOML | VM size, ports, health checks |
| **Mobile Apps** | build.gradle, Info.plist | Gradle/Plist | App version, SDK versions |
| **CI/CD** | .github/workflows/ | YAML | Build steps, deployment |
| **Monitoring** | prometheus.yml | YAML | Scrape configs, rules |
| **Infrastructure** | Terraform (future) | HCL | Cloud resources |

### 10.3 Environment Variables

**Relay Server:**

```bash
# Production environment variables (Fly.io Secrets)
fly secrets set \
    DATABASE_URL="sqlite:///data/yaok_relay.db" \
    RUST_LOG="info" \
    RELAY_PORT="41641" \
    HTTP_PORT="8080" \
    MAX_CONNECTIONS="10000" \
    PROMETHEUS_ENDPOINT="https://prometheus.yaok.app" \
    --app yaok-relay-ams
```

**Mobile Apps:**

```kotlin
// Android: BuildConfig (gradle.properties)
buildConfigField("String", "RELAY_URL", "\"relay.yaok.app:41641\"")
buildConfigField("String", "API_VERSION", "\"v1\"")
buildConfigField("Boolean", "DEBUG_MODE", "false")
```

```swift
// iOS: Info.plist
<key>RelayURL</key>
<string>relay.yaok.app:41641</string>
<key>APIVersion</key>
<string>v1</string>
```

### 10.4 Configuration Change Process

**Standard Changes:**

1. **Propose**: Create PR with config change
2. **Review**: Technical lead reviews
3. **Test**: Deploy to staging, validate
4. **Approve**: Merge to main
5. **Deploy**: CI/CD deploys to production
6. **Verify**: Check metrics, no errors

**Emergency Changes:**

1. **Identify**: Critical issue requiring config change
2. **Apply**: Direct change via CLI (bypass PR)
3. **Document**: Record in incident log
4. **Validate**: Immediate testing
5. **Follow-up**: Create PR post-incident (document change)

**Example (Emergency Rate Limit Increase):**

```bash
# Emergency: Increase rate limit due to legitimate traffic spike
fly secrets set MAX_CONNECTIONS="15000" --app yaok-relay-ams

# Restart to apply
fly apps restart yaok-relay-ams

# Monitor
fly logs --app yaok-relay-ams

# Follow-up PR: Update fly.toml with new value
```

---

## 11. Capacity Planning

### 11.1 Capacity Metrics

**Key Metrics:**

| Metric | Current | Target (6 months) | Capacity Threshold |
|--------|---------|-------------------|-------------------|
| **Active Users** | 5,000 | 20,000 | 80% of capacity |
| **Messages/Day** | 50,000 | 500,000 | 80% of capacity |
| **Relay Connections** | 2,000 | 8,000 | 8,000 per region |
| **Database Size** | 2 GB | 10 GB | 80% of volume |
| **Bandwidth** | 10 GB/day | 50 GB/day | 80% of quota |

### 11.2 Growth Projections

**User Growth Model:**

```
Year 1: 5,000 users (current)
Year 2: 50,000 users (10x growth)
Year 3: 200,000 users (4x growth)
Year 5: 1,000,000 users (5x growth)
```

**Resource Requirements (Per User):**

- **Storage**: ~50 MB per user (messages, media)
- **Bandwidth**: ~10 MB/month per active user
- **Compute**: ~0.1 CPU seconds/day per user

**Scaling Roadmap:**

| Milestone | Users | Infrastructure Changes |
|-----------|-------|----------------------|
| **Current** | 5,000 | 3 regions, 2 instances each, 256MB VM |
| **Q2 2026** | 20,000 | Scale to 3 instances per region |
| **Q4 2026** | 50,000 | Upgrade to 512MB VM, 4 instances per region |
| **Q2 2027** | 100,000 | Add 2 new regions (aus, eur-west) |
| **2028** | 500,000 | Dedicated infrastructure, Redis cache |

### 11.3 Capacity Monitoring

**Dashboard Panels:**

1. **User Growth**: DAU/MAU trend, growth rate
2. **Resource Utilization**: CPU, memory, disk usage
3. **Database Growth**: DB size trend, query performance
4. **Network Usage**: Bandwidth consumption, peak times
5. **Cost Tracking**: Infrastructure costs vs. budget

**Alerting:**

```yaml
# Prometheus alert rules
- alert: CapacityWarning
  expr: relay_active_connections / 10000 > 0.8
  for: 1h
  labels:
    severity: medium
  annotations:
    summary: "Relay capacity at 80%"
    description: "Region {{ $labels.region }} at {{ $value | humanizePercentage }} capacity"

- alert: DatabaseCapacityWarning
  expr: disk_usage_percent{mount="/data"} > 80
  for: 30m
  labels:
    severity: medium
  annotations:
    summary: "Database volume at 80% capacity"
```

### 11.4 Capacity Planning Review

**Quarterly Review Meeting:**

**Attendees:** CTO, Platform Engineer, SRE, Product Manager

**Agenda:**
1. Review current capacity metrics
2. User growth analysis (actual vs. projected)
3. Resource utilization trends
4. Cost analysis (actual vs. budget)
5. Scaling decisions (next 6 months)
6. Infrastructure optimization opportunities

**Output:** Capacity Plan document (updated quarterly)

---

## 12. Disaster Recovery

### 12.1 Disaster Scenarios

| Scenario | Likelihood | Impact | RTO | RPO |
|----------|------------|--------|-----|-----|
| **Region Outage** | Medium | High | 30 min | 1 hour |
| **Database Corruption** | Low | High | 1 hour | 1 hour |
| **DDoS Attack** | Medium | Medium | 2 hours | 0 (no data loss) |
| **Data Center Failure** | Low | High | 1 hour | 1 hour |
| **Human Error (Config)** | Medium | Medium | 15 min | 0 (rollback) |
| **Security Breach** | Low | Critical | 4 hours | 1 hour |

### 12.2 Region Outage Response

**Scenario:** One Fly.io region becomes unavailable (e.g., ams down)

**Detection:**
- Prometheus alerts: `relay_up{region="ams"} == 0`
- Fly.io status page: https://status.flyio.net

**Response:**

**Step 1: Verify Outage (5 minutes)**

```bash
# Check relay health
curl https://relay-ams.yaok.app/health

# Check Fly.io status
fly status --app yaok-relay-ams

# Check other regions (should be unaffected)
curl https://relay-iad.yaok.app/health
curl https://relay-sin.yaok.app/health
```

**Step 2: Notify Users (15 minutes)**

```bash
# Update status page
# Post to Twitter/Status Page: "Amsterdam region experiencing issues. Service available via other regions."

# Mobile apps automatically failover to next closest region
# No user action required
```

**Step 3: Monitor Impact**

```bash
# Monitor metrics
# Grafana: Active connections on iad/sin should increase
# Watch for cascading failures (overload)
```

**Step 4: Scale Remaining Regions (if needed)**

```bash
# If load increases significantly
fly scale count 3 --app yaok-relay-iad --region iad
fly scale count 3 --app yaok-relay-sin --region sin
```

**Step 5: Recovery**

```bash
# When Fly.io restores ams region
fly apps restart yaok-relay-ams

# Verify health
curl https://relay-ams.yaok.app/health

# Scale back other regions
fly scale count 2 --app yaok-relay-iad
fly scale count 2 --app yaok-relay-sin
```

### 12.3 Database Corruption Recovery

**Scenario:** SQLite database corruption detected

**Detection:**
- Health check fails: `database_ok: false`
- Logs: `database disk image is malformed`

**Response:**

**Step 1: Stop Writes (Immediate)**

```bash
# Scale affected app to 0 (stop all instances)
fly scale count 0 --app yaok-relay-${REGION}
```

**Step 2: Assess Damage**

```bash
# SSH into VM
fly ssh console --app yaok-relay-${REGION}

# Check integrity
sqlite3 /data/yaok_relay.db "PRAGMA integrity_check;"

# If recoverable, dump data
sqlite3 /data/yaok_relay.db ".dump" > /tmp/backup.sql
```

**Step 3: Restore from Backup**

```bash
# Download latest backup
aws s3 cp s3://yaok-backups/relay/${REGION}/$(date +%Y%m%d).tar.gz /tmp/

# Extract
tar -xzf /tmp/$(date +%Y%m%d).tar.gz -C /data/

# Verify integrity
sqlite3 /data/yaok_relay.db "PRAGMA integrity_check;"
```

**Step 4: Restart Service**

```bash
# Scale back up
fly scale count 2 --app yaok-relay-${REGION}

# Monitor logs
fly logs --app yaok-relay-${REGION}
```

**Step 5: Post-Incident**

- Document root cause
- Review backup procedures
- Consider write-ahead logging (WAL) improvements

### 12.4 Complete Infrastructure Failure

**Scenario:** All Fly.io regions unavailable (extremely unlikely)

**Fallback Plan:**

1. **Mobile apps operate in offline mode**
   - BLE and WiFi Direct still functional
   - Messages queued locally
   - No relay-based delivery

2. **Activate backup infrastructure** (if available)
   - Deploy to AWS/GCP as emergency fallback
   - Update DNS to point to new infrastructure
   - Restore data from S3 backups

3. **Communicate with users**
   - In-app notification: "Service temporarily unavailable. Local messaging still works."
   - Status page update
   - Email/social media notification

### 12.5 Disaster Recovery Drills

**Quarterly DR Drill:**

**Schedule:** First Saturday of each quarter, 10:00 UTC

**Procedure:**

1. **Announce drill** (1 week notice to team)
2. **Execute scenario** (e.g., simulate region outage)
3. **Measure response**:
   - Time to detect: Target <5 min
   - Time to respond: Target <15 min
   - Time to resolve: Target <30 min
4. **Document lessons learned**
5. **Update procedures** based on findings

**Drill Checklist:**

- [ ] All on-call engineers notified
- [ ] Backup systems verified accessible
- [ ] Communication channels tested (Slack, PagerDuty)
- [ ] Backup restoration tested (sample data)
- [ ] Failover procedures tested
- [ ] Timeline documented
- [ ] Post-drill retrospective scheduled

---

## Appendix A: Operational Runbook Index

| Runbook | Description | Location |
|---------|-------------|----------|
| **Service Down** | Relay server unavailable | Monitoring & Alerting Setup, Appendix |
| **High Error Rate** | Error rate > 5% | Monitoring & Alerting Setup, Appendix |
| **Database Issues** | Database corruption, performance | Section 4.2 |
| **Certificate Renewal** | TLS certificate expiring | Section 6 |
| **Scaling Up** | Add capacity (horizontal/vertical) | Section 7 |
| **Region Outage** | Geographic region failure | Section 12.2 |
| **Security Incident** | Security breach response | Incident Response Plan (YA-OK-IRP-001) |

---

## Appendix B: Contact Information

| Role | Name | Email | Phone | Escalation |
|------|------|-------|-------|------------|
| **On-Call Engineer** | [Rotation] | oncall@yaok.app | [PagerDuty] | Immediate |
| **Platform Lead** | [TBD] | platform@yaok.app | [Phone] | <30 min |
| **Security Lead** | [TBD] | security@yaok.app | [Phone] | <1 hour |
| **CTO** | [TBD] | cto@yaok.app | [Phone] | <2 hours |

**PagerDuty:** https://yaok.pagerduty.com  
**Slack:** #yaok-ops, #yaok-incidents  
**Status Page:** https://status.yaok.app

---

## Appendix C: SOP Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-06 | Initial SOPs | Operations Team |

---

**Document Classification:** INTERNAL  
**Distribution:** Operations Team, Engineering Team, Management  
**Review Cycle:** Quarterly

**End of Operational Procedures Document**
