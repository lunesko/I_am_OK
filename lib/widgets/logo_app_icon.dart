import 'package:flutter/material.dart';

/// App Icon логотип "Я ОК" у стилі Monobank
/// Варіант 1 з прототипу
class LogoAppIcon extends StatelessWidget {
  final double size;
  final bool isDarkMode;
  final String? symbol;
  final bool showShadow;
  
  const LogoAppIcon({
    super.key,
    this.size = 120.0,
    this.isDarkMode = false,
    this.symbol,
    this.showShadow = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.25;
    final symbolSize = size * 0.5;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
            ? [
                const Color(0xFF4A90E2), // Light Blue
                const Color(0xFF6BA3F0), // Lighter Blue
              ]
            : [
                const Color(0xFF0057B7), // Primary Blue
                const Color(0xFF4A90E2), // Primary Blue Light
              ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
          ? [
              BoxShadow(
                color: const Color(0xFF0057B7).withOpacity(0.3),
                blurRadius: size * 0.25,
                offset: Offset(0, size * 0.08),
              ),
            ]
          : null,
      ),
      child: Center(
        child: Text(
          symbol ?? '💚',
          style: TextStyle(
            fontSize: symbolSize,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Розміри для різних контекстів
class LogoAppIconSizes {
  // App Icon
  static const double appIcon1024 = 1024.0;
  static const double appIcon512 = 512.0;
  static const double appIcon192 = 192.0;
  static const double appIcon180 = 180.0;
  static const double appIcon120 = 120.0;
  static const double appIcon87 = 87.0;
  static const double appIcon80 = 80.0;
  static const double appIcon76 = 76.0;
  static const double appIcon60 = 60.0;
  static const double appIcon58 = 58.0;
  static const double appIcon40 = 40.0;
  static const double appIcon29 = 29.0;
  static const double appIcon20 = 20.0;
  
  // Notification
  static const double notification64 = 64.0;
  static const double notification48 = 48.0;
  static const double notification40 = 40.0;
  static const double notification24 = 24.0;
  
  // Favicon
  static const double favicon32 = 32.0;
  static const double favicon16 = 16.0;
}

/// Приклади використання
class LogoAppIconExamples {
  /// App Icon для iOS/Android
  static Widget appIcon({
    double size = LogoAppIconSizes.appIcon512,
    bool isDarkMode = false,
  }) {
    return LogoAppIcon(
      size: size,
      isDarkMode: isDarkMode,
      symbol: '💚',
      showShadow: size >= 64.0, // Тінь тільки для великих розмірів
    );
  }
  
  /// Notification badge
  static Widget notification({
    double size = LogoAppIconSizes.notification48,
    bool isDarkMode = false,
  }) {
    return LogoAppIcon(
      size: size,
      isDarkMode: isDarkMode,
      symbol: size >= 48.0 ? '💚' : '✓', // Спрощений символ для малих розмірів
      showShadow: false, // Без тіні для notification
    );
  }
  
  /// Favicon
  static Widget favicon({
    double size = LogoAppIconSizes.favicon32,
    bool isDarkMode = false,
  }) {
    return LogoAppIcon(
      size: size,
      isDarkMode: isDarkMode,
      symbol: size >= 32.0 ? '💚' : null, // Без символу для дуже малих розмірів
      showShadow: false,
    );
  }
  
  /// Splash Screen (великий розмір)
  static Widget splash({bool isDarkMode = false}) {
    return LogoAppIcon(
      size: 200.0,
      isDarkMode: isDarkMode,
      symbol: '💚',
      showShadow: true,
    );
  }
}
