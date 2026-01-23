// ============================================================
// ФАЙЛОВА СТРУКТУРА ПРОЄКТУ
// ============================================================
// lib/
// ├── main.dart
// ├── models/
// │   ├── user_model.dart
// │   ├── checkin_model.dart
// │   └── contact_model.dart
// ├── services/
// │   ├── auth_service.dart
// │   ├── firestore_service.dart
// │   ├── notification_service.dart
// │   └── local_storage_service.dart
// ├── screens/
// │   ├── auth_screen.dart
// │   ├── biometric_screen.dart
// │   ├── main_screen.dart
// │   ├── family_screen.dart
// │   └── settings_screen.dart
// └── widgets/
//     └── custom_widgets.dart

// ============================================================
// pubspec.yaml - ДОДАТИ ЦІ ЗАЛЕЖНОСТІ
// ============================================================
/*
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.9
  
  # State Management
  provider: ^6.1.1
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  
  # Биометрия
  local_auth: ^2.1.8
  
  # UI/UX
  flutter_local_notifications: ^16.3.0
  
  # Utils
  intl: ^0.18.1
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
*/

// ============================================================
// models/user_model.dart
// ============================================================
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;
  final List<String> contactIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
    this.contactIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      contactIds: List<String>.from(json['contactIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'contactIds': contactIds,
    };
  }
}

// ============================================================
// models/checkin_model.dart
// ============================================================
class CheckinModel {
  final String id;
  final String userId;
  final String status; // 'ok', 'busy', 'later', 'hug'
  final DateTime timestamp;
  final bool synced;
  final List<String> recipientIds;
  final Map<String, bool> readBy; // userId: hasRead

  CheckinModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.timestamp,
    this.synced = false,
    required this.recipientIds,
    this.readBy = const {},
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'ok',
      timestamp: DateTime.parse(json['timestamp']),
      synced: json['synced'] ?? false,
      recipientIds: List<String>.from(json['recipientIds'] ?? []),
      readBy: Map<String, bool>.from(json['readBy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
      'recipientIds': recipientIds,
      'readBy': readBy,
    };
  }

  CheckinModel copyWith({bool? synced}) {
    return CheckinModel(
      id: id,
      userId: userId,
      status: status,
      timestamp: timestamp,
      synced: synced ?? this.synced,
      recipientIds: recipientIds,
      readBy: readBy,
    );
  }
}

// ============================================================
// models/contact_model.dart
// ============================================================
class ContactModel {
  final String id;
  final String name;
  final String? avatar;
  final String? pushToken;
  final DateTime? lastCheckin;
  final bool isActive;

  ContactModel({
    required this.id,
    required this.name,
    this.avatar,
    this.pushToken,
    this.lastCheckin,
    this.isActive = true,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      pushToken: json['pushToken'],
      lastCheckin: json['lastCheckin'] != null 
          ? DateTime.parse(json['lastCheckin'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'pushToken': pushToken,
      'lastCheckin': lastCheckin?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

// ============================================================
// services/auth_service.dart
// ============================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Поточний користувач
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Симуляція входу через Дія ID (в реальності - OAuth 2.0)
  Future<UserCredential?> signInWithDiaID(String email, String name) async {
    try {
      // В production тут буде OAuth flow з Дія ID
      // Зараз використовуємо email/password для тестування
      
      UserCredential credential;
      
      try {
        // Спробувати увійти
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: 'diaid_temp_password', // Тимчасовий пароль
        );
      } catch (e) {
        // Якщо користувача немає - створити
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: 'diaid_temp_password',
        );
        
        // Створити профіль у Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
          'contactIds': [],
        });
      }
      
      return credential;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }

  // Симуляція входу через BankID
  Future<UserCredential?> signInWithBankID(String phone, String name) async {
    try {
      // В production - інтеграція з BankID API
      final email = '$phone@bankid.temp'; // Тимчасово
      return await signInWithDiaID(email, name);
    } catch (e) {
      print('BankID auth error: $e');
      return null;
    }
  }

  // Вихід
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Видалення акаунту
  Future<void> deleteAccount() async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    try {
      // Видалити дані з Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Видалити всі чекіни
      final checkins = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in checkins.docs) {
        await doc.reference.delete();
      }
      
      // Видалити акаунт Firebase Auth
      await currentUser?.delete();
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }
}

// ============================================================
// services/firestore_service.dart
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Зберегти чекін
  Future<void> saveCheckin(CheckinModel checkin) async {
    try {
      await _firestore.collection('checkins').doc(checkin.id).set(
        checkin.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Save checkin error: $e');
      rethrow;
    }
  }

  // Отримати останній чекін користувача
  Future<CheckinModel?> getLastCheckin(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CheckinModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      print('Get last checkin error: $e');
      return null;
    }
  }

  // Отримати чекіни для користувача (які він отримує від інших)
  Stream<List<CheckinModel>> getCheckinsForUser(String userId) {
    return _firestore
        .collection('checkins')
        .where('recipientIds', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CheckinModel.fromJson(doc.data()))
            .toList());
  }

  // Позначити чекін як прочитаний
  Future<void> markCheckinAsRead(String checkinId, String userId) async {
    try {
      await _firestore.collection('checkins').doc(checkinId).update({
        'readBy.$userId': true,
      });
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Додати контакт
  Future<void> addContact(String userId, String contactId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'contactIds': FieldValue.arrayUnion([contactId]),
      });
    } catch (e) {
      print('Add contact error: $e');
      rethrow;
    }
  }

  // Видалити контакт
  Future<void> removeContact(String userId, String contactId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'contactIds': FieldValue.arrayRemove([contactId]),
      });
    } catch (e) {
      print('Remove contact error: $e');
      rethrow;
    }
  }

  // Отримати інформацію про користувача
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // Оновити push-токен
  Future<void> updatePushToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'pushToken': token,
      });
    } catch (e) {
      print('Update push token error: $e');
    }
  }
}

// ============================================================
// services/notification_service.dart
// ============================================================
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Ініціалізація
  Future<void> initialize() async {
    // Запит дозволу на push-повідомлення
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notifications permission granted');
      
      // Отримати токен
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      // Зберегти токен у Firestore
      if (token != null) {
        // AuthService().currentUser?.uid
        // FirestoreService().updatePushToken(userId, token);
      }
    }

    // Налаштування локальних сповіщень
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Обробка натискання на сповіщення
        print('Notification tapped: ${details.payload}');
      },
    );

    // Обробка повідомлень у foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Обробка повідомлень при натисканні (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Обробка повідомлення у foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Показати локальне сповіщення
    _showLocalNotification(
      title: message.notification?.title ?? 'Я ОК',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Обробка натискання на повідомлення
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    // Навігація до потрібного екрану
  }

  // Показати локальне сповіщення
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'yaok_channel',
      'Я ОК Notifications',
      channelDescription: 'Сповіщення про статус близьких',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Відправити push через Cloud Functions (backend потрібен)
  Future<void> sendCheckinNotification({
    required List<String> recipientIds,
    required String senderName,
    required String status,
  }) async {
    // В production: викликати Cloud Function для відправки push
    // Поки що - логування
    print('Sending notification to $recipientIds: $senderName - $status');
    
    // Приклад виклику Cloud Function:
    /*
    final response = await http.post(
      Uri.parse('https://your-cloud-function-url/sendNotification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipientIds': recipientIds,
        'title': 'Я ОК',
        'body': '$senderName: ${_getStatusText(status)}',
        'data': {'type': 'checkin', 'status': status},
      }),
    );
    */
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ok': return '💚 Я ОК';
      case 'busy': return '💛 Все нормально, зайнятий';
      case 'later': return '💙 Зателефоную пізніше';
      case 'hug': return '🤍 Обійми';
      default: return 'Новий статус';
    }
  }

  // Планувати нагадування
  Future<void> scheduleReminder(DateTime time) async {
    // Використовувати flutter_local_notifications для планування
    print('Reminder scheduled for $time');
  }
}

// ============================================================
// services/local_storage_service.dart (OFFLINE MODE)
// ============================================================
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LocalStorageService {
  static const String _checkinsBox = 'pending_checkins';
  late Box<Map> _box;

  // Ініціалізація Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_checkinsBox);
  }

  // Зберегти чекін локально (offline)
  Future<void> savePendingCheckin(CheckinModel checkin) async {
    try {
      await _box.put(checkin.id, checkin.toJson());
      print('Checkin saved locally: ${checkin.id}');
    } catch (e) {
      print('Local save error: $e');
    }
  }

  // Отримати всі несинхронізовані чекіни
  List<CheckinModel> getPendingCheckins() {
    try {
      return _box.values
          .map((json) => CheckinModel.fromJson(Map<String, dynamic>.from(json)))
          .where((checkin) => !checkin.synced)
          .toList();
    } catch (e) {
      print('Get pending checkins error: $e');
      return [];
    }
  }

  // Видалити чекін після синхронізації
  Future<void> removePendingCheckin(String checkinId) async {
    await _box.delete(checkinId);
  }

  // Синхронізувати всі чекіни при появі інтернету
  Future<void> syncPendingCheckins(FirestoreService firestoreService) async {
    final connectivity = await Connectivity().checkConnectivity();
    
    if (connectivity == ConnectivityResult.none) {
      print('No internet connection');
      return;
    }

    final pending = getPendingCheckins();
    print('Syncing ${pending.length} pending checkins...');

    for (var checkin in pending) {
      try {
        await firestoreService.saveCheckin(checkin);
        await _box.put(checkin.id, checkin.copyWith(synced: true).toJson());
        print('Synced checkin: ${checkin.id}');
      } catch (e) {
        print('Sync error for ${checkin.id}: $e');
      }
    }
  }

  // Автоматична синхронізація при з'єднанні
  void startAutoSync(FirestoreService firestoreService) {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('Internet connected, syncing...');
        syncPendingCheckins(firestoreService);
      }
    });
  }
}

// ============================================================
// main.dart - ГОЛОВНИЙ ФАЙЛ З ІНТЕГРАЦІЄЮ
// ============================================================
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Ініціалізація Firebase (потрібен firebase_options.dart)
// Створюється командою: flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase
  await Firebase.initializeApp();
  
  // Local Storage
  final localStorage = LocalStorageService();
  await localStorage.initialize();
  
  // Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => notificationService),
        Provider<LocalStorageService>(create: (_) => localStorage),
      ],
      child: const YaOkApp(),
    ),
  );
}

class YaOkApp extends StatelessWidget {
  const YaOkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return MaterialApp(
      title: 'Я ОК',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        fontFamily: 'e-Ukraine',
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            return const MainScreen();
          }
          
          return const AuthScreen();
        },
      ),
    );
  }
}

// ============================================================
// ІНСТРУКЦІЇ ДЛЯ НАЛАШТУВАННЯ
// ============================================================
/*

1. НАЛАШТУВАННЯ FIREBASE:

   flutter pub global activate flutterfire_cli
   flutterfire configure

2. ДОДАТИ firebase_options.dart до .gitignore

3. НАЛАШТУВАТИ FIREBASE CONSOLE:
   - Authentication: Enable Email/Password
   - Firestore: Create database
   - Cloud Messaging: Enable
   - Додати SHA-1 для Android

4. СТРУКТУРА FIRESTORE:

   users/
   └── {userId}/
       ├── id: string
       ├── name: string
       ├── email: string
       ├── createdAt: timestamp
       ├── contactIds: array
       └── pushToken: string
   
   checkins/
   └── {checkinId}/
       ├── userId: string
       ├── status: string
       ├── timestamp: timestamp
       ├── recipientIds: array
       ├── readBy: map
       └── synced: boolean

5. ДОДАТИ PERMISSIONS:

   Android (AndroidManifest.xml):
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   
   iOS (Info.plist):
   <key>NSFaceIDUsageDescription</key>
   <string>Для безпечного входу в додаток</string>

6. CLOUD FUNCTIONS (backend для push-ів):
   
   Створити в Firebase Console → Functions
   Або розгорнути Node.js функцію для відправки FCM

ГОТОВО! 🚀
*/