import 'package:flutter/material.dart';

/// Text Only логотип "Я ОК" з градієнтом
/// Варіант 4 з прототипу
class LogoTextOnly extends StatelessWidget {
  final double fontSize;
  final bool isDarkMode;
  final TextAlign? textAlign;
  
  const LogoTextOnly({
    super.key,
    this.fontSize = 48.0,
    this.isDarkMode = false,
    this.textAlign,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
            ? [
                const Color(0xFF4A90E2), // Light Blue
                const Color(0xFF30D158), // Light Green
              ]
            : [
                const Color(0xFF0057B7), // Primary Blue
                const Color(0xFF34C759), // Success Green
              ],
        ).createShader(bounds);
      },
      child: Text(
        'Я ОК',
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: Colors.white, // Будь-який колір, shaderMask перезапише
          fontFamily: 'SF Pro Display', // Fallback до системного шрифту
        ),
      ),
    );
  }
}

/// Розміри для різних контекстів
class LogoTextOnlySizes {
  static const double splash = 48.0;
  static const double header = 28.0;
  static const double onboarding = 36.0;
  static const double settings = 24.0;
  static const double compact = 20.0;
}

/// Приклади використання
class LogoTextOnlyExamples {
  /// Для Splash Screen
  static Widget splash({bool isDarkMode = false}) {
    return LogoTextOnly(
      fontSize: LogoTextOnlySizes.splash,
      isDarkMode: isDarkMode,
    );
  }
  
  /// Для Header
  static Widget header({bool isDarkMode = false}) {
    return LogoTextOnly(
      fontSize: LogoTextOnlySizes.header,
      isDarkMode: isDarkMode,
    );
  }
  
  /// Для Onboarding
  static Widget onboarding({bool isDarkMode = false}) {
    return LogoTextOnly(
      fontSize: LogoTextOnlySizes.onboarding,
      isDarkMode: isDarkMode,
    );
  }
  
  /// Для Settings
  static Widget settings({bool isDarkMode = false}) {
    return LogoTextOnly(
      fontSize: LogoTextOnlySizes.settings,
      isDarkMode: isDarkMode,
    );
  }
  
  /// Compact версія
  static Widget compact({bool isDarkMode = false}) {
    return LogoTextOnly(
      fontSize: LogoTextOnlySizes.compact,
      isDarkMode: isDarkMode,
    );
  }
}
