import 'package:flutter/material.dart';

/// Всі іконки проекту "Я ОК"
/// Експортовано з icons-export-tool.html
class AppIcons {
  // ============================================================
  // STATUS ICONS
  // ============================================================
  
  static const String statusOk = '💚';
  static const String statusBusy = '💛';
  static const String statusLater = '💙';
  static const String statusHug = '🤍';
  
  // ============================================================
  // NAVIGATION ICONS
  // ============================================================
  
  static const String navFamily = '👥';
  static const String navSettings = '⚙️';
  static const String navNotifications = '🔔';
  static const String navBack = '←';
  static const String navClose = '✕';
  
  // ============================================================
  // ACTION ICONS
  // ============================================================
  
  static const String actionCheck = '✓';
  static const String actionPending = '⏱';
  static const String actionAdd = '+';
  static const String actionNext = '→';
  
  // ============================================================
  // SYSTEM ICONS
  // ============================================================
  
  static const String systemSecurity = '🛡️';
  static const String systemInternet = '📡';
  static const String systemWarning = '⚠️';
  static const String systemContacts = '👥';
  static const String systemLock = '🔒';
  static const String systemOffline = '⚡';
  static const String systemBiometric = '👆';
  
  // ============================================================
  // UI ELEMENTS
  // ============================================================
  
  static const String uiEmptyNotifications = '🔔';
  static const String uiLogo = '💚';
}

/// Widget для відображення емоджі іконок
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? backgroundColor;
  
  const EmojiIcon({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: backgroundColor != null
        ? BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size * 0.25),
          )
        : null,
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }
}

/// Status Icon Widget
class StatusIcon extends StatelessWidget {
  final String status; // 'ok', 'busy', 'later', 'hug'
  final double size;
  
  const StatusIcon({
    super.key,
    required this.status,
    this.size = 28.0,
  });
  
  @override
  Widget build(BuildContext context) {
    String emoji;
    switch (status) {
      case 'ok':
        emoji = AppIcons.statusOk;
        break;
      case 'busy':
        emoji = AppIcons.statusBusy;
        break;
      case 'later':
        emoji = AppIcons.statusLater;
        break;
      case 'hug':
        emoji = AppIcons.statusHug;
        break;
      default:
        emoji = AppIcons.statusOk;
    }
    
    return EmojiIcon(emoji: emoji, size: size);
  }
}

/// Navigation Icon Widget
class NavIcon extends StatelessWidget {
  final String type; // 'family', 'settings', 'notifications', 'back', 'close'
  final double size;
  
  const NavIcon({
    super.key,
    required this.type,
    this.size = 24.0,
  });
  
  @override
  Widget build(BuildContext context) {
    String emoji;
    switch (type) {
      case 'family':
        emoji = AppIcons.navFamily;
        break;
      case 'settings':
        emoji = AppIcons.navSettings;
        break;
      case 'notifications':
        emoji = AppIcons.navNotifications;
        break;
      case 'back':
        emoji = AppIcons.navBack;
        break;
      case 'close':
        emoji = AppIcons.navClose;
        break;
      default:
        emoji = AppIcons.navFamily;
    }
    
    return EmojiIcon(emoji: emoji, size: size);
  }
}

/// System Icon Widget
class SystemIcon extends StatelessWidget {
  final String type; // 'security', 'internet', 'warning', etc.
  final double size;
  
  const SystemIcon({
    super.key,
    required this.type,
    this.size = 24.0,
  });
  
  @override
  Widget build(BuildContext context) {
    String emoji;
    switch (type) {
      case 'security':
        emoji = AppIcons.systemSecurity;
        break;
      case 'internet':
        emoji = AppIcons.systemInternet;
        break;
      case 'warning':
        emoji = AppIcons.systemWarning;
        break;
      case 'contacts':
        emoji = AppIcons.systemContacts;
        break;
      case 'lock':
        emoji = AppIcons.systemLock;
        break;
      case 'offline':
        emoji = AppIcons.systemOffline;
        break;
      case 'biometric':
        emoji = AppIcons.systemBiometric;
        break;
      default:
        emoji = AppIcons.systemSecurity;
    }
    
    return EmojiIcon(emoji: emoji, size: size);
  }
}
