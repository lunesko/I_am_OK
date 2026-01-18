import 'package:flutter/material.dart';

/// Анімації для "Я ОК"
/// Створено на основі HTML прототипу
class AppAnimations {
  // ============================================================
  // DURATION & CURVES
  // ============================================================
  
  static const Duration screenTransition = Duration(milliseconds: 400);
  static const Duration buttonPress = Duration(milliseconds: 200);
  static const Duration checkBounce = Duration(milliseconds: 600);
  static const Duration fadeIn = Duration(milliseconds: 500);
  static const Duration staggerDelay = Duration(milliseconds: 100);
  
  static const Curve screenCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.elasticOut;
  
  // ============================================================
  // SCREEN TRANSITIONS
  // ============================================================
  
  /// Slide transition (як в HTML прототипі)
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    bool fromRight = true,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(fromRight ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: screenCurve,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
  
  // ============================================================
  // BUTTON ANIMATIONS
  // ============================================================
  
  /// Scale animation для кнопок (press effect)
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return _AnimatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
  
  // ============================================================
  // SUCCESS ANIMATIONS
  // ============================================================
  
  /// Bounce animation для checkmark (як в HTML)
  static Widget checkBounceAnimation({
    required Widget child,
  }) {
    return _CheckBounceAnimation(child: child);
  }
  
  // ============================================================
  // STAGGERED ANIMATIONS
  // ============================================================
  
  /// Staggered animation для списку отримувачів
  static Widget staggeredList({
    required List<Widget> children,
    required Animation<double> parentAnimation,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: parentAnimation,
              curve: Interval(
                index * 0.1,
                0.5 + index * 0.1,
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.2, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: parentAnimation,
                curve: Interval(
                  index * 0.1,
                  0.5 + index * 0.1,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: child,
          ),
        );
      }).toList(),
    );
  }
  
  // ============================================================
  // PULSE ANIMATION
  // ============================================================
  
  /// Pulse animation для логотипу (як в HTML)
  static Widget pulseAnimation({
    required Widget child,
  }) {
    return _PulseAnimation(child: child);
  }
  
  // ============================================================
  // LOADING ANIMATION
  // ============================================================
  
  /// Loading spinner (як в HTML прототипі)
  static Widget loadingSpinner({
    Color? color,
    double size = 40.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 4.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color(0xFF0057B7),
        ),
      ),
    );
  }
  
  // ============================================================
  // CARD HOVER ANIMATION
  // ============================================================
  
  /// Slide animation для карточок (hover effect)
  static Widget animatedCard({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return _AnimatedCard(
      onTap: onTap,
      child: child,
    );
  }
  
  // ============================================================
  // BIOMETRIC PULSE ANIMATION
  // ============================================================
  
  /// Pulse animation для біометрії (з тінню)
  static Widget biometricPulseAnimation({
    required Widget child,
  }) {
    return _BiometricPulseAnimation(child: child);
  }
  
  // ============================================================
  // SHAKE ANIMATION
  // ============================================================
  
  /// Shake animation для помилок
  static Widget shakeAnimation({
    required Widget child,
  }) {
    return _ShakeAnimation(child: child);
  }
  
  // ============================================================
  // FADE IN SCALE ANIMATION
  // ============================================================
  
  /// Fade in scale animation для onboarding
  static Widget fadeInScaleAnimation({
    required Widget child,
  }) {
    return _FadeInScaleAnimation(child: child);
  }
}

// ============================================================
// PRIVATE ANIMATION WIDGETS
// ============================================================

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  
  const _AnimatedButton({
    required this.child,
    required this.onPressed,
  });
  
  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.buttonPress,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class _CheckBounceAnimation extends StatefulWidget {
  final Widget child;
  
  const _CheckBounceAnimation({required this.child});
  
  @override
  State<_CheckBounceAnimation> createState() => _CheckBounceAnimationState();
}

class _CheckBounceAnimationState extends State<_CheckBounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.checkBounce,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    )..addListener(() {
      if (_scaleAnimation.value > 0.5 && _scaleAnimation.value < 0.6) {
        // Bounce effect
        _controller.forward(from: 0.5);
      }
    });
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  
  const _PulseAnimation({required this.child});
  
  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const _AnimatedCard({
    required this.child,
    this.onTap,
  });
  
  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _BiometricPulseAnimation extends StatefulWidget {
  final Widget child;
  
  const _BiometricPulseAnimation({required this.child});
  
  @override
  State<_BiometricPulseAnimation> createState() => _BiometricPulseAnimationState();
}

class _BiometricPulseAnimationState extends State<_BiometricPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _shadowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0057B7).withOpacity(0.7 - _shadowAnimation.value / 20),
                  blurRadius: _shadowAnimation.value,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _ShakeAnimation extends StatefulWidget {
  final Widget child;
  
  const _ShakeAnimation({required this.child});
  
  @override
  State<_ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<_ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  double _shakeOffset(double value) {
    if (value < 0.25) {
      return -10.0 * (value / 0.25);
    } else if (value < 0.5) {
      return -10.0 + 20.0 * ((value - 0.25) / 0.25);
    } else if (value < 0.75) {
      return 10.0 - 20.0 * ((value - 0.5) / 0.25);
    } else {
      return -10.0 + 10.0 * ((value - 0.75) / 0.25);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset(_shakeAnimation.value), 0),
          child: widget.child,
        );
      },
    );
  }
}

class _FadeInScaleAnimation extends StatefulWidget {
  final Widget child;
  
  const _FadeInScaleAnimation({required this.child});
  
  @override
  State<_FadeInScaleAnimation> createState() => _FadeInScaleAnimationState();
}

class _FadeInScaleAnimationState extends State<_FadeInScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
