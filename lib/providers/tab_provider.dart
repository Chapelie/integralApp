// lib/providers/tab_provider.dart
// Provider pour gérer les additions (tabs)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tab.dart';
import '../core/tab_service.dart';
import '../providers/cart_provider.dart';

// Tab State
class TabState {
  final List<TabModel> tabs;
  final bool isLoading;
  final String? error;

  TabState({
    this.tabs = const [],
    this.isLoading = false,
    this.error,
  });

  TabState copyWith({
    List<TabModel>? tabs,
    bool? isLoading,
    String? error,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Tab Notifier
class TabNotifier extends Notifier<TabState> {
  late final TabService _service;

  @override
  TabState build() {
    _service = ref.watch(tabServiceProvider);
    // Use Future.microtask to avoid circular dependency
    Future.microtask(() {
      if (ref.mounted) {
        load();
      }
    });
    return TabState();
  }

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final loadedTabs = await _service.getAllOpenTabs(forceRefresh: forceRefresh);
      state = state.copyWith(tabs: loadedTabs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await load(forceRefresh: true);
  }

  Future<TabModel?> createTabFromCart(CartState cartState) async {
    if (cartState.items.isEmpty) {
      state = state.copyWith(error: 'Le panier est vide pour créer une addition');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tabItems = cartState.items.map((cartItem) {
        return TabItemInput(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          quantity: cartItem.quantity,
          price: cartItem.product.price ?? 0.0,
          taxRate: cartItem.product.taxRate,
          lineTotal: (cartItem.product.price ?? 0.0) * cartItem.quantity,
        );
      }).toList();

      final newTab = await _service.createTab(
        customerId: cartState.selectedCustomer?.id,
        tableId: cartState.tableId,
        tableNumber: cartState.tableNumber,
        waiterId: cartState.waiterId,
        waiterName: cartState.waiterName,
        items: tabItems,
        subtotal: cartState.subtotal,
        taxAmount: cartState.taxAmount,
        total: cartState.total,
        notes: cartState.notes,
      );
      await load(forceRefresh: true);
      return newTab;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> settleTab(String tabId, double amountPaid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.recordPayment(tabId, amountPaid);
      await load(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tabProvider = NotifierProvider<TabNotifier, TabState>(
  () => TabNotifier(),
);

final tabServiceProvider = Provider((ref) => TabService());

