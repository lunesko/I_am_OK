import 'package:flutter/material.dart';
// import 'package:flutter_nearby_connections/flutter_nearby_connections.dart'; // Тимчасово вимкнено
import '../services/meshgram/nearby_connections_stub.dart' as nearby;
import '../services/meshgram/meshgram_poc_service.dart';
import '../theme/app_theme.dart';

/// Екран для тестування MeshGram PoC (Wi-Fi Direct).
/// Демонстрація передачі повідомлень між двома пристроями.
class MeshGramPoCScreen extends StatefulWidget {
  const MeshGramPoCScreen({super.key});

  @override
  State<MeshGramPoCScreen> createState() => _MeshGramPoCScreenState();
}

class _MeshGramPoCScreenState extends State<MeshGramPoCScreen> {
  final MeshGramPoCService _service = MeshGramPoCService();
  final TextEditingController _messageController = TextEditingController();
  List<nearby.Device> _devices = [];
  List<String> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      await _service.initialize();
      _service.devicesStream.listen((devices) {
        if (mounted) setState(() => _devices = devices);
      });
      _service.messagesStream.listen((message) {
        if (mounted && message.isNotEmpty) {
          setState(() => _messages.add(message));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка ініціалізації: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _service.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _startAdvertising() async {
    try {
      await _service.startAdvertising();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📡 Реклама запущена (цей пристрій видимий)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }
  
  Future<void> _startDiscovering() async {
    try {
      await _service.startDiscovering();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔍 Пошук запущено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }
  
  Future<void> _connectToDevice(nearby.Device device) async {
    try {
      await _service.connectToDevice(device);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка підключення: $e')),
        );
      }
    }
  }
  
  Future<void> _sendMessage(String deviceId) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    try {
      await _service.sendMessage(deviceId, message);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка відправки: $e')),
        );
      }
    }
  }
  
  Future<void> _sendTestCheckin(String deviceId) async {
    try {
      await _service.sendTestCheckin(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Тестовий чек-ін "Я ОК" відправлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeshGram PoC'),
        backgroundColor: AppTheme.cardWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Інструкція
            _buildInfoCard(),
            const SizedBox(height: 16),
            
            // Кнопки управління
            _buildControlButtons(),
            const SizedBox(height: 16),
            
            // Список пристроїв
            _buildDevicesList(),
            const SizedBox(height: 16),
            
            // Відправка повідомлення
            _buildMessageInput(),
            const SizedBox(height: 16),
            
            // Повідомлення
            _buildMessagesList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      color: AppTheme.backgroundGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Як тестувати', style: AppTheme.h2),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. На обох пристроях натисни "Реклама" (Advertising)\n'
              '2. На одному з них натисни "Пошук" (Discovering)\n'
              '3. Підключися до знайденого пристрою\n'
              '4. Відправ тестове повідомлення або чек-ін',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _service.isAdvertising ? null : _startAdvertising,
            icon: const Icon(Icons.cast),
            label: const Text('Реклама'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _service.isAdvertising ? Colors.grey : Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _service.isDiscovering ? null : _startDiscovering,
            icon: const Icon(Icons.search),
            label: const Text('Пошук'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _service.isDiscovering ? Colors.grey : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDevicesList() {
    if (_devices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Пристроїв не знайдено',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Знайдені пристрої (${_devices.length})',
              style: AppTheme.h2,
            ),
          ),
          ..._devices.map((device) => _buildDeviceItem(device)),
        ],
      ),
    );
  }
  
  Widget _buildDeviceItem(nearby.Device device) {
    final isConnected = device.state == nearby.SessionState.connected;
    
    return ListTile(
      leading: Icon(
        isConnected ? Icons.link : Icons.link_off,
        color: isConnected ? Colors.green : Colors.grey,
      ),
      title: Text(device.deviceName),
      subtitle: Text(device.deviceId.substring(0, 8)),
      trailing: isConnected
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendTestCheckin(device.deviceId),
                  tooltip: 'Відправити "Я ОК"',
                ),
              ],
            )
          : ElevatedButton(
              onPressed: () => _connectToDevice(device),
              child: const Text('Підключитися'),
            ),
    );
  }
  
  Widget _buildMessageInput() {
    final connectedDevices = _devices.where(
      (d) => d.state == nearby.SessionState.connected,
    ).toList();
    
    if (connectedDevices.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Відправити повідомлення', style: AppTheme.h2),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введіть повідомлення',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (connectedDevices.isNotEmpty) {
                      _sendMessage(connectedDevices.first.deviceId);
                    }
                  },
                  child: const Text('Відправити'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Повідомлень немає',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Повідомлення (${_messages.length})',
                  style: AppTheme.h2,
                ),
                TextButton(
                  onPressed: () {
                    _service.clearMessages();
                    setState(() => _messages.clear());
                  },
                  child: const Text('Очистити'),
                ),
              ],
            ),
          ),
          ..._messages.reversed.map((msg) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.startsWith('→')
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        msg.startsWith('→') ? Icons.send : Icons.download,
                        size: 16,
                        color: msg.startsWith('→') ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
