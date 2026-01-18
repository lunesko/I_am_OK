import '../../models/checkin_model.dart';
import '../../models/mesh_node.dart';
import '../../models/mesh_packet.dart';

/// MeshGram: Store & Forward через Wi‑Fi Direct / BLE / LoRa.
/// Зараз — stub: scanNearbyNodes повертає [], sendMessage зберігає в чергу локально,
/// onMessageReceived — заглушка. Реальна реалізація — Phase 2.
class MeshGramTransport {
  /// Сканування сусідніх вузлів. Stub: порожній список.
  Future<List<MeshNode>> scanNearbyNodes() async {
    // TODO Phase 2: Wi-Fi Direct, BLE, LoRa
    return [];
  }

  /// Відправити чек-ін через mesh. Stub: зберігає для пізньої синхронізації.
  Future<void> sendCheckin(CheckinModel checkin) async {
    // TODO Phase 2: encrypt → MeshPacket → selectBestNode → send / storeForLater
    // Поки що нічого не робимо — при виборі MESHGRAM і відсутності вузлів
    // TransportRouter поверне LOCAL_QUEUE. Якщо вузлів немає, сюди не потрапимо.
    // Але якщо forceMeshMode=true, можуть викликати sendCheckin при 0 вузлів —
    // тоді поки що просто no-op (або зберігати в локальну чергу для майбутнього).
  }

  /// Обробити вхідний mesh-пакет (для нас — дешифрувати; для ретрансляції — forward).
  /// Stub: no-op.
  Future<void> onMessageReceived(MeshPacket packet) async {
    // TODO Phase 2: TTL check, for me? decrypt+notify : relay
  }
}
