import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  bool _followSystemTheme = true;

  ThemeMode get themeMode => _themeMode;
  bool get followSystemTheme => _followSystemTheme;

  // Initialize theme from database
  Future<void> initializeTheme() async {
    try {
      // You could store theme preference in database
      // For now, use system default
      _themeMode = ThemeMode.system;
      _followSystemTheme = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme: $e');
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    try {
      if (_followSystemTheme) {
        _followSystemTheme = false;
        _themeMode = ThemeMode.dark;
      } else {
        switch (_themeMode) {
          case ThemeMode.light:
            _themeMode = ThemeMode.dark;
            break;
          case ThemeMode.dark:
            _themeMode = ThemeMode.light;
            break;
          case ThemeMode.system:
            _themeMode = ThemeMode.dark;
            break;
        }
      }

      // Update system UI overlay style
      _updateSystemOverlay();

      // Save to database if needed
      // await _saveThemeToDatabase();

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode, {bool followSystem = false}) async {
    try {
      _themeMode = mode;
      _followSystemTheme = followSystem;

      _updateSystemOverlay();
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  // Get current brightness based on theme mode and system
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  // Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }

  // Update system UI overlay style based on current theme
  void _updateSystemOverlay() {
    final isDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  // Get theme icon based on current mode
  IconData getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  // Get theme display name
  String getThemeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Teması';
    }
  }

  // Get all available theme options
  List<ThemeModeOption> getThemeOptions() {
    return [
      ThemeModeOption(
        mode: ThemeMode.system,
        icon: Icons.brightness_auto_outlined,
        title: 'Sistem',
        subtitle: 'Cihaz ayarını takip et',
      ),
      ThemeModeOption(
        mode: ThemeMode.light,
        icon: Icons.light_mode_outlined,
        title: 'Açık',
        subtitle: 'Daytime modu',
      ),
      ThemeModeOption(
        mode: ThemeMode.dark,
        icon: Icons.dark_mode_outlined,
        title: 'Koyu',
        subtitle: 'Gece modu',
      ),
    ];
  }
}

class ThemeModeOption {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;

  ThemeModeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// Theme listener widget
class ThemeListener extends StatelessWidget {
  final Widget child;

  const ThemeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) => child,
    );
  }
}

// Theme toggle button widget
class ThemeToggleButton extends StatelessWidget {
  final double? size;
  final EdgeInsets? padding;

  const ThemeToggleButton({super.key, this.size, this.padding});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        final themeService = ThemeService();
        return IconButton(
          onPressed: themeService.toggleTheme,
          icon: Icon(themeService.getThemeIcon(), size: size ?? 24),
          padding: padding ?? const EdgeInsets.all(8),
          tooltip: 'Tema Değiştir',
        );
      },
    );
  }
}

// Animated theme transition
class AnimatedThemeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      child: child,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
