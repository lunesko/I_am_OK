# Policy System Documentation

## Overview

The Policy System provides fine-grained control over network behavior, transport prioritization, and resource management in the Ya OK application.

## Architecture

Located in: `ya_ok_core/src/policy/mod.rs`

### Components

1. **PolicyManager**: Central policy enforcement engine
2. **Policy**: Enumeration of available policies
3. **Transport Rules**: Per-transport configuration

## Policy Types

### 1. Transport Priority

Controls which transport layers are preferred:

```rust
pub enum TransportPriority {
    WiFiFirst,     // Prefer WiFi Direct over BLE
    BLEFirst,      // Prefer BLE over WiFi (battery saving)
    RelayFallback, // Use relay only if direct transports fail
    RelayPreferred // Use relay for faster delivery
}
```

**Use Cases**:
- `WiFiFirst`: Large messages, high bandwidth scenarios
- `BLEFirst`: Battery-constrained devices
- `RelayFallback`: Offline-first operation
- `RelayPreferred`: Fast delivery when online

### 2. Message Priority

Controls message queue ordering:

```rust
pub enum MessagePriority {
    High,   // Status messages
    Medium, // Text messages
    Low     // Voice/media messages
}
```

**Rationale**: Status messages ("I'm OK") are prioritized over bulk data.

### 3. Battery Policy

Controls power consumption:

```rust
pub enum BatteryPolicy {
    Aggressive,  // Full functionality, high power
    Balanced,    // Adaptive (default)
    PowerSaver   // Minimal radio usage
}
```

**Behavior**:
- **Aggressive**: All transports active, frequent discovery
- **Balanced**: Adaptive discovery intervals
- **PowerSaver**: BLE only, extended intervals

## Usage

### Initialization

```rust
let mut policy_manager = PolicyManager::new();
policy_manager.set_transport_priority(TransportPriority::BLEFirst);
policy_manager.set_battery_policy(BatteryPolicy::Balanced);
```

### Runtime Configuration

Policies can be changed dynamically based on:
- Battery level
- Network connectivity
- User preferences

### Integration Points

- **Transport Manager**: Consults policies for transport selection
- **DTN Router**: Uses message priorities for queue ordering
- **Platform Layer**: Adjusts policies based on OS signals

## Configuration File

Policies can be persisted in `policy.json`:

```json
{
  "transport_priority": "BLEFirst",
  "battery_policy": "Balanced",
  "max_relay_rate": 100,
  "max_message_size": 10240
}
```

## Future Extensions

- Geographic policies (different transports by region)
- Time-based policies (night mode, etc.)
- Contact-specific policies (VIP priority)

## References

- SRS § 3.5: Bluetooth Transport (priority rules)
- SRS § 3.7: Relay Transport (fallback rules)
- Architecture Doc: Transport Abstraction
