# Ya OK - Архитектура системы

## Общий обзор

```
┌──────────────────────────────────────────────────────────────┐
│                     Mobile Clients                            │
│  ┌──────────────┐              ┌──────────────┐              │
│  │   iOS App    │              │ Android App  │              │
│  │  (Swift)     │              │  (Kotlin)    │              │
│  └──────┬───────┘              └──────┬───────┘              │
│         │                             │                       │
│         └──────────────┬──────────────┘                       │
└────────────────────────┼──────────────────────────────────────┘
                         │
                         │ UDP Packets
                         │ (Encrypted P2P)
                         ▼
         ┌───────────────────────────────┐
         │                               │
         │     Relay Server (Rust)       │
         │   Azure Container Apps        │
         │                               │
         │  • UDP hole punching          │
         │  • Packet forwarding          │
         │  • Rate limiting              │
         │  • Peer TTL management        │
         │                               │
         └───────────────┬───────────────┘
                         │
                         │ Metrics/Logs
                         ▼
         ┌───────────────────────────────┐
         │   Application Insights        │
         │   + Log Analytics             │
         └───────────────────────────────┘


┌──────────────────────────────────────────────────────────────┐
│                    Static Web Content                         │
│                    (Nginx on App Service)                     │
│                                                               │
│  • Privacy Policy                                             │
│  • Terms of Service                                           │
│  • Support Page                                               │
└──────────────────────────────────────────────────────────────┘
```

## Компоненты системы

### 1. Mobile Applications

#### iOS App
- **Технологии**: Swift, UIKit
- **Ключевые модули**:
  - `CoreBridge.swift`: Bridge между Swift и Rust core
  - `PeerService.swift`: Управление peer-to-peer соединениями
  - `UdpService.swift`: UDP коммуникация
  - `TransportCoordinator.swift`: Координация транспорта
  - `NotificationManager.swift`: Push уведомления
  - `ContactStore.swift`: Управление контактами

#### Android App
- **Технологии**: Kotlin, Android SDK
- **Местоположение**: `/android`
- **Build System**: Gradle
- **Firebase**: Google Services для push notifications

### 2. Rust Core Library (`ya_ok_core`)

```
ya_ok_core/
├── Cargo.toml
├── src/
│   ├── lib.rs           # Public API
│   ├── crypto.rs        # E2E encryption
│   ├── packet.rs        # Packet structure
│   ├── peer.rs          # Peer management
│   └── transport.rs     # UDP transport
└── target/
```

**Ключевые возможности:**
- End-to-end encryption (Noise Protocol)
- Packet serialization/deserialization
- Peer discovery and management
- UDP hole punching logic
- FFI bindings для iOS/Android

### 3. Relay Server

```
relay/
├── Cargo.toml
├── Dockerfile            # Optimized multi-stage build
├── fly.toml              # Fly.io configuration
└── src/
    └── main.rs           # Server implementation
```

**Функциональность:**
- UDP packet relay между peers
- Rate limiting (200 pps по умолчанию)
- Peer TTL management (300 sec)
- Метрики и статистика
- Graceful handling packet size limits

**Переменные окружения:**
```bash
RELAY_PORT=40100                    # UDP port
MAX_PACKET_SIZE=64000               # Max packet size in bytes
RATE_LIMIT_PPS=200                  # Packets per second limit
PEER_TTL_SECS=300                   # Peer timeout
METRICS_INTERVAL_SECS=60            # Metrics logging interval
RELAY_BIND=0.0.0.0:40100           # Bind address
```

### 4. Static Web (Legal Documents)

```
Dockerfile                          # Nginx alpine
├── privacy.html
├── terms.html
└── support-page.html
```

## Поток данных

### Регистрация и обнаружение пира

```
┌──────────┐                    ┌──────────┐                    ┌──────────┐
│  Peer A  │                    │  Relay   │                    │  Peer B  │
└────┬─────┘                    └────┬─────┘                    └────┬─────┘
     │                               │                               │
     │ 1. Register (peer_id, addr)   │                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │                               │   2. Register (peer_id, addr) │
     │                               │◄──────────────────────────────┤
     │                               │                               │
     │ 3. Lookup peer B              │                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │ 4. Peer B address             │                               │
     │◄──────────────────────────────┤                               │
     │                               │                               │
```

### Передача сообщений (P2P with fallback)

```
┌──────────┐                    ┌──────────┐                    ┌──────────┐
│  Peer A  │                    │  Relay   │                    │  Peer B  │
└────┬─────┘                    └────┬─────┘                    └────┬─────┘
     │                               │                               │
     │ 1. Direct UDP attempt         │                               │
     ├───────────────────────────────┼──────────────────────────────►│
     │                               │                               │
     │ (if direct fails)             │                               │
     │                               │                               │
     │ 2. Send via relay             │                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │                               │ 3. Forward packet             │
     │                               ├──────────────────────────────►│
     │                               │                               │
     │                               │ 4. Response via relay         │
     │                               │◄──────────────────────────────┤
     │                               │                               │
     │ 5. Response forwarded         │                               │
     │◄──────────────────────────────┤                               │
     │                               │                               │
```

## Безопасность

### 1. End-to-End Encryption
- Использует **Noise Protocol Framework**
- Симметричное шифрование после handshake
- Forward secrecy
- Identity verification

### 2. Network Security
- UDP packets не содержат plaintext
- Relay server не может расшифровать контент
- Rate limiting против DoS
- Peer TTL против resource exhaustion

### 3. Application Security
- Non-root user в Docker контейнере
- Minimal attack surface (Rust + slim images)
- No persistent storage в relay
- Stateless design

## Deployment

### Current: Fly.io

```toml
# relay/fly.toml
app = "i-am-ok-relay"

[[services]]
  internal_port = 40100
  protocol = "udp"
  auto_stop_machines = "off"      # Always running
  min_machines_running = 1
```

**Преимущества:**
- ✅ Global edge locations
- ✅ UDP поддержка
- ✅ Автоматический SSL для TCP
- ✅ Простой deployment

### Planned: Azure

```
Azure Container Apps
├── Relay Server (Container App)
│   ├── UDP ingress enabled
│   ├── Scaling rules (CPU/Memory)
│   └── Application Insights integration
│
└── Static Web (App Service)
    ├── Nginx container
    ├── Custom domain
    └── SSL certificate
```

## Мониторинг и метрики

### Relay Server Metrics

```rust
struct Stats {
    received: u64,          // Total packets received
    forwarded: u64,         // Successfully forwarded
    dropped_rate: u64,      // Dropped due to rate limit
    dropped_size: u64,      // Dropped due to size limit
}
```

Логируются каждые 60 секунд.

### Рекомендуемые метрики для Azure:

- **Application Insights**:
  - Request rate
  - Response time
  - Error rate
  - Custom events (peer registration, packet forwarding)

- **Container Apps**:
  - CPU usage
  - Memory usage
  - Replica count
  - Network throughput

- **Log Analytics**:
  - Structured logs
  - Query capabilities
  - Alerting

## Масштабирование

### Horizontal Scaling

Relay server поддерживает horizontal scaling:

```yaml
# Container App scale rules
scale:
  minReplicas: 1
  maxReplicas: 10
  rules:
    - name: cpu-rule
      custom:
        type: cpu
        metadata:
          value: "70"
```

**Важно**: Peers должны быть aware о нескольких relay instances:
- Используйте consistent hashing для routing
- Или используйте anycast для load balancing

### Vertical Scaling

```yaml
# Container resources
resources:
  cpu: 0.5
  memory: 1Gi
```

Увеличить при необходимости на основе metrics.

## Будущие улучшения

### 1. Relay Discovery Service
- Автоматическое обнаружение ближайшего relay
- Health checks и failover
- Geographic load balancing

### 2. Enhanced Monitoring
- Real-time dashboard
- Prometheus metrics export
- Grafana visualization

### 3. Performance Optimization
- Connection pooling
- Packet batching
- Zero-copy networking (io_uring)

### 4. Security Enhancements
- DDoS protection
- Geo-blocking опции
- Advanced rate limiting

## Технологический стек

| Component | Technology | Version |
|-----------|-----------|---------|
| Core Library | Rust | 1.76+ |
| Relay Server | Rust + Tokio | 1.76+ |
| iOS App | Swift | 5.9+ |
| Android App | Kotlin | 1.9+ |
| Build System | Gradle | 8.x |
| Containerization | Docker | 24.x |
| Orchestration | Fly.io / Azure | - |
| CI/CD | GitHub Actions | - |

## Ссылки

- [Relay Server Guide](../docs/RELAY_SERVER_GUIDE.md)
- [Definition of Done](../docs/DEFINITION_OF_DONE_AND_SCENARIOS.md)
- [Project Status](../PROJECT_STATUS_RUST_CORE.md)
- [Risk Register](../ya_ok_core/RISK_REGISTER.md)
