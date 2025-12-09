// lib/core/responsive_helper.dart
// Responsive design helper for IntegralPOS application

import 'package:flutter/material.dart';

/// Responsive design helper class
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  static const double smallMobileBreakpoint = 360.0;

  // Base spacing unit
  static const double baseSpacing = 8.0;

  /// Check if current screen is small mobile (very small screens)
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileBreakpoint;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {double multiplier = 1.0}) {
    return baseSpacing * multiplier;
  }

  /// Get responsive page padding
  static EdgeInsets pagePadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive login padding
  static EdgeInsets loginPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0);
    }
  }

  /// Get responsive sidebar width
  static double sidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 280.0;
    } else if (isTablet(context)) {
      return 300.0;
    } else {
      return 320.0;
    }
  }

  /// Get responsive grid columns
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get responsive card width
  static double cardWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 400.0;
    } else {
      return 500.0;
    }
  }

  /// Get responsive text scale
  static double textScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.2);
  }
}

/// Responsive scaffold widget
class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Scaffold(
        appBar: appBar as PreferredSizeWidget?,
        body: body,
        drawer: drawer,
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      );
    } else {
      return Scaffold(
        appBar: appBar as PreferredSizeWidget?,
        body: body,
        drawer: drawer,
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      );
    }
  }
}