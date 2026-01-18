import 'package:flutter/material.dart';

/// Design Tokens для "Я ОК"
/// Експортовано з HTML прототипу та Figma макету
class DesignTokens {
  // ============================================================
  // SPACING SYSTEM
  // ============================================================
  
  static const double spacingXS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 20.0;
  static const double spacingXL = 30.0;
  static const double spacingXXL = 40.0;
  
  // ============================================================
  // BORDER RADIUS
  // ============================================================
  
  static const double radiusSM = 10.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 30.0;
  static const double radiusCircle = 999.0;
  
  // ============================================================
  // ANIMATION TIMINGS
  // ============================================================
  
  static const int durationFast = 200; // ms
  static const int durationNormal = 300; // ms
  static const int durationSlow = 400; // ms
  static const int durationLoading = 1000; // ms
  static const int durationCheckBounce = 600; // ms
  static const int durationFadeIn = 500; // ms
  static const int durationShake = 500; // ms
  static const int durationPulse = 2000; // ms
  
  // ============================================================
  // EASING CURVES
  // ============================================================
  
  // CSS: cubic-bezier(0.4, 0.0, 0.2, 1)
  static const String easingDefault = 'cubic-bezier(0.4, 0.0, 0.2, 1)';
  
  // CSS: cubic-bezier(0.68, -0.55, 0.265, 1.55)
  static const String easingBounce = 'cubic-bezier(0.68, -0.55, 0.265, 1.55)';
  
  // Flutter equivalents
  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveBounce = Curves.elasticOut;
  
  // ============================================================
  // SHADOWS
  // ============================================================
  
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x4D34C759), // rgba(52, 199, 89, 0.3)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];
  
  static const List<BoxShadow> controlShadow = [
    BoxShadow(
      color: Color(0x33000000), // rgba(0, 0, 0, 0.2)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  // ============================================================
  // TOUCH TARGETS
  // ============================================================
  
  static const double touchTargetMin = 44.0; // iOS HIG
  static const double touchTargetRecommended = 48.0; // Material Design
  
  // ============================================================
  // ICON SIZES
  // ============================================================
  
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 60.0;
  
  // ============================================================
  // AVATAR SIZES
  // ============================================================
  
  static const double avatarSM = 32.0;
  static const double avatarMD = 48.0;
  static const double avatarLG = 64.0;
  static const double avatarXL = 120.0;
  
  // ============================================================
  // SCREEN DIMENSIONS
  // ============================================================
  
  static const double screenWidth = 375.0; // iPhone 13
  static const double screenHeight = 812.0; // iPhone 13
  
  // ============================================================
  // BREAKPOINTS (для responsive design)
  // ============================================================
  
  static const double breakpointSM = 600.0;
  static const double breakpointMD = 900.0;
  static const double breakpointLG = 1200.0;
  
  // ============================================================
  // Z-INDEX LAYERS
  // ============================================================
  
  static const int zBase = 0;
  static const int zElevated = 10;
  static const int zOverlay = 100;
  static const int zModal = 1000;
  static const int zControls = 2000;
  
  // ============================================================
  // OPACITY VALUES
  // ============================================================
  
  static const double opacityDisabled = 0.5;
  static const double opacitySecondary = 0.7;
  static const double opacityTertiary = 0.5;
  static const double opacityHover = 0.8;
  
  // ============================================================
  // ANIMATION DELAYS
  // ============================================================
  
  static const int staggerDelay = 100; // ms
  static const int autoSyncDelay = 500; // ms
  
  // ============================================================
  // GRADIENT STOPS
  // ============================================================
  
  static const List<double> gradientStopsDefault = [0.0, 1.0];
  static const List<double> gradientStopsNotification = [0.0, 0.2];
  
  // ============================================================
  // BORDER WIDTHS
  // ============================================================
  
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 4.0;
  
  // ============================================================
  // NOTIFICATION INDICATORS
  // ============================================================
  
  static const double notificationBadgeSize = 8.0;
  static const double notificationBorderWidth = 4.0;
  
  // ============================================================
  // SWIPE THRESHOLDS
  // ============================================================
  
  static const double swipeThreshold = 50.0; // pixels
  static const double swipeVelocityThreshold = 300.0; // pixels/second
}
