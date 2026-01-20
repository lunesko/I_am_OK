# Sequence Diagram: Передача пакета в «Я ОК»

## Основной flow: Отправка статуса

```mermaid
sequenceDiagram
    participant UI as Пользователь
    participant API as FFI API
    participant Core as Rust Core
    participant Identity as Identity
    participant Crypto as Crypto
    participant Message as Message
    participant Packet as Packet
    participant Router as DTN Router
    participant Transport as Transport Layer
    participant Storage as Storage

    UI->>API: ya_ok_send_status(OK)
    API->>Core: send_status()

    Core->>Identity: get current identity
    Identity-->>Core: identity

    Core->>Message: Message::status(sender_id, OK)
    Message-->>Core: message

    Core->>Storage: store_message(message)
    Storage-->>Core: ok

    Core->>Packet: Packet::from_message(message, identity, receiver_key)
    Packet->>Crypto: encrypt_payload()
    Crypto-->>Packet: encrypted_payload
    Packet->>Identity: sign(packet_data)
    Identity-->>Packet: signature
    Packet-->>Core: packet

    Core->>Router: flood_packet(packet)
    Router->>Transport: discover_peers()
    Transport-->>Router: [peer1, peer2, ...]

    loop Каждый пир
        Router->>Transport: send_packet(peer)
        Transport-->>Router: ok/error
    end

    Router-->>Core: ok
    Core-->>API: SUCCESS
    API-->>UI: ok
```

## Расширенный flow: Получение и forwarding

```mermaid
sequenceDiagram
    participant Peer1 as Узел A
    participant Peer2 as Узел B
    participant Peer3 as Узел C

    Peer1->>Peer1: Отправка статуса (flooding)
    Peer1->>Peer2: BLE: packet (hops=0)
    Peer2->>Peer2: Проверка TTL/hops
    Peer2->>Peer2: Дедупликация по message_id
    Peer2->>Peer2: Сохранение в storage
    Peer2->>Peer2: Увеличение hops
    Peer2->>Peer3: BLE: packet (hops=1)
    Peer2->>Peer1: BLE: packet (hops=1) - flooding back

    Peer3->>Peer3: Аналогичная обработка
```

## Flow: Gossip синхронизация

```mermaid
sequenceDiagram
    participant NodeA as Узел A
    participant NodeB as Узел B
    participant Gossip as Gossip Protocol

    NodeA->>Gossip: sync_with_peer(B)
    Gossip->>NodeB: DigestRequest(since=last_sync)
    NodeB->>NodeB: get_messages_since(since)
    NodeB->>Gossip: DigestResponse(digests[])
    Gossip->>Gossip: find missing message_ids
    Gossip->>NodeB: MessageRequest(missing_ids)
    NodeB->>Gossip: MessageResponse(messages[])
    Gossip->>NodeA: store_messages(messages)
```

## Flow: Адаптивный выбор транспорта

```mermaid
sequenceDiagram
    participant Router as DTN Router
    participant UDP as UDP Transport
    participant WiFi as Wi-Fi Direct
    participant BLE as BLE Transport

    Router->>UDP: is_available()?
    UDP-->>Router: true (интернет есть)

    Router->>UDP: send_packet(high_priority)
    UDP-->>Router: sent via IP/P2P

    Note over Router: Позже интернет пропал

    Router->>UDP: is_available()?
    UDP-->>Router: false

    Router->>WiFi: is_available()?
    WiFi-->>Router: true

    Router->>WiFi: send_packet(medium_priority)
    WiFi-->>Router: sent via Wi-Fi Direct

    Note over Router: Wi-Fi тоже нет

    Router->>BLE: is_available()?
    BLE-->>Router: true (всегда)

    Router->>BLE: send_packet(any_priority)
    BLE-->>Router: sent via BLE
```

## Flow: Policy enforcement

```mermaid
sequenceDiagram
    participant UI as Пользователь
    participant Policy as Policy Manager
    participant Message as Message

    UI->>Message: send long text (>256 bytes)
    Message->>Policy: validate_text_size(text)
    Policy-->>Message: Error: TextTooLong

    UI->>Message: send status (OK)
    Message->>Policy: validate_message()
    Policy-->>Message: OK

    Note over Policy: Военная policy активна

    UI->>Message: send long voice (>3s)
    Message->>Policy: validate_voice_length(5s)
    Policy-->>Message: Error: VoiceTooLong
```

## Data Flow: Структура пакета

```
Packet {
  message_id: "uuid"
  sender_id: "hex_public_key"
  timestamp: "2024-01-20T10:30:00Z"
  ttl: 3600
  hops: 0
  max_hops: 10
  priority: High
  encrypted_payload: {
    ciphertext: "aes_gcm_encrypted_data"
    nonce: "12_bytes"
    sender_public_key: "32_bytes_x25519"
  }
  signature: "64_bytes_ed25519"
}
```

## Error Handling Flow

```mermaid
sequenceDiagram
    participant Sender as Отправитель
    participant Receiver as Получатель
    participant Packet as Packet

    Sender->>Receiver: packet with invalid signature
    Receiver->>Packet: verify_signature()
    Packet-->>Receiver: InvalidSignature error
    Receiver->>Receiver: drop packet

    Sender->>Receiver: packet with expired TTL
    Receiver->>Packet: is_expired()
    Packet-->>Receiver: true
    Receiver->>Receiver: drop packet

    Sender->>Receiver: duplicate message_id
    Receiver->>Receiver: check dedup cache
    Receiver-->>Receiver: already seen
    Receiver->>Receiver: drop packet
```

## Performance Considerations

### Fast Path (BLE, локальная сеть)
- Direct packet forwarding
- Minimal encryption overhead
- No storage for transit packets

### Slow Path (Store & Forward)
- Persistent storage
- TTL management
- Background forwarding when transport available

### Gossip Path (синхронизация)
- Digest-based exchange
- Only missing messages
- Background periodic sync