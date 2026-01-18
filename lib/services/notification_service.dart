import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  bool _firebaseAvailable = false;

  // Callback для навігації при натисканні на сповіщення
  Function(RemoteMessage)? onNotificationTap;

  // Ініціалізація
  Future<void> initialize() async {
    // Перевірити, чи Firebase доступний
    try {
      _messaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;
    } catch (e) {
      print('⚠️ Firebase Messaging недоступний: $e');
      _firebaseAvailable = false;
    }

    // Якщо Firebase доступний - налаштувати FCM
    if (_firebaseAvailable && _messaging != null) {
      try {
        // Запит дозволу на push-повідомлення
        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ Notifications permission granted');
          
          // Отримати токен
          String? token = await _messaging!.getToken();
          print('📱 FCM Token: $token');
        }

        // Обробка повідомлень у foreground
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Обробка повідомлень при натисканні (app opened from notification)
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          _handleMessageOpenedApp(message);
        });

        // Обробка повідомлень при запуску зі сповіщення
        RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      } catch (e) {
        print('⚠️ Firebase Messaging помилка: $e');
        _firebaseAvailable = false;
      }
    } else {
      print('💡 Використовуються тільки локальні сповіщення');
    }

    // Налаштування локальних сповіщень (завжди доступні)
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
        print('🔔 Notification tapped: ${details.payload}');
      },
    );
  }

  // Отримати FCM токен
  Future<String?> getToken() async {
    if (!_firebaseAvailable || _messaging == null) {
      return null;
    }
    try {
      return await _messaging!.getToken();
    } catch (e) {
      print('❌ Get token error: $e');
      return null;
    }
  }

  // Обробка повідомлення у foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message: ${message.notification?.title}');
    
    // Показати локальне сповіщення
    _showLocalNotification(
      title: message.notification?.title ?? 'Я ОК',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Обробка натискання на повідомлення
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Message opened app: ${message.notification?.title}');
    if (onNotificationTap != null) {
      onNotificationTap!(message);
    }
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

  // Планувати нагадування (спрощена версія)
  Future<void> scheduleReminder({
    required DateTime time,
    required String title,
    required String body,
  }) async {
    // Для планування потрібен пакет timezone
    // Поки що - логування
    print('📅 Reminder scheduled for $time: $title - $body');
    
    // TODO: Додати планування через flutter_local_notifications з timezone
  }
}
