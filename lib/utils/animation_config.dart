import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan animasyon konfigürasyonları
class AnimationConfig {
  // Animasyon süreleri
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);

  // Easing curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve sharpCurve = Curves.easeOutExpo;

  // Fade animasyonları
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
    double intervalStart = 0.0,
    double intervalEnd = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(intervalStart, intervalEnd, curve: curve),
      ),
    );
  }

  // Slide animasyonları
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(0.0, 0.3),
    Offset end = Offset.zero,
    Curve curve = defaultCurve,
    double intervalStart = 0.0,
    double intervalEnd = 1.0,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(intervalStart, intervalEnd, curve: curve),
      ),
    );
  }

  // Scale animasyonları
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = bounceCurve,
    double intervalStart = 0.0,
    double intervalEnd = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(intervalStart, intervalEnd, curve: curve),
      ),
    );
  }

  // Rotation animasyonları
  static Animation<double> createRotationAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  // Staggered animasyonlar için interval hesaplama
  static double calculateStaggerInterval(int index, int totalItems, {
    double staggerDelay = 0.1,
    double maxDelay = 0.8,
  }) {
    final delay = index * staggerDelay;
    final clampedDelay = delay.clamp(0.0, maxDelay);
    return clampedDelay;
  }

  // Performans optimizasyonu için widget builder
  static Widget buildOptimizedAnimatedWidget({
    required Widget child,
    required Animation<double> animation,
    bool addRepaintBoundary = true,
  }) {
    Widget result = AnimatedBuilder(
      animation: animation,
      builder: (context, child) => child!,
      child: child,
    );

    if (addRepaintBoundary) {
      result = RepaintBoundary(child: result);
    }

    return result;
  }

  // Liste animasyonları için optimized builder
  static Widget buildStaggeredListItem({
    required Widget child,
    required AnimationController controller,
    required int index,
    int totalItems = 10,
    Duration itemDelay = const Duration(milliseconds: 50),
  }) {
    final delay = calculateStaggerInterval(index, totalItems);
    final animation = createFadeAnimation(
      controller: controller,
      intervalStart: delay,
      intervalEnd: (delay + 0.3).clamp(0.0, 1.0),
    );

    final slideAnimation = createSlideAnimation(
      controller: controller,
      begin: const Offset(0.0, 0.2),
      intervalStart: delay,
      intervalEnd: (delay + 0.3).clamp(0.0, 1.0),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // Mikro animasyonlar (button press, hover vb.)
  static Widget buildMicroAnimation({
    required Widget child,
    required VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 150),
    double scaleValue = 0.95,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) {
              // Scale down animation would be handled by state management
            },
            onTapUp: (_) {
              // Scale up animation would be handled by state management
              onTap?.call();
            },
            onTapCancel: () {
              // Reset scale animation would be handled by state management
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Loading animasyonları
  static Widget buildLoadingAnimation({
    Color? color,
    double size = 24.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
              strokeWidth: 2.0,
            ),
          ),
        );
      },
    );
  }

  // Shimmer effect
  static Widget buildShimmerEffect({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: -1.0, end: 2.0),
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? Colors.grey[300]!,
                highlightColor ?? Colors.grey[100]!,
                baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                (value - 1.0).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 1.0).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Animasyon mixin'i - sayfalarda kullanım için
mixin AnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  void initializePageAnimations({
    Duration fadeDuration = AnimationConfig.normalDuration,
    Duration slideDuration = AnimationConfig.slowDuration,
  }) {
    fadeController = AnimationController(duration: fadeDuration, vsync: this);
    slideController = AnimationController(duration: slideDuration, vsync: this);

    fadeAnimation = AnimationConfig.createFadeAnimation(controller: fadeController);
    slideAnimation = AnimationConfig.createSlideAnimation(controller: slideController);
  }

  void startPageAnimations() {
    fadeController.forward();
    slideController.forward();
  }

  void disposePageAnimations() {
    fadeController.dispose();
    slideController.dispose();
  }

  Widget buildAnimatedPage({required Widget child}) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Performans optimizasyonu için widget wrapper
class OptimizedAnimatedWidget extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final bool addRepaintBoundary;

  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    required this.animation,
    this.addRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfig.buildOptimizedAnimatedWidget(
      child: child,
      animation: animation,
      addRepaintBoundary: addRepaintBoundary,
    );
  }
}