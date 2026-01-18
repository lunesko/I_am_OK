import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/checkin_model.dart';
import '../models/contact_model.dart';
import 'firestore_service.dart';

class LocalStorageService {
  static const String _checkinsBoxName = 'pending_checkins';
  static const String _contactsBoxName = 'contacts';
  static const String _settingsBoxName = 'settings';
  
  late Box<Map> _checkinsBox;
  late Box<Map> _contactsBox;
  late Box _settingsBox;

  // Ініціалізація Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
    _checkinsBox = await Hive.openBox<Map>(_checkinsBoxName);
    _contactsBox = await Hive.openBox<Map>(_contactsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // ============================================================
  // Чек-іни (Offline Mode)
  // ============================================================

  // Зберегти чекін локально (offline)
  Future<void> savePendingCheckin(CheckinModel checkin) async {
    try {
      await _checkinsBox.put(checkin.id, checkin.toJson());
      print('💾 Checkin saved locally: ${checkin.id}');
    } catch (e) {
      print('❌ Local save error: $e');
    }
  }

  // Отримати всі несинхронізовані чекіни
  List<CheckinModel> getPendingCheckins() {
    try {
      return _checkinsBox.values
          .map((json) => CheckinModel.fromJson(Map<String, dynamic>.from(json)))
          .where((checkin) => !checkin.synced)
          .toList();
    } catch (e) {
      print('❌ Get pending checkins error: $e');
      return [];
    }
  }

  // Отримати всі чекіни (синхронізовані та ні)
  List<CheckinModel> getAllCheckins() {
    try {
      return _checkinsBox.values
          .map((json) => CheckinModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('❌ Get all checkins error: $e');
      return [];
    }
  }

  // Видалити чекін після синхронізації
  Future<void> removePendingCheckin(String checkinId) async {
    await _checkinsBox.delete(checkinId);
  }

  // Позначити чекін як синхронізований
  Future<void> markCheckinAsSynced(String checkinId) async {
    try {
      final json = _checkinsBox.get(checkinId);
      if (json != null) {
        final checkin = CheckinModel.fromJson(Map<String, dynamic>.from(json));
        await _checkinsBox.put(checkinId, checkin.copyWith(synced: true).toJson());
      }
    } catch (e) {
      print('❌ Mark as synced error: $e');
    }
  }

  // ============================================================
  // Контакти
  // ============================================================

  // Зберегти контакт локально
  Future<void> saveContact(ContactModel contact) async {
    try {
      await _contactsBox.put(contact.id, contact.toJson());
      print('💾 Contact saved locally: ${contact.name}');
    } catch (e) {
      print('❌ Save contact error: $e');
    }
  }

  // Отримати всі контакти
  List<ContactModel> getContacts() {
    try {
      return _contactsBox.values
          .map((json) => ContactModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('❌ Get contacts error: $e');
      return [];
    }
  }

  // Видалити контакт
  Future<void> removeContact(String contactId) async {
    await _contactsBox.delete(contactId);
  }

  // ============================================================
  // Налаштування
  // ============================================================

  // Зберегти налаштування
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // Отримати налаштування
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // Видалити налаштування
  Future<void> removeSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // ============================================================
  // Синхронізація
  // ============================================================

  // Синхронізувати всі чекіни при появі інтернету
  Future<void> syncPendingCheckins(FirestoreService firestoreService) async {
    final connectivity = await Connectivity().checkConnectivity();
    
    if (connectivity == ConnectivityResult.none) {
      print('📡 No internet connection');
      return;
    }

    final pending = getPendingCheckins();
    if (pending.isEmpty) {
      print('✅ No pending checkins to sync');
      return;
    }

    print('🔄 Syncing ${pending.length} pending checkins...');

    for (var checkin in pending) {
      try {
        await firestoreService.saveCheckin(checkin);
        await markCheckinAsSynced(checkin.id);
        print('✅ Synced checkin: ${checkin.id}');
      } catch (e) {
        print('❌ Sync error for ${checkin.id}: $e');
      }
    }
  }

  // Автоматична синхронізація при з'єднанні
  void startAutoSync(FirestoreService firestoreService) {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('📡 Internet connected, syncing...');
        syncPendingCheckins(firestoreService);
      }
    });
  }

  // Очистити всі дані
  Future<void> clearAll() async {
    await _checkinsBox.clear();
    await _contactsBox.clear();
    await _settingsBox.clear();
  }
}
