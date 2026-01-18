import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  
  // Local Storage
  final localStorage = LocalStorageService();
  await localStorage.initialize();
  
  // Notifications (працює без Firebase)
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Auth Service (локальна система без Firebase)
  final authService = AuthService();
  authService.initialize(localStorage);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
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
        Provider<bool>.value(value: false), // Firebase відключено
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
      home: StreamBuilder<LocalUser?>(
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
