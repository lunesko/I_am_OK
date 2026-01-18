import 'package:flutter/material.dart';
import 'package:ya_ok/widgets/animations.dart';

/// Навігація з анімаціями переходів (як в HTML прототипі)
class ScreenTransitions {
  /// Slide transition зліва направо (вперед)
  static PageRouteBuilder slideFromRight(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: AppAnimations.screenTransition,
      reverseTransitionDuration: AppAnimations.screenTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Вихідний екран
        final exitAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppAnimations.screenCurve,
        ));
        
        // Новий екран
        final enterAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.screenCurve,
        ));
        
        return Stack(
          children: [
            SlideTransition(position: exitAnimation, child: child),
            SlideTransition(
              position: enterAnimation,
              child: screen,
            ),
          ],
        );
      },
    );
  }
  
  /// Slide transition справа наліво (назад)
  static PageRouteBuilder slideFromLeft(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: AppAnimations.screenTransition,
      reverseTransitionDuration: AppAnimations.screenTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final exitAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppAnimations.screenCurve,
        ));
        
        final enterAnimation = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.screenCurve,
        ));
        
        return Stack(
          children: [
            SlideTransition(position: exitAnimation, child: child),
            SlideTransition(
              position: enterAnimation,
              child: screen,
            ),
          ],
        );
      },
    );
  }
  
  /// Fade transition (для модальних вікон)
  static PageRouteBuilder fadeTransition(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: AppAnimations.fadeIn,
      reverseTransitionDuration: AppAnimations.fadeIn,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppAnimations.screenCurve,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Custom PageRoute для використання в Navigator
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushSlideFromRight<T extends Object?>(Widget screen) {
    return push<T>(ScreenTransitions.slideFromRight(screen) as Route<T>);
  }
  
  Future<T?> pushSlideFromLeft<T extends Object?>(Widget screen) {
    return push<T>(ScreenTransitions.slideFromLeft(screen) as Route<T>);
  }
  
  Future<T?> pushFade<T extends Object?>(Widget screen) {
    return push<T>(ScreenTransitions.fadeTransition(screen) as Route<T>);
  }
}
