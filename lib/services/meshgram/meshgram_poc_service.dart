import 'dart:async';
// import 'package:flutter_nearby_connections/flutter_nearby_connections.dart'; // Тимчасово вимкнено
import 'nearby_connections_stub.dart' as nearby;

/// MeshGram PoC: мінімальна реалізація Wi-Fi Direct для демонстрації.
/// Використовує Google Nearby Connections API (підтримує Wi-Fi Direct, Bluetooth, BLE).
class MeshGramPoCService {
  static const String serviceId = 'com.poruch.yaok.meshgram';
  
  nearby.NearbyService? _nearbyService;
  StreamSubscription? _subscription;
  final List<nearby.Device> _devices = [];
  final List<String> _messages = [];
  
  List<nearby.Device> get devices => List.unmodifiable(_devices);
  List<String> get messages => List.unmodifiable(_messages);
  
  StreamController<List<Device>>? _devicesController;
  StreamController<String>? _messagesController;
  
  Stream<List<nearby.Device>> get devicesStream => _devicesController?.stream ?? const Stream.empty();
  Stream<String> get messagesStream => _messagesController?.stream ?? const Stream.empty();
  
  bool _isInitialized = false;
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  
  bool get isInitialized => _isInitialized;
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  
  /// Ініціалізація Nearby Service.
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _nearbyService = nearby.NearbyService();
      _devicesController = StreamController<List<nearby.Device>>.broadcast();
      _messagesController = StreamController<String>.broadcast();
      
      _isInitialized = true;
      print('✅ MeshGram PoC: Initialized');
    } catch (e) {
      print('❌ MeshGram PoC: Initialize error: $e');
      rethrow;
    }
  }
  
  /// Почати рекламу (цей пристрій буде видимий для інших).
  Future<void> startAdvertising() async {
    if (!_isInitialized || _isAdvertising) return;
    
    try {
      await _nearbyService!.startAdvertising(
        serviceId,
        strategy: nearby.Strategy.P2P_STAR,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      
      _isAdvertising = true;
      print('📡 MeshGram PoC: Started advertising');
    } catch (e) {
      print('❌ MeshGram PoC: Start advertising error: $e');
      rethrow;
    }
  }
  
  /// Почати пошук інших пристроїв.
  Future<void> startDiscovering() async {
    if (!_isInitialized || _isDiscovering) return;
    
    try {
      await _nearbyService!.startDiscovery(
        serviceId,
        strategy: nearby.Strategy.P2P_STAR,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
      
      _isDiscovering = true;
      print('🔍 MeshGram PoC: Started discovering');
    } catch (e) {
      print('❌ MeshGram PoC: Start discovering error: $e');
      rethrow;
    }
  }
  
  /// Зупинити рекламу.
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    
    try {
      await _nearbyService!.stopAdvertising();
      _isAdvertising = false;
      print('📡 MeshGram PoC: Stopped advertising');
    } catch (e) {
      print('❌ MeshGram PoC: Stop advertising error: $e');
    }
  }
  
  /// Зупинити пошук.
  Future<void> stopDiscovering() async {
    if (!_isDiscovering) return;
    
    try {
      await _nearbyService!.stopDiscovery();
      _isDiscovering = false;
      print('🔍 MeshGram PoC: Stopped discovering');
    } catch (e) {
      print('❌ MeshGram PoC: Stop discovering error: $e');
    }
  }
  
  /// Підключитися до пристрою.
  Future<void> connectToDevice(nearby.Device device) async {
    try {
      await _nearbyService!.requestConnection(
        device.deviceId,
        serviceId,
        onConnectionInitiated: _onConnectionInitiated,
      );
      print('🔗 MeshGram PoC: Connection requested to ${device.deviceName}');
    } catch (e) {
      print('❌ MeshGram PoC: Connect error: $e');
      rethrow;
    }
  }
  
  /// Відправити повідомлення до пристрою.
  Future<void> sendMessage(String deviceId, String message) async {
    try {
      await _nearbyService!.sendMessage(
        deviceId,
        message,
      );
      _messages.add('→ $message');
      _messagesController?.add('→ $message');
      print('📤 MeshGram PoC: Sent message to $deviceId: $message');
    } catch (e) {
      print('❌ MeshGram PoC: Send message error: $e');
      rethrow;
    }
  }
  
  /// Відправити тестовий чек-ін "Я ОК".
  Future<void> sendTestCheckin(String deviceId) async {
    final checkin = '{"type":"checkin","status":"ok","timestamp":"${DateTime.now().toIso8601String()}"}';
    await sendMessage(deviceId, checkin);
  }
  
  /// Обробка знайденого пристрою.
  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    print('🔍 MeshGram PoC: Found device: $endpointName ($endpointId)');
    
    final device = nearby.Device(
      deviceId: endpointId,
      deviceName: endpointName,
      state: nearby.SessionState.notConnected,
    );
    
    if (!_devices.any((d) => d.deviceId == endpointId)) {
      _devices.add(device);
      _devicesController?.add(_devices);
    }
  }
  
  /// Обробка втраченого пристрою.
  void _onEndpointLost(String endpointId) {
    print('🔍 MeshGram PoC: Lost device: $endpointId');
    _devices.removeWhere((d) => d.deviceId == endpointId);
    _devicesController?.add(_devices);
  }
  
  /// Обробка ініціалізації з'єднання.
  void _onConnectionInitiated(String endpointId, nearby.ConnectionInfo info) {
    print('🔗 MeshGram PoC: Connection initiated with $endpointId');
    
    // Автоматично приймаємо з'єднання
    _nearbyService!.acceptConnection(
      endpointId,
      onPayLoadRecived: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }
  
  /// Обробка результату з'єднання.
  void _onConnectionResult(String endpointId, nearby.Status status) {
    print('🔗 MeshGram PoC: Connection result: $status');
    
    final device = _devices.firstWhere(
      (d) => d.deviceId == endpointId,
      orElse: () => nearby.Device(
        deviceId: endpointId,
        deviceName: 'Unknown',
        state: nearby.SessionState.notConnected,
      ),
    );
    
    final index = _devices.indexOf(device);
    if (index != -1) {
      _devices[index] = nearby.Device(
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        state: status == nearby.Status.CONNECTED
            ? nearby.SessionState.connected
            : nearby.SessionState.notConnected,
      );
      _devicesController?.add(_devices);
    }
  }
  
  /// Обробка роз'єднання.
  void _onDisconnected(String endpointId) {
    print('🔌 MeshGram PoC: Disconnected from $endpointId');
    
    final index = _devices.indexWhere((d) => d.deviceId == endpointId);
    if (index != -1) {
      _devices[index] = nearby.Device(
        deviceId: _devices[index].deviceId,
        deviceName: _devices[index].deviceName,
        state: nearby.SessionState.notConnected,
      );
      _devicesController?.add(_devices);
    }
  }
  
  /// Обробка отриманого повідомлення.
  void _onPayloadReceived(String endpointId, nearby.Payload payload) {
    if (payload.type == nearby.PayloadType.BYTES) {
      final message = String.fromCharCodes(payload.bytes!);
      _messages.add('← $message');
      _messagesController?.add('← $message');
      print('📥 MeshGram PoC: Received message from $endpointId: $message');
    }
  }
  
  /// Обробка оновлення передачі.
  void _onPayloadTransferUpdate(String endpointId, nearby.PayloadTransferUpdate update) {
    // Можна показати прогрес передачі великих файлів
    print('📊 MeshGram PoC: Transfer update: ${update.status}');
  }
  
  /// Очистити список повідомлень.
  void clearMessages() {
    _messages.clear();
    _messagesController?.add('');
  }
  
  /// Зупинити всі операції та очистити ресурси.
  Future<void> dispose() async {
    await stopAdvertising();
    await stopDiscovering();
    await _subscription?.cancel();
    await _devicesController?.close();
    await _messagesController?.close();
    _devices.clear();
    _messages.clear();
    _isInitialized = false;
    print('🧹 MeshGram PoC: Disposed');
  }
}
