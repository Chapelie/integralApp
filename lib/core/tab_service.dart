// lib/core/tab_service.dart
// Service for managing pending tabs (additions)
library;

import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';
import '../models/tab.dart';
import '../models/sale_item.dart';

/// Helper class to convert CartItem to TabItemInput
class TabItemInput {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double taxRate;
  final double lineTotal;

  TabItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.taxRate,
    required this.lineTotal,
  });

  SaleItem toSaleItem() {
    return SaleItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      price: price,
      taxRate: taxRate,
      lineTotal: lineTotal,
    );
  }
}

class TabService {
  static final TabService _instance = TabService._internal();
  factory TabService() => _instance;
  TabService._internal();

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();

  static const String _storageKey = 'tabs';

  /// Create a new tab (addition)
  Future<TabModel> createTab({
    String? customerId,
    String? tableId,
    String? tableNumber,
    String? waiterId,
    String? waiterName,
    required List<TabItemInput> items,
    required double subtotal,
    required double taxAmount,
    required double total,
    String? notes,
    bool isSynced = false,
  }) async {
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId == null) {
      throw Exception('No warehouse selected');
    }

    final tabItems = items.map((e) => e.toSaleItem()).toList();

    final tab = TabModel(
      id: const Uuid().v4(),
      warehouseId: warehouseId,
      customerId: customerId,
      tableId: tableId,
      tableNumber: tableNumber,
      waiterId: waiterId,
      waiterName: waiterName,
      items: tabItems,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      remaining: total,
      createdAt: DateTime.now(),
      notes: notes,
      isSynced: isSynced,
    );

    await _saveTabLocally(tab);

    // Attempt to sync with API in background
    try {
      final response = await _apiService.post(
        AppConstants.tabsEndpoint(warehouseId),
        data: tab.toJson(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final syncedId = response.data['data']['id'] as String? ?? tab.id;
        final updatedTab = tab.copyWith(id: syncedId, isSynced: true, syncedAt: DateTime.now());
        await _saveTabLocally(updatedTab);
        return updatedTab;
      }
    } catch (e) {
      print('Failed to sync tab ${tab.id}: $e');
    }

    return tab;
  }

  /// Get all open tabs
  Future<List<TabModel>> getAllOpenTabs({bool forceRefresh = false}) async {
    List<TabModel> localTabs = await _getAllTabsLocally();
    localTabs = localTabs.where((t) => t.status == 'open').toList();

    if (!forceRefresh && localTabs.isNotEmpty) {
      _syncTabsFromAPI().catchError((e) {
        print('[TabService] Background sync error: $e');
      });
      return localTabs;
    }

    final apiTabs = await _syncTabsFromAPI();
    return apiTabs.where((t) => t.status == 'open').toList();
  }

  /// Get a single tab by ID
  Future<TabModel?> getTab(String id) async {
    return await _getTabLocally(id);
  }

  /// Record a payment for a tab (partial or final)
  Future<TabModel> recordPayment(String id, double amountPaid) async {
    final existingTab = await _getTabLocally(id);
    if (existingTab == null) {
      throw Exception('Tab not found');
    }

    final newPaidAmount = (existingTab.paidAmount + amountPaid).clamp(0.0, existingTab.total);
    final newRemaining = (existingTab.total - newPaidAmount).clamp(0.0, double.infinity);
    final newStatus = newRemaining == 0 ? 'settled' : 'open';

    final updatedTab = existingTab.copyWith(
      paidAmount: newPaidAmount,
      remaining: newRemaining,
      status: newStatus,
      settledAt: newStatus == 'settled' ? DateTime.now() : null,
      isSynced: false,
    );

    await _saveTabLocally(updatedTab);

    // Attempt to sync update with API in background
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId != null) {
      try {
        final response = await _apiService.put(
          AppConstants.settleTabEndpoint(warehouseId, updatedTab.id),
          data: updatedTab.toJson(),
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final finalUpdatedTab = updatedTab.copyWith(isSynced: true, syncedAt: DateTime.now());
          await _saveTabLocally(finalUpdatedTab);
          return finalUpdatedTab;
        }
      } catch (e) {
        print('Failed to sync tab update ${updatedTab.id}: $e');
      }
    }

    return updatedTab;
  }

  /// Save tab locally
  Future<void> _saveTabLocally(TabModel tab) async {
    final tabs = await _getAllTabsLocally();
    final index = tabs.indexWhere((t) => t.id == tab.id);

    if (index >= 0) {
      tabs[index] = tab;
    } else {
      tabs.add(tab);
    }

    final tabsJson = tabs.map((t) => t.toJson()).toList();
    await _storageService.writeSetting(_storageKey, tabsJson);
  }

  /// Get tab locally
  Future<TabModel?> _getTabLocally(String id) async {
    final tabs = await _getAllTabsLocally();
    try {
      return tabs.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all tabs locally
  Future<List<TabModel>> _getAllTabsLocally() async {
    final tabsData = _storageService.readSetting(_storageKey);
    if (tabsData == null || tabsData is! List) {
      return [];
    }
    return tabsData.map((json) => TabModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Sync tabs from API
  Future<List<TabModel>> _syncTabsFromAPI() async {
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId == null) {
      return [];
    }

    try {
      final response = await _apiService.get(AppConstants.tabsEndpoint(warehouseId));
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<TabModel> apiTabs = (response.data['data'] as List)
            .map((json) => TabModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Merge with local data (API takes precedence for synced items)
        List<TabModel> mergedTabs = await _getAllTabsLocally();
        for (final apiTab in apiTabs) {
          final index = mergedTabs.indexWhere((t) => t.id == apiTab.id);
          if (index >= 0) {
            mergedTabs[index] = apiTab.copyWith(isSynced: true, syncedAt: DateTime.now());
          } else {
            mergedTabs.add(apiTab.copyWith(isSynced: true, syncedAt: DateTime.now()));
          }
        }
        await _storageService.writeSetting(_storageKey, mergedTabs.map((t) => t.toJson()).toList());
        return mergedTabs;
      }
      return await _getAllTabsLocally();
    } catch (e) {
      print('[TabService] Error syncing tabs from API: $e');
      return await _getAllTabsLocally();
    }
  }
}


