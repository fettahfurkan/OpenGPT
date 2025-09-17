import 'package:flutter/material.dart';

/// Smooth ve akıcı sayfa geçişleri için yardımcı sınıf
class PageTransitions {
  /// Fade + Slide geçiş animasyonu
  static PageRouteBuilder<T> fadeSlideTransition<T extends Object?>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Offset beginOffset = const Offset(0.3, 0.0),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade animasyonu
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.8, curve: curve),
        ));

        // Slide animasyonu
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Scale animasyonu (hafif)
        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Yumuşak scale geçiş animasyonu
  static PageRouteBuilder<T> scaleTransition<T extends Object?>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
    double beginScale = 0.8,
    Curve curve = Curves.easeOutBack,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide geçiş animasyonu (yön belirlenebilir)
  static PageRouteBuilder<T> slideTransition<T extends Object?>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    SlideDirection direction = SlideDirection.right,
    Curve curve = Curves.easeOutCubic,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.7, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Modal bottom sheet tarzı geçiş
  static PageRouteBuilder<T> modalTransition<T extends Object?>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 450),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: Colors.black54,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Hızlı fade geçiş (basit sayfalar için)
  static PageRouteBuilder<T> quickFadeTransition<T extends Object?>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

/// Slide yönleri
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Navigator extension'ları
extension NavigatorExtensions on NavigatorState {
  /// Smooth push
  Future<T?> pushSmooth<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeSlide,
  }) {
    PageRouteBuilder<T> route;
    
    switch (type) {
      case PageTransitionType.fadeSlide:
        route = PageTransitions.fadeSlideTransition<T>(page: page);
        break;
      case PageTransitionType.scale:
        route = PageTransitions.scaleTransition<T>(page: page);
        break;
      case PageTransitionType.slideRight:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.right,
        );
        break;
      case PageTransitionType.slideLeft:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.left,
        );
        break;
      case PageTransitionType.slideUp:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.up,
        );
        break;
      case PageTransitionType.modal:
        route = PageTransitions.modalTransition<T>(page: page);
        break;
      case PageTransitionType.quickFade:
        route = PageTransitions.quickFadeTransition<T>(page: page);
        break;
    }
    
    return push<T>(route);
  }

  /// Smooth push replacement
  Future<T?> pushReplacementSmooth<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeSlide,
    TO? result,
  }) {
    PageRouteBuilder<T> route;
    
    switch (type) {
      case PageTransitionType.fadeSlide:
        route = PageTransitions.fadeSlideTransition<T>(page: page);
        break;
      case PageTransitionType.scale:
        route = PageTransitions.scaleTransition<T>(page: page);
        break;
      case PageTransitionType.slideRight:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.right,
        );
        break;
      case PageTransitionType.slideLeft:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.left,
        );
        break;
      case PageTransitionType.slideUp:
        route = PageTransitions.slideTransition<T>(
          page: page,
          direction: SlideDirection.up,
        );
        break;
      case PageTransitionType.modal:
        route = PageTransitions.modalTransition<T>(page: page);
        break;
      case PageTransitionType.quickFade:
        route = PageTransitions.quickFadeTransition<T>(page: page);
        break;
    }
    
    return pushReplacement<T, TO>(route, result: result);
  }
}

/// Geçiş türleri
enum PageTransitionType {
  fadeSlide,
  scale,
  slideRight,
  slideLeft,
  slideUp,
  modal,
  quickFade,
}