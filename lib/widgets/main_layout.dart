// lib/widgets/main_layout.dart
// Layout principal avec sidebar pour tous les écrans

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive_helper.dart';
import '../features/pos/widgets/sidebar.dart';
import '../features/pos/widgets/hamburger_menu.dart';
import '../providers/navigation_provider.dart';

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
    // Obtenir la route actuelle depuis le provider si disponible, sinon utiliser celle passée en paramètre
    final navigationState = ref.watch(navigationProvider);
    final activeRoute = navigationState.currentRoute.path;

    if (isDesktop) {
      // Desktop with fixed sidebar
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: Row(
          children: [
            Sidebar(
              currentRoute: activeRoute,
              onNavigate: (route) => _handleNavigation(context, ref, route),
            ),
            Expanded(child: child),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    } else {
      // Mobile with drawer + universal hamburger
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildMobileAppBar(context),
        drawer: HamburgerMenu(
          currentRoute: activeRoute,
          onNavigate: (route) => _handleNavigation(context, ref, route),
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
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent, // Évite les couleurs qui se chevauchent
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

  void _handleNavigation(BuildContext context, WidgetRef ref, String route) {
    if (route == currentRoute) return;

    // Met à jour l'état de navigation (IndexedStack)
    ref.read(navigationProvider.notifier).navigateToPath(route);

    // Assure un vrai changement de page même depuis une page "hors shell" (ex: formulaires)
    final currentName = ModalRoute.of(context)?.settings.name;
    if (currentName != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }
}
