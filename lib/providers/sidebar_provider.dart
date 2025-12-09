// lib/providers/sidebar_provider.dart
// Provider pour gérer l'état de collapse de la sidebar

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SidebarNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadCollapseState();
    return false;
  }

  Future<void> _loadCollapseState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCollapsed = prefs.getBool('sidebar_collapsed') ?? false;
    state = savedCollapsed;
  }

  Future<void> toggleCollapse() async {
    final newState = !state;
    state = newState;
    
    // Sauvegarder l'état
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_collapsed', newState);
  }

  Future<void> setCollapsed(bool collapsed) async {
    state = collapsed;
    
    // Sauvegarder l'état
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_collapsed', collapsed);
  }
}

final sidebarProvider = NotifierProvider<SidebarNotifier, bool>(() {
  return SidebarNotifier();
});
