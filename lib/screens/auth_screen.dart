import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_app_icon.dart';
import '../widgets/screen_transitions.dart';
import 'biometric_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithDiaID() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Симуляція входу (в production - OAuth flow)
      final credential = await authService.signInWithDiaID(
        'user@example.com',
        'Користувач',
      );
      
      if (credential != null && mounted) {
        // Перейти на екран біометрії
        Navigator.of(context).push(
          ScreenTransitions.slideFromRight(
            const BiometricScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Auth error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithBankID() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Симуляція входу (в production - BankID API)
      final credential = await authService.signInWithBankID(
        '+380501234567',
        'Користувач',
      );
      
      if (credential != null && mounted) {
        // Перейти на екран біометрії
        Navigator.of(context).push(
          ScreenTransitions.slideFromRight(
            const BiometricScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ BankID auth error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                LogoAppIconExamples.appIcon(size: 120.0),
                
                const SizedBox(height: 30),
                
                // App Title
                Text(
                  'Я ОК',
                  style: AppTheme.h1.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Subtitle
                Text(
                  'Один дотик — спокій для близьких',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Дія ID Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithDiaID,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3C43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('🇺🇦'),
                            SizedBox(width: 12),
                            Text(
                              'Увійти через Дія',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                
                const SizedBox(height: 12),
                
                // BankID Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithBankID,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.borderLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Увійти через BankID',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Без реєстрації. Без геолокації. Безпечно.',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
