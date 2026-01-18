import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';
import 'package:ya_ok/widgets/screen_transitions.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ya_ok/screens/main_screen.dart';

/// Biometric Authentication Screen
class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Автоматично запустити автентифікацію через 500ms
    Future.delayed(Duration(milliseconds: 500), () {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    final localAuth = LocalAuthentication();
    final availableBiometrics = await localAuth.getAvailableBiometrics();
    final isAvailable = availableBiometrics.isNotEmpty;
    
    if (!isAvailable) {
      // Якщо біометрія недоступна, пропустити
      _goToMain();
      return;
    }

    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Підтвердіть вхід для безпеки',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Успішна автентифікація
        _goToMain();
      } else {
        // Користувач скасував
        setState(() {
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      // Помилка автентифікації
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      ScreenTransitions.slideFromRight(
        MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Biometric icon з pulse анімацією
                AppAnimations.biometricPulseAnimation(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacing30),

                // Title
                Text(
                  'Підтвердіть вхід',
                  style: AppTheme.h1,
                ),

                SizedBox(height: AppTheme.spacing10),

                // Subtitle
                Text(
                  'Використайте Face ID або Touch ID',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppTheme.spacing40),

                // Loading indicator (якщо автентифікується)
                if (_isAuthenticating)
                  AppAnimations.loadingSpinner()
                else
                  // Manual button
                  AppAnimations.animatedButton(
                    onPressed: _authenticate,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing30,
                          vertical: AppTheme.spacing14,
                        ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: Text(
                        'Підтвердити',
                        style: AppTheme.button,
                        textAlign: TextAlign.center,
                      ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
