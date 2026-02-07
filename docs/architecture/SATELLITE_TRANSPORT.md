# Satellite Transport Documentation

## Overview

The Satellite Transport module (`transport/satellite.rs`) is a **stub implementation** for future satellite connectivity support. Currently, it is not functional and serves as a placeholder for v2.0 development.

## Status

**Implementation Status**: 🚧 **STUB / NOT IMPLEMENTED**  
**Planned Version**: v2.0 (future)  
**Priority**: P3 (Low)

## Architecture

Located in: `ya_ok_core/src/transport/satellite.rs`

### Current Implementation

```rust
pub struct SatelliteTransport;

impl SatelliteTransport {
    // Stub - returns error
}

#[async_trait]
impl Transport for SatelliteTransport {
    async fn send(&self, _data: &[u8], _peer: &Peer) -> Result<(), TransportError> {
        Err(TransportError::NotSupported)
    }
    
    async fn receive(&self) -> Result<Vec<u8>, TransportError> {
        Err(TransportError::NotSupported)
    }
}
```

## Planned Features (v2.0)

### Use Cases

1. **Emergency Communication**: Remote areas without cellular/WiFi
2. **Maritime**: Ships at sea
3. **Rural Connectivity**: Areas without terrestrial infrastructure
4. **Disaster Recovery**: When ground infrastructure fails

### Technology Options

| Technology | Bandwidth | Latency | Cost | Availability |
|------------|-----------|---------|------|--------------|
| **Iridium** | 2.4 Kbps | ~1s | High | Global |
| **Starlink** | 100+ Mbps | 20-40ms | Medium | Expanding |
| **Inmarsat** | 432 Kbps | ~0.5s | High | Maritime |
| **Swarm** | 1 Kbps | Variable | Low | IoT-focused |

### Proposed Design

#### Message Optimization

- **Compression**: Text messages only (~100-500 bytes)
- **Status-Only Mode**: "I'm OK" = 10 bytes
- **Batch Transmission**: Group messages to reduce overhead

#### Protocol Adaptations

```rust
struct SatelliteConfig {
    provider: SatelliteProvider,  // Iridium, Starlink, etc.
    max_message_size: usize,      // Typically 340 bytes for Iridium
    retry_count: u8,
    timeout: Duration
}
```

#### Cost Management

- **User-Initiated**: Manual send for satellite (high cost)
- **Buffering**: Queue messages locally until user confirms send
- **Quota System**: Daily/monthly message limits

## Integration Points

### Transport Manager

Satellite transport would be lowest priority (highest cost):

```
Priority: BLE > WiFi Direct > Relay > Satellite
```

### User Interface

Requires explicit UI warnings:
- "Satellite transmission may incur costs"
- "Estimated cost: $0.50 per message"
- Confirmation dialog before send

## Development Roadmap

### Phase 1 (v2.0)

- [ ] Implement Iridium SBD API integration
- [ ] Add message compression (zstd)
- [ ] Create cost estimation UI
- [ ] Add satellite status indicator

### Phase 2 (v2.1)

- [ ] Starlink support
- [ ] Store-and-forward optimization
- [ ] Satellite availability prediction

### Phase 3 (v3.0)

- [ ] Multi-satellite fallback
- [ ] Adaptive compression based on link quality
- [ ] Emergency SOS mode (status only)

## Why Not In v1.0?

1. **Complexity**: Requires integration with satellite modems/APIs
2. **Cost**: Satellite connectivity is expensive, needs careful UX
3. **Testing**: Requires physical satellite hardware
4. **Market Validation**: Validate DTN core before adding satellite

## References

- Iridium SBD API: https://www.iridium.com/products/iridium-sbd/
- Starlink Developer Docs: (TBD)
- RFC 5050: Bundle Protocol (DTN)

## Notes

- Current code is safe to leave in place (returns errors)
- Satellite module does NOT interfere with other transports
- Can be enabled via feature flag when ready: `cargo build --features satellite`

---

**Status**: Documented as future work  
**Action**: No changes needed for v1.0  
**Risk**: LOW (stub implementation, no impact)
