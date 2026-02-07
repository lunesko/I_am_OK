# Monitoring & Alerting Setup
## Ya OK - Comprehensive Observability Framework

**Document ID:** YA-OK-MON-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** Draft  
**Classification:** INTERNAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | DevOps Team | Initial version - Complete monitoring setup |

### Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| DevOps Lead | [TBD] | | |
| SRE Lead | [TBD] | | |
| Product Owner | [TBD] | | |

### Related Documents

- **YA-OK-DEPLOY-001**: Production Deployment Guide
- **YA-OK-NFR-001**: Non-Functional Requirements
- **YA-OK-SEC-001**: Security Threat Model
- **YA-OK-ARCH-001**: C4 Architecture Diagrams

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Monitoring Architecture](#2-monitoring-architecture)
3. [Metrics Definition](#3-metrics-definition)
4. [Dashboards](#4-dashboards)
5. [Alerting Rules](#5-alerting-rules)
6. [SLIs and SLOs](#6-slis-and-slos)
7. [Log Management](#7-log-management)
8. [Distributed Tracing](#8-distributed-tracing)
9. [Incident Response](#9-incident-response)
10. [Monitoring Tools Configuration](#10-monitoring-tools-configuration)
11. [Runbooks](#11-runbooks)

---

## 1. Introduction

### 1.1 Purpose

This document defines the comprehensive monitoring and alerting framework for Ya OK, including:
- Infrastructure and application metrics
- Dashboard specifications
- Alerting rules and thresholds
- Service Level Indicators (SLIs) and Service Level Objectives (SLOs)
- Log aggregation and analysis
- Incident response procedures

### 1.2 Scope

**Components Monitored:**
- Mobile applications (Android/iOS)
- Rust core library (ya_ok_core)
- Relay server (Fly.io deployment)
- Backend services and APIs
- Infrastructure (compute, network, storage)

**Monitoring Dimensions:**
- **Performance**: Latency, throughput, resource utilization
- **Availability**: Uptime, error rates, health checks
- **Security**: Authentication failures, encryption errors, suspicious activity
- **Business**: User engagement, message volume, feature adoption

### 1.3 Standards and Frameworks

**Industry Standards:**
- **ITIL 4**: Service management best practices
- **ISO/IEC 20000**: Service management system requirements
- **Google SRE**: Site Reliability Engineering principles
- **The Four Golden Signals**: Latency, Traffic, Errors, Saturation

**Tools and Technologies:**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **Jaeger**: Distributed tracing
- **Alertmanager**: Alert routing and notification
- **Firebase Crashlytics**: Mobile crash reporting
- **Sentry**: Error tracking

---

## 2. Monitoring Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Monitoring Stack                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Android    │    │     iOS      │    │ Relay Server │      │
│  │     App      │    │     App      │    │   (Fly.io)   │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │                   │                    │               │
│         │ Crashlytics       │ Crashlytics        │ Metrics       │
│         │ Sentry            │ Sentry             │ (Prometheus)  │
│         └───────────────────┴────────────────────┘               │
│                              │                                    │
│         ┌────────────────────┴────────────────────┐              │
│         │                                          │              │
│    ┌────▼──────┐         ┌────────────┐     ┌────▼──────┐       │
│    │ Firebase  │         │   Sentry   │     │Prometheus │       │
│    │Crashlytics│         │   (Errors) │     │ (Metrics) │       │
│    └─────┬─────┘         └──────┬─────┘     └─────┬─────┘       │
│          │                      │                   │             │
│          └──────────────────────┼───────────────────┘             │
│                                 │                                 │
│                        ┌────────▼─────────┐                       │
│                        │     Grafana      │                       │
│                        │   (Dashboards)   │                       │
│                        └────────┬─────────┘                       │
│                                 │                                 │
│                        ┌────────▼─────────┐                       │
│                        │  Alertmanager    │                       │
│                        │   (Alerting)     │                       │
│                        └────────┬─────────┘                       │
│                                 │                                 │
│                        ┌────────▼─────────┐                       │
│                        │   Notifications  │                       │
│                        │ (PagerDuty/Slack)│                       │
│                        └──────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

**Metrics Pipeline:**
```
Mobile Apps → Firebase Analytics → Grafana Dashboard
Relay Server → Prometheus Exporter → Prometheus → Grafana
```

**Logs Pipeline:**
```
Mobile Apps → Crashlytics / Sentry
Relay Server → Loki → Grafana
```

**Alerts Pipeline:**
```
Prometheus → Alertmanager → PagerDuty / Slack / Email
```

### 2.3 Monitoring Layers

| Layer | Components | Tools | Metrics |
|-------|------------|-------|---------|
| **Application** | Mobile apps, Rust core | Firebase, Sentry | Crash rate, errors, performance |
| **Runtime** | Relay server | Prometheus | Request rate, latency, errors |
| **Infrastructure** | Fly.io VMs, network | Fly.io metrics | CPU, memory, disk, network |
| **Business** | User engagement | Custom analytics | DAU, message volume, retention |

---

## 3. Metrics Definition

### 3.1 The Four Golden Signals

**1. Latency**
- Time to process requests
- Message encryption/decryption time
- Network round-trip time

**2. Traffic**
- Requests per second
- Messages sent/received per minute
- Active connections

**3. Errors**
- Error rate (%)
- Failed requests
- Crash rate

**4. Saturation**
- CPU utilization
- Memory usage
- Network bandwidth
- Connection pool usage

### 3.2 Application Metrics

#### Mobile App Metrics (Firebase Analytics)

| Metric | Type | Description | Unit | Target |
|--------|------|-------------|------|--------|
| `app_crash_rate` | Gauge | Crash-free sessions | % | ≥99.5% |
| `app_startup_time` | Histogram | Time from launch to ready | ms | p95 <2000ms |
| `message_send_latency` | Histogram | Time to send message (BLE) | ms | p95 <300ms |
| `message_receive_latency` | Histogram | Time from send to notification | ms | p95 <500ms |
| `encryption_time` | Histogram | Message encryption duration | ms | p95 <10ms |
| `decryption_time` | Histogram | Message decryption duration | ms | p95 <10ms |
| `ble_discovery_time` | Histogram | Time to discover peer | ms | p95 <5000ms |
| `wifi_direct_setup_time` | Histogram | WiFi Direct group formation | ms | p95 <15000ms |
| `memory_usage` | Gauge | App memory consumption | MB | <200 MB |
| `battery_drain_rate` | Gauge | Battery consumption | %/hr | <2% (idle) |
| `database_query_time` | Histogram | SQLite query duration | ms | p95 <100ms |
| `active_users_daily` | Counter | Daily active users | count | Trend up |
| `messages_sent_daily` | Counter | Messages sent per day | count | Trend up |
| `file_transfer_success_rate` | Gauge | Successful file transfers | % | ≥95% |

#### Relay Server Metrics (Prometheus)

| Metric | Type | Description | Unit | Target |
|--------|------|-------------|------|--------|
| `relay_requests_total` | Counter | Total requests received | count | - |
| `relay_requests_success` | Counter | Successful requests | count | - |
| `relay_requests_failed` | Counter | Failed requests | count | - |
| `relay_request_duration_seconds` | Histogram | Request processing time | seconds | p95 <0.1s |
| `relay_active_connections` | Gauge | Current WebSocket connections | count | Monitor |
| `relay_message_queue_size` | Gauge | Queued messages | count | <1000 |
| `relay_message_ttl_violations` | Counter | Messages exceeding TTL | count | <1% |
| `relay_cpu_usage_percent` | Gauge | CPU utilization | % | <80% |
| `relay_memory_usage_bytes` | Gauge | Memory consumption | bytes | <200 MB |
| `relay_uptime_seconds` | Counter | Server uptime | seconds | - |
| `relay_registration_rate` | Gauge | Registrations per second | /s | Monitor |
| `relay_heartbeat_failures` | Counter | Missed heartbeats | count | Alert |
| `relay_error_rate` | Gauge | Error rate | % | <1% |

### 3.3 Infrastructure Metrics (Fly.io)

| Metric | Type | Description | Unit | Target |
|--------|------|-------------|------|--------|
| `fly_vm_cpu_percent` | Gauge | VM CPU usage | % | <80% |
| `fly_vm_memory_bytes` | Gauge | VM memory usage | bytes | <220 MB |
| `fly_vm_disk_usage_bytes` | Gauge | Disk space used | bytes | <80% capacity |
| `fly_network_rx_bytes` | Counter | Network bytes received | bytes | Monitor |
| `fly_network_tx_bytes` | Counter | Network bytes transmitted | bytes | Monitor |
| `fly_vm_restarts` | Counter | VM restart count | count | Alert |
| `fly_health_check_failures` | Counter | Failed health checks | count | Alert |

### 3.4 Security Metrics

| Metric | Type | Description | Unit | Target |
|--------|------|-------------|------|--------|
| `auth_failures_total` | Counter | Failed authentication attempts | count | Alert >100/min |
| `decryption_failures_total` | Counter | Failed message decryptions | count | Alert >10/min |
| `invalid_signatures_total` | Counter | Invalid message signatures | count | Alert >5/min |
| `rate_limit_exceeded` | Counter | Rate limit violations | count | Monitor |
| `suspicious_activity` | Counter | Security event triggers | count | Alert immediately |
| `keystore_access_denied` | Counter | Keystore access failures | count | Alert |
| `relay_ddos_attempts` | Counter | Suspected DDoS attacks | count | Alert |

### 3.5 Business Metrics

| Metric | Type | Description | Unit | Target |
|--------|------|-------------|------|--------|
| `daily_active_users` | Gauge | Users active in 24h | count | Growth target |
| `weekly_active_users` | Gauge | Users active in 7d | count | Growth target |
| `monthly_active_users` | Gauge | Users active in 30d | count | Growth target |
| `messages_per_user_daily` | Gauge | Avg messages per user | count | Engagement |
| `user_retention_day_1` | Gauge | % users active next day | % | ≥40% |
| `user_retention_day_7` | Gauge | % users active after 7 days | % | ≥25% |
| `user_retention_day_30` | Gauge | % users active after 30 days | % | ≥15% |
| `feature_adoption_relay` | Gauge | % users using relay | % | Monitor |
| `feature_adoption_biometric` | Gauge | % users using biometric auth | % | Monitor |
| `avg_contacts_per_user` | Gauge | Average contact count | count | Engagement |
| `file_transfers_daily` | Counter | File attachments sent | count | Monitor |

---

## 4. Dashboards

### 4.1 Dashboard Hierarchy

```
1. Executive Dashboard (high-level KPIs)
   ├── Service Health Overview
   ├── Business Metrics
   └── Cost Overview

2. Platform Health Dashboard
   ├── Android App Health
   ├── iOS App Health
   └── Relay Server Health

3. Performance Dashboard
   ├── Latency Metrics
   ├── Throughput Metrics
   └── Resource Utilization

4. Security Dashboard
   ├── Authentication Events
   ├── Encryption Status
   └── Threat Detection

5. Infrastructure Dashboard
   ├── Fly.io Resources
   ├── Network Performance
   └── Storage Capacity
```

### 4.2 Executive Dashboard

**Purpose:** High-level overview for stakeholders

**Panels:**

1. **Service Health**
   - Uptime (last 24h, 7d, 30d)
   - Error rate (%)
   - Active incidents

2. **Key Performance Indicators**
   - Daily active users (DAU)
   - Messages sent (24h)
   - Crash-free rate (%)
   - Average latency (p95)

3. **Business Metrics**
   - New user registrations (7d)
   - User retention (D1, D7, D30)
   - Feature adoption rates

4. **Alerts Summary**
   - Active alerts count
   - Recent incidents
   - MTTR (Mean Time To Recovery)

**Grafana Dashboard JSON:**

```json
{
  "dashboard": {
    "title": "Ya OK - Executive Dashboard",
    "tags": ["executive", "overview"],
    "timezone": "utc",
    "panels": [
      {
        "id": 1,
        "title": "Service Uptime (24h)",
        "type": "stat",
        "targets": [
          {
            "expr": "avg_over_time(up{job=\"yaok-relay\"}[24h]) * 100",
            "legendFormat": "Uptime %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 99, "color": "yellow"},
                {"value": 99.9, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Error Rate (24h)",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(relay_requests_failed[24h])) / sum(rate(relay_requests_total[24h])) * 100",
            "legendFormat": "Error Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 1, "color": "yellow"},
                {"value": 5, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 3,
        "title": "Daily Active Users",
        "type": "graph",
        "targets": [
          {
            "expr": "daily_active_users",
            "legendFormat": "DAU"
          }
        ]
      },
      {
        "id": 4,
        "title": "Messages Sent (24h)",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(increase(messages_sent_daily[24h]))",
            "legendFormat": "Messages"
          }
        ]
      }
    ]
  }
}
```

### 4.3 Platform Health Dashboard

**Android App Panel:**

```
┌─────────────────────────────────────────────────────────┐
│ Android App Health                                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Crash-Free Rate: 99.6% ✓     Startup Time: 1.8s ✓     │
│  Active Users: 1,234           Memory: 156 MB ✓          │
│                                                           │
│  [Crash Rate Graph - Last 7 Days]                       │
│  [Startup Time Distribution - P50, P95, P99]            │
│  [Memory Usage Over Time]                                │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**iOS App Panel:**

```
┌─────────────────────────────────────────────────────────┐
│ iOS App Health                                           │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Crash-Free Rate: 99.7% ✓     Startup Time: 1.6s ✓     │
│  Active Users: 987             Memory: 142 MB ✓          │
│                                                           │
│  [Crash Rate Graph - Last 7 Days]                       │
│  [Startup Time Distribution - P50, P95, P99]            │
│  [Memory Usage Over Time]                                │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**Relay Server Panel:**

```
┌─────────────────────────────────────────────────────────┐
│ Relay Server Health                                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Uptime: 99.95% ✓             Request Rate: 450/s ✓     │
│  Active Connections: 2,345    Latency (p95): 67ms ✓     │
│  Error Rate: 0.3% ✓           CPU: 45% ✓                │
│                                                           │
│  [Request Rate - All Regions]                            │
│  [Latency Distribution - P50, P95, P99]                 │
│  [Active Connections Over Time]                          │
│  [Error Rate by Type]                                    │
│                                                           │
│  Region Health:                                          │
│  Amsterdam (ams):  ✓ Healthy   2 instances              │
│  Virginia (iad):   ✓ Healthy   2 instances              │
│  Singapore (sin):  ✓ Healthy   2 instances              │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### 4.4 Performance Dashboard

**Latency Monitoring:**

```promql
# Message encryption latency (p95)
histogram_quantile(0.95, 
  rate(encryption_time_bucket[5m])
)

# Message send latency (p95)
histogram_quantile(0.95, 
  rate(message_send_latency_bucket[5m])
)

# Relay request latency (p95)
histogram_quantile(0.95, 
  rate(relay_request_duration_seconds_bucket[5m])
)
```

**Throughput Monitoring:**

```promql
# Messages per second
rate(messages_sent_daily[1m])

# Relay requests per second
rate(relay_requests_total[1m])

# BLE data throughput
rate(ble_bytes_transmitted[1m])
```

### 4.5 Security Dashboard

**Authentication Panel:**

```
┌─────────────────────────────────────────────────────────┐
│ Authentication & Security                                │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Auth Success Rate: 99.8% ✓                             │
│  Failed Logins (1h): 12                                  │
│  Locked Accounts: 2                                      │
│                                                           │
│  [Failed Authentication Attempts - Last 24h]            │
│  [Top Failed Login Sources (IP)]                         │
│  [Account Lockout Events]                                │
│                                                           │
│  Encryption Health:                                      │
│  Decryption Failures: 3 (last 24h) ✓                    │
│  Invalid Signatures: 0 (last 24h) ✓                     │
│                                                           │
│  [Decryption Failure Rate]                               │
│  [Signature Verification Status]                         │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Alerting Rules

### 5.1 Alert Severity Levels

| Severity | Description | Response Time | Notification |
|----------|-------------|---------------|--------------|
| **Critical (P0)** | Service down, data loss | Immediate | PagerDuty (on-call) |
| **High (P1)** | Degraded service, security issue | <15 minutes | PagerDuty + Slack |
| **Medium (P2)** | Performance degradation | <1 hour | Slack |
| **Low (P3)** | Minor issues, warnings | Next business day | Slack |

### 5.2 Critical Alerts (P0)

#### Alert: Service Down

```yaml
alert: ServiceDown
expr: up{job="yaok-relay"} == 0
for: 1m
labels:
  severity: critical
  component: relay-server
annotations:
  summary: "Relay server is down"
  description: "Relay server {{ $labels.instance }} has been down for more than 1 minute"
  runbook: "https://docs.yaok.app/runbooks/service-down"
```

#### Alert: High Error Rate

```yaml
alert: HighErrorRate
expr: |
  sum(rate(relay_requests_failed[5m])) / 
  sum(rate(relay_requests_total[5m])) > 0.05
for: 5m
labels:
  severity: critical
  component: relay-server
annotations:
  summary: "Error rate above 5%"
  description: "Error rate is {{ $value | humanizePercentage }}"
  runbook: "https://docs.yaok.app/runbooks/high-error-rate"
```

#### Alert: High Crash Rate

```yaml
alert: HighCrashRate
expr: app_crash_free_rate < 0.995
for: 10m
labels:
  severity: critical
  component: mobile-app
annotations:
  summary: "App crash rate above threshold"
  description: "Crash-free rate is {{ $value | humanizePercentage }}"
  runbook: "https://docs.yaok.app/runbooks/high-crash-rate"
```

### 5.3 High Alerts (P1)

#### Alert: High Latency

```yaml
alert: HighLatency
expr: |
  histogram_quantile(0.95,
    rate(relay_request_duration_seconds_bucket[5m])
  ) > 0.5
for: 10m
labels:
  severity: high
  component: relay-server
annotations:
  summary: "p95 latency above 500ms"
  description: "Current p95 latency: {{ $value }}s"
  runbook: "https://docs.yaok.app/runbooks/high-latency"
```

#### Alert: High CPU Usage

```yaml
alert: HighCPUUsage
expr: relay_cpu_usage_percent > 80
for: 15m
labels:
  severity: high
  component: relay-server
annotations:
  summary: "CPU usage above 80%"
  description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
  runbook: "https://docs.yaok.app/runbooks/high-cpu"
```

#### Alert: Authentication Failures

```yaml
alert: HighAuthFailureRate
expr: rate(auth_failures_total[5m]) > 100
for: 5m
labels:
  severity: high
  component: security
annotations:
  summary: "High authentication failure rate"
  description: "{{ $value }} failed auth attempts per second"
  runbook: "https://docs.yaok.app/runbooks/auth-failures"
```

### 5.4 Medium Alerts (P2)

#### Alert: Memory Usage Warning

```yaml
alert: HighMemoryUsage
expr: relay_memory_usage_bytes > 200000000
for: 30m
labels:
  severity: medium
  component: relay-server
annotations:
  summary: "Memory usage above 200MB"
  description: "Memory usage: {{ $value | humanize1024 }}"
  runbook: "https://docs.yaok.app/runbooks/high-memory"
```

#### Alert: Message Queue Backup

```yaml
alert: MessageQueueBackup
expr: relay_message_queue_size > 1000
for: 10m
labels:
  severity: medium
  component: relay-server
annotations:
  summary: "Message queue backing up"
  description: "{{ $value }} messages queued"
  runbook: "https://docs.yaok.app/runbooks/queue-backup"
```

### 5.5 Low Alerts (P3)

#### Alert: Disk Space Warning

```yaml
alert: DiskSpaceWarning
expr: fly_vm_disk_usage_bytes / fly_vm_disk_capacity_bytes > 0.7
for: 1h
labels:
  severity: low
  component: infrastructure
annotations:
  summary: "Disk usage above 70%"
  description: "Disk usage: {{ $value | humanizePercentage }}"
```

### 5.6 Alertmanager Configuration

**alertmanager.yml:**

```yaml
global:
  resolve_timeout: 5m
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    # Critical alerts -> PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true
    
    # High alerts -> PagerDuty + Slack
    - match:
        severity: high
      receiver: 'pagerduty-high'
      continue: true
    
    # Medium alerts -> Slack
    - match:
        severity: medium
      receiver: 'slack-medium'
    
    # Low alerts -> Slack
    - match:
        severity: low
      receiver: 'slack-low'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_P0_SERVICE_KEY'
        severity: 'critical'
        description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'
    slack_configs:
      - channel: '#incidents'
        color: 'danger'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'pagerduty-high'
    pagerduty_configs:
      - service_key: 'YOUR_P1_SERVICE_KEY'
        severity: 'error'
    slack_configs:
      - channel: '#alerts'
        color: 'warning'
        title: '⚠️ HIGH: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'slack-medium'
    slack_configs:
      - channel: '#alerts'
        color: 'warning'
        title: '⚡ MEDIUM: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'slack-low'
    slack_configs:
      - channel: '#monitoring'
        title: 'ℹ️ LOW: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

inhibit_rules:
  # Inhibit low/medium alerts if critical alert firing
  - source_match:
      severity: 'critical'
    target_match_re:
      severity: 'medium|low'
    equal: ['alertname', 'instance']
```

---

## 6. SLIs and SLOs

### 6.1 Service Level Indicators (SLIs)

**Definition:** SLIs are quantitative measures of service behavior

| SLI | Measurement | Data Source | Calculation |
|-----|-------------|-------------|-------------|
| **Availability** | % uptime | Prometheus | `avg_over_time(up[30d]) * 100` |
| **Latency** | p95 response time | Prometheus | `histogram_quantile(0.95, rate(duration_bucket[5m]))` |
| **Error Rate** | % failed requests | Prometheus | `sum(failed) / sum(total) * 100` |
| **Throughput** | Requests per second | Prometheus | `rate(requests_total[5m])` |

### 6.2 Service Level Objectives (SLOs)

**Definition:** SLOs are target values or ranges for SLIs

#### Relay Server SLOs

| Service | SLO | Measurement Window | Error Budget |
|---------|-----|-------------------|--------------|
| **Availability** | 99.9% uptime | 30 days | 43.2 minutes/month |
| **Latency** | p95 < 100ms | 7 days | 5% of requests may exceed |
| **Error Rate** | < 1% errors | 24 hours | 1% of requests may fail |
| **Data Durability** | 99.99% | 30 days | 0.01% data loss acceptable |

#### Mobile App SLOs

| Service | SLO | Measurement Window | Error Budget |
|---------|-----|-------------------|--------------|
| **Crash-Free Rate** | ≥ 99.5% | 7 days | 0.5% of sessions may crash |
| **Startup Time** | p95 < 2s | 24 hours | 5% may exceed 2s |
| **Message Send Latency** | p95 < 300ms | 24 hours | 5% may exceed 300ms |
| **Battery Drain** | < 2%/hour (idle) | 24 hours | Avg must be under 2% |

### 6.3 Error Budget Policy

**Error Budget:** Time/requests service can fail while still meeting SLO

**Example Calculation (Availability SLO: 99.9%):**
```
Monthly uptime: 30 days * 24 hours * 60 minutes = 43,200 minutes
Error budget: 43,200 * (1 - 0.999) = 43.2 minutes of downtime allowed

If downtime exceeds 43.2 minutes in a month → SLO violated
```

**Error Budget Policy:**

| Error Budget Remaining | Actions |
|------------------------|---------|
| **>50%** | • Feature development as usual<br>• Accept calculated risks |
| **25-50%** | • Slow down feature releases<br>• Increase code review rigor<br>• Additional testing |
| **10-25%** | • Freeze non-critical features<br>• Focus on reliability improvements<br>• Reduce deployment frequency |
| **<10%** | • Feature freeze (except critical fixes)<br>• All hands on reliability<br>• Root cause analysis required |
| **Exhausted (0%)** | • Complete feature freeze<br>• Emergency response mode<br>• Executive escalation |

### 6.4 SLO Monitoring Dashboard

**Grafana Panel:**

```json
{
  "title": "SLO Compliance - 30 Day Window",
  "panels": [
    {
      "title": "Availability SLO (99.9%)",
      "targets": [
        {
          "expr": "avg_over_time(up{job=\"yaok-relay\"}[30d]) * 100",
          "legendFormat": "Current"
        }
      ],
      "thresholds": [
        {"value": 99.9, "color": "green"},
        {"value": 99.5, "color": "yellow"},
        {"value": 0, "color": "red"}
      ]
    },
    {
      "title": "Error Budget Remaining",
      "targets": [
        {
          "expr": "(1 - (sum(increase(relay_downtime_seconds[30d])) / (30 * 24 * 3600))) / (1 - 0.999)",
          "legendFormat": "Budget %"
        }
      ]
    }
  ]
}
```

---

## 7. Log Management

### 7.1 Log Collection

**Mobile Apps:**
- **Crashlytics**: Crash reports, non-fatal errors
- **Sentry**: Error tracking with context
- **Custom logs**: App events, user actions (non-PII)

**Relay Server:**
- **Loki**: Centralized log aggregation
- **Structured logging**: JSON format with trace IDs

### 7.2 Log Levels

| Level | Usage | Examples | Retention |
|-------|-------|----------|-----------|
| **ERROR** | Errors requiring attention | Failed requests, exceptions | 90 days |
| **WARN** | Potential issues | High latency, retries | 30 days |
| **INFO** | Significant events | Server start, deployments | 30 days |
| **DEBUG** | Detailed diagnostics | Request details, state changes | 7 days (dev only) |
| **TRACE** | Very detailed | Function calls, variables | Off in production |

### 7.3 Structured Logging Format

**Relay Server Log Entry (JSON):**

```json
{
  "timestamp": "2026-02-06T10:15:30.123Z",
  "level": "INFO",
  "message": "Message forwarded successfully",
  "service": "yaok-relay",
  "version": "0.2.0",
  "region": "ams",
  "instance_id": "abc123",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "hashed_user_id",
  "duration_ms": 45,
  "event": "message_forward",
  "metadata": {
    "message_size": 1024,
    "transport": "relay",
    "destination_online": true
  }
}
```

### 7.4 Log Queries (Loki)

**Query Failed Requests:**
```logql
{job="yaok-relay"} 
  |= "ERROR" 
  | json 
  | event = "request_failed"
```

**Query Slow Requests (>500ms):**
```logql
{job="yaok-relay"} 
  | json 
  | duration_ms > 500
```

**Query by Trace ID:**
```logql
{job="yaok-relay"} 
  | json 
  | trace_id = "550e8400-e29b-41d4-a716-446655440000"
```

### 7.5 Log Retention Policy

| Log Type | Retention | Storage | Reason |
|----------|-----------|---------|--------|
| Error logs | 90 days | Hot storage | Debugging, compliance |
| Warning logs | 30 days | Hot storage | Troubleshooting |
| Info logs | 30 days | Warm storage | Audit trail |
| Debug logs | 7 days | Hot storage | Development only |
| Metrics | 13 months | Prometheus TSDB | Trend analysis |
| Crash reports | 90 days | Crashlytics | Bug fixing |

---

## 8. Distributed Tracing

### 8.1 Tracing Architecture

**Tracer:** Jaeger (OpenTelemetry compatible)

**Instrumentation Points:**
- Mobile app → Rust core (FFI calls)
- Rust core → Transport layer
- Transport → Relay server
- Relay server → Destination client

### 8.2 Trace Context Propagation

**W3C Trace Context Format:**
```
traceparent: 00-{trace_id}-{span_id}-{trace_flags}
tracestate: yaok=region:ams,version:0.2.0
```

**Example:**
```
traceparent: 00-550e8400e29b41d4a716446655440000-1234567890abcdef-01
```

### 8.3 Key Traces

#### Trace: Message Send (End-to-End)

```
┌─────────────┐
│ Android App │ [Span: message_send_start]
└──────┬──────┘
       │ 2ms
┌──────▼──────┐
│ Rust Core   │ [Span: encrypt_message]
└──────┬──────┘
       │ 5ms
┌──────▼──────┐
│ BLE/Relay   │ [Span: transport_send]
└──────┬──────┘
       │ 150ms (BLE) or 80ms (Relay)
┌──────▼──────┐
│Relay Server │ [Span: relay_forward]
└──────┬──────┘
       │ 50ms
┌──────▼──────┐
│Recipient App│ [Span: message_receive]
└─────────────┘

Total latency: ~207ms (BLE) or ~137ms (Relay)
```

### 8.4 Jaeger Configuration

**Jaeger Collector Endpoint:**
```
JAEGER_AGENT_HOST=jaeger-collector.yaok-monitoring.svc.cluster.local
JAEGER_AGENT_PORT=6831
JAEGER_SAMPLER_TYPE=probabilistic
JAEGER_SAMPLER_PARAM=0.01  # Sample 1% of traces
```

**Sampling Strategy:**
- **Production**: 1% sampling (reduce overhead)
- **Staging**: 10% sampling
- **Development**: 100% sampling

---

## 9. Incident Response

### 9.1 Incident Severity Definitions

| Severity | Impact | Response Time | Notification |
|----------|--------|---------------|--------------|
| **SEV-0** | Complete outage, data loss | Immediate | CEO, CTO, All engineering |
| **SEV-1** | Major degradation, security breach | <5 minutes | CTO, Engineering leads, On-call |
| **SEV-2** | Partial degradation, workaround exists | <30 minutes | Engineering team, On-call |
| **SEV-3** | Minor issue, no user impact | <4 hours | Assigned engineer |

### 9.2 Incident Response Process

**Phase 1: Detection (0-5 minutes)**
1. Alert fires → PagerDuty notification
2. On-call engineer acknowledges alert
3. Initial assessment (severity determination)

**Phase 2: Response (5-30 minutes)**
1. Incident commander assigned (SEV-0/1)
2. Create incident channel (#incident-YYYYMMDD-NNN)
3. Initial investigation
4. Status page update (if user-facing)

**Phase 3: Mitigation (30 minutes - 4 hours)**
1. Implement temporary fix (rollback, scaling, etc.)
2. Verify mitigation effective
3. Continue monitoring

**Phase 4: Resolution (4-24 hours)**
1. Implement permanent fix
2. Deploy fix to production
3. Verify resolution
4. Close incident

**Phase 5: Post-Incident Review (1-7 days)**
1. Write postmortem (blameless)
2. Identify root cause
3. Create action items
4. Share learnings

### 9.3 Incident Communication Template

**Initial Update (within 15 minutes):**
```
🚨 INCIDENT: [Title]

Severity: SEV-1
Started: 2026-02-06 10:15 UTC
Incident Commander: @jane.doe

Impact: 
- Relay server experiencing high latency
- ~30% of messages delayed by >1 minute

Status:
- Investigating root cause
- No data loss detected

Next Update: 10:30 UTC (15 minutes)
```

**Resolution Update:**
```
✅ RESOLVED: [Title]

Duration: 45 minutes (10:15-11:00 UTC)
Root Cause: Database connection pool exhausted

Resolution:
- Increased connection pool size
- Deployed hotfix v0.2.1
- Service fully recovered

Impact:
- ~1,500 messages delayed
- No data loss
- All messages delivered

Next Steps:
- Postmortem: 2026-02-07
- Implement connection pool monitoring
```

### 9.4 Runbook Links

| Incident Type | Runbook URL |
|---------------|-------------|
| Service Down | https://docs.yaok.app/runbooks/service-down |
| High Error Rate | https://docs.yaok.app/runbooks/high-error-rate |
| High Latency | https://docs.yaok.app/runbooks/high-latency |
| Database Issues | https://docs.yaok.app/runbooks/database-issues |
| Security Breach | https://docs.yaok.app/runbooks/security-breach |
| DDoS Attack | https://docs.yaok.app/runbooks/ddos-attack |

---

## 10. Monitoring Tools Configuration

### 10.1 Prometheus Setup

**Prometheus Configuration (prometheus.yml):**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'yaok-production'
    environment: 'production'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules
rule_files:
  - "alerts/*.yml"
  - "recording_rules/*.yml"

# Scrape configurations
scrape_configs:
  # Relay server metrics
  - job_name: 'yaok-relay'
    static_configs:
      - targets: ['relay-ams.yaok.app:9091']
        labels:
          region: 'ams'
      - targets: ['relay-iad.yaok.app:9091']
        labels:
          region: 'iad'
      - targets: ['relay-sin.yaok.app:9091']
        labels:
          region: 'sin'
    scrape_interval: 10s
    scrape_timeout: 5s

  # Fly.io VM metrics
  - job_name: 'fly-metrics'
    static_configs:
      - targets: ['fly-exporter:9090']

  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

**Recording Rules (recording_rules.yml):**

```yaml
groups:
  - name: yaok_relay_rules
    interval: 30s
    rules:
      # Success rate (1 minute window)
      - record: relay:request_success_rate:1m
        expr: |
          sum(rate(relay_requests_success[1m])) /
          sum(rate(relay_requests_total[1m]))
      
      # Error rate (1 minute window)
      - record: relay:request_error_rate:1m
        expr: |
          sum(rate(relay_requests_failed[1m])) /
          sum(rate(relay_requests_total[1m]))
      
      # p95 latency (5 minute window)
      - record: relay:request_latency_p95:5m
        expr: |
          histogram_quantile(0.95,
            sum(rate(relay_request_duration_seconds_bucket[5m])) by (le)
          )
      
      # Active connections by region
      - record: relay:active_connections:region
        expr: |
          sum(relay_active_connections) by (region)
```

### 10.2 Grafana Setup

**Data Sources:**

```yaml
# grafana-datasources.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      timeInterval: "15s"

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

  - name: Jaeger
    type: jaeger
    access: proxy
    url: http://jaeger-query:16686
    editable: false
```

**Dashboard Provisioning:**

```yaml
# grafana-dashboards.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
```

### 10.3 Firebase Crashlytics Setup

**Android Configuration:**

```kotlin
// app/src/main/kotlin/app/yaok/Application.kt

import com.google.firebase.crashlytics.FirebaseCrashlytics

class YaOkApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Crashlytics
        FirebaseCrashlytics.getInstance().apply {
            setCrashlyticsCollectionEnabled(!BuildConfig.DEBUG)
            
            // Set custom keys for debugging
            setCustomKey("rust_core_version", BuildConfig.RUST_CORE_VERSION)
            setCustomKey("build_type", BuildConfig.BUILD_TYPE)
        }
    }
    
    fun logNonFatal(throwable: Throwable) {
        FirebaseCrashlytics.getInstance().recordException(throwable)
    }
}
```

**iOS Configuration:**

```swift
// AppDelegate.swift

import FirebaseCrashlytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Set custom keys
        Crashlytics.crashlytics().setCustomValue(BuildConfig.rustCoreVersion, forKey: "rust_core_version")
        Crashlytics.crashlytics().setCustomValue(BuildConfig.buildType, forKey: "build_type")
        
        return true
    }
    
    func logNonFatal(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
```

### 10.4 Sentry Integration

**DSN Configuration:**

```bash
# Environment variables
SENTRY_DSN=https://public@sentry.io/project-id
SENTRY_ENVIRONMENT=production
SENTRY_RELEASE=yaok@0.2.0
SENTRY_TRACES_SAMPLE_RATE=0.1
```

**Rust Integration:**

```toml
# Cargo.toml
[dependencies]
sentry = { version = "0.32", features = ["anyhow", "debug-images"] }
```

```rust
// src/main.rs

use sentry;

fn main() {
    let _guard = sentry::init((
        std::env::var("SENTRY_DSN").unwrap(),
        sentry::ClientOptions {
            release: sentry::release_name!(),
            environment: Some(std::env::var("SENTRY_ENVIRONMENT").unwrap().into()),
            traces_sample_rate: 0.1,
            ..Default::default()
        },
    ));
    
    // Application code
}
```

---

## 11. Runbooks

### 11.1 Runbook Template

```markdown
# Runbook: [Incident Type]

## Metadata
- **Owner**: [Team/Person]
- **Severity**: [P0/P1/P2/P3]
- **Last Updated**: [Date]

## Symptoms
- Describe what users/operators experience
- List relevant metrics/alerts

## Impact
- User impact
- Business impact
- Affected components

## Diagnosis
### Step 1: Check [Component]
bash commands or queries

### Step 2: Verify [Condition]
bash commands or queries

## Mitigation
### Quick Fix (Temporary)
1. Steps to mitigate immediately
2. Expected time to mitigate

### Permanent Fix
1. Steps for long-term resolution
2. Testing required

## Rollback
- How to rollback if mitigation fails
- Rollback validation

## Prevention
- Monitoring improvements
- Code changes
- Process changes

## Related
- Similar incidents
- Related runbooks
```

### 11.2 Sample Runbook: Service Down

```markdown
# Runbook: Relay Server Down

## Metadata
- **Owner**: DevOps Team
- **Severity**: P0 (Critical)
- **Last Updated**: 2026-02-06

## Symptoms
- Alert: `ServiceDown` firing
- Relay server health check failing
- Mobile apps cannot connect via relay
- `up{job="yaok-relay"} == 0` in Prometheus

## Impact
- **User Impact**: Messages cannot be sent via relay (BLE/WiFi still work)
- **Business Impact**: 30-50% of messages may be delayed
- **Affected Components**: Relay server, message delivery

## Diagnosis

### Step 1: Check Fly.io Status
bash
flyctl status -a yaok-relay


Expected: VM instances running, health checks passing

### Step 2: Check Logs
bash
flyctl logs -a yaok-relay --lines 100


Look for:
- Panic/crash messages
- Out of memory errors
- Network errors

### Step 3: Check Health Endpoint
bash
curl -v https://relay.yaok.app/health


Expected: 200 OK, `{"status":"healthy"}`

### Step 4: Check Prometheus Metrics
promql
up{job="yaok-relay"}
relay_active_connections
relay_error_rate


## Mitigation

### Quick Fix: Restart Service
bash
flyctl machine restart <machine_id> -a yaok-relay


Expected time: 30-60 seconds

### If Restart Fails: Rollback
bash
flyctl releases -a yaok-relay
flyctl releases rollback v<previous_version> -a yaok-relay


Expected time: 2 minutes

### If Rollback Fails: Scale Up New Instances
bash
flyctl scale count 2 --region ams -a yaok-relay


Expected time: 5 minutes

## Verification
bash
# 1. Check health
curl https://relay.yaok.app/health

# 2. Check metrics
curl https://relay.yaok.app/metrics | grep relay_uptime

# 3. Send test message via mobile app


## Prevention
1. Add health check monitoring with faster interval
2. Implement auto-restart on failure
3. Add capacity planning alerts
4. Review recent deployments for issues

## Related
- Runbook: High Error Rate
- Runbook: High Latency
- Incident: 2026-01-15 Relay Outage
```

### 11.3 Sample Runbook: High Error Rate

```markdown
# Runbook: High Error Rate

## Metadata
- **Owner**: Backend Team
- **Severity**: P0 (Critical)
- **Last Updated**: 2026-02-06

## Symptoms
- Alert: `HighErrorRate` firing
- Error rate >5% for 5+ minutes
- Users reporting failed message sends
- Increased Sentry error reports

## Impact
- **User Impact**: Message delivery failures, poor UX
- **Business Impact**: User churn risk, negative reviews
- **Affected Components**: Relay server, message routing

## Diagnosis

### Step 1: Identify Error Types
bash
flyctl logs -a yaok-relay | grep ERROR | tail -50


Common error types:
- Connection errors
- Timeout errors
- Database errors
- Validation errors

### Step 2: Check Error Rate by Type
promql
sum by (error_type) (rate(relay_errors_total[5m]))


### Step 3: Check Downstream Dependencies
bash
# Check database connectivity
psql -h db.yaok.app -U yaok -c "SELECT 1;"

# Check network latency
ping -c 10 relay.yaok.app


## Mitigation

### If Database Connection Pool Exhausted:
bash
# Increase pool size
flyctl secrets set -a yaok-relay \
  MAX_DB_CONNECTIONS=100


### If Rate Limited:
bash
# Temporarily increase rate limits
flyctl secrets set -a yaok-relay \
  RATE_LIMIT_PER_IP=200


### If Memory Leak:
bash
# Restart service to clear memory
flyctl machine restart <machine_id> -a yaok-relay


## Verification
bash
# Check error rate decreased
watch -n 5 'curl -s https://relay.yaok.app/metrics | grep error_rate'


## Prevention
1. Add circuit breaker for downstream dependencies
2. Implement connection pool monitoring
3. Add load shedding for overload scenarios
4. Improve error handling and retry logic

## Related
- Runbook: High Latency
- Runbook: Database Connection Issues
```

---

## Appendix A: Metrics Glossary

| Metric | Definition | Formula |
|--------|------------|---------|
| **Uptime** | % time service is available | `(total_time - downtime) / total_time * 100` |
| **Error Rate** | % requests that fail | `failed_requests / total_requests * 100` |
| **Latency (p95)** | 95th percentile response time | `histogram_quantile(0.95, duration_bucket)` |
| **Throughput** | Requests processed per second | `rate(requests_total[1m])` |
| **MTBF** | Mean Time Between Failures | `total_uptime / failure_count` |
| **MTTR** | Mean Time To Recovery | `sum(recovery_time) / incident_count` |
| **Apdex** | Application Performance Index | `(satisfied + tolerating*0.5) / total` |
| **Crash-Free Rate** | % sessions without crashes | `(total_sessions - crashed_sessions) / total_sessions * 100` |

---

## Appendix B: Alert Priority Matrix

| Alert | Severity | Response Time | Action |
|-------|----------|---------------|--------|
| Service Down | P0 | Immediate | Restart/rollback |
| High Error Rate (>5%) | P0 | Immediate | Investigate, mitigate |
| High Crash Rate (>1%) | P0 | <5 minutes | Rollback app version |
| Security Breach | P0 | Immediate | Isolate, investigate |
| High Latency (>500ms) | P1 | <15 minutes | Scale up, optimize |
| High CPU (>80%) | P1 | <15 minutes | Scale up, investigate |
| Auth Failures Spike | P1 | <15 minutes | Check for attack |
| Memory Warning (>200MB) | P2 | <1 hour | Monitor, plan optimization |
| Disk Space (>70%) | P3 | Next business day | Clean up logs, expand |

---

## Appendix C: Monitoring Checklist

### Initial Setup
- [ ] Prometheus installed and configured
- [ ] Grafana installed with datasources
- [ ] Alertmanager configured
- [ ] PagerDuty integration tested
- [ ] Slack notifications working
- [ ] Firebase Crashlytics enabled
- [ ] Sentry configured for mobile apps
- [ ] Loki for log aggregation
- [ ] Jaeger for distributed tracing

### Dashboard Creation
- [ ] Executive dashboard created
- [ ] Platform health dashboard created
- [ ] Performance dashboard created
- [ ] Security dashboard created
- [ ] Infrastructure dashboard created

### Alerting Rules
- [ ] Critical alerts (P0) configured
- [ ] High alerts (P1) configured
- [ ] Medium alerts (P2) configured
- [ ] Low alerts (P3) configured
- [ ] Alert routing tested
- [ ] On-call rotation configured

### SLO Tracking
- [ ] SLIs defined and measured
- [ ] SLOs documented
- [ ] Error budget calculated
- [ ] SLO dashboard created
- [ ] Error budget policy implemented

### Runbooks
- [ ] Service Down runbook created
- [ ] High Error Rate runbook created
- [ ] High Latency runbook created
- [ ] Security Incident runbook created
- [ ] Runbooks accessible to on-call

### Post-Deployment
- [ ] Metrics flowing from relay server
- [ ] Mobile app metrics in Firebase
- [ ] Logs aggregated in Loki
- [ ] Dashboards populated with data
- [ ] Alerts tested and firing correctly
- [ ] On-call schedule populated
- [ ] Incident response process documented

---

**Document Classification:** INTERNAL  
**Distribution:** DevOps Team, SRE Team, Engineering Team  
**Review Cycle:** Quarterly or after major incidents

**End of Monitoring & Alerting Setup Document**
