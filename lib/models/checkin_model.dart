import 'meshgram_enums.dart';

class CheckinModel {
  final String id;
  final String userId;
  final String status; // 'ok', 'busy', 'later', 'hug' — для сумісності з Firestore
  final DateTime timestamp;
  final bool synced;
  final List<String> recipientIds;
  final Map<String, bool> readBy; // userId: hasRead

  // MeshGram — опціональні поля
  final String? textMessage;
  final TransportType transport;
  final int? hopCount;
  final List<String>? routePath;
  final String? voiceMessageId;

  CheckinModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.timestamp,
    this.synced = false,
    required this.recipientIds,
    this.readBy = const {},
    this.textMessage,
    this.transport = TransportType.FIREBASE,
    this.hopCount,
    this.routePath,
    this.voiceMessageId,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'ok',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      synced: json['synced'] ?? false,
      recipientIds: List<String>.from(json['recipientIds'] ?? []),
      readBy: Map<String, bool>.from(json['readBy'] ?? {}),
      textMessage: json['textMessage'],
      transport: transportTypeFromString(json['transport']?.toString()),
      hopCount: json['hopCount'],
      routePath: json['routePath'] != null
          ? List<String>.from(json['routePath'])
          : null,
      voiceMessageId: json['voiceMessageId'],
    );
  }

  factory CheckinModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CheckinModel(
      id: id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'ok',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      synced: data['synced'] ?? false,
      recipientIds: List<String>.from(data['recipientIds'] ?? []),
      readBy: Map<String, bool>.from(data['readBy'] ?? {}),
      textMessage: data['textMessage'],
      transport: transportTypeFromString(data['transport']?.toString()),
      hopCount: data['hopCount'],
      routePath: data['routePath'] != null
          ? List<String>.from(data['routePath'])
          : null,
      voiceMessageId: data['voiceMessageId'],
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'userId': userId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
      'recipientIds': recipientIds,
      'readBy': readBy,
    };
    if (textMessage != null) m['textMessage'] = textMessage;
    if (transport != TransportType.FIREBASE) m['transport'] = transport.value;
    if (hopCount != null) m['hopCount'] = hopCount;
    if (routePath != null && routePath!.isNotEmpty) m['routePath'] = routePath;
    if (voiceMessageId != null) m['voiceMessageId'] = voiceMessageId;
    return m;
  }

  Map<String, dynamic> toFirestore() {
    final m = <String, dynamic>{
      'userId': userId,
      'status': status,
      'timestamp': timestamp,
      'synced': synced,
      'recipientIds': recipientIds,
      'readBy': readBy,
    };
    if (textMessage != null) m['textMessage'] = textMessage;
    if (transport != TransportType.FIREBASE) m['transport'] = transport.value;
    if (hopCount != null) m['hopCount'] = hopCount;
    if (routePath != null && routePath!.isNotEmpty) m['routePath'] = routePath;
    if (voiceMessageId != null) m['voiceMessageId'] = voiceMessageId;
    return m;
  }

  CheckinModel copyWith({
    bool? synced,
    Map<String, bool>? readBy,
    String? textMessage,
    TransportType? transport,
    int? hopCount,
    List<String>? routePath,
    String? voiceMessageId,
  }) {
    return CheckinModel(
      id: id,
      userId: userId,
      status: status,
      timestamp: timestamp,
      synced: synced ?? this.synced,
      recipientIds: recipientIds,
      readBy: readBy ?? this.readBy,
      textMessage: textMessage ?? this.textMessage,
      transport: transport ?? this.transport,
      hopCount: hopCount ?? this.hopCount,
      routePath: routePath ?? this.routePath,
      voiceMessageId: voiceMessageId ?? this.voiceMessageId,
    );
  }

  String get statusEmoji {
    switch (status) {
      case 'ok':
        return '💚';
      case 'busy':
        return '💛';
      case 'later':
        return '💙';
      case 'hug':
        return '🤍';
      default:
        return '💚';
    }
  }

  String get statusText {
    switch (status) {
      case 'ok':
        return 'Я ОК';
      case 'busy':
        return 'Все нормально, зайнятий';
      case 'later':
        return 'Зателефоную пізніше';
      case 'hug':
        return 'Обійми';
      default:
        return 'Я ОК';
    }
  }
}
