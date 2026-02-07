# Incident Response Plan
## Ya OK - Security Incident Response & Management

**Document ID:** YA-OK-IRP-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** Draft  
**Classification:** CONFIDENTIAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | Security Team | Initial version - Complete IRP |

### Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Security Officer | [TBD] | | |
| CTO | [TBD] | | |
| Legal Counsel | [TBD] | | |

### Related Documents

- **YA-OK-SEC-001**: Security Threat Model
- **YA-OK-SEC-002**: Security Requirements Specification
- **YA-OK-OPS-001**: Operational Procedures
- **YA-OK-MON-001**: Monitoring & Alerting Setup

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Incident Response Framework](#2-incident-response-framework)
3. [Incident Classification](#3-incident-classification)
4. [Detection and Reporting](#4-detection-and-reporting)
5. [Incident Response Team](#5-incident-response-team)
6. [Response Procedures](#6-response-procedures)
7. [Communication Protocols](#7-communication-protocols)
8. [Evidence Collection & Forensics](#8-evidence-collection--forensics)
9. [Post-Incident Activities](#9-post-incident-activities)
10. [Incident Playbooks](#10-incident-playbooks)

---

## 1. Introduction

### 1.1 Purpose

This Incident Response Plan (IRP) defines procedures for detecting, responding to, and recovering from security incidents affecting Ya OK systems, per ISO/IEC 27035 (Information Security Incident Management) and NIST SP 800-61 (Computer Security Incident Handling Guide).

### 1.2 Scope

**Systems Covered:**
- Android and iOS mobile applications
- Rust core library (ya_ok_core)
- Relay server infrastructure (Fly.io)
- Supporting infrastructure (databases, monitoring, CI/CD)
- User data (encrypted messages, contacts, identity keys)

**Incidents Covered:**
- Unauthorized access or data breach
- Cryptographic compromise
- Denial of Service (DoS/DDoS)
- Malware or ransomware
- Data integrity compromise
- Privacy violations
- Insider threats
- Supply chain attacks

**Out of Scope:**
- Individual user device compromises (user responsibility)
- Third-party service incidents (Firebase, Sentry) - handled by vendors
- Non-security operational issues (see Operational Procedures)

### 1.3 Objectives

1. **Minimize Impact**: Contain incidents quickly to limit damage
2. **Preserve Evidence**: Maintain forensic integrity for investigation
3. **Restore Service**: Return to normal operations safely
4. **Learn & Improve**: Conduct post-incident analysis
5. **Comply**: Meet regulatory requirements (GDPR, CCPA)
6. **Communicate**: Keep stakeholders informed

### 1.4 Compliance & Standards

- **ISO/IEC 27035**: Information security incident management
- **NIST SP 800-61 Rev 2**: Computer security incident handling
- **GDPR Article 33**: Personal data breach notification (72 hours)
- **CCPA**: California Consumer Privacy Act notification requirements
- **PCI DSS** (if applicable): Payment card data breach procedures

---

## 2. Incident Response Framework

### 2.1 Incident Response Lifecycle

Based on NIST SP 800-61:

```
┌───────────────────────────────────────────────────┐
│         Incident Response Lifecycle               │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. PREPARATION                                   │
│     ↓                                             │
│  2. DETECTION & ANALYSIS                          │
│     ↓                                             │
│  3. CONTAINMENT, ERADICATION & RECOVERY           │
│     ↓                                             │
│  4. POST-INCIDENT ACTIVITY                        │
│     ↓                                             │
│  [Lessons Learned] → [Update Procedures] → 1     │
│                                                   │
└───────────────────────────────────────────────────┘
```

### 2.2 Phase Descriptions

**Phase 1: Preparation**
- Establish incident response capability
- Train team members
- Deploy monitoring and detection tools
- Document procedures

**Phase 2: Detection & Analysis**
- Identify potential incidents
- Analyze alerts and indicators
- Determine incident scope and severity
- Document initial findings

**Phase 3: Containment, Eradication & Recovery**
- **Containment**: Limit spread, preserve evidence
- **Eradication**: Remove threat, patch vulnerabilities
- **Recovery**: Restore systems, verify integrity

**Phase 4: Post-Incident Activity**
- Conduct lessons learned meeting
- Update procedures and controls
- Prepare final incident report
- Legal/regulatory notifications (if required)

---

## 3. Incident Classification

### 3.1 Severity Levels

| Level | Name | Impact | Response Time | Escalation |
|-------|------|--------|---------------|------------|
| **SEV-0** | Critical | Complete service outage, active data breach | Immediate | CEO, Legal |
| **SEV-1** | High | Major service degradation, potential breach | <15 minutes | CTO, Security |
| **SEV-2** | Medium | Partial service impact, security vulnerability | <1 hour | Security Lead |
| **SEV-3** | Low | Minor impact, no immediate threat | <24 hours | On-call engineer |

### 3.2 Incident Categories

| Category | Examples | Initial Severity |
|----------|----------|------------------|
| **Data Breach** | Unauthorized access to user data, database leak | SEV-0 |
| **Crypto Compromise** | Private key exposure, encryption failure | SEV-0 |
| **DoS/DDoS** | Service unavailable due to attack | SEV-1 |
| **Malware** | Ransomware, trojan in infrastructure | SEV-1 |
| **Account Takeover** | Unauthorized relay server access | SEV-1 |
| **Vulnerability** | Critical CVE in dependencies | SEV-2 |
| **Data Integrity** | Database corruption, message tampering | SEV-1 |
| **Privacy Violation** | GDPR violation, unauthorized data collection | SEV-1 |
| **Insider Threat** | Malicious employee action | SEV-1 |
| **Supply Chain** | Compromised dependency, build system | SEV-2 |

### 3.3 Impact Assessment

**Business Impact:**
- **Critical**: Revenue loss > $100k, legal liability, brand damage
- **High**: Revenue loss $10k-$100k, significant user impact
- **Medium**: Revenue loss $1k-$10k, partial user impact
- **Low**: Minimal financial impact, isolated users

**Data Impact:**
- **Critical**: Plaintext user messages exposed, private keys leaked
- **High**: Encrypted data exposed, contact lists leaked
- **Medium**: Metadata exposed (user IDs, timestamps)
- **Low**: Public information only

**Service Impact:**
- **Critical**: All services down >4 hours
- **High**: Major service down >1 hour
- **Medium**: Minor service degraded <4 hours
- **Low**: No service impact

---

## 4. Detection and Reporting

### 4.1 Detection Methods

**Automated Detection:**

| Tool | Monitors | Alerts |
|------|----------|--------|
| **Prometheus** | Service health, error rates, anomalies | High error rate, service down |
| **Sentry** | Application errors, crashes | Critical errors, crash spikes |
| **Firebase Crashlytics** | Mobile app crashes | High crash rate |
| **Grafana** | Metrics dashboards, trends | Dashboard annotations |
| **Loki** | Log aggregation, patterns | Error log spikes |
| **GitHub Dependabot** | Dependency vulnerabilities | CVE alerts |
| **Fail2ban** (future) | Brute force attempts | IP bans |

**Manual Detection:**
- User reports (support email, in-app)
- Security researcher reports (security@yaok.app)
- Penetration testing findings
- Code review findings
- Threat intelligence feeds

### 4.2 Incident Reporting

**Internal Reporting:**

**Primary Channel:** #yaok-security-incidents (Slack)

**Report Template:**

```markdown
**SECURITY INCIDENT REPORT**

**Reported By:** [Name]
**Date/Time:** [ISO 8601 timestamp]
**Severity:** [SEV-0/1/2/3 - initial estimate]

**Summary:**
[Brief description of the incident]

**Systems Affected:**
- [ ] Android app
- [ ] iOS app
- [ ] Relay server (region: ___)
- [ ] Database
- [ ] Other: ___

**Indicators:**
- [Alert name / log entry / user report]
- [Supporting evidence]

**Initial Actions Taken:**
- [Any immediate containment steps]

**Next Steps:**
- [ ] Assign Incident Commander
- [ ] Begin investigation
- [ ] Initiate response procedures
```

**External Reporting:**

**Security Researchers:**
- Email: security@yaok.app
- PGP key: [Published on website]
- Response SLA: <24 hours acknowledgment

**Bug Bounty Program** (future):
- HackerOne platform
- Rewards: $100-$10,000 based on severity
- Scope: Mobile apps, relay server, API

### 4.3 Escalation Triggers

**Immediate Escalation (SEV-0/1):**
- Active data breach in progress
- Cryptographic keys compromised
- Complete service outage (all regions)
- Ransomware detected
- Mass user account takeover

**Standard Escalation (SEV-2/3):**
- Security vulnerability identified
- Suspicious activity detected
- Failed authentication spikes
- Performance degradation

---

## 5. Incident Response Team

### 5.1 Team Structure

**Core Team:**

| Role | Responsibilities | Contact |
|------|------------------|---------|
| **Incident Commander (IC)** | Overall coordination, decisions, communications | On-call rotation |
| **Security Lead** | Investigation, forensics, remediation | security@yaok.app |
| **Platform Engineer** | Infrastructure, access control, restoration | platform@yaok.app |
| **Developer** | Code analysis, patching, hotfixes | dev@yaok.app |
| **Communications Lead** | User/stakeholder notifications, PR | comms@yaok.app |
| **Legal Counsel** | Regulatory compliance, legal implications | legal@yaok.app |

**Extended Team (as needed):**
- External forensics consultant
- Law enforcement liaison
- Insurance provider
- Third-party security firm

### 5.2 Incident Commander (IC) Duties

**During Incident:**
1. Assess severity and assign team members
2. Coordinate response activities
3. Make containment/recovery decisions
4. Authorize emergency changes
5. Manage communications (internal/external)
6. Document timeline and actions
7. Declare incident resolved

**Post-Incident:**
1. Conduct lessons learned meeting
2. Prepare final incident report
3. Update response procedures
4. Close incident ticket

### 5.3 On-Call Rotation

**Primary On-Call:**
- 24/7 coverage (1-week rotation)
- Response time: <15 minutes (SEV-0/1)
- PagerDuty integration

**Backup On-Call:**
- Escalation if primary unavailable
- Response time: <30 minutes

**Current Rotation:**
[Maintained in PagerDuty: https://yaok.pagerduty.com]

---

## 6. Response Procedures

### 6.1 Initial Response (First 15 Minutes)

**Step 1: Acknowledge (0-5 minutes)**

```bash
# Acknowledge alert in PagerDuty
# Post to #yaok-security-incidents

**INCIDENT DECLARED: SEV-[X]**
IC: [Your Name]
Time: [HH:MM UTC]
Summary: [One line description]
Status: INVESTIGATING
```

**Step 2: Assess (5-10 minutes)**

- Review alerts and logs
- Identify affected systems
- Estimate severity and impact
- Check if ongoing or past incident

**Step 3: Contain (10-15 minutes)**

**Immediate Containment Actions:**

| Incident Type | Containment Action |
|---------------|-------------------|
| **Data Breach** | Revoke access tokens, disable affected accounts |
| **DoS/DDoS** | Enable rate limiting, block attacking IPs |
| **Malware** | Isolate infected systems, kill processes |
| **Account Takeover** | Reset passwords, revoke sessions |
| **Vulnerability** | Deploy workaround, disable vulnerable feature |

### 6.2 Investigation Phase

**Evidence Collection:**

```bash
# Collect system logs (preserve timestamps)
fly logs --app yaok-relay-ams > incident-logs-$(date +%Y%m%d-%H%M%S).log

# Export database for forensics (if suspected compromise)
fly ssh console --app yaok-relay-ams -C "sqlite3 /data/yaok_relay.db .dump" > db-dump-forensics.sql

# Capture network traffic (if available)
tcpdump -i eth0 -w incident-capture.pcap

# List active connections
netstat -anp > active-connections.txt

# Check file integrity
find /opt/yaok -type f -exec sha256sum {} \; > file-hashes.txt
```

**Timeline Documentation:**

```markdown
## Incident Timeline

| Time (UTC) | Event | Source | Action Taken |
|------------|-------|--------|--------------|
| 10:23:45 | High error rate alert triggered | Prometheus | Alert acknowledged |
| 10:25:12 | Logs show authentication failures | Loki | Began investigation |
| 10:27:33 | Identified brute force attack | Log analysis | Blocked source IPs |
| 10:30:00 | Attack ceased | Monitoring | Continued monitoring |
```

### 6.3 Containment Strategies

**Short-Term Containment:**
- **Goal**: Stop the bleeding, minimize immediate damage
- **Time**: Minutes to hours
- **Examples**:
  - Block attacking IP addresses
  - Disable compromised accounts
  - Isolate affected systems
  - Enable additional logging

**Long-Term Containment:**
- **Goal**: Maintain operations while preparing for eradication
- **Time**: Hours to days
- **Examples**:
  - Apply temporary patches
  - Implement compensating controls
  - Increase monitoring
  - Segment network (if applicable)

### 6.4 Eradication

**Remove Threat:**

```bash
# Malware removal
systemctl stop yaok-relay
rm -rf /opt/yaok/suspicious-files
clamav --scan /opt/yaok/

# Patch vulnerability
cd ya_ok_core
cargo update <vulnerable_crate>
cargo build --release

# Rotate compromised credentials
fly secrets unset OLD_SECRET --app yaok-relay-ams
fly secrets set NEW_SECRET=$(openssl rand -base64 32) --app yaok-relay-ams

# Revoke exposed API keys
# Update all clients with new keys
```

**Verify Eradication:**

- Re-scan for malware
- Verify vulnerability patched
- Check logs for attack indicators
- Monitor for recurrence (24-48 hours)

### 6.5 Recovery

**Restore Service:**

```bash
# Verify system integrity
sha256sum -c file-hashes.txt

# Restore from clean backup (if needed)
aws s3 cp s3://yaok-backups/relay/clean-backup.tar.gz /tmp/
tar -xzf /tmp/clean-backup.tar.gz -C /data/

# Restart services
fly apps restart yaok-relay-ams

# Verify functionality
curl https://relay-ams.yaok.app/health
```

**Validation Checklist:**

- [ ] All services operational
- [ ] No attack indicators in logs
- [ ] Metrics return to baseline
- [ ] User functionality restored
- [ ] Vulnerability patched and verified
- [ ] Security controls enhanced
- [ ] Monitoring confirms normal behavior

---

## 7. Communication Protocols

### 7.1 Internal Communications

**Slack Channels:**
- **#yaok-security-incidents**: Incident coordination (restricted)
- **#yaok-incidents**: General incident updates
- **#yaok-engineering**: Technical team updates

**Status Updates:**

**Frequency:**
- SEV-0: Every 30 minutes
- SEV-1: Every 1 hour
- SEV-2: Every 4 hours
- SEV-3: Daily

**Template:**

```markdown
**INCIDENT UPDATE: [Incident ID]**

**Status:** [INVESTIGATING / CONTAINED / RESOLVED]
**Severity:** SEV-[X]
**Time Elapsed:** [HH:MM]

**Current Situation:**
[Brief summary of current state]

**Actions Taken:**
- [Action 1]
- [Action 2]

**Next Steps:**
- [Next action 1]
- [Next action 2]

**ETA to Resolution:** [Best estimate]
**Next Update:** [Time]

IC: [Name]
```

### 7.2 User Communications

**Status Page:** https://status.yaok.app

**Update Template:**

```markdown
**Service Disruption Notice**

**Summary:** We are currently investigating an issue affecting [service/region].

**Impact:** [Description of user impact]

**Status:** [Investigating / Identified / Monitoring / Resolved]

**Workaround:** [If available]

**Updates:** We will provide updates every [timeframe].

**Updated:** [ISO 8601 timestamp]
```

**In-App Notification:**

```kotlin
// Critical incidents only (SEV-0)
showInAppBanner(
    message = "Ya OK is experiencing issues. We're working on a fix.",
    severity = NotificationSeverity.WARNING,
    actionText = "Status Page",
    actionUrl = "https://status.yaok.app"
)
```

### 7.3 Regulatory Notifications

**GDPR Personal Data Breach (Article 33):**

**Timeline:** Notify supervisory authority within 72 hours of becoming aware

**Required Information:**
- Nature of the breach
- Categories and number of data subjects affected
- Likely consequences
- Measures taken or proposed
- Contact point for more information

**Notification Method:** https://edpb.europa.eu/

**Template:** (See Appendix B)

**CCPA Breach Notification:**

**Timeline:** Without unreasonable delay

**Threshold:** >500 California residents affected

**Method:** Written notice, email, or substitute notice

### 7.4 Media Relations

**Designated Spokesperson:** Communications Lead or CEO only

**Guidelines:**
- Never speculate or provide unconfirmed information
- Focus on facts: what happened, what we're doing
- Emphasize user protection and transparency
- Coordinate with legal counsel

**Prepared Statements:**

```
"We are aware of [incident type] affecting [system]. Our security team is 
investigating. User safety is our priority. We will provide updates as we 
learn more. [Contact information]"
```

---

## 8. Evidence Collection & Forensics

### 8.1 Evidence Handling

**Chain of Custody:**

| Field | Description |
|-------|-------------|
| **Evidence ID** | Unique identifier (INC-YYYYMMDD-XXX) |
| **Description** | Type and content |
| **Collected By** | Name and role |
| **Date/Time** | ISO 8601 timestamp |
| **Location** | System/path where found |
| **Hash** | SHA-256 checksum |
| **Storage** | Secure location |
| **Access Log** | Who accessed, when, why |

**Evidence Types:**
- System logs (application, security, access)
- Database dumps
- Network packet captures
- Memory dumps
- File system snapshots
- Configuration files
- User reports and screenshots

### 8.2 Forensic Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| **Volatility** | Memory analysis | Malware detection, process analysis |
| **Wireshark** | Network traffic analysis | Protocol analysis, packet inspection |
| **Sleuth Kit** | File system analysis | Deleted file recovery, timeline |
| **strings** | Extract text | Find URLs, IPs, credentials in binaries |
| **binwalk** | Binary analysis | Firmware analysis, embedded files |
| **YARA** | Pattern matching | Malware signatures |

### 8.3 Forensic Procedures

**Preserve Evidence:**

```bash
#!/bin/bash
# Forensic data collection script

INCIDENT_ID="INC-20260206-001"
EVIDENCE_DIR="/forensics/${INCIDENT_ID}"
mkdir -p ${EVIDENCE_DIR}

# System information
uname -a > ${EVIDENCE_DIR}/system-info.txt
date -u > ${EVIDENCE_DIR}/collection-time.txt

# Process list
ps auxww > ${EVIDENCE_DIR}/processes.txt

# Network connections
netstat -anp > ${EVIDENCE_DIR}/network-connections.txt
ss -tunapl > ${EVIDENCE_DIR}/sockets.txt

# File system
find / -type f -mtime -1 > ${EVIDENCE_DIR}/recent-files.txt

# Logs
cp -r /var/log ${EVIDENCE_DIR}/logs/

# Database snapshot
sqlite3 /data/yaok_relay.db .dump > ${EVIDENCE_DIR}/database-dump.sql

# Hash all evidence
find ${EVIDENCE_DIR} -type f -exec sha256sum {} \; > ${EVIDENCE_DIR}/evidence-hashes.txt

# Compress and encrypt
tar -czf ${EVIDENCE_DIR}.tar.gz ${EVIDENCE_DIR}
gpg --encrypt --recipient forensics@yaok.app ${EVIDENCE_DIR}.tar.gz

# Upload to secure storage
aws s3 cp ${EVIDENCE_DIR}.tar.gz.gpg s3://yaok-forensics/${INCIDENT_ID}/ \
    --storage-class GLACIER

echo "Evidence collected: ${INCIDENT_ID}"
```

**Analysis:**

```bash
# Analyze logs for attack patterns
grep -i "authentication failure" ${EVIDENCE_DIR}/logs/auth.log | wc -l

# Find suspicious IPs
awk '{print $1}' ${EVIDENCE_DIR}/logs/access.log | sort | uniq -c | sort -rn | head -20

# Timeline analysis
log2timeline.py --storage-file ${INCIDENT_ID}.plaso ${EVIDENCE_DIR}
psort.py ${INCIDENT_ID}.plaso "date > '2026-02-06 10:00:00' and date < '2026-02-06 12:00:00'"

# Memory analysis (if dump available)
volatility -f memory.dump --profile=LinuxUbuntu22x64 pslist
volatility -f memory.dump --profile=LinuxUbuntu22x64 netscan
```

---

## 9. Post-Incident Activities

### 9.1 Lessons Learned Meeting

**Timing:** Within 7 days of incident resolution

**Attendees:**
- Incident Commander
- Incident Response Team
- Engineering leads
- Management (for SEV-0/1)

**Agenda:**
1. Incident timeline review
2. What went well?
3. What could be improved?
4. Root cause analysis
5. Action items (assign owners, due dates)

**Template:**

```markdown
# Incident Postmortem: [Incident ID]

**Date:** [Date]
**Facilitator:** [Name]
**Attendees:** [List]

## Incident Summary
- **Severity:** SEV-X
- **Duration:** [Start] to [End] ([HH:MM] total)
- **Impact:** [Users affected, data compromised, revenue loss]
- **Root Cause:** [Technical root cause]

## Timeline
[Detailed timeline from detection to resolution]

## What Went Well
- [Positive aspect 1]
- [Positive aspect 2]

## What Went Wrong
- [Problem 1]
- [Problem 2]

## Action Items
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| [Action 1] | [Name] | [Date] | High |
| [Action 2] | [Name] | [Date] | Medium |

## Prevention
[How to prevent similar incidents in future]

## Detection
[How to detect earlier next time]
```

### 9.2 Final Incident Report

**Audience:** Management, Legal, Regulators (if required)

**Sections:**
1. Executive Summary
2. Incident Details (timeline, systems affected)
3. Impact Assessment (users, data, financial)
4. Root Cause Analysis (5 Whys, Fishbone)
5. Response Actions (containment, eradication, recovery)
6. Evidence Summary (forensic findings)
7. Lessons Learned
8. Recommendations (short-term, long-term)
9. Appendices (logs, evidence, communications)

**Template:** (See Appendix C)

### 9.3 Follow-Up Actions

**Immediate (0-7 days):**
- [ ] Complete forensic analysis
- [ ] Patch vulnerabilities
- [ ] Reset compromised credentials
- [ ] Update detection rules
- [ ] Notify affected users (if required)

**Short-Term (7-30 days):**
- [ ] Implement quick wins from lessons learned
- [ ] Enhance monitoring and alerting
- [ ] Update incident response procedures
- [ ] Conduct security training
- [ ] Review access controls

**Long-Term (30-90 days):**
- [ ] Implement architectural changes
- [ ] Deploy new security controls
- [ ] Conduct tabletop exercise
- [ ] Update threat model
- [ ] Third-party security audit

---

## 10. Incident Playbooks

### 10.1 Playbook: Data Breach

**Scenario:** Unauthorized access to user data detected

**Detection Indicators:**
- Unusual database queries in logs
- Large data exports
- Unauthorized API access
- User reports of compromised accounts

**Response:**

**Step 1: Verify (0-5 min)**

```bash
# Check access logs
fly logs --app yaok-relay-ams | grep -E "database|export|unauthorized"

# Check for unusual queries
sqlite3 /data/yaok_relay.db "SELECT * FROM sqlite_stat1;"

# Identify source IP
grep "unauthorized" /var/log/yaok-relay/access.log | awk '{print $1}' | sort | uniq -c
```

**Step 2: Contain (5-15 min)**

```bash
# Block suspicious IPs
fly ips block <attacker_ip> --app yaok-relay-ams

# Rotate database credentials
fly secrets set DATABASE_PASSWORD=$(openssl rand -base64 32) --app yaok-relay-ams

# Enable enhanced logging
fly secrets set RUST_LOG="debug" --app yaok-relay-ams

# Restart with new credentials
fly apps restart yaok-relay-ams
```

**Step 3: Assess (15-60 min)**

- Determine data accessed (query logs, forensics)
- Identify affected users
- Estimate exposure window
- Classify data sensitivity (plaintext vs. encrypted)

**Step 4: Notify (60 min - 72 hours)**

- Internal: Management, legal, PR
- Regulatory: GDPR (72 hours), CCPA (without delay)
- Users: Affected users only (email notification)

**Step 5: Remediate**

- Patch vulnerability that enabled breach
- Implement additional access controls
- Enhance monitoring for similar activity
- Conduct security audit

**Step 6: Post-Incident**

- Lessons learned meeting
- Update threat model
- Security training for team
- Consider third-party audit

### 10.2 Playbook: DDoS Attack

**Scenario:** Relay server overwhelmed with traffic

**Detection Indicators:**
- Service degradation or unavailability
- High CPU/bandwidth usage
- Prometheus alert: `relay_requests_total` spike
- User reports: "Can't connect to relay"

**Response:**

**Step 1: Confirm (0-5 min)**

```bash
# Check request rate
fly metrics --app yaok-relay-ams

# Identify source IPs
fly logs --app yaok-relay-ams | grep -E "connection|request" | awk '{print $5}' | sort | uniq -c | sort -rn | head -20

# Check attack pattern
# - Single source: Simple DDoS
# - Many sources: Distributed DDoS
# - Valid requests: Application-layer attack
```

**Step 2: Mitigate (5-30 min)**

**Option A: Rate Limiting (Application-Layer)**

```rust
// Update rate limiter (code change + deploy)
const MAX_REQUESTS_PER_IP: u32 = 100;  // Reduce from 1000
const RATE_LIMIT_WINDOW: Duration = Duration::from_secs(60);
```

**Option B: IP Blocking (Network-Layer)**

```bash
# Block attacking IPs
for IP in $(cat attacking-ips.txt); do
    fly ips block ${IP} --app yaok-relay-ams
done

# Or use Cloudflare (if enabled)
# Cloudflare auto-mitigates DDoS attacks
```

**Option C: Enable DDoS Protection (Fly.io)**

```bash
# Contact Fly.io support for DDoS mitigation
# They can enable upstream filtering

# Or migrate to Cloudflare (emergency)
# Update DNS to Cloudflare nameservers
```

**Step 3: Scale (if legitimate traffic)**

```bash
# If traffic spike is legitimate (viral event, etc.)
fly scale count 5 --app yaok-relay-ams  # Increase instances
fly scale vm dedicated-cpu-1x --app yaok-relay-ams  # Increase resources
```

**Step 4: Monitor**

- Watch metrics for attack cessation
- Monitor error rates and latency
- Check if other regions affected

**Step 5: Post-Attack**

- Analyze attack vectors
- Implement permanent rate limiting
- Consider CDN (Cloudflare) for future protection
- Update DDoS response procedures

### 10.3 Playbook: Ransomware

**Scenario:** Ransomware detected on infrastructure

**Detection Indicators:**
- Files encrypted with unknown extensions
- Ransom note (README.txt, DECRYPT.html)
- High disk I/O (encryption in progress)
- Suspicious processes

**Response:**

**Step 1: Isolate (IMMEDIATE)**

```bash
# STOP - Do NOT restart or shut down cleanly
# Isolation is priority to prevent spread

# Disconnect network (if possible)
ip link set eth0 down

# Or scale to 0 (Fly.io)
fly scale count 0 --app yaok-relay-ams

# Notify team - DO NOT attempt decryption yet
```

**Step 2: Preserve Evidence**

```bash
# Snapshot VM (Fly.io)
fly volumes snapshot create vol_yaok_relay_ams_data --tag "ransomware-incident"

# Memory dump (if possible before isolation)
# This preserves encryption keys in RAM
```

**Step 3: Assess**

- Identify ransomware variant (ransom note, file extensions)
- Check backups (are they encrypted?)
- Determine infection vector (vulnerability, phishing, etc.)
- Estimate data loss

**Step 4: Do NOT Pay Ransom**

- Policy: Ya OK does not pay ransoms
- No guarantee of decryption
- Funds criminal activity
- Encourages future attacks

**Step 5: Restore from Backup**

```bash
# Verify backup integrity (test restore on isolated system)
aws s3 cp s3://yaok-backups/relay/ams/20260205.tar.gz /tmp/

# Verify NOT encrypted
tar -tzf /tmp/20260205.tar.gz

# Build new infrastructure (clean deploy)
fly apps create yaok-relay-ams-new
fly deploy --app yaok-relay-ams-new

# Restore data
# ... (see Backup & Restore procedures)

# Migrate DNS
# Update to new infrastructure
```

**Step 6: Forensics**

- Engage external forensics firm (if major incident)
- Identify initial infection vector
- Determine ransomware family
- Check for data exfiltration (double extortion)

**Step 7: Harden**

- Patch vulnerability that enabled infection
- Implement application whitelisting
- Enhanced endpoint protection (antivirus, EDR)
- Backup verification automation
- Offline backup copies

### 10.4 Playbook: Cryptographic Key Compromise

**Scenario:** Private cryptographic keys exposed

**Detection Indicators:**
- Keys found in public repository
- Keys logged in plaintext
- Insider with access leaves company
- Third-party breach notification

**Response:**

**Step 1: Assess Scope (0-15 min)**

**Key Type Identification:**

| Key Type | Impact | Urgency |
|----------|--------|---------|
| **User Identity Keys** | Individual user compromise | High |
| **Relay Server Keys** | Server impersonation | Critical |
| **Code Signing Keys** | App tampering | Critical |
| **API Keys** | Unauthorized access | High |

**Step 2: Revoke (15-30 min)**

**User Identity Keys:**

```sql
-- Mark user as compromised (server-side)
UPDATE users SET key_compromised = 1, force_rekey = 1 WHERE user_id = '<user_id>';

-- Notify user in-app
-- "Your encryption keys may be compromised. Please regenerate."
```

**Relay Server Keys:**

```bash
# Generate new server keypair
openssl ecparam -genkey -name prime256v1 -out new-server-key.pem

# Deploy new keys
fly secrets set SERVER_PRIVATE_KEY=$(cat new-server-key.pem | base64) --app yaok-relay-ams

# Restart
fly apps restart yaok-relay-ams

# All clients will get new server public key on next connect
```

**Code Signing Keys:**

```bash
# Revoke compromised certificate (Apple/Google)
# Generate new keystore (Android)
keytool -genkey -v -keystore new-upload-key.jks ...

# Re-sign all published apps (emergency update)
# Submit expedited review to app stores
```

**Step 3: Notify (30 min - 24 hours)**

**Internal:**
- Security team
- Engineering team
- Management

**External:**
- Affected users (email notification)
- App store review teams (expedited review request)
- Security researchers (if responsible disclosure)

**Step 4: Key Rotation**

```bash
# Automate key rotation for future
# Implement key rotation schedule (90 days)

# User keys: App prompts user to regenerate
# Server keys: Automated rotation script
# Code signing: Annual renewal reminder
```

**Step 5: Post-Incident**

- Root cause: How were keys exposed?
- Prevention: Key management improvements
  * Never log private keys
  * Use hardware security modules (HSM)
  * Implement secrets management (Vault)
  * Code review for key handling
- Detection: Monitor for key exposure
  * GitHub secret scanning
  * Log monitoring for key patterns

### 10.5 Playbook: Insider Threat

**Scenario:** Malicious or negligent employee action

**Detection Indicators:**
- Unusual data access patterns
- Off-hours access
- Large data downloads
- Access after termination
- Privileged action abuse

**Response:**

**Step 1: Document (IMMEDIATELY)**

- DO NOT confront suspect (avoid tipping off)
- Preserve all evidence
- Engage legal counsel
- Consider law enforcement (if criminal)

**Step 2: Contain Access (0-30 min)**

```bash
# Disable account
fly auth revoke <user_email>

# Revoke SSH keys
fly ssh keys delete <key_id>

# Revoke GitHub access
# GitHub → Settings → People → Remove member

# Rotate secrets they had access to
fly secrets unset ALL_SECRETS --app yaok-relay-ams
# Reset all secrets from secure vault
```

**Step 3: Investigate**

```bash
# Audit logs for user's actions
fly logs --app yaok-relay-ams | grep "user=<email>"

# Check data access
sqlite3 /data/yaok_relay.db "SELECT * FROM audit_log WHERE user_id = '<user_id>';"

# Review code changes (GitHub)
git log --author="<email>" --since="2026-01-01"

# Check for data exfiltration
grep -r "<user_email>" /var/log/aws-s3-access.log
```

**Step 4: Legal/HR**

- Document findings
- Engage HR for termination procedures
- Consider legal action (if theft, sabotage)
- Law enforcement (if criminal activity)

**Step 5: Remediation**

- Change all credentials user had access to
- Review and tighten access controls
- Implement privileged access management (PAM)
- Enhanced audit logging
- Background checks for new hires

---

## Appendix A: Contact Information

### Emergency Contacts

| Role | Name | Email | Phone | PagerDuty |
|------|------|-------|-------|-----------|
| **Security Officer** | [TBD] | security@yaok.app | [Phone] | [PD ID] |
| **Incident Commander** | [Rotation] | oncall@yaok.app | | [PD Schedule] |
| **CTO** | [TBD] | cto@yaok.app | [Phone] | |
| **Legal Counsel** | [TBD] | legal@yaok.app | [Phone] | |
| **PR/Communications** | [TBD] | pr@yaok.app | [Phone] | |

### External Contacts

| Organization | Contact | Purpose |
|--------------|---------|---------|
| **Fly.io Support** | support@fly.io | Infrastructure emergencies |
| **FBI (Cyber)** | [Local office] | Criminal investigations |
| **Data Protection Authority** | [DPA contact] | GDPR breach notifications |
| **Forensics Firm** | [Firm name] | External forensic analysis |
| **Cyber Insurance** | [Insurer] | Incident coverage |

---

## Appendix B: GDPR Breach Notification Template

```
Subject: Personal Data Breach Notification per GDPR Article 33

To: [Data Protection Authority]
From: Ya OK Data Protection Officer
Date: [Date]

1. NATURE OF THE BREACH
Description: [Detailed description of incident]
Date/Time Discovered: [ISO 8601 timestamp]
Estimated Start: [When breach began]
Categories of Personal Data: [Encrypted messages, contact lists, user IDs, etc.]

2. DATA SUBJECTS AFFECTED
Number of Data Subjects: [Approximate number]
Geographic Location: [Countries]
Categories: [Ya OK users]

3. LIKELY CONSEQUENCES
[Assessment of impact on data subjects]
- [Consequence 1]
- [Consequence 2]

4. MEASURES TAKEN
Immediate Actions: [Containment, eradication steps]
Mitigation: [Steps to minimize harm to data subjects]
Prevention: [Measures to prevent recurrence]

5. CONTACT POINT
Name: [Data Protection Officer]
Email: dpo@yaok.app
Phone: [Phone number]

6. ADDITIONAL INFORMATION
[Any other relevant information]

Signature: [Name]
Position: Data Protection Officer
Date: [Date]
```

---

## Appendix C: Incident Report Template

```markdown
# Security Incident Report

**Incident ID:** INC-YYYYMMDD-XXX
**Classification:** [CONFIDENTIAL / RESTRICTED]
**Date:** [Date]
**Author:** [Incident Commander]

---

## Executive Summary

[2-3 paragraph summary of incident, impact, and resolution]

---

## Incident Details

**Severity:** SEV-[X]
**Category:** [Data Breach / DoS / Malware / etc.]
**Detection Time:** [ISO 8601 timestamp]
**Resolution Time:** [ISO 8601 timestamp]
**Total Duration:** [HH:MM:SS]

**Systems Affected:**
- [System 1]
- [System 2]

**Data Affected:**
- [Data category 1]: [# records]
- [Data category 2]: [# records]

---

## Timeline

| Time (UTC) | Event | Actor | Action Taken |
|------------|-------|-------|--------------|
| [Time] | [Event description] | [Person/System] | [Response] |
| ... | ... | ... | ... |

---

## Root Cause Analysis

**Immediate Cause:**
[What directly caused the incident]

**Root Cause (5 Whys):**
1. Why did incident occur? [Answer]
2. Why [answer 1]? [Answer]
3. Why [answer 2]? [Answer]
4. Why [answer 3]? [Answer]
5. Why [answer 4]? [Root cause]

**Contributing Factors:**
- [Factor 1]
- [Factor 2]

---

## Impact Assessment

**Users Affected:** [Number and percentage]
**Service Downtime:** [Duration]
**Financial Impact:** [Estimated cost]
**Reputational Impact:** [Assessment]
**Data Compromise:** [Yes/No, details]

---

## Response Actions

**Containment:**
- [Action 1]
- [Action 2]

**Eradication:**
- [Action 1]
- [Action 2]

**Recovery:**
- [Action 1]
- [Action 2]

---

## Lessons Learned

**What Went Well:**
- [Item 1]
- [Item 2]

**What Went Wrong:**
- [Item 1]
- [Item 2]

**Action Items:**

| ID | Action | Owner | Due Date | Status |
|----|--------|-------|----------|--------|
| 1 | [Action] | [Name] | [Date] | [Open/Closed] |
| 2 | [Action] | [Name] | [Date] | [Open/Closed] |

---

## Recommendations

**Immediate (0-7 days):**
- [Recommendation 1]
- [Recommendation 2]

**Short-Term (7-30 days):**
- [Recommendation 1]
- [Recommendation 2]

**Long-Term (30+ days):**
- [Recommendation 1]
- [Recommendation 2]

---

## Appendices

A. Detailed Timeline
B. Log Excerpts
C. Forensic Analysis
D. Communications Sent
E. Evidence Inventory

---

**Report Classification:** CONFIDENTIAL
**Distribution:** [List of recipients]
**Retention:** [Retention period per policy]
```

---

**Document Classification:** CONFIDENTIAL  
**Distribution:** Incident Response Team, Management, Legal  
**Review Cycle:** Annually or after major incidents

**End of Incident Response Plan**
