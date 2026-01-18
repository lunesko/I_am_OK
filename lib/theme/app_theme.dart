import 'package:flutter/material.dart';

/// Design System для "Я ОК"
/// Створено на основі Figma макету
class AppTheme {
  // ============================================================
  // КОЛЬОРОВА ПАЛІТРА
  // ============================================================
  
  // Primary Colors
  static const Color primaryBlue = Color(0xFF0057B7);
  static const Color primaryBlueLight = Color(0xFF4A90E2);
  
  // Success Colors
  static const Color successGreen = Color(0xFF34C759);
  static const Color successGreenLight = Color(0xFF30D158);
  
  // Warning Colors
  static const Color warningYellow = Color(0xFFFFCC00);
  static const Color alertOrange = Color(0xFFFF9500);
  static const Color alertOrangeLight = Color(0xFFFFB340);
  
  // Background Colors
  static const Color backgroundGray = Color(0xFFF5F5F7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF3C3C43);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF666666);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color borderGray = Color(0xFFE5E5EA);
  
  // ============================================================
  // ГРАДІЄНТИ
  // ============================================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueLight],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, successGreenLight],
  );
  
  static const LinearGradient donateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, warningYellow],
  );
  
  // ============================================================
  // ТИПОГРАФІКА
  // ============================================================
  
  // H1 - Screen Title
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  // H2 - Card Title
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  // Body - Regular Text
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.4,
  );
  
  // Caption - Secondary Text
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.3,
  );
  
  // Button - Action Text
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.2,
  );
  
  // ============================================================
  // SPACING SYSTEM (8px grid)
  // ============================================================
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing30 = 30.0;
  static const double spacing40 = 40.0;
  
  // Додаткові spacing (для сумісності)
  static const double spacing10 = 10.0;
  static const double spacing14 = 14.0;
  
  // ============================================================
  // BORDER RADIUS
  // ============================================================
  
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 30.0;
  static const double radiusRound = 50.0;
  
  // ============================================================
  // SHADOWS
  // ============================================================
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: successGreen.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> logoShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // ============================================================
  // THEME DATA
  // ============================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGray,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: successGreen,
        surface: cardWhite,
        error: alertOrange,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: h1,
        displayMedium: h2,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
      ),
      cardTheme: CardTheme(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge),
          ),
          textStyle: button,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: h1,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: ColorScheme.dark(
        primary: primaryBlueLight,
        secondary: successGreenLight,
        surface: const Color(0xFF1C1C1E),
        error: alertOrange,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: h1.copyWith(color: Colors.white),
        displayMedium: h2.copyWith(color: Colors.white),
        bodyLarge: body.copyWith(color: Colors.white),
        bodyMedium: body.copyWith(color: Colors.white),
        bodySmall: caption.copyWith(color: const Color(0xFF999999)),
        labelLarge: button,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge),
          ),
          textStyle: button,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
  
  // ============================================================
  // STATUS COLORS
  // ============================================================
  
  static Color getStatusColor(String status) {
    switch (status) {
      case 'ok':
        return successGreen;
      case 'busy':
        return warningYellow;
      case 'later':
        return primaryBlue;
      case 'hug':
        return Colors.grey.shade300;
      default:
        return successGreen;
    }
  }
  
  static String getStatusEmoji(String status) {
    switch (status) {
      case 'ok':
        return '💚';
      case 'busy':
        return '💛';
      case 'later':
        return '💙';
      case 'hug':
        return '🤍';
      default:
        return '💚';
    }
  }
  
  static String getStatusText(String status) {
    switch (status) {
      case 'ok':
        return 'Я ОК';
      case 'busy':
        return 'Все нормально, зайнятий';
      case 'later':
        return 'Зателефоную пізніше';
      case 'hug':
        return 'Обійми';
      default:
        return 'Я ОК';
    }
  }
  
  // ============================================================
  // ANIMATIONS
  // ============================================================
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeOut;
}
