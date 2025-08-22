import 'package:flutter/material.dart';

class AppTheme {
  // 2025 Color Trends - Light Theme
  static const Color _primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color _primaryContainerLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color _secondaryLight = Color(0xFF10B981); // Emerald 500
  static const Color _secondaryContainerLight = Color(0xFFECFDF5); // Emerald 50
  static const Color _surfaceLight = Color(0xFFFAFAFA); // Neutral 50
  static const Color _backgroundLight = Color(0xFFFFFFFF);
  static const Color _onSurfaceLight = Color(0xFF1F2937); // Gray 800
  static const Color _outlineLight = Color(0xFFE5E7EB); // Gray 200

  // 2025 Color Trends - Dark Theme
  static const Color _primaryDark = Color(0xFF818CF8); // Indigo 400
  static const Color _primaryContainerDark = Color(0xFF312E81); // Indigo 800
  static const Color _secondaryDark = Color(0xFF34D399); // Emerald 400
  static const Color _secondaryContainerDark = Color(0xFF064E3B); // Emerald 800
  static const Color _surfaceDark = Color(0xFF111827); // Gray 900
  static const Color _backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color _onSurfaceDark = Color(0xFFF9FAFB); // Gray 50
  static const Color _outlineDark = Color(0xFF374151); // Gray 700

  // Accent Colors for 2025
  static const Color accentPurple = Color(0xFF8B5CF6); // Violet 500
  static const Color accentPink = Color(0xFFEC4899); // Pink 500
  static const Color accentOrange = Color(0xFFF59E0B); // Amber 500
  static const Color accentTeal = Color(0xFF14B8A6); // Teal 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        primaryContainer: _primaryContainerLight,
        secondary: _secondaryLight,
        secondaryContainer: _secondaryContainerLight,
        surface: _surfaceLight,
        background: _backgroundLight,
        onSurface: _onSurfaceLight,
        onBackground: _onSurfaceLight,
        outline: _outlineLight,
        error: Color(0xFFEF4444), // Red 500
        errorContainer: Color(0xFFFEF2F2), // Red 50
      ),

      // Typography with modern hierarchy
      textTheme: _buildTextTheme(Brightness.light),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: _primaryLight,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _onSurfaceLight,
          letterSpacing: -0.5,
        ),
      ),

      // Card Theme with glassmorphism
      cardTheme: CardThemeData(
        elevation: 0,
        color: _backgroundLight,
        surfaceTintColor: _primaryLight,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _outlineLight.withOpacity(0.5), width: 1),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _outlineLight.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _outlineLight.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _primaryContainerLight,
        selectedColor: _primaryLight,
        labelStyle: const TextStyle(
          color: _primaryLight,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        primaryContainer: _primaryContainerDark,
        secondary: _secondaryDark,
        secondaryContainer: _secondaryContainerDark,
        surface: _surfaceDark,
        background: _backgroundDark,
        onSurface: _onSurfaceDark,
        onBackground: _onSurfaceDark,
        outline: _outlineDark,
        error: Color(0xFFF87171), // Red 400
        errorContainer: Color(0xFF7F1D1D), // Red 900
      ),

      textTheme: _buildTextTheme(Brightness.dark),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: _primaryDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _onSurfaceDark,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceDark,
        surfaceTintColor: _primaryDark,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _outlineDark.withOpacity(0.5), width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: _backgroundDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: _backgroundDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: _primaryDark,
          side: const BorderSide(color: _primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _outlineDark.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _outlineDark.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: _primaryDark,
        foregroundColor: _backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _primaryContainerDark,
        selectedColor: _primaryDark,
        labelStyle: const TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light
        ? _onSurfaceLight
        : _onSurfaceDark;

    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        color: textColor,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: textColor,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: textColor,
        height: 1.2,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: textColor,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: textColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: textColor,
        height: 1.35,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        height: 1.4,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textColor.withOpacity(0.7),
        height: 1.5,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: textColor.withOpacity(0.7),
        height: 1.4,
      ),
    );
  }

  // Gradients for 2025 design
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [_primaryLight, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [_primaryDark, Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [_secondaryLight, Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPink, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism effect
  static BoxDecoration glassmorphism(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Neumorphism effect
  static BoxDecoration neumorphism(
    BuildContext context, {
    bool isPressed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: surfaceColor,
      boxShadow: [
        if (!isPressed) ...[
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ] else ...[
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ],
    );
  }
}
