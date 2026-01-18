import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/checkin_model.dart';
import '../../models/meshgram_enums.dart';
import 'firebase_transport.dart';
import 'mesh_gram_transport.dart';

/// Вибір транспорту: Firebase (інтернет), MeshGram (mesh) або локальна черга.
/// Логіка згідно MESHGRAM_SPEC: forceMesh → mesh; hasInternet → firebase;
/// nearbyNodes → mesh; інакше → LOCAL_QUEUE.
class TransportRouter {
  final FirebaseTransport firebaseTransport;
  final MeshGramTransport meshGramTransport;

  bool forceMeshMode = false;

  TransportRouter({
    required this.firebaseTransport,
    required this.meshGramTransport,
  });

  /// Відправити чек-ін через обраний транспорт. Для LOCAL_QUEUE нічого не робить.
  /// Повертає тип транспорту, яким відправлено (null = не відправлено, лише черга).
  Future<TransportType?> sendCheckin(CheckinModel checkin) async {
    final t = await selectTransport();
    switch (t) {
      case TransportType.FIREBASE:
        await firebaseTransport.sendCheckin(
          checkin.copyWith(transport: TransportType.FIREBASE),
        );
        return TransportType.FIREBASE;
      case TransportType.MESHGRAM:
        await meshGramTransport.sendCheckin(
          checkin.copyWith(transport: TransportType.MESHGRAM),
        );
        return TransportType.MESHGRAM;
      case TransportType.LOCAL_QUEUE:
      case TransportType.HYBRID:
        return null;
    }
  }

  /// Визначає, який транспорт використовувати зараз.
  Future<TransportType> selectTransport() async {
    if (forceMeshMode) return TransportType.MESHGRAM;

    final result = await Connectivity().checkConnectivity();
    final hasInternet = result != ConnectivityResult.none;

    if (hasInternet) return TransportType.FIREBASE;

    final nearbyNodes = await meshGramTransport.scanNearbyNodes();
    if (nearbyNodes.isNotEmpty) return TransportType.MESHGRAM;

    return TransportType.LOCAL_QUEUE;
  }

  /// Стрім поточної зміни типу транспорту (для UI).
  Stream<TransportType> get transportStream async* {
    while (true) {
      yield await selectTransport();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  /// Кількість mesh-вузлів поблизу (для індикатора).
  Future<int> get nearbyMeshNodeCount async {
    final nodes = await meshGramTransport.scanNearbyNodes();
    return nodes.length;
  }

  /// Чи є інтернет.
  Future<bool> get hasInternet async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }
}
