import 'meshgram_enums.dart';

/// Вузол mesh-мережі (пристрій поблизу).
class MeshNode {
  final String nodeId;
  final String? userName;
  final DateTime lastSeen;
  final int signalStrength; // RSSI -100..0
  final MeshConnectionType type;
  final bool isRelay;
  final int batteryLevel; // 0..100
  final List<String> knownRoutes;

  const MeshNode({
    required this.nodeId,
    this.userName,
    required this.lastSeen,
    this.signalStrength = -100,
    required this.type,
    this.isRelay = true,
    this.batteryLevel = 100,
    this.knownRoutes = const [],
  });

  MeshNode copyWith({
    String? userName,
    DateTime? lastSeen,
    int? signalStrength,
    bool? isRelay,
    int? batteryLevel,
    List<String>? knownRoutes,
  }) {
    return MeshNode(
      nodeId: nodeId,
      userName: userName ?? this.userName,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
      type: type,
      isRelay: isRelay ?? this.isRelay,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      knownRoutes: knownRoutes ?? this.knownRoutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'userName': userName,
        'lastSeen': lastSeen.toIso8601String(),
        'signalStrength': signalStrength,
        'type': type.value,
        'isRelay': isRelay,
        'batteryLevel': batteryLevel,
        'knownRoutes': knownRoutes,
      };

  factory MeshNode.fromJson(Map<String, dynamic> json) {
    return MeshNode(
      nodeId: json['nodeId'] ?? '',
      userName: json['userName'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      signalStrength: json['signalStrength'] ?? -100,
      type: meshConnectionTypeFromString(json['type']?.toString()),
      isRelay: json['isRelay'] ?? true,
      batteryLevel: json['batteryLevel'] ?? 100,
      knownRoutes: List<String>.from(json['knownRoutes'] ?? []),
    );
  }
}
