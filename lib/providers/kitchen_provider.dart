// kitchen_provider.dart
// Provider for managing kitchen orders state
// Uses Riverpod for state management

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/kitchen_order.dart';
import '../models/sale_item.dart';
import '../core/kitchen_service.dart';

part 'kitchen_provider.g.dart';

/// Provider for KitchenService
@riverpod
KitchenService kitchenService(Ref ref) {
  return KitchenService();
}

/// Provider for all kitchen orders
@riverpod
class KitchenOrderList extends _$KitchenOrderList {
  @override
  Future<List<KitchenOrder>> build() async {
    final service = ref.watch(kitchenServiceProvider);
    return await service.getAllOrders();
  }

  /// Refresh orders list
  Future<void> refresh({bool forceRefresh = true}) async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    if (!ref.mounted) return;
    state = await AsyncValue.guard(() async {
      if (!ref.mounted) return <KitchenOrder>[];
      final service = ref.read(kitchenServiceProvider);
      return await service.getAllOrders(forceRefresh: forceRefresh);
    });
  }

  /// Create a new kitchen order
  Future<KitchenOrder> createOrder({
    required String saleId,
    required List<SaleItem> items,
    String? tableNumber,
    String? waiterName,
    String? notes,
  }) async {
    try {
      final service = ref.read(kitchenServiceProvider);
      final order = await service.createOrder(
        saleId: saleId,
        items: items,
        tableNumber: tableNumber,
        waiterName: waiterName,
        notes: notes,
      );
      await refresh();
      return order;
    } catch (e) {
      print('[KitchenOrderList] Error creating order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    KitchenOrderStatus newStatus,
  ) async {
    try {
      final service = ref.read(kitchenServiceProvider);
      await service.updateOrderStatus(orderId, newStatus);
      await refresh();
    } catch (e) {
      print('[KitchenOrderList] Error updating order status: $e');
      rethrow;
    }
  }

  /// Start preparing order
  Future<void> startPreparing(String orderId) async {
    try {
      // Persist change first
      final service = ref.read(kitchenServiceProvider);
      await service.startPreparing(orderId);
      
      // Vérifier que le provider est encore monté avant de continuer
      if (!ref.mounted) return;
      
      // Refresh both providers to ensure UI updates immediately
      await refresh();
      
      // Vérifier à nouveau après refresh
      if (!ref.mounted) return;
      
      // Invalidate activeKitchenOrdersProvider to force refresh
      ref.invalidate(activeKitchenOrdersProvider);
    } catch (e) {
      print('[KitchenOrderList] Error starting preparation: $e');
      // Ne pas rethrow si le provider est disposé
      if (ref.mounted) {
        rethrow;
      }
    }
  }

  /// Mark order as ready
  Future<void> markAsReady(String orderId) async {
    try {
      // Persist change first
      final service = ref.read(kitchenServiceProvider);
      await service.markAsReady(orderId);
      
      // Vérifier que le provider est encore monté avant de continuer
      if (!ref.mounted) return;
      
      // Refresh both providers to ensure UI updates immediately
      await refresh();
      
      // Vérifier à nouveau après refresh
      if (!ref.mounted) return;
      
      // Invalidate activeKitchenOrdersProvider to force refresh
      ref.invalidate(activeKitchenOrdersProvider);
    } catch (e) {
      print('[KitchenOrderList] Error marking as ready: $e');
      // Ne pas rethrow si le provider est disposé
      if (ref.mounted) {
        rethrow;
      }
    }
  }

  /// Mark order as served
  Future<void> markAsServed(String orderId) async {
    try {
      // Persist change first
      final service = ref.read(kitchenServiceProvider);
      await service.markAsServed(orderId);
      
      // Vérifier que le provider est encore monté avant de continuer
      if (!ref.mounted) return;
      
      // Refresh both providers to ensure UI updates immediately
      await refresh();
      
      // Vérifier à nouveau après refresh
      if (!ref.mounted) return;
      
      // Invalidate activeKitchenOrdersProvider to force refresh
      ref.invalidate(activeKitchenOrdersProvider);
    } catch (e) {
      print('[KitchenOrderList] Error marking as served: $e');
      // Ne pas rethrow si le provider est disposé
      if (ref.mounted) {
        rethrow;
      }
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      final service = ref.read(kitchenServiceProvider);
      await service.cancelOrder(orderId);
      
      if (!ref.mounted) return;
      await refresh();
    } catch (e) {
      print('[KitchenOrderList] Error cancelling order: $e');
      if (ref.mounted) {
        rethrow;
      }
    }
  }

  /// Add items to an existing order
  Future<void> addItemsToOrder(String orderId, List<SaleItem> items) async {
    try {
      final service = ref.read(kitchenServiceProvider);
      await service.addItemsToOrder(orderId, items);
      
      if (!ref.mounted) return;
      await refresh();
      
      if (!ref.mounted) return;
      ref.invalidate(activeKitchenOrdersProvider);
    } catch (e) {
      print('[KitchenOrderList] Error adding items to order: $e');
      if (ref.mounted) {
        rethrow;
      }
    }
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      final service = ref.read(kitchenServiceProvider);
      await service.deleteOrder(orderId);
      
      if (!ref.mounted) return;
      await refresh();
    } catch (e) {
      print('[KitchenOrderList] Error deleting order: $e');
      if (ref.mounted) {
        rethrow;
      }
    }
  }
}

/// Provider for active kitchen orders
@riverpod
Future<List<KitchenOrder>> activeKitchenOrders(Ref ref) async {
  final service = ref.watch(kitchenServiceProvider);
  return await service.getActiveOrders();
}

/// Provider for orders by status
@riverpod
Future<List<KitchenOrder>> ordersByStatus(
  Ref ref,
  KitchenOrderStatus status,
) async {
  final service = ref.watch(kitchenServiceProvider);
  return await service.getOrdersByStatus(status);
}

/// Provider for kitchen statistics
@riverpod
Future<Map<String, dynamic>> kitchenStatistics(Ref ref) async {
  final service = ref.watch(kitchenServiceProvider);
  return await service.getKitchenStatistics();
}

/// Provider for order by sale ID
@riverpod
Future<KitchenOrder?> orderBySaleId(
  Ref ref,
  String saleId,
) async {
  final service = ref.watch(kitchenServiceProvider);
  return await service.getOrderBySaleId(saleId);
}
