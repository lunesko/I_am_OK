import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';

/// Елемент списку отримувачів (для Success Screen)
class RecipientItem extends StatelessWidget {
  final String name;
  final bool hasRead;
  
  const RecipientItem({
    super.key,
    required this.name,
    this.hasRead = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: AppTheme.body,
          ),
          if (hasRead)
            Icon(
              Icons.check,
              color: AppTheme.successGreen,
              size: 20,
            )
          else
            Icon(
              Icons.access_time,
              color: AppTheme.textSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }
}
