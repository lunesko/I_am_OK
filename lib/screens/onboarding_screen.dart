import 'package:flutter/material.dart';
import 'package:ya_ok/theme/app_theme.dart';
import 'package:ya_ok/widgets/animations.dart';
import 'package:ya_ok/widgets/screen_transitions.dart';
import 'package:ya_ok/screens/auth_screen.dart';

/// Onboarding Screen з 3 слайдами
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      emoji: '💚',
      title: 'Один дотик — спокій для близьких',
      text: 'Натисніть одну кнопку, щоб повідомити рідних, що з вами все добре',
      gradient: AppTheme.primaryGradient,
    ),
    OnboardingSlide(
      emoji: '🔒',
      title: 'Повна безпека',
      text: 'Без геолокації. Без відстеження. Ваша приватність під захистом',
      gradient: AppTheme.successGradient,
    ),
    OnboardingSlide(
      emoji: '⚡',
      title: 'Працює офлайн',
      text: 'Натисніть кнопку навіть без інтернету — повідомлення відправиться, коли з\'явиться зв\'язок',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.screenTransition,
        curve: AppAnimations.screenCurve,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    // Навігація на Auth Screen
    Navigator.of(context).pushReplacement(
      ScreenTransitions.slideFromRight(
        AuthScreen(), // Потрібно імпортувати
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing20),
                child: TextButton(
                  onPressed: _goToAuth,
                  child: Text(
                    'Пропустити',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // PageView з слайдами
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingSlideWidget(slide: _slides[index]);
                },
              ),
            ),

            // Dots indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _DotIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Next button
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing20),
              child: AppAnimations.animatedButton(
                onPressed: _nextPage,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing40,
                      vertical: AppTheme.spacing16,
                    ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Далі' : 'Почати',
                    style: AppTheme.button,
                    textAlign: TextAlign.center,
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideWidget extends StatefulWidget {
  final OnboardingSlide slide;

  const _OnboardingSlideWidget({required this.slide});

  @override
  State<_OnboardingSlideWidget> createState() => _OnboardingSlideWidgetState();
}

class _OnboardingSlideWidgetState extends State<_OnboardingSlideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing30,
        vertical: AppTheme.spacing40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration з анімацією
          FadeTransition(
            opacity: _fadeScaleAnimation,
            child: ScaleTransition(
              scale: _fadeScaleAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: widget.slide.gradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.slide.emoji,
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: AppTheme.spacing40),

          // Title
          Text(
            widget.slide.title,
            style: AppTheme.h1,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppTheme.spacing16),

          // Text
          Text(
            widget.slide.text,
            style: AppTheme.body.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.buttonPress,
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue : AppTheme.borderGray,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingSlide {
  final String emoji;
  final String title;
  final String text;
  final Gradient gradient;

  OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.text,
    required this.gradient,
  });
}
