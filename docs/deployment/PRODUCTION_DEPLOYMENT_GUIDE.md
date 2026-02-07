# Production Deployment Guide
## Ya OK - Comprehensive Deployment Procedures

**Document ID:** YA-OK-DEPLOY-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** Draft  
**Classification:** INTERNAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | DevOps Team | Initial version - Complete deployment guide |

### Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| DevOps Lead | [TBD] | | |
| Security Lead | [TBD] | | |
| Release Manager | [TBD] | | |

### Related Documents

- **YA-OK-ARCH-001**: C4 Architecture Diagrams
- **YA-OK-TEST-001**: Formal Test Cases
- **YA-OK-SEC-001**: Security Threat Model
- **YA-OK-MON-001**: Monitoring & Alerting Setup

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Pre-Deployment Checklist](#2-pre-deployment-checklist)
3. [Android App Deployment](#3-android-app-deployment)
4. [iOS App Deployment](#4-ios-app-deployment)
5. [Relay Server Deployment](#5-relay-server-deployment)
6. [Configuration Management](#6-configuration-management)
7. [Environment Setup](#7-environment-setup)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Post-Deployment Validation](#9-post-deployment-validation)
10. [Rollback Procedures](#10-rollback-procedures)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Introduction

### 1.1 Purpose

This guide provides comprehensive, step-by-step procedures for deploying the Ya OK messaging system to production environments. It covers:
- Android app deployment to Google Play Store
- iOS app deployment to Apple App Store
- Relay server deployment to Fly.io
- Configuration management across all platforms
- Validation and rollback procedures

### 1.2 Scope

**In Scope:**
- Production deployment procedures
- Staging environment deployment (for pre-production testing)
- Configuration management
- Validation checks
- Rollback procedures
- Emergency hotfix deployment

**Out of Scope:**
- Development environment setup (see README.md)
- Infrastructure provisioning (see separate IaC documentation)
- Post-deployment monitoring (see Monitoring & Alerting Setup)

### 1.3 Audience

- **DevOps Engineers**: Execute deployment procedures
- **Release Managers**: Coordinate releases, approve deployments
- **QA Team**: Perform post-deployment validation
- **On-Call Engineers**: Handle rollbacks and incidents

### 1.4 Deployment Model

**Deployment Strategy:** Blue-Green Deployment (Relay Server), Store Review Process (Mobile Apps)

| Component | Deployment Method | Frequency | Downtime |
|-----------|-------------------|-----------|----------|
| **Android App** | Google Play Store (Staged Rollout) | Bi-weekly | N/A (users update) |
| **iOS App** | Apple App Store | Bi-weekly | N/A (users update) |
| **Relay Server** | Fly.io Blue-Green | On-demand | Zero downtime |

---

## 2. Pre-Deployment Checklist

### 2.1 General Prerequisites

**Before ANY deployment, verify:**

- [ ] All P0/P1 test cases passed (see YA-OK-TEST-001)
- [ ] Code review completed and approved (2+ reviewers)
- [ ] Security scan clean (no critical/high vulnerabilities)
- [ ] Performance benchmarks met (see NFR-PERF-*)
- [ ] Release notes prepared and reviewed
- [ ] Database migrations tested (if applicable)
- [ ] Rollback plan documented
- [ ] On-call engineer identified and briefed
- [ ] Stakeholders notified (release announcement)
- [ ] Change request approved (ITIL Change Management)

### 2.2 Android Deployment Prerequisites

- [ ] Android build successful (Release variant)
- [ ] APK/AAB signed with production keystore
- [ ] ProGuard/R8 optimization applied
- [ ] Google Play Console access verified
- [ ] Store listing updated (screenshots, description)
- [ ] Version code incremented
- [ ] Version name updated (follows SemVer)
- [ ] Closed beta testing completed (100+ users, 7 days)
- [ ] Staged rollout plan defined (1% → 10% → 50% → 100%)

### 2.3 iOS Deployment Prerequisites

- [ ] iOS build successful (Release configuration)
- [ ] IPA signed with distribution certificate
- [ ] Bitcode enabled (optional but recommended)
- [ ] App Store Connect access verified
- [ ] Store listing updated (screenshots, description)
- [ ] Build number incremented
- [ ] Version number updated (follows SemVer)
- [ ] TestFlight beta testing completed (100+ users, 7 days)
- [ ] App Store review guidelines compliance verified

### 2.4 Relay Server Prerequisites

- [ ] Relay server build successful (Docker image)
- [ ] Image tagged with version (e.g., `yaok-relay:v0.2.0`)
- [ ] Image pushed to container registry
- [ ] Fly.io access verified (flyctl authenticated)
- [ ] Environment variables configured
- [ ] Database migration scripts prepared (if applicable)
- [ ] Health check endpoint working
- [ ] Load testing completed (1000 concurrent users)
- [ ] Blue-Green deployment slots available

---

## 3. Android App Deployment

### 3.1 Build Android Release

**Prerequisites:**
- JDK 17 installed
- Android SDK configured
- Keystore file accessible (`keystore.jks`)
- `keystore.properties` configured

**Build Steps:**

```bash
# 1. Navigate to Android project
cd android/

# 2. Clean previous builds
./gradlew clean

# 3. Update version in build.gradle
# Edit: android/app/build.gradle
# versionCode: 10 (increment by 1)
# versionName: "0.2.0" (SemVer)

# 4. Build release AAB (Android App Bundle)
./gradlew bundleRelease

# 5. Verify build output
ls -lh app/build/outputs/bundle/release/
# Expected: app-release.aab (~15-20 MB)

# 6. Optional: Build APK for direct testing
./gradlew assembleRelease
ls -lh app/build/outputs/apk/release/
# Expected: app-release.apk (~20-25 MB)
```

**Build Configuration:**

```groovy
// android/app/build.gradle

android {
    compileSdk 34
    
    defaultConfig {
        applicationId "app.yaok.android"
        minSdk 24
        targetSdk 34
        versionCode 10        // INCREMENT THIS
        versionName "0.2.0"   // UPDATE THIS (SemVer)
        
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
        }
    }
    
    signingConfigs {
        release {
            if (project.hasProperty('keystoreFile')) {
                storeFile file(keystoreFile)
                storePassword keystorePassword
                keyAlias keystoreAlias
                keyPassword keystoreKeyPassword
            }
        }
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}
```

### 3.2 Verify Build Integrity

**Run Pre-Upload Checks:**

```bash
# 1. Verify APK signature
jarsigner -verify -verbose -certs app/build/outputs/apk/release/app-release.apk
# Expected: "jar verified."

# 2. Check ProGuard mapping (for crash deobfuscation)
ls -lh app/build/outputs/mapping/release/
# Expected: mapping.txt, seeds.txt, usage.txt

# 3. Analyze APK size
./gradlew assembleRelease --scan
# Review build scan for size breakdown

# 4. Run lint checks
./gradlew lintRelease
cat app/build/reports/lint-results-release.html
# Verify: No critical issues

# 5. Test APK on physical device
adb install -r app/build/outputs/apk/release/app-release.apk
# Launch app, perform smoke test:
# - App launches without crash
# - Identity generation works
# - Send/receive test message (BLE)
# - No obvious UI issues
```

### 3.3 Upload to Google Play Console

**Steps:**

1. **Login to Google Play Console**
   - Navigate to: https://play.google.com/console
   - Select app: "Ya OK - Private Messaging"

2. **Create New Release**
   - Navigate: `Production` → `Create new release`
   - Release name: `0.2.0 (10)`
   - Release type: `Managed publishing`

3. **Upload AAB**
   - Click `Upload` → Select `app-release.aab`
   - Wait for upload and processing (2-5 minutes)
   - Review processing status: Should show "Ready"

4. **Add Release Notes**
   ```
   Version 0.2.0 - February 2026
   
   New Features:
   - WiFi Direct support for faster file transfers
   - Improved battery optimization
   - Enhanced security with biometric authentication
   
   Improvements:
   - 40% faster message encryption
   - Reduced app size by 15%
   - Better BLE connection stability
   
   Bug Fixes:
   - Fixed crash on Android 14 devices
   - Resolved notification issues
   - Improved relay fallback reliability
   
   Security Updates:
   - Updated cryptographic libraries
   - Enhanced key storage protection
   ```

5. **Configure Rollout**
   - Rollout type: `Staged rollout`
   - Initial percentage: `1%` (first 1% of users)
   - Rollout schedule:
     - Day 1: 1% (monitor for crashes)
     - Day 2: 10% (if stable)
     - Day 4: 50% (if no issues)
     - Day 7: 100% (full release)

6. **Review and Publish**
   - Click `Review release`
   - Verify all details correct
   - Click `Start rollout to Production`

### 3.4 Monitor Rollout

**Monitoring Dashboard:**

```bash
# Access Google Play Console → Statistics

# Key Metrics to Monitor:
1. Crash Rate: Should be <0.5%
2. ANR Rate: Should be <0.1%
3. User Ratings: Should maintain >4.5 stars
4. Uninstall Rate: Should be <3%
5. Error Reports: Check for new error clusters
```

**Rollout Decision Matrix:**

| Metric | Threshold | Action if Exceeded |
|--------|-----------|-------------------|
| Crash Rate | >1% | Pause rollout, investigate |
| ANR Rate | >0.3% | Pause rollout, investigate |
| 1-star reviews | >10% increase | Review feedback, consider pause |
| Critical bug reports | >50 reports | Pause rollout, hotfix |

**Pause Rollout:**

```bash
# In Google Play Console:
1. Navigate to Production → Manage release
2. Click "Pause rollout"
3. Investigate issues (check Firebase Crashlytics)
4. Prepare hotfix if needed
5. Resume rollout only after fix verified
```

---

## 4. iOS App Deployment

### 4.1 Build iOS Release

**Prerequisites:**
- Xcode 15+ installed
- Apple Developer account access
- Distribution certificate installed
- Provisioning profile configured

**Build Steps:**

```bash
# 1. Navigate to iOS project
cd ios/

# 2. Clean build folder
rm -rf build/
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner

# 3. Update version
# Open Runner.xcodeproj in Xcode
# Select Runner target → General
# Version: 0.2.0 (SemVer)
# Build: 10 (increment by 1)

# Or use command line:
agvtool new-marketing-version 0.2.0
agvtool new-version -all 10

# 4. Archive for distribution
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  -destination generic/platform=iOS \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=TEAMID123 \
  PROVISIONING_PROFILE_SPECIFIER="Ya OK Distribution"

# 5. Export IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist

# 6. Verify IPA created
ls -lh build/Runner.ipa
# Expected: Runner.ipa (~30-40 MB)
```

**ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>TEAMID123</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>app.yaok.ios</key>
        <string>Ya OK Distribution</string>
    </dict>
</dict>
</plist>
```

### 4.2 Verify Build Integrity

**Run Pre-Upload Checks:**

```bash
# 1. Verify code signature
codesign -vvv --deep --strict build/Runner.ipa
# Expected: "satisfies its Designated Requirement"

# 2. Extract and inspect IPA
unzip build/Runner.ipa -d build/Runner-extracted/
plutil -p build/Runner-extracted/Payload/Runner.app/Info.plist
# Verify CFBundleShortVersionString: 0.2.0
# Verify CFBundleVersion: 10

# 3. Check IPA size
du -h build/Runner.ipa
# Should be <50 MB (Apple size limit: 150 MB over-the-air)

# 4. Validate IPA structure
xcrun altool --validate-app -f build/Runner.ipa \
  --type ios \
  --username your-apple-id@example.com \
  --password @keychain:AC_PASSWORD
# Expected: "No errors validating archive"

# 5. Test IPA on device (via TestFlight internal testing)
# Upload to TestFlight, install on device, perform smoke test
```

### 4.3 Upload to App Store Connect

**Using Xcode:**

1. **Open Xcode Organizer**
   - Xcode → Window → Organizer
   - Select archive created in step 4.1
   - Click `Distribute App`

2. **Distribution Method**
   - Select `App Store Connect`
   - Click `Next`

3. **Distribution Options**
   - Upload: ✓
   - App Thinning: All compatible device variants
   - Include bitcode: ✗ (deprecated)
   - Manage Version and Build Number: Manual
   - Click `Next`

4. **Re-sign**
   - Automatically manage signing: ✓
   - Click `Next`

5. **Review and Upload**
   - Review IPA content and signing
   - Click `Upload`
   - Wait for upload (5-10 minutes)

**Using Command Line (Transporter):**

```bash
# 1. Install Transporter (if not installed)
# Available on Mac App Store

# 2. Upload IPA
xcrun altool --upload-app \
  -f build/Runner.ipa \
  --type ios \
  --username your-apple-id@example.com \
  --password @keychain:AC_PASSWORD

# 3. Monitor upload progress
# Expected: "Package successfully uploaded"
```

### 4.4 Submit for App Store Review

**Steps:**

1. **Login to App Store Connect**
   - Navigate to: https://appstoreconnect.apple.com
   - Select app: "Ya OK - Private Messaging"

2. **Prepare Submission**
   - Navigate: `App Store` → `iOS App` → `+` (Add Version)
   - Version: `0.2.0`
   - Platform: `iOS`

3. **Select Build**
   - Build: Select uploaded build `10`
   - Wait for build processing (15-30 minutes)
   - Status should change to "Ready to Submit"

4. **Update App Information**
   ```
   What's New in This Version:
   
   • WiFi Direct Support - Transfer files up to 10x faster between nearby devices
   • Biometric Authentication - Unlock app with Face ID or Touch ID
   • Battery Optimization - Up to 30% longer battery life with improved background processing
   • Enhanced Security - Updated encryption libraries and stronger key protection
   • UI Improvements - Smoother animations and better accessibility support
   • Bug Fixes - Resolved notification issues and improved connection stability
   
   Ya OK is a private, decentralized messaging app that works without servers. Your messages stay between you and your contacts - always encrypted, always private.
   ```

5. **Review Guidelines Compliance**
   - [ ] App Privacy details updated
   - [ ] Screenshots current (6.7", 6.5", 5.5" displays)
   - [ ] App Preview video (optional, recommended)
   - [ ] Age rating appropriate (12+)
   - [ ] Export compliance: Yes (uses encryption)
   - [ ] Content rights: Own all rights
   - [ ] Advertising identifier: No

6. **Submit for Review**
   - Click `Add for Review`
   - Click `Submit to App Review`
   - Expected review time: 24-48 hours

### 4.5 Monitor App Review Status

**Check Status:**

```bash
# App Store Connect → My Apps → Ya OK → Activity

# Possible Statuses:
1. "Waiting for Review" - In queue (12-48 hours)
2. "In Review" - Being reviewed (2-24 hours)
3. "Pending Developer Release" - Approved, waiting for manual release
4. "Ready for Sale" - Live in App Store
5. "Rejected" - Review failed, requires fixes
```

**Common Rejection Reasons & Fixes:**

| Rejection Reason | Guideline | Fix |
|------------------|-----------|-----|
| Incomplete app information | 2.1 | Add all required metadata, screenshots |
| Permissions not justified | 5.1.5 | Add clear purpose strings (Info.plist) |
| Crashes on launch | 2.1 | Fix crash, resubmit with new build |
| Privacy policy missing | 5.1.1 | Add privacy policy URL |
| Export compliance | 3.3.2 | Provide encryption registration number |

**If Rejected:**

1. Read rejection email carefully
2. Fix all issues mentioned
3. Increment build number (e.g., 10 → 11)
4. Upload new build
5. Reply to App Review explaining fixes
6. Resubmit for review

**If Approved:**

1. Release method: `Automatic release` or `Manual release`
2. If manual: Click `Release this Version` in App Store Connect
3. App goes live within 24 hours
4. Monitor crash reports and user reviews

---

## 5. Relay Server Deployment

### 5.1 Build Relay Server Docker Image

**Prerequisites:**
- Docker installed and running
- Fly.io account created
- `flyctl` CLI installed and authenticated

**Build Steps:**

```bash
# 1. Navigate to relay directory
cd relay/

# 2. Review Dockerfile
cat Dockerfile

# Expected contents:
# FROM rust:1.75-slim as builder
# WORKDIR /app
# COPY Cargo.toml Cargo.lock ./
# COPY src ./src
# RUN cargo build --release
#
# FROM debian:bookworm-slim
# RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
# COPY --from=builder /app/target/release/ya-ok-relay /usr/local/bin/
# EXPOSE 41641/udp
# EXPOSE 8080/tcp
# CMD ["ya-ok-relay"]

# 3. Build Docker image
docker build -t yaok-relay:v0.2.0 .

# Build time: ~3-5 minutes
# Expected output: Successfully built <image_id>

# 4. Verify image
docker images | grep yaok-relay
# Expected: yaok-relay  v0.2.0  <image_id>  <size: ~50-80 MB>

# 5. Test image locally
docker run -d \
  --name yaok-relay-test \
  -p 41641:41641/udp \
  -p 8080:8080/tcp \
  -e RUST_LOG=info \
  yaok-relay:v0.2.0

# 6. Check container running
docker ps | grep yaok-relay-test

# 7. Test health endpoint
curl http://localhost:8080/health
# Expected: {"status":"healthy","version":"0.2.0"}

# 8. Stop test container
docker stop yaok-relay-test
docker rm yaok-relay-test
```

### 5.2 Configure Fly.io Deployment

**fly.toml Configuration:**

```toml
# relay/fly.toml

app = "yaok-relay"
primary_region = "ams"  # Amsterdam

[build]
  dockerfile = "Dockerfile"

[env]
  RUST_LOG = "info"
  MAX_CLIENTS = "10000"
  MESSAGE_TTL_DAYS = "7"
  HEARTBEAT_INTERVAL_SECS = "60"

[[services]]
  protocol = "udp"
  internal_port = 41641

  [[services.ports]]
    port = 41641

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [services.concurrency]
    type = "connections"
    hard_limit = 1000
    soft_limit = 800

  [[services.tcp_checks]]
    interval = "15s"
    timeout = "10s"
    grace_period = "30s"
    restart_limit = 0

  [[services.http_checks]]
    interval = "10s"
    timeout = "5s"
    grace_period = "20s"
    method = "GET"
    path = "/health"
    protocol = "http"

[metrics]
  port = 9091
  path = "/metrics"

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

### 5.3 Deploy to Fly.io (Blue-Green)

**Deployment Steps:**

```bash
# 1. Authenticate with Fly.io
flyctl auth login
# Opens browser, login with GitHub/email

# 2. Verify app exists (first-time setup)
flyctl apps list | grep yaok-relay
# If not exists: flyctl apps create yaok-relay

# 3. Set secrets (environment variables)
flyctl secrets set -a yaok-relay \
  RELAY_SECRET_KEY="$(openssl rand -hex 32)" \
  DATABASE_URL="sqlite:///data/relay.db"

# Secrets are encrypted and stored securely

# 4. Deploy new version (Blue-Green strategy)
flyctl deploy --app yaok-relay --strategy bluegreen

# Deployment process:
# - Builds Docker image (or uses cached layers)
# - Pushes image to Fly.io registry
# - Creates new VM instances (Green)
# - Runs health checks on Green instances
# - If healthy: Routes traffic to Green
# - If healthy: Destroys old Blue instances
# - If unhealthy: Keeps Blue running, destroys Green

# Expected output:
# ==> Building image
# [+] Building 45.2s (13/13) FINISHED
# ==> Pushing image to registry
# ==> Creating release
# ==> Deploying machines
# ==> Monitoring deployment
#     ✓ Machine started successfully
#     ✓ Health checks passing
# ==> Deployment successful!

# 5. Verify deployment
flyctl status -a yaok-relay

# Expected output:
# App
#   Name     = yaok-relay
#   Owner    = personal
#   Hostname = yaok-relay.fly.dev
#   Platform = machines
#   Regions  = ams (Amsterdam)
#
# Machines
# PROCESS ID              VERSION REGION  STATE   CHECKS  CREATED
# app     1234567890abcd  v10     ams     started 3 total 30s ago

# 6. Check health
curl https://yaok-relay.fly.dev/health
# Expected: {"status":"healthy","version":"0.2.0"}

# 7. Check metrics
curl https://yaok-relay.fly.dev/metrics
# Expected: Prometheus metrics
```

### 5.4 Multi-Region Deployment

**Deploy to Multiple Regions:**

```bash
# Ya OK relay deployed in 3 regions for redundancy

# 1. Scale to Amsterdam (primary)
flyctl scale count 2 --region ams -a yaok-relay

# 2. Add Virginia region
flyctl scale count 2 --region iad -a yaok-relay

# 3. Add Singapore region
flyctl scale count 2 --region sin -a yaok-relay

# 4. Verify all regions
flyctl status -a yaok-relay

# Expected output:
# Machines
# PROCESS ID      VERSION REGION  STATE   CHECKS
# app     abc123  v10     ams     started 3 total
# app     def456  v10     ams     started 3 total
# app     ghi789  v10     iad     started 3 total
# app     jkl012  v10     iad     started 3 total
# app     mno345  v10     sin     started 3 total
# app     pqr678  v10     sin     started 3 total

# Total: 6 instances (2 per region)
```

**Regional Routing:**

Fly.io automatically routes users to nearest region based on geographic proximity.

- **Europe**: → Amsterdam (ams)
- **North America**: → Virginia (iad)
- **Asia/Pacific**: → Singapore (sin)

### 5.5 Monitor Relay Deployment

**Real-Time Monitoring:**

```bash
# 1. View logs
flyctl logs -a yaok-relay

# 2. View metrics
flyctl dashboard metrics -a yaok-relay
# Opens Grafana dashboard in browser

# 3. Check instance health
flyctl checks list -a yaok-relay

# Expected output:
# Health Checks for yaok-relay
#   NAME    STATUS  REGION  LAST CHECK
#   http    passing ams     3s ago
#   tcp     passing ams     5s ago
#   http    passing iad     2s ago
#   tcp     passing iad     4s ago
```

**Key Metrics:**

| Metric | Description | Threshold | Alert |
|--------|-------------|-----------|-------|
| CPU Usage | % CPU utilization | <80% | Alert if >90% |
| Memory Usage | MB memory used | <200 MB | Alert if >220 MB |
| Request Rate | Requests/second | - | Monitor trends |
| Error Rate | Errors/second | <1% | Alert if >5% |
| Response Time | p95 latency | <200ms | Alert if >500ms |
| Active Connections | WebSocket connections | <10,000 | Alert if >9,000 |

---

## 6. Configuration Management

### 6.1 Environment Variables

**Android (android/local.properties):**

```properties
# DO NOT COMMIT TO GIT

sdk.dir=/Users/username/Library/Android/sdk
relay.url=https://relay.yaok.app:41641
relay.enabled=true
sentry.dsn=https://xxx@sentry.io/yyy
```

**iOS (ios/Runner/Config.plist):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>RelayURL</key>
    <string>https://relay.yaok.app:41641</string>
    <key>RelayEnabled</key>
    <true/>
    <key>SentryDSN</key>
    <string>https://xxx@sentry.io/yyy</string>
</dict>
</plist>
```

**Relay Server (Fly.io Secrets):**

```bash
# Set via flyctl (encrypted)
flyctl secrets set -a yaok-relay \
  RELAY_SECRET_KEY="random-32-byte-hex" \
  DATABASE_URL="sqlite:///data/relay.db" \
  RUST_LOG="info" \
  MAX_CLIENTS="10000" \
  MESSAGE_TTL_DAYS="7"
```

### 6.2 Feature Flags

**Implementation (Using LaunchDarkly or similar):**

```kotlin
// Android: app/src/main/kotlin/app/yaok/FeatureFlags.kt

object FeatureFlags {
    const val WIFI_DIRECT_ENABLED = "wifi_direct_enabled"
    const val RELAY_ENABLED = "relay_enabled"
    const val BIOMETRIC_AUTH = "biometric_auth"
    
    fun isEnabled(flag: String): Boolean {
        return when (flag) {
            WIFI_DIRECT_ENABLED -> BuildConfig.DEBUG || remoteConfig.getBoolean(flag)
            RELAY_ENABLED -> remoteConfig.getBoolean(flag)
            BIOMETRIC_AUTH -> remoteConfig.getBoolean(flag)
            else -> false
        }
    }
}
```

**Remote Configuration (Firebase Remote Config):**

```json
{
  "wifi_direct_enabled": true,
  "relay_enabled": true,
  "biometric_auth": true,
  "min_android_version": 24,
  "min_ios_version": "14.0",
  "relay_url": "https://relay.yaok.app:41641",
  "message_ttl_days": 7,
  "max_file_size_mb": 50
}
```

### 6.3 Secrets Management

**Storage:**

- **Local Development**: `.env` files (gitignored)
- **CI/CD**: GitHub Secrets
- **Android**: `keystore.properties` (gitignored)
- **iOS**: Xcode keychain
- **Relay**: Fly.io Secrets (encrypted)

**Never Commit:**

- Private keys
- Keystore passwords
- API keys
- Database credentials
- Signing certificates

**Rotation Schedule:**

| Secret Type | Rotation Frequency |
|-------------|-------------------|
| API Keys | Every 90 days |
| Keystore Password | Annually |
| Relay Secret Key | Every 6 months |
| Certificate | Before expiration |

---

## 7. Environment Setup

### 7.1 Development Environment

**Purpose:** Local development and testing

**Configuration:**
- Debug builds enabled
- Logging: Verbose
- Relay: Local relay server (localhost:41641)
- Database: SQLite (local file)
- API endpoints: Mock/staging

**Setup:**

```bash
# Android
./gradlew assembleDebug

# iOS
xcodebuild -configuration Debug

# Relay (local)
cd relay/
cargo run -- --port 41641
```

### 7.2 Staging Environment

**Purpose:** Pre-production testing, QA validation

**Configuration:**
- Release builds (with debug symbols)
- Logging: Info level
- Relay: Staging relay server (staging-relay.yaok.app)
- Database: Staging database (isolated from production)
- API endpoints: Staging

**Deployment:**

```bash
# Android - Internal Testing Track
./gradlew bundleRelease
# Upload to Google Play Console → Internal Testing

# iOS - TestFlight
xcodebuild archive -configuration Release
# Upload to TestFlight

# Relay - Staging App
flyctl deploy -a yaok-relay-staging
```

### 7.3 Production Environment

**Purpose:** Live environment serving real users

**Configuration:**
- Release builds (optimized, obfuscated)
- Logging: Warn/Error only (no sensitive data)
- Relay: Production relay server (relay.yaok.app)
- Database: Production database (encrypted, backed up)
- API endpoints: Production

**Deployment:**
- See sections 3, 4, 5 above

---

## 8. CI/CD Pipeline

### 8.1 GitHub Actions Workflow

**Workflow File: `.github/workflows/deploy.yml`**

```yaml
name: Deploy Ya OK

on:
  push:
    tags:
      - 'v*'  # Trigger on version tags (e.g., v0.2.0)

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Run Android Tests
        run: |
          cd android
          ./gradlew test
      
      - name: Run Rust Tests
        run: |
          cd ya_ok_core
          cargo test
      
      - name: Security Scan
        run: |
          cargo audit
          ./gradlew dependencyCheckAnalyze

  build-android:
    name: Build Android
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/keystore.jks
      
      - name: Build AAB
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          cd android
          ./gradlew bundleRelease
      
      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: app-release.aab
          path: android/app/build/outputs/bundle/release/app-release.aab

  build-ios:
    name: Build iOS
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.2'
      
      - name: Install Provisioning Profile
        run: |
          echo "${{ secrets.PROVISIONING_PROFILE }}" | base64 -d > profile.mobileprovision
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
      
      - name: Build IPA
        run: |
          cd ios
          xcodebuild archive \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -archivePath build/Runner.xcarchive
          
          xcodebuild -exportArchive \
            -archivePath build/Runner.xcarchive \
            -exportPath build/ \
            -exportOptionsPlist ExportOptions.plist
      
      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: Runner.ipa
          path: ios/build/Runner.ipa

  deploy-relay:
    name: Deploy Relay Server
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flyctl
        uses: superfly/flyctl-actions/setup-flyctl@master
      
      - name: Deploy to Fly.io
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
        run: |
          cd relay
          flyctl deploy --app yaok-relay --strategy bluegreen
      
      - name: Verify Deployment
        run: |
          sleep 30
          curl -f https://relay.yaok.app/health || exit 1

  publish-android:
    name: Publish to Google Play
    needs: build-android
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: app-release.aab
      
      - name: Publish to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: app.yaok.android
          releaseFiles: app-release.aab
          track: production
          status: completed
          inAppUpdatePriority: 3

  publish-ios:
    name: Publish to App Store
    needs: build-ios
    runs-on: macos-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: Runner.ipa
      
      - name: Upload to App Store Connect
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
        run: |
          xcrun altool --upload-app \
            -f Runner.ipa \
            --type ios \
            --username "$APPLE_ID" \
            --password "$APPLE_PASSWORD"
```

### 8.2 CI/CD Pipeline Stages

**Pipeline Flow:**

```
1. Code Commit → Push to main branch
2. Run Tests → Unit + Integration tests
3. Security Scan → Vulnerability checks
4. Build → Android AAB, iOS IPA, Relay Docker image
5. Deploy Relay → Fly.io (Blue-Green)
6. Manual Approval → Release Manager approves
7. Publish Apps → Google Play, App Store
8. Monitor → Check metrics, rollout
```

**Manual Approval Gate:**

```yaml
# Add to workflow for production deployments

publish-android:
  needs: build-android
  environment: production  # Requires manual approval
  runs-on: ubuntu-latest
  steps:
    # ... publish steps
```

---

## 9. Post-Deployment Validation

### 9.1 Automated Checks

**Health Check Script: `scripts/post-deploy-check.sh`**

```bash
#!/bin/bash
set -e

echo "=== Ya OK Post-Deployment Validation ==="

# 1. Relay Server Health
echo "1. Checking Relay Server..."
RELAY_STATUS=$(curl -s https://relay.yaok.app/health | jq -r '.status')
if [ "$RELAY_STATUS" != "healthy" ]; then
  echo "❌ Relay server unhealthy!"
  exit 1
fi
echo "✅ Relay server healthy"

# 2. Relay Server Regions
echo "2. Checking multi-region deployment..."
for REGION in ams iad sin; do
  STATUS=$(curl -s "https://$REGION.yaok-relay.fly.dev/health" | jq -r '.status')
  if [ "$STATUS" != "healthy" ]; then
    echo "❌ Region $REGION unhealthy!"
    exit 1
  fi
  echo "✅ Region $REGION healthy"
done

# 3. Google Play Store Rollout
echo "3. Checking Google Play rollout..."
# Manual check - review Play Console
echo "⚠️  Manual: Verify rollout at https://play.google.com/console"

# 4. App Store Connect Status
echo "4. Checking App Store status..."
# Manual check - review App Store Connect
echo "⚠️  Manual: Verify status at https://appstoreconnect.apple.com"

# 5. Crash Monitoring
echo "5. Checking crash rates..."
# Query Firebase Crashlytics or Sentry
# CRASH_RATE=$(firebase crashlytics:reports:get --project yaok-app | jq -r '.crashFreePercentage')
# if (( $(echo "$CRASH_RATE < 99.5" | bc -l) )); then
#   echo "❌ Crash rate too high: $CRASH_RATE%"
#   exit 1
# fi
echo "⚠️  Manual: Check Firebase Crashlytics dashboard"

# 6. User Feedback
echo "6. Checking user ratings..."
# Manual check - review store ratings
echo "⚠️  Manual: Monitor Play Store and App Store reviews"

echo ""
echo "=== Validation Complete ==="
```

### 9.2 Manual Validation Checklist

**Relay Server:**

- [ ] Health endpoint returns 200 OK
- [ ] All regions responding (ams, iad, sin)
- [ ] Metrics endpoint accessible
- [ ] Logs show no errors
- [ ] Resource usage normal (CPU <50%, Memory <200 MB)

**Android App:**

- [ ] Staged rollout started at 1%
- [ ] No crash clusters in Crashlytics
- [ ] Play Store listing correct (version, screenshots)
- [ ] User reviews stable (no negative spike)
- [ ] Crash rate <0.5%
- [ ] ANR rate <0.1%

**iOS App:**

- [ ] App Store review approved
- [ ] Released to App Store (or scheduled)
- [ ] App Store listing correct
- [ ] No crash reports in Xcode Organizer
- [ ] User reviews stable
- [ ] Crash rate <0.5%

**Functional Validation (Smoke Test):**

- [ ] Download app from store (not side-loaded)
- [ ] Launch app, create identity
- [ ] Add contact via QR code
- [ ] Send test message (BLE)
- [ ] Send test message (Relay)
- [ ] Receive message successfully
- [ ] File attachment works
- [ ] Authentication (PIN/biometric) works
- [ ] Settings persist correctly
- [ ] No UI glitches or crashes

### 9.3 Performance Validation

**Benchmarks to Verify:**

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| App startup | <2s | [TBD] | [ ] |
| Message encryption | <5ms | [TBD] | [ ] |
| Message send (BLE) | <200ms | [TBD] | [ ] |
| Message send (Relay) | <500ms | [TBD] | [ ] |
| Relay response time | <100ms | [TBD] | [ ] |
| Memory usage | <200 MB | [TBD] | [ ] |
| Battery drain (idle) | <2%/hr | [TBD] | [ ] |

**Load Test (Relay Server):**

```bash
# Use Apache Bench or similar
ab -n 10000 -c 100 https://relay.yaok.app/health

# Expected:
# Requests per second: >1000 req/s
# Time per request: <100ms (mean)
# Failed requests: 0
```

---

## 10. Rollback Procedures

### 10.1 Android Rollback

**Scenario:** Critical bug discovered in production rollout

**Steps:**

1. **Pause Rollout**
   ```
   Google Play Console → Production → Releases → Manage
   Click "Pause rollout"
   ```

2. **Assess Impact**
   - Review crash reports
   - Check user feedback
   - Determine severity (P0-P3)

3. **Decision: Rollback or Hotfix**
   - If P0/P1: Rollback immediately
   - If P2/P3: Consider hotfix instead

4. **Rollback to Previous Version**
   ```
   Play Console → Production → Releases
   Click "Halt rollout" (users stay on current version)
   Note: Cannot force-downgrade users who already updated
   ```

5. **Prepare Hotfix**
   - Fix critical bug
   - Increment version code (e.g., 10 → 11)
   - Test thoroughly
   - Upload new release

6. **Resume Rollout**
   ```
   Upload fixed version (v0.2.1 with version code 11)
   Start new staged rollout: 1% → 10% → 50% → 100%
   ```

**Rollback Limitations:**
- Cannot force users to downgrade
- Users who updated will keep buggy version until new release
- Provide app update notification: "Critical update available"

### 10.2 iOS Rollback

**Scenario:** Critical bug discovered after App Store release

**Steps:**

1. **Remove App from Sale (Emergency Only)**
   ```
   App Store Connect → Pricing and Availability
   Uncheck all territories
   Save
   ```
   **Note:** This prevents new downloads but doesn't affect existing users

2. **Prepare Hotfix**
   - Fix critical bug
   - Increment build number (e.g., 10 → 11)
   - Version number: 0.2.1 (patch version)
   - Test thoroughly

3. **Expedited Review**
   ```
   App Store Connect → Version → App Review Information
   Check "Request Expedited Review"
   Justification: "Critical bug causing crashes for all users"
   ```
   Expected review time: 2-24 hours (vs. 24-48 hours standard)

4. **Release Hotfix**
   - Upload fixed build
   - Submit for review
   - Once approved: Automatic release or manual release
   - App goes live within 24 hours

**Rollback Limitations:**
- Cannot rollback iOS apps (no way to force downgrade)
- Must ship hotfix and wait for review
- Users must manually update to get fix
- Provide in-app alert: "Critical update required"

### 10.3 Relay Server Rollback

**Scenario:** Deployment causes relay server issues

**Steps:**

1. **Identify Issue**
   ```bash
   flyctl logs -a yaok-relay
   # Check for errors, high latency, connection issues
   ```

2. **Immediate Rollback**
   ```bash
   # List recent releases
   flyctl releases -a yaok-relay
   
   # Example output:
   # VERSION STABLE  TYPE    STATUS   DESC
   # v10     true    deploy  success  Deploy v0.2.0
   # v9      false   deploy  success  Deploy v0.1.9
   
   # Rollback to previous version (v9)
   flyctl releases rollback v9 -a yaok-relay
   ```

3. **Verify Rollback**
   ```bash
   # Check status
   flyctl status -a yaok-relay
   
   # Verify health
   curl https://relay.yaok.app/health
   # Should return: {"status":"healthy","version":"0.1.9"}
   ```

4. **Monitor Recovery**
   ```bash
   flyctl logs -a yaok-relay
   flyctl dashboard metrics -a yaok-relay
   ```

5. **Post-Rollback Actions**
   - Investigate root cause
   - Fix issue locally
   - Test thoroughly in staging
   - Redeploy when ready

**Rollback Time:** ~1-2 minutes (zero downtime with Blue-Green)

### 10.4 Emergency Hotfix Process

**Fast-Track Deployment for Critical Issues:**

**Criteria for Emergency Hotfix:**
- P0 (Critical) bugs: App crashes, data loss, security vulnerability
- Affects >10% of users
- No acceptable workaround

**Process:**

1. **Declare Incident**
   - Create incident ticket
   - Notify stakeholders (PagerDuty, Slack)
   - Assign on-call engineer

2. **Develop Fix**
   - Create hotfix branch: `hotfix/v0.2.1`
   - Implement minimal fix (no feature changes)
   - Write unit test for fix
   - Code review (1 reviewer minimum)

3. **Test Fix**
   - Run automated tests
   - Manual testing on affected scenario
   - No full regression (time-critical)

4. **Deploy Hotfix**
   ```bash
   # Android: Increment version code, upload AAB
   # iOS: Increment build number, request expedited review
   # Relay: Deploy immediately
   
   git tag v0.2.1
   git push origin v0.2.1
   # CI/CD pipeline deploys automatically
   ```

5. **Monitor Closely**
   - Watch crash rates
   - Monitor user feedback
   - Check metrics every 15 minutes for first 2 hours

6. **Communicate**
   - Update users via in-app announcement
   - Post on social media
   - Update status page

---

## 11. Troubleshooting

### 11.1 Common Deployment Issues

#### Issue: Android Build Fails

**Symptoms:**
```
> Task :app:bundleRelease FAILED
Execution failed for task ':app:bundleRelease'.
```

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Missing keystore | Verify `keystore.properties` configured correctly |
| Incorrect keystore password | Double-check password, try resetting |
| Dependency conflict | Run `./gradlew dependencies` to identify conflicts |
| Out of memory | Increase Gradle heap size in `gradle.properties`: `org.gradle.jvmargs=-Xmx4g` |
| ProGuard issues | Check `proguard-rules.pro`, add keep rules for problematic classes |

**Debug Steps:**

```bash
# 1. Clean build
./gradlew clean

# 2. Build with stacktrace
./gradlew bundleRelease --stacktrace

# 3. Check ProGuard mapping
cat app/build/outputs/mapping/release/missing_rules.txt

# 4. Disable ProGuard temporarily (testing only)
# android/app/build.gradle:
# buildTypes {
#   release {
#     minifyEnabled false  // Change to false
#   }
# }
```

#### Issue: iOS Build Fails

**Symptoms:**
```
error: Signing for "Runner" requires a development team.
```

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Missing development team | Set team in Xcode: Runner target → Signing & Capabilities → Team |
| Expired certificate | Renew certificate in Apple Developer portal |
| Provisioning profile mismatch | Download latest profile, install in Xcode |
| Code signing identity not found | Open Keychain Access, verify certificate installed |
| Bitcode error | Disable bitcode in build settings (if not needed) |

**Debug Steps:**

```bash
# 1. Clean build folder
rm -rf ios/build/
xcodebuild clean

# 2. Check signing
security find-identity -v -p codesigning
# Should show: "Apple Distribution: Your Name (TEAMID)"

# 3. Verify provisioning profile
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# 4. Build with verbose output
xcodebuild archive -workspace Runner.xcworkspace -scheme Runner -configuration Release -verbose
```

#### Issue: Relay Deployment Fails on Fly.io

**Symptoms:**
```
Error: failed to fetch an image or build from source: error building: failed to solve...
```

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Dockerfile syntax error | Validate Dockerfile syntax |
| Build timeout | Increase timeout or optimize build (use caching) |
| Out of memory during build | Use multi-stage build, reduce dependencies |
| Network error pulling base image | Retry deployment, check Fly.io status |
| Health check failing | Verify `/health` endpoint returns 200 |

**Debug Steps:**

```bash
# 1. Build Docker image locally
docker build -t yaok-relay:test relay/
# If succeeds locally, issue is with Fly.io build

# 2. Check Fly.io logs
flyctl logs -a yaok-relay

# 3. SSH into instance
flyctl ssh console -a yaok-relay
# Inside instance:
curl localhost:8080/health

# 4. Check health check configuration
flyctl checks list -a yaok-relay

# 5. Force rebuild (no cache)
flyctl deploy -a yaok-relay --no-cache
```

### 11.2 Deployment Failure Recovery

**Scenario: Deployment Stuck in "In Progress"**

**Android (Google Play):**

```bash
# 1. Check rollout status
# Play Console → Production → Manage release
# Status should update within 24 hours

# 2. If stuck >24 hours:
# Contact Google Play Support
# Provide: App ID, Release version, Timestamp

# 3. Meanwhile, prepare new release
# Increment version code, re-upload
```

**iOS (App Store):**

```bash
# 1. Check build processing status
# App Store Connect → TestFlight → iOS Builds
# Processing usually takes 10-30 minutes

# 2. If stuck >2 hours:
# Remove build, re-upload
# App Store Connect → Build → Remove Build
# Upload new build with incremented build number

# 3. If review stuck:
# App Store Connect → App Review → Contact Us
```

**Relay (Fly.io):**

```bash
# 1. Check deployment status
flyctl status -a yaok-relay

# 2. If machines stuck in "starting" state:
flyctl machine stop <machine_id> -a yaok-relay
flyctl machine start <machine_id> -a yaok-relay

# 3. If deployment completely failed:
flyctl releases rollback -a yaok-relay

# 4. Nuclear option: destroy and recreate
flyctl machine destroy <machine_id> -a yaok-relay
flyctl deploy -a yaok-relay
```

### 11.3 Support Contacts

**Internal Contacts:**

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Lead | devops@yaok.app | 24/7 on-call |
| Release Manager | releases@yaok.app | Business hours |
| Security Team | security@yaok.app | 24/7 on-call |

**External Support:**

| Platform | Support Channel | Response Time |
|----------|----------------|---------------|
| Google Play | https://support.google.com/googleplay/android-developer | 24-48 hours |
| Apple App Store | https://developer.apple.com/contact | 1-2 business days |
| Fly.io | https://community.fly.io | 1-4 hours |
| GitHub Actions | https://support.github.com | 24 hours |

---

## Appendix A: Deployment Checklist

### Pre-Deployment

- [ ] All tests pass (unit, integration, security)
- [ ] Code review completed
- [ ] Release notes prepared
- [ ] Change request approved
- [ ] Rollback plan documented
- [ ] On-call engineer notified
- [ ] Stakeholders informed

### Android Deployment

- [ ] Build release AAB
- [ ] Sign with production keystore
- [ ] Upload to Google Play Console
- [ ] Configure staged rollout (1%)
- [ ] Submit for review
- [ ] Monitor rollout metrics

### iOS Deployment

- [ ] Build release IPA
- [ ] Sign with distribution certificate
- [ ] Upload to App Store Connect
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Release to App Store

### Relay Deployment

- [ ] Build Docker image
- [ ] Tag with version
- [ ] Deploy to Fly.io (Blue-Green)
- [ ] Verify health checks
- [ ] Monitor logs and metrics
- [ ] Validate multi-region deployment

### Post-Deployment

- [ ] Run automated health checks
- [ ] Perform manual smoke test
- [ ] Monitor crash rates
- [ ] Check user feedback
- [ ] Update documentation
- [ ] Close change request

---

## Appendix B: Deployment Timeline

**Standard Release Cycle:**

```
Week 1:
- Monday: Code freeze, create release branch
- Tuesday-Wednesday: QA testing, bug fixes
- Thursday: Release candidate ready
- Friday: Closed beta release (Android: Internal, iOS: TestFlight)

Week 2:
- Monday: Monitor beta feedback
- Tuesday: Fix critical issues (if any)
- Wednesday: Build production release
- Thursday: Deploy relay server, submit apps for review
- Friday: Monitor rollout, communicate with users

Week 3:
- Monday: Staged rollout to 10%
- Wednesday: Rollout to 50%
- Friday: Rollout to 100%

Week 4:
- Monitor metrics, user feedback
- Plan next release
```

**Hotfix Timeline:**

```
Hour 0: Issue detected
Hour 1: Incident declared, fix started
Hour 2: Fix developed, tested
Hour 3: Hotfix deployed (relay), submitted (apps)
Hour 4-24: Monitor rollout
Day 1-2: iOS expedited review
Day 2-3: Staged rollout complete
```

---

**Document Classification:** INTERNAL  
**Distribution:** DevOps Team, Release Team, QA Team  
**Review Cycle:** Updated on every major release

**End of Production Deployment Guide**
