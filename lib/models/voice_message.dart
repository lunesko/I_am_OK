import 'dart:typed_data';

import 'meshgram_enums.dart';

/// Один пакет голосового повідомлення для передачі через mesh (256 байт).
class VoicePacket {
  final String messageId;
  final int index;
  final Uint8List encryptedData;
  final String checksum; // SHA-256
  final bool received;
  final DateTime? receivedAt;

  const VoicePacket({
    required this.messageId,
    required this.index,
    required this.encryptedData,
    required this.checksum,
    this.received = false,
    this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'index': index,
        'encryptedData': encryptedData.toList(),
        'checksum': checksum,
        'received': received,
        'receivedAt': receivedAt?.toIso8601String(),
      };

  factory VoicePacket.fromJson(Map<String, dynamic> json) {
    return VoicePacket(
      messageId: json['messageId'] ?? '',
      index: json['index'] ?? 0,
      encryptedData: Uint8List.fromList(
        List<int>.from(json['encryptedData'] ?? []),
      ),
      checksum: json['checksum'] ?? '',
      received: json['received'] ?? false,
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'].toString())
          : null,
    );
  }
}

/// Голосове повідомлення (запис, відправка, отримання через Mesh/Firebase).
class VoiceMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final int durationMs;
  final DateTime timestamp;
  final TransportType transport;
  final List<VoicePacket> packets;
  final int totalPackets;
  final int receivedPackets;
  final String codecType; // "opus"
  final int bitrate; // 8000 bps
  final bool isEncrypted;
  final VoiceMessageStatus status;

  const VoiceMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.durationMs,
    required this.timestamp,
    required this.transport,
    required this.packets,
    required this.totalPackets,
    required this.receivedPackets,
    this.codecType = 'opus',
    this.bitrate = 8000,
    this.isEncrypted = true,
    required this.status,
  });

  VoiceMessage copyWith({
    List<VoicePacket>? packets,
    int? receivedPackets,
    VoiceMessageStatus? status,
  }) {
    return VoiceMessage(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      durationMs: durationMs,
      timestamp: timestamp,
      transport: transport,
      packets: packets ?? this.packets,
      totalPackets: totalPackets,
      receivedPackets: receivedPackets ?? this.receivedPackets,
      codecType: codecType,
      bitrate: bitrate,
      isEncrypted: isEncrypted,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'transport': transport.value,
        'packets': packets.map((p) => p.toJson()).toList(),
        'totalPackets': totalPackets,
        'receivedPackets': receivedPackets,
        'codecType': codecType,
        'bitrate': bitrate,
        'isEncrypted': isEncrypted,
        'status': status.name,
      };

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      transport: _parseTransport(json['transport']),
      packets: (json['packets'] as List<dynamic>?)
              ?.map((e) => VoicePacket.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      totalPackets: json['totalPackets'] ?? 0,
      receivedPackets: json['receivedPackets'] ?? 0,
      codecType: json['codecType'] ?? 'opus',
      bitrate: json['bitrate'] ?? 8000,
      isEncrypted: json['isEncrypted'] ?? true,
      status: _parseStatus(json['status']),
    );
  }

  static TransportType _parseTransport(dynamic v) {
    if (v == null) return TransportType.FIREBASE;
    final s = v.toString();
    if (s == 'MESHGRAM') return TransportType.MESHGRAM;
    if (s == 'HYBRID') return TransportType.HYBRID;
    return TransportType.FIREBASE;
  }

  static VoiceMessageStatus _parseStatus(dynamic v) {
    if (v == null) return VoiceMessageStatus.RECORDING;
    final s = v.toString().toUpperCase();
    for (final e in VoiceMessageStatus.values) {
      if (e.name == s) return e;
    }
    return VoiceMessageStatus.RECORDING;
  }
}
