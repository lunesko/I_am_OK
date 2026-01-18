import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';

/// Error Screen з різними типами помилок
class ErrorScreen extends StatelessWidget {
  final ErrorType type;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  
  const ErrorScreen({
    super.key,
    required this.type,
    this.onRetry,
    this.onBack,
  });
  
  @override
  Widget build(BuildContext context) {
    final errorData = _getErrorData(type);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon з shake анімацією
                AppAnimations.shakeAnimation(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: errorData.iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        errorData.emoji,
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacing30),
                
                // Title
                Text(
                  errorData.title,
                  style: AppTheme.h1,
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppTheme.spacing12),
                
                // Text
                Text(
                  errorData.text,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppTheme.spacing30),
                
                // Primary button
                if (onRetry != null)
                  AppAnimations.animatedButton(
                    onPressed: onRetry!,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing30,
                          vertical: AppTheme.spacing14,
                        ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: Text(
                        errorData.primaryButtonText,
                        style: AppTheme.button,
                        textAlign: TextAlign.center,
                      ),
                      ),
                    ),
                  ),
                
                // Secondary button
                if (onBack != null)
                  Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacing20),
                    child: TextButton(
                      onPressed: onBack,
                      child: Text(
                        errorData.secondaryButtonText ?? 'Повернутися назад',
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  ErrorData _getErrorData(ErrorType type) {
    switch (type) {
      case ErrorType.noInternet:
        return ErrorData(
          emoji: '📡',
          title: 'Немає з\'єднання',
          text: 'Перевірте підключення до інтернету. Ваше повідомлення буде відправлено автоматично, коли з\'явиться зв\'язок.',
          iconColor: AppTheme.alertOrange,
          primaryButtonText: 'Зрозуміло',
          secondaryButtonText: null,
        );
        
      case ErrorType.serverError:
        return ErrorData(
          emoji: '⚠️',
          title: 'Щось пішло не так',
          text: 'Не вдалося підключитися до сервера. Спробуйте ще раз через кілька хвилин.',
          iconColor: AppTheme.alertOrange,
          primaryButtonText: 'Повторити спробу',
          secondaryButtonText: 'Повернутися назад',
        );
        
      case ErrorType.noContacts:
        return ErrorData(
          emoji: '👥',
          title: 'Додайте близьких',
          text: 'Щоб відправляти статуси, спочатку додайте людей до свого списку контактів.',
          iconColor: AppTheme.primaryBlue,
          primaryButtonText: 'Додати контакти',
          secondaryButtonText: 'Пізніше',
        );
    }
  }
}

enum ErrorType {
  noInternet,
  serverError,
  noContacts,
}

class ErrorData {
  final String emoji;
  final String title;
  final String text;
  final Color iconColor;
  final String primaryButtonText;
  final String? secondaryButtonText;
  
  ErrorData({
    required this.emoji,
    required this.title,
    required this.text,
    required this.iconColor,
    required this.primaryButtonText,
    this.secondaryButtonText,
  });
}
