# TLS Configuration for Ya OK Relay

## Overview

The relay server now supports **DTLS (Datagram TLS)** for secure UDP communication, addressing requirements:
- **FR-RELAY-001-01**: System SHALL connect to relay server via UDP over TLS (DTLS)
- **FR-RELAY-001-05**: System SHALL verify relay TLS certificate (certificate pinning)

## Generating Certificates

### Development (Self-Signed)

```bash
# Generate private key
openssl genrsa -out relay-key.pem 2048

# Generate self-signed certificate (valid 365 days)
openssl req -new -x509 -key relay-key.pem -out relay-cert.pem -days 365 \
  -subj "/CN=i-am-ok-relay.fly.dev/O=Ya OK/C=UA"

# Verify certificate
openssl x509 -in relay-cert.pem -text -noout
```

### Production (Let's Encrypt)

```bash
# Install certbot
sudo apt install certbot

# Get certificate (HTTP-01 challenge)
sudo certbot certonly --standalone -d i-am-ok-relay.fly.dev

# Certificates will be in:
# /etc/letsencrypt/live/i-am-ok-relay.fly.dev/fullchain.pem
# /etc/letsencrypt/live/i-am-ok-relay.fly.dev/privkey.pem

# Copy to relay directory
sudo cp /etc/letsencrypt/live/i-am-ok-relay.fly.dev/fullchain.pem ./relay-cert.pem
sudo cp /etc/letsencrypt/live/i-am-ok-relay.fly.dev/privkey.pem ./relay-key.pem
sudo chown $USER:$USER relay-*.pem
```

### Certificate Pinning

Extract SHA-256 fingerprint for client-side pinning:

```bash
# Get certificate fingerprint
openssl x509 -in relay-cert.pem -noout -fingerprint -sha256

# Example output:
# SHA256 Fingerprint=A1:B2:C3:D4:E5:F6:...
```

Add this fingerprint to client configuration (Android/iOS apps).

## Configuration

### Environment Variables

```bash
# TLS certificate paths
export TLS_CERT_PATH="./relay-cert.pem"
export TLS_KEY_PATH="./relay-key.pem"

# Optional: Require client certificates (mutual TLS)
export TLS_CLIENT_CA_PATH="./client-ca.pem"

# Disable TLS for testing (NOT RECOMMENDED)
export TLS_DISABLED="false"
```

### Running with TLS

```bash
# Development (self-signed cert)
TLS_CERT_PATH=./relay-cert.pem TLS_KEY_PATH=./relay-key.pem cargo run

# Production
TLS_CERT_PATH=/etc/letsencrypt/live/i-am-ok-relay.fly.dev/fullchain.pem \
TLS_KEY_PATH=/etc/letsencrypt/live/i-am-ok-relay.fly.dev/privkey.pem \
RELAY_PORT=443 cargo run --release

# Docker
docker run -p 443:443/udp \
  -v /etc/letsencrypt:/certs:ro \
  -e TLS_CERT_PATH=/certs/live/i-am-ok-relay.fly.dev/fullchain.pem \
  -e TLS_KEY_PATH=/certs/live/i-am-ok-relay.fly.dev/privkey.pem \
  yaok-relay:latest
```

## Testing TLS

### OpenSSL Client

```bash
# Test DTLS connection
openssl s_client -dtls1_2 -connect i-am-ok-relay.fly.dev:40100

# Expected output:
# SSL handshake has read ... bytes
# Verify return code: 0 (ok)
```

### Wireshark

1. Capture UDP traffic on port 40100
2. Verify packets show "DTLS" protocol (not plaintext)
3. Check for TLS handshake messages (ClientHello, ServerHello)

### Certificate Verification

```bash
# Verify certificate chain
openssl verify -CAfile relay-cert.pem relay-cert.pem

# Check expiration
openssl x509 -in relay-cert.pem -noout -enddate
```

## Security Notes

### Certificate Rotation

- Certificates expire (Let's Encrypt: 90 days)
- Use `certbot renew` for automatic renewal
- Update client pinned fingerprint when rotating certificates

### Cipher Suites

The relay uses Rust's `rustls` with secure defaults:
- TLS 1.3 (preferred)
- TLS 1.2 (fallback)
- ECDHE with AES-GCM or ChaCha20-Poly1305
- No weak ciphers (RC4, DES, MD5)

### Known Limitations

1. **DTLS vs TCP TLS**: UDP-based DTLS is more complex than TCP TLS. Consider switching to WebSocket Secure (WSS) for production.
2. **Certificate Pinning Updates**: Clients must update app when certificate rotates. Use multiple pins (current + backup).
3. **Performance**: TLS adds ~2-5ms latency per handshake. Use session resumption.

## Migration Path

### v1.0: Plain UDP (Current - INSECURE)

```
Client --[Plaintext UDP]--> Relay
```

### v1.1: DTLS (This Implementation)

```
Client --[DTLS UDP]--> Relay
```

### v2.0: WebSocket Secure (Recommended)

```
Client --[WSS (HTTPS)]--> Relay (WebSocket over TLS)
```

**Advantages of WSS**:
- Standard HTTPS/TLS (port 443)
- Better firewall traversal
- HTTP/2 multiplexing
- Certificate management via reverse proxy (nginx, caddy)

## Troubleshooting

### Error: "Certificate not found"

```
Error: TLS_CERT_PATH not set or file not found
```

Solution: Set `TLS_CERT_PATH` and `TLS_KEY_PATH` environment variables.

### Error: "Permission denied"

```
Error: Failed to bind DTLS socket on 0.0.0.0:443: Permission denied
```

Solution: Ports <1024 require root. Use `sudo` or capabilities:

```bash
sudo setcap 'cap_net_bind_service=+ep' ./target/release/yaok-relay
```

### Error: "Certificate verification failed"

Client cannot verify server certificate. Possible causes:
1. Self-signed cert without pinning
2. Expired certificate
3. Wrong hostname (CN mismatch)

Solution: Use Let's Encrypt for production, or distribute self-signed cert to clients.

## References

- RFC 6347: Datagram Transport Layer Security (DTLS)
- RFC 8446: TLS 1.3
- Let's Encrypt: https://letsencrypt.org/
- Rustls Documentation: https://docs.rs/rustls/

---

**Status**: DTLS support implemented (2026-02-07)  
**Issue**: Addresses CRITICAL-002 from compliance audit  
**Next Steps**: Test with Android/iOS clients, implement certificate pinning client-side
