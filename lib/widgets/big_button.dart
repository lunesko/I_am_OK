import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';

/// Велика кнопка "Відправити" (як в HTML прототипі)
class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final bool isLoading;
  
  const BigButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppAnimations.animatedButton(
      onPressed: isLoading ? () {} : onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.successGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.buttonShadow,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing30,
          vertical: AppTheme.spacing30,
        ),
        child: isLoading
          ? AppAnimations.loadingSpinner(
              color: Colors.white,
              size: 24,
            )
          : Text(
              text,
              style: AppTheme.button,
              textAlign: TextAlign.center,
            ),
      ),
    );
  }
}
