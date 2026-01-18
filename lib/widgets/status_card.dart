import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';

/// Карточка статусу (як в HTML прототипі)
class StatusCard extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback onTap;
  
  const StatusCard({
    super.key,
    required this.status,
    this.isSelected = false,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppAnimations.animatedCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.backgroundGray 
            : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: isSelected
            ? Border.all(color: AppTheme.primaryBlue, width: 2)
            : null,
          boxShadow: AppTheme.cardShadow,
        ),
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            // Emoji
            Text(
              AppTheme.getStatusEmoji(status),
              style: TextStyle(fontSize: 28),
            ),
            
            SizedBox(width: AppTheme.spacing12),
            
            // Text
            Expanded(
              child: Text(
                AppTheme.getStatusText(status),
                style: AppTheme.body,
              ),
            ),
            
            // Check icon (показується тільки якщо selected)
            if (isSelected)
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: AppAnimations.buttonPress,
                child: Icon(
                  Icons.check,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
