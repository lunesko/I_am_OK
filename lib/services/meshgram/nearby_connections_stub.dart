// Заглушка для flutter_nearby_connections
// Використовується, коли пакет тимчасово вимкнено через проблеми з AGP 8.x

/// Заглушка для Device
class Device {
  final String deviceId;
  final String deviceName;
  final SessionState state;

  Device({
    required this.deviceId,
    required this.deviceName,
    required this.state,
  });
}

/// Заглушка для SessionState
enum SessionState {
  notConnected,
  connecting,
  connected,
}

/// Заглушка для NearbyService
class NearbyService {
  Future<void> startAdvertising(
    String serviceId, {
    required Strategy strategy,
    required Function(String, ConnectionInfo) onConnectionInitiated,
    required Function(String, Status) onConnectionResult,
    required Function(String) onDisconnected,
  }) async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> startDiscovery(
    String serviceId, {
    required Strategy strategy,
    required Function(String, String, String) onEndpointFound,
    required Function(String) onEndpointLost,
  }) async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> stopAdvertising() async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> stopDiscovery() async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> requestConnection(
    String endpointId,
    String serviceId, {
    required Function(String, ConnectionInfo) onConnectionInitiated,
  }) async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> acceptConnection(
    String endpointId, {
    required Function(String, Payload) onPayLoadRecived,
    required Function(String, PayloadTransferUpdate) onPayloadTransferUpdate,
  }) async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }

  Future<void> sendMessage(String endpointId, String message) async {
    throw UnimplementedError('flutter_nearby_connections is disabled');
  }
}

/// Заглушка для Strategy
enum Strategy {
  P2P_STAR,
  P2P_CLUSTER,
}

/// Заглушка для ConnectionInfo
class ConnectionInfo {
  final String endpointName;
  final String authenticationToken;

  ConnectionInfo({
    required this.endpointName,
    required this.authenticationToken,
  });
}

/// Заглушка для Status
enum Status {
  CONNECTED,
  REJECTED,
  ERROR,
}

/// Заглушка для Payload
class Payload {
  final PayloadType type;
  final List<int>? bytes;

  Payload({
    required this.type,
    this.bytes,
  });
}

/// Заглушка для PayloadType
enum PayloadType {
  BYTES,
  FILE,
  STREAM,
}

/// Заглушка для PayloadTransferUpdate
class PayloadTransferUpdate {
  final Status status;
  final int? bytesTransferred;
  final int? totalBytes;

  PayloadTransferUpdate({
    required this.status,
    this.bytesTransferred,
    this.totalBytes,
  });
}
