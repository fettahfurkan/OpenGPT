import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1440;

  // Breakpoints
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  // Screen size getters
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Safe area values
  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Responsive values based on screen size
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: 16,
        tablet: 24,
        desktop: 32,
      ),
      vertical: getResponsiveValue(
        context,
        mobile: 16,
        tablet: 20,
        desktop: 24,
      ),
    );
  }

  // Responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: 8,
        tablet: 12,
        desktop: 16,
      ),
      vertical: getResponsiveValue(context, mobile: 8, tablet: 10, desktop: 12),
    );
  }

  // Card width based on screen size
  static double getCardWidth(BuildContext context) {
    final screenWidth = getWidth(context);

    if (isDesktop(context)) {
      return (screenWidth * 0.85).clamp(300, 800);
    } else if (isTablet(context)) {
      return (screenWidth * 0.9).clamp(280, 600);
    } else {
      return screenWidth * 0.95;
    }
  }

  // Max width for content
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 900,
    );
  }

  // Grid columns count
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  // Font size scaling
  static double getScaledFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getWidth(context);
    final scaleFactor = (screenWidth / 375).clamp(
      0.8,
      1.2,
    ); // 375 is iPhone baseline
    return baseFontSize * scaleFactor;
  }

  // Button height based on screen size
  static double getButtonHeight(BuildContext context) {
    return getResponsiveValue(context, mobile: 48, tablet: 52, desktop: 56);
  }

  // AppBar height
  static double getAppBarHeight(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }

  // Icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    return getResponsiveValue(
      context,
      mobile: baseSize,
      tablet: baseSize + 2,
      desktop: baseSize + 4,
    );
  }

  // Border radius
  static double getBorderRadius(
    BuildContext context, {
    double baseRadius = 12,
  }) {
    return getResponsiveValue(
      context,
      mobile: baseRadius,
      tablet: baseRadius + 2,
      desktop: baseRadius + 4,
    );
  }
}

// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isDesktop(context)) {
          return desktop?.call(context, constraints) ??
              tablet?.call(context, constraints) ??
              mobile(context, constraints);
        } else if (ResponsiveUtils.isTablet(context)) {
          return tablet?.call(context, constraints) ??
              mobile(context, constraints);
        } else {
          return mobile(context, constraints);
        }
      },
    );
  }
}

// Safe scroll view to prevent overflow
class SafeScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const SafeScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: physics ?? const BouncingScrollPhysics(),
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context);
    final spacing = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );

    return Padding(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing ?? spacing,
          crossAxisSpacing: crossAxisSpacing ?? spacing,
          childAspectRatio: ResponsiveUtils.isDesktop(context) ? 3.2 : 2.66,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

// Adaptive container with max width
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.getMaxContentWidth(context),
      ),
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      child: child,
    );
  }
}
