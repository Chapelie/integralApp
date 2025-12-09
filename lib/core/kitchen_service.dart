// kitchen_service.dart
// Service for managing kitchen orders
// Handles kitchen order lifecycle and status updates
// Offline-first: local storage is primary, API sync in background

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/kitchen_order.dart';
import '../models/sale_item.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';

class KitchenService {
  static final KitchenService _instance = KitchenService._internal();
  factory KitchenService() => _instance;
  KitchenService._internal();

  final _storageService = StorageService();
  final _apiService = ApiService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _uuid = const Uuid();
  static const String _storageKey = 'kitchen_orders';

  /// Get all kitchen orders (offline-first: local first, then sync with API)
  Future<List<KitchenOrder>> getAllOrders({bool forceRefresh = false}) async {
    try {
      // 1. Read from local storage first (for immediate display)
      final ordersJson = _storageService.readSetting(_storageKey);
      List<KitchenOrder> localOrders = [];

      if (ordersJson != null) {
        final List<dynamic> ordersList = jsonDecode(ordersJson as String);
        localOrders = ordersList
            .map((json) => KitchenOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 2. If not forcing refresh and we have local data, return it immediately
      if (!forceRefresh && localOrders.isNotEmpty) {
        // Sync with API in background (non-blocking)
        _syncOrdersFromAPI().catchError((e) {
          print('[KitchenService] Background sync error: $e');
        });
        return localOrders;
      }

      // 3. Try to sync from API (if forcing refresh or no local data)
      try {
        final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
        if (warehouseId != null) {
          final apiOrders = await _fetchOrdersFromAPI(warehouseId);
          if (apiOrders.isNotEmpty) {
            await _saveOrders(apiOrders);
            return apiOrders;
          }
        }
      } catch (e) {
        print('[KitchenService] API sync failed, using local data: $e');
      }

      // 4. Fallback to local data
      return localOrders;
    } catch (e) {
      print('[KitchenService] Error getting orders: $e');
      return [];
    }
  }

  /// Fetch orders from API
  Future<List<KitchenOrder>> _fetchOrdersFromAPI(String warehouseId) async {
    try {
      final endpoint = AppConstants.kitchenTicketsEndpoint(warehouseId);
      print('[KitchenService] Fetching orders from API: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> ordersData = response.data['data'] ?? [];
        return ordersData
            .map((json) => KitchenOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[KitchenService] Error fetching from API: $e');
      rethrow;
    }
  }

  /// Sync orders from API in background
  Future<void> _syncOrdersFromAPI() async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) return;

      final apiOrders = await _fetchOrdersFromAPI(warehouseId);
      if (apiOrders.isNotEmpty) {
        await _saveOrders(apiOrders);
        print('[KitchenService] Orders synced from API: ${apiOrders.length}');
      }
    } catch (e) {
      print('[KitchenService] Background sync error: $e');
      // Silent fail - local data is still available
    }
  }

  /// Get active kitchen orders (not served or cancelled)
  Future<List<KitchenOrder>> getActiveOrders() async {
    try {
      final orders = await getAllOrders();
      return orders
          .where((order) =>
              order.status != KitchenOrderStatus.served &&
              order.status != KitchenOrderStatus.cancelled)
          .toList();
    } catch (e) {
      print('[KitchenService] Error getting active orders: $e');
      return [];
    }
  }

  /// Get orders by status
  Future<List<KitchenOrder>> getOrdersByStatus(
      KitchenOrderStatus status) async {
    try {
      final orders = await getAllOrders();
      return orders.where((order) => order.status == status).toList();
    } catch (e) {
      print('[KitchenService] Error getting orders by status: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<KitchenOrder?> getOrderById(String id) async {
    try {
      final orders = await getAllOrders();
      return orders.firstWhere((order) => order.id == id);
    } catch (e) {
      print('[KitchenService] Error getting order by ID: $e');
      return null;
    }
  }

  /// Get order by sale ID
  Future<KitchenOrder?> getOrderBySaleId(String saleId) async {
    try {
      final orders = await getAllOrders();
      return orders.firstWhere((order) => order.saleId == saleId);
    } catch (e) {
      print('[KitchenService] Error getting order by sale ID: $e');
      return null;
    }
  }

  /// Create a new kitchen order (offline-first: save local first, then sync to API)
  Future<KitchenOrder> createOrder({
    required String saleId,
    required List<SaleItem> items,
    String? tableNumber,
    String? waiterName,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final order = KitchenOrder(
        id: _uuid.v4(),
        saleId: saleId,
        tableNumber: tableNumber,
        waiterName: waiterName,
        items: items,
        status: KitchenOrderStatus.pending,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save locally first (immediate response)
      final orders = await getAllOrders();
      orders.add(order);
      await _saveOrders(orders);

      print('[KitchenService] Kitchen order created locally: ${order.id}');

      // 2. Sync to API in background (non-blocking)
      _createOrderInAPI(order).catchError((e) {
        print('[KitchenService] API sync error (order will sync later): $e');
        // Order is already saved locally, will sync later
      });

      return order;
    } catch (e) {
      print('[KitchenService] Error creating order: $e');
      rethrow;
    }
  }

  /// Create order in API
  Future<void> _createOrderInAPI(KitchenOrder order) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        print('[KitchenService] No warehouse ID, skipping API sync');
        return;
      }

      final endpoint = AppConstants.kitchenTicketsEndpoint(warehouseId);
      final response = await _apiService.post(
        endpoint,
        data: {
          'sale_id': order.saleId,
          'items': order.items.map((item) => item.toJson()).toList(),
          'table_number': order.tableNumber,
          'waiter_name': order.waiterName,
          'notes': order.notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[KitchenService] Order synced to API: ${order.id}');
      }
    } catch (e) {
      print('[KitchenService] Error creating order in API: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<KitchenOrder> updateOrderStatus(
    String orderId,
    KitchenOrderStatus newStatus,
  ) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      DateTime? startedAt = order.startedAt;
      DateTime? readyAt = order.readyAt;
      DateTime? servedAt = order.servedAt;

      switch (newStatus) {
        case KitchenOrderStatus.preparing:
          startedAt ??= DateTime.now();
          break;
        case KitchenOrderStatus.ready:
          readyAt ??= DateTime.now();
          break;
        case KitchenOrderStatus.served:
          servedAt ??= DateTime.now();
          break;
        default:
          break;
      }

      final updatedOrder = order.copyWith(
        status: newStatus,
        startedAt: startedAt,
        readyAt: readyAt,
        servedAt: servedAt,
        updatedAt: DateTime.now(),
      );

      return await updateOrder(updatedOrder);
    } catch (e) {
      print('[KitchenService] Error updating order status: $e');
      rethrow;
    }
  }

  /// Update kitchen order (offline-first: save local first, then sync to API)
  Future<KitchenOrder> updateOrder(KitchenOrder order) async {
    try {
      final orders = await getAllOrders();
      final index = orders.indexWhere((o) => o.id == order.id);

      if (index == -1) {
        throw Exception('Order not found');
      }

      final updatedOrder = order.copyWith(updatedAt: DateTime.now());
      orders[index] = updatedOrder;
      await _saveOrders(orders);

      print('[KitchenService] Order updated locally: ${order.id}');

      // Sync to API in background
      _updateOrderInAPI(updatedOrder).catchError((e) {
        print('[KitchenService] API sync error (order will sync later): $e');
      });

      return updatedOrder;
    } catch (e) {
      print('[KitchenService] Error updating order: $e');
      rethrow;
    }
  }

  /// Update order in API
  Future<void> _updateOrderInAPI(KitchenOrder order) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) return;

      final endpoint = AppConstants.kitchenTicketEndpoint(warehouseId, order.id);
      await _apiService.put(
        endpoint,
        data: order.toJson(),
      );
      print('[KitchenService] Order synced to API: ${order.id}');
    } catch (e) {
      print('[KitchenService] Error updating order in API: $e');
      rethrow;
    }
  }

  /// Mark order as preparing
  Future<KitchenOrder> startPreparing(String orderId) async {
    return await updateOrderStatus(orderId, KitchenOrderStatus.preparing);
  }

  /// Mark order as ready
  Future<KitchenOrder> markAsReady(String orderId) async {
    return await updateOrderStatus(orderId, KitchenOrderStatus.ready);
  }

  /// Mark order as served
  Future<KitchenOrder> markAsServed(String orderId) async {
    return await updateOrderStatus(orderId, KitchenOrderStatus.served);
  }

  /// Cancel order
  Future<KitchenOrder> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, KitchenOrderStatus.cancelled);
  }

  /// Add items to an existing kitchen order
  Future<KitchenOrder> addItemsToOrder(String orderId, List<SaleItem> newItems) async {
    try {
      final orders = await getAllOrders();
      final index = orders.indexWhere((o) => o.id == orderId);

      if (index == -1) {
        throw Exception('Order not found');
      }

      final order = orders[index];
      
      // Merge new items with existing items
      // If a product already exists, increase quantity; otherwise add new item
      final updatedItems = List<SaleItem>.from(order.items);
      
      for (final newItem in newItems) {
        final existingIndex = updatedItems.indexWhere(
          (item) => item.productId == newItem.productId,
        );
        
        if (existingIndex >= 0) {
          // Product exists, increase quantity
          final existingItem = updatedItems[existingIndex];
          updatedItems[existingIndex] = SaleItem(
            productId: existingItem.productId,
            productName: existingItem.productName,
            quantity: existingItem.quantity + newItem.quantity,
            price: existingItem.price,
            taxRate: existingItem.taxRate,
            lineTotal: existingItem.price * (existingItem.quantity + newItem.quantity),
            discount: existingItem.discount,
          );
        } else {
          // New product, add it
          updatedItems.add(newItem);
        }
      }

      final updatedOrder = order.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      
      orders[index] = updatedOrder;
      await _saveOrders(orders);

      print('[KitchenService] Items added to order: $orderId (${newItems.length} new items)');
      return updatedOrder;
    } catch (e) {
      print('[KitchenService] Error adding items to order: $e');
      rethrow;
    }
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      final orders = await getAllOrders();
      orders.removeWhere((order) => order.id == orderId);
      await _saveOrders(orders);

      print('[KitchenService] Order deleted: $orderId');
    } catch (e) {
      print('[KitchenService] Error deleting order: $e');
      rethrow;
    }
  }

  /// Save orders to storage
  Future<void> _saveOrders(List<KitchenOrder> orders) async {
    try {
      final ordersJson = jsonEncode(
        orders.map((order) => order.toJson()).toList(),
      );
      await _storageService.writeSetting(_storageKey, ordersJson);
    } catch (e) {
      print('[KitchenService] Error saving orders: $e');
      rethrow;
    }
  }

  /// Get kitchen statistics
  Future<Map<String, dynamic>> getKitchenStatistics() async {
    try {
      final orders = await getAllOrders();
      final activeOrders = orders.where((o) =>
        o.status != KitchenOrderStatus.served &&
        o.status != KitchenOrderStatus.cancelled
      ).toList();

      return {
        'total': orders.length,
        'active': activeOrders.length,
        'pending': orders.where((o) => o.status == KitchenOrderStatus.pending).length,
        'preparing': orders.where((o) => o.status == KitchenOrderStatus.preparing).length,
        'ready': orders.where((o) => o.status == KitchenOrderStatus.ready).length,
        'served': orders.where((o) => o.status == KitchenOrderStatus.served).length,
        'cancelled': orders.where((o) => o.status == KitchenOrderStatus.cancelled).length,
        'averageWaitTime': _calculateAverageWaitTime(orders),
      };
    } catch (e) {
      print('[KitchenService] Error getting statistics: $e');
      return {};
    }
  }

  /// Calculate average wait time
  double _calculateAverageWaitTime(List<KitchenOrder> orders) {
    final completedOrders = orders.where((o) => o.servedAt != null).toList();

    if (completedOrders.isEmpty) {
      return 0.0;
    }

    final totalMinutes = completedOrders.fold<int>(
      0,
      (sum, order) => sum + (order.getWaitingTime() ?? 0),
    );

    return totalMinutes / completedOrders.length;
  }

  /// Clear old orders (older than specified days)
  Future<void> clearOldOrders({int daysToKeep = 7}) async {
    try {
      final orders = await getAllOrders();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final recentOrders = orders.where((order) {
        return order.createdAt.isAfter(cutoffDate);
      }).toList();

      await _saveOrders(recentOrders);
      print('[KitchenService] Old orders cleared');
    } catch (e) {
      print('[KitchenService] Error clearing old orders: $e');
      rethrow;
    }
  }

  /// Clear all orders
  Future<void> clearAllOrders() async {
    try {
      await _storageService.deleteSetting(_storageKey);
      if (kDebugMode) {
        print('[KitchenService] All orders cleared');
      }
    } catch (e) {
      print('[KitchenService] Error clearing all orders: $e');
      rethrow;
    }
  }
}
