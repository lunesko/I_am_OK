import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';
import 'package:intl/intl.dart';

/// Notifications Screen
class NotificationsScreen extends StatelessWidget {
  final List<NotificationItem> notifications;
  
  const NotificationsScreen({
    super.key,
    this.notifications = const [],
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Сповіщення', style: AppTheme.h1),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.borderLight,
          ),
        ),
      ),
      body: notifications.isEmpty
        ? _EmptyNotificationsState()
        : ListView.builder(
            padding: EdgeInsets.all(AppTheme.spacing20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _NotificationItemWidget(
                notification: notifications[index],
                onTap: () {
                  // Навігація на Main Screen
                  Navigator.of(context).pop();
                },
              );
            },
          ),
    );
  }
}

class _NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  
  const _NotificationItemWidget({
    required this.notification,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppAnimations.animatedCard(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: notification.isUnread
            ? AppTheme.cardWhite
            : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: notification.isUnread
            ? Border(
                left: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 4,
                ),
              )
            : null,
        ),
        child: Container(
          decoration: notification.isUnread
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.cardWhite,
                  ],
                  stops: [0.0, 0.2],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              )
            : null,
          padding: EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: notification.avatarGradient ?? AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    notification.avatarEmoji ?? '💚',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              SizedBox(width: AppTheme.spacing12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Text
                    Text(
                      notification.text,
                      style: AppTheme.caption,
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Time
                    Text(
                      _formatTime(notification.timestamp),
                      style: AppTheme.caption.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Щойно';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} хвилин тому';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} годин тому';
    } else if (difference.inDays == 1) {
      return 'Вчора, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm', 'uk').format(timestamp);
    } else {
      return DateFormat('dd.MM.yyyy, HH:mm', 'uk').format(timestamp);
    }
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🔔',
              style: TextStyle(
                fontSize: 80,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            
            SizedBox(height: AppTheme.spacing20),
            
            Text(
              'Поки що немає сповіщень',
              style: AppTheme.h2,
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.spacing10),
            
            Text(
              'Тут будуть з\'являтися повідомлення про статуси ваших близьких',
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String text;
  final DateTime timestamp;
  final bool isUnread;
  final String? avatarEmoji;
  final Gradient? avatarGradient;
  
  NotificationItem({
    required this.title,
    required this.text,
    required this.timestamp,
    this.isUnread = false,
    this.avatarEmoji,
    this.avatarGradient,
  });
}
