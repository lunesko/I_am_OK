# Gossip Protocol Documentation

## Overview

The Gossip Protocol enables peer-to-peer state synchronization in the Ya OK mesh network. It ensures that all connected peers have consistent views of:
- Active peer lists
- Message acknowledgments
- Network topology

## Architecture

Located in: `ya_ok_core/src/sync/mod.rs`

### Components

1. **Gossip**: State synchronization engine
2. **GossipProtocol**: Trait defining gossip behavior
3. **GossipMessage**: Protocol data units

## Protocol Design

### Epidemic Dissemination

Uses **push-pull gossip** for state propagation:
- **Push**: Node sends updates to random peers
- **Pull**: Node requests updates from random peers

### Anti-Entropy

Periodic full state reconciliation to repair divergence:
- Merkle tree hashes for efficient comparison
- Delta-based synchronization (only send differences)

## Message Types

### 1. PeerAnnounce

Announces new peer availability:

```rust
struct PeerAnnounce {
    peer_id: String,
    public_key: Vec<u8>,
    transports: Vec<TransportType>,
    timestamp: DateTime<Utc>
}
```

**Propagation**: Forwarded to all neighbors (1 hop TTL)

### 2. ACK Propagation

Spreads delivery confirmations:

```rust
struct ACKGossip {
    message_id: String,
    ack_from: String,
    ack_type: AckType,
    timestamp: DateTime<Utc>
}
```

**Purpose**: Inform sender that message was delivered via relay or intermediate node

### 3. State Digest

Periodic state summary exchange:

```rust
struct StateDigest {
    peer_list_hash: [u8; 32],
    ack_list_hash: [u8; 32],
    version: u64
}
```

**Use**: Detect state divergence, trigger full sync

## Gossip Parameters

### Timing

- **Gossip Interval**: 30 seconds (configurable)
- **Fanout**: 3 random peers per round
- **TTL**: 3 hops maximum

### Anti-Entropy

- **Full Sync Interval**: 5 minutes
- **Max Digest Size**: 1KB
- **Max Delta Size**: 10KB

## Implementation

### Push-Pull Cycle

```rust
// Every 30 seconds:
1. Select 3 random peers
2. Send state digest
3. If peer has newer state, request delta
4. If we have newer state, push delta
5. Apply received updates
```

### Conflict Resolution

- **Last-Write-Wins**: Timestamp-based ordering
- **Causal Ordering**: Vector clocks for ACKs

## Integration

### With DTN Router

- Gossip provides peer discovery
- Router uses gossip for relay selection

### With Storage

- ACKs stored locally are gossiped
- Reduces ACK latency in multi-hop networks

## Security Considerations

### Gossip Authentication

All gossip messages are signed with Ed25519:
- Prevents impersonation
- Enables origin validation

### Rate Limiting

- Max 10 gossip messages/minute per peer
- Prevents gossip storms

### Sybil Resistance

- Only gossip to verified contacts
- No open mesh participation

## Performance

### Bandwidth Usage

- ~1KB every 30 seconds per active peer
- Minimal overhead for small networks (<50 peers)

### Convergence Time

- **Small Network** (10 peers): ~1 minute
- **Medium Network** (100 peers): ~3 minutes
- **Large Network** (1000 peers): ~10 minutes

## Future Extensions

- **Hierarchical Gossip**: Reduce convergence time in large networks
- **Adaptive Intervals**: Adjust based on network activity
- **Compression**: CBOR or zstd for state deltas

## References

- Paper: "Epidemic Algorithms for Replicated Database Maintenance" (Demers et al., 1987)
- RFC 6940: Optimized Link State Routing Protocol
- Architecture Doc: DTN Routing
