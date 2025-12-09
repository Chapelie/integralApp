// lib/providers/navigation_provider.dart
// Provider pour gérer la navigation avec IndexedStack

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRoute {
  pos('/pos'),
  products('/products'),
  customers('/customers'),
  inventory('/inventory'),
  employees('/employees'),
  cashRegister('/cash-register'),
  reports('/reports'),
  receipts('/receipts'),
  accounting('/accounting'),
  settings('/settings'),
  tables('/tables'),
  waiters('/waiters'),
  kitchen('/kitchen');

  final String path;
  const AppRoute(this.path);

  static AppRoute? fromPath(String path) {
    try {
      return AppRoute.values.firstWhere((r) => r.path == path);
    } catch (e) {
      return null;
    }
  }
}

class NavigationState {
  final AppRoute currentRoute;

  NavigationState({required this.currentRoute});

  NavigationState copyWith({AppRoute? currentRoute}) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return NavigationState(currentRoute: AppRoute.pos);
  }

  void navigateTo(AppRoute route) {
    if (state.currentRoute == route) return;
    state = state.copyWith(currentRoute: route);
  }

  void navigateToPath(String path) {
    final route = AppRoute.fromPath(path);
    if (route != null) {
      navigateTo(route);
    }
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(
  () => NavigationNotifier(),
);

