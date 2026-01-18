import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Firebase options (створюється через flutterfire configure)
import 'firebase_options.dart';

// Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/local_storage_service.dart';
import 'services/transport/firebase_transport.dart';
import 'services/transport/mesh_gram_transport.dart';
import 'services/transport/transport_router.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';

// Theme
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase ініціалізація (опціонально)
  // УВАГА: Для повної роботи потрібно налаштувати firebase_options.dart
  bool firebaseInitialized = false;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // Перевіряємо, чи не placeholder значення
    if (options.apiKey != 'YOUR_ANDROID_API_KEY' && 
        options.appId != 'YOUR_ANDROID_APP_ID') {
      await Firebase.initializeApp(options: options);
      firebaseInitialized = true;
      print('✅ Firebase ініціалізовано');
    } else {
      print('⚠️ Firebase не налаштовано (використовуються placeholder значення)');
      print('💡 Додаток працюватиме в офлайн-режимі');
    }
  } catch (e) {
    print('⚠️ Firebase помилка: $e');
    print('💡 Додаток працюватиме в офлайн-режимі');
  }
    
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
        Provider<TransportRouter>(create: (c) {
          final fs = Provider.of<FirestoreService>(c, listen: false);
          return TransportRouter(
            firebaseTransport: FirebaseTransport(fs),
            meshGramTransport: MeshGramTransport(),
          );
        }),
        Provider<bool>.value(value: firebaseInitialized), // Для перевірки в UI
      ],
      child: const YaOkApp(),
    ),
  );
}

class YaOkApp extends StatelessWidget {
  const YaOkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return MaterialApp(
      title: 'Я ОК',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData) {
            // Користувач авторизований - показати головний екран
            return const MainScreen();
          }
          
          // Користувач не авторизований - показати onboarding/auth
          return const OnboardingScreen();
        },
      ),
    );
  }
}


