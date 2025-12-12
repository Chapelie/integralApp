// lib/widgets/main_layout.dart
// Layout principal avec sidebar pour tous les écrans

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../core/responsive_helper.dart';
import '../features/pos/widgets/sidebar.dart';
import '../features/pos/widgets/hamburger_menu.dart';
import '../providers/sidebar_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;
  final PreferredSizeWidget? appBar; // enforce AppBar type
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      // Desktop with fixed sidebar
      // Only show appBar if it's a full-featured header (like UnifiedHeader with search/sync)
      // For simple headers, the Sidebar header is sufficient
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            Sidebar(
              currentRoute: currentRoute,
              onNavigate: (route) => _handleNavigation(context, route),
            ),
            Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), child: child)),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    } else {
      // Mobile with drawer + universal hamburger
      return Scaffold(
        appBar: _buildMobileAppBar(context),
        drawer: HamburgerMenu(
          currentRoute: currentRoute,
          onNavigate: (route) => _handleNavigation(context, route),
        ),
        body: child,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }
  }

  PreferredSizeWidget? _buildMobileAppBar(BuildContext context) {
    if (appBar != null) return appBar; // page provided its own AppBar
    // Provide a minimal AppBar with hamburger as default on mobile
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      title: const Text(''),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (route == currentRoute) return;
    switch (route) {
      case '/pos':
        Navigator.of(context).pushReplacementNamed('/pos');
        break;
      case '/products':
        Navigator.of(context).pushReplacementNamed('/products');
        break;
      case '/inventory':
        Navigator.of(context).pushReplacementNamed('/inventory');
        break;
      case '/customers':
        Navigator.of(context).pushReplacementNamed('/customers');
        break;
      case '/employees':
        Navigator.of(context).pushReplacementNamed('/employees');
        break;
      case '/cash-register':
        Navigator.of(context).pushReplacementNamed('/cash-register');
        break;
      case '/reports':
        Navigator.of(context).pushReplacementNamed('/reports');
        break;
      case '/accounting':
        Navigator.of(context).pushReplacementNamed('/accounting');
        break;
      case '/settings':
        Navigator.of(context).pushReplacementNamed('/settings');
        break;
      case '/tables':
        Navigator.of(context).pushReplacementNamed('/tables');
        break;
      case '/waiters':
        Navigator.of(context).pushReplacementNamed('/waiters');
        break;
      case '/kitchen':
        Navigator.of(context).pushReplacementNamed('/kitchen');
        break;
      case '/tabs':
        Navigator.of(context).pushReplacementNamed('/tabs');
        break;
      case '/credit-notes':
        Navigator.of(context).pushReplacementNamed('/credit-notes');
        break;
      case '/receipts':
        Navigator.of(context).pushReplacementNamed('/receipts');
        break;
      default:
        Navigator.of(context).pushReplacementNamed(route);
        break;
    }
  }
}
