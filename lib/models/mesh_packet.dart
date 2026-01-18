import 'dart:typed_data';

/// Пакет для Store & Forward у mesh-мережі.
class MeshPacket {
  final String id;
  final Uint8List payload; // зашифровані дані (Checkin або інше)
  final String recipientId;
  final int ttl; // Time to live: години (напр. 24)
  final int hopCount;
  final int maxHops;
  final DateTime timestamp;
  final List<String> routePath;

  const MeshPacket({
    required this.id,
    required this.payload,
    required this.recipientId,
    this.ttl = 24,
    this.hopCount = 0,
    this.maxHops = 10,
    required this.timestamp,
    this.routePath = const [],
  });

  /// Чи протерміновано пакет (TTL у годинах).
  bool get isExpired {
    final age = DateTime.now().difference(timestamp);
    return age.inHours >= ttl;
  }

  MeshPacket copyWith({
    int? hopCount,
    List<String>? routePath,
  }) {
    return MeshPacket(
      id: id,
      payload: payload,
      recipientId: recipientId,
      ttl: ttl,
      hopCount: hopCount ?? this.hopCount,
      maxHops: maxHops,
      timestamp: timestamp,
      routePath: routePath ?? this.routePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payload': payload.toList(),
        'recipientId': recipientId,
        'ttl': ttl,
        'hopCount': hopCount,
        'maxHops': maxHops,
        'timestamp': timestamp.toIso8601String(),
        'routePath': routePath,
      };

  factory MeshPacket.fromJson(Map<String, dynamic> json) {
    return MeshPacket(
      id: json['id'] ?? '',
      payload: Uint8List.fromList(
        List<int>.from(json['payload'] ?? []),
      ),
      recipientId: json['recipientId'] ?? '',
      ttl: json['ttl'] ?? 24,
      hopCount: json['hopCount'] ?? 0,
      maxHops: json['maxHops'] ?? 10,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      routePath: List<String>.from(json['routePath'] ?? []),
    );
  }
}
