// lib/core/stock_adjustment_service.dart
// Service for managing stock adjustments
// Handles stock adjustment CRUD operations with API sync
// Offline-first: local storage is primary, API sync in background

import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';

class StockAdjustmentItem {
  final String productId;
  final int quantity;
  final String reason;

  StockAdjustmentItem({
    required this.productId,
    required this.quantity,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'reason': reason,
    };
  }
}

class StockAdjustment {
  final String id;
  final String warehouseId;
  final List<StockAdjustmentItem> items;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final String status; // 'pending', 'completed'

  StockAdjustment({
    required this.id,
    required this.warehouseId,
    required this.items,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => StockAdjustmentItem(
                productId: item['product_id'] as String,
                quantity: item['quantity'] as int,
                reason: item['reason'] as String,
              ))
          .toList(),
      notes: json['notes'] as String?,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class StockAdjustmentService {
  static final StockAdjustmentService _instance = StockAdjustmentService._internal();
  factory StockAdjustmentService() => _instance;
  StockAdjustmentService._internal();

  final _storageService = StorageService();
  final _apiService = ApiService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _uuid = const Uuid();
  static const String _storageKey = 'stock_adjustments';

  /// Create a stock adjustment (offline-first: save local first, then sync to API)
  Future<StockAdjustment> createAdjustment({
    required List<StockAdjustmentItem> items,
    String? notes,
    required String userId,
  }) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('No warehouse selected');
      }

      final now = DateTime.now();
      final adjustment = StockAdjustment(
        id: _uuid.v4(),
        warehouseId: warehouseId,
        items: items,
        notes: notes,
        userId: userId,
        createdAt: now,
      );

      // 1. Save locally first (immediate response)
      await _saveAdjustmentLocally(adjustment);

      print('[StockAdjustmentService] Adjustment created locally: ${adjustment.id}');

      // 2. Sync to API in background (non-blocking)
      _createAdjustmentInAPI(adjustment).catchError((e) {
        print('[StockAdjustmentService] API sync error (adjustment will sync later): $e');
        // Adjustment is already saved locally, will sync later
      });

      return adjustment;
    } catch (e) {
      print('[StockAdjustmentService] Error creating adjustment: $e');
      rethrow;
    }
  }

  /// Create adjustment in API
  Future<void> _createAdjustmentInAPI(StockAdjustment adjustment) async {
    try {
      final endpoint = AppConstants.stockAdjustmentsEndpoint(adjustment.warehouseId);
      final response = await _apiService.post(
        endpoint,
        data: adjustment.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[StockAdjustmentService] Adjustment synced to API: ${adjustment.id}');
        // Update local adjustment with API response if needed
        if (response.data['data'] != null) {
          final apiAdjustment = StockAdjustment.fromJson(response.data['data']);
          await _saveAdjustmentLocally(apiAdjustment);
        }
      }
    } catch (e) {
      print('[StockAdjustmentService] Error creating adjustment in API: $e');
      rethrow;
    }
  }

  /// Complete a stock adjustment (offline-first: save local first, then sync to API)
  Future<StockAdjustment> completeAdjustment(String adjustmentId) async {
    try {
      // 1. Update locally first
      final adjustment = await _getAdjustmentLocally(adjustmentId);
      if (adjustment == null) {
        throw Exception('Adjustment not found');
      }

      final completedAdjustment = StockAdjustment(
        id: adjustment.id,
        warehouseId: adjustment.warehouseId,
        items: adjustment.items,
        notes: adjustment.notes,
        userId: adjustment.userId,
        createdAt: adjustment.createdAt,
        status: 'completed',
      );

      await _saveAdjustmentLocally(completedAdjustment);

      print('[StockAdjustmentService] Adjustment completed locally: $adjustmentId');

      // 2. Sync to API in background
      _completeAdjustmentInAPI(adjustment.warehouseId, adjustmentId).catchError((e) {
        print('[StockAdjustmentService] API sync error: $e');
      });

      return completedAdjustment;
    } catch (e) {
      print('[StockAdjustmentService] Error completing adjustment: $e');
      rethrow;
    }
  }

  /// Complete adjustment in API
  Future<void> _completeAdjustmentInAPI(String warehouseId, String adjustmentId) async {
    try {
      final endpoint = AppConstants.completeStockAdjustmentEndpoint(warehouseId, adjustmentId);
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        print('[StockAdjustmentService] Adjustment completed in API: $adjustmentId');
      }
    } catch (e) {
      print('[StockAdjustmentService] Error completing adjustment in API: $e');
      rethrow;
    }
  }

  /// Save adjustment locally
  Future<void> _saveAdjustmentLocally(StockAdjustment adjustment) async {
    try {
      final adjustments = await _getAllAdjustmentsLocally();
      final index = adjustments.indexWhere((a) => a.id == adjustment.id);
      
      if (index >= 0) {
        adjustments[index] = adjustment;
      } else {
        adjustments.add(adjustment);
      }

      final adjustmentsJson = adjustments.map((a) => a.toJson()).toList();
      await _storageService.writeSetting(_storageKey, adjustmentsJson);
    } catch (e) {
      print('[StockAdjustmentService] Error saving adjustment locally: $e');
      rethrow;
    }
  }

  /// Get adjustment locally
  Future<StockAdjustment?> _getAdjustmentLocally(String adjustmentId) async {
    try {
      final adjustments = await _getAllAdjustmentsLocally();
      return adjustments.firstWhere((a) => a.id == adjustmentId);
    } catch (e) {
      return null;
    }
  }

  /// Get all adjustments locally
  Future<List<StockAdjustment>> _getAllAdjustmentsLocally() async {
    try {
      final adjustmentsData = _storageService.readSetting(_storageKey);
      if (adjustmentsData == null || adjustmentsData is! List) {
        return [];
      }
      return adjustmentsData
          .map((json) => StockAdjustment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[StockAdjustmentService] Error getting adjustments locally: $e');
      return [];
    }
  }

  /// Get all adjustments (offline-first: local first, then sync with API)
  Future<List<StockAdjustment>> getAllAdjustments({bool forceRefresh = false}) async {
    try {
      // 1. Read from local storage first
      List<StockAdjustment> localAdjustments = await _getAllAdjustmentsLocally();

      // 2. If not forcing refresh and we have local data, return it immediately
      if (!forceRefresh && localAdjustments.isNotEmpty) {
        // Sync with API in background (non-blocking)
        _syncAdjustmentsFromAPI().catchError((e) {
          print('[StockAdjustmentService] Background sync error: $e');
        });
        return localAdjustments;
      }

      // 3. Try to sync from API (if forcing refresh or no local data)
      try {
        final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
        if (warehouseId != null) {
          final apiAdjustments = await _fetchAdjustmentsFromAPI(warehouseId);
          if (apiAdjustments.isNotEmpty) {
            // Save to local storage
            for (final adjustment in apiAdjustments) {
              await _saveAdjustmentLocally(adjustment);
            }
            return apiAdjustments;
          }
        }
      } catch (e) {
        print('[StockAdjustmentService] API sync failed, using local data: $e');
      }

      // 4. Fallback to local data
      return localAdjustments;
    } catch (e) {
      print('[StockAdjustmentService] Error getting adjustments: $e');
      return [];
    }
  }

  /// Fetch adjustments from API
  Future<List<StockAdjustment>> _fetchAdjustmentsFromAPI(String warehouseId) async {
    try {
      final endpoint = AppConstants.stockAdjustmentsEndpoint(warehouseId);
      print('[StockAdjustmentService] Fetching adjustments from API: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> adjustmentsData = response.data['data'] ?? [];
        return adjustmentsData
            .map((json) => StockAdjustment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[StockAdjustmentService] Error fetching from API: $e');
      rethrow;
    }
  }

  /// Sync adjustments from API in background
  Future<void> _syncAdjustmentsFromAPI() async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) return;

      final apiAdjustments = await _fetchAdjustmentsFromAPI(warehouseId);
      if (apiAdjustments.isNotEmpty) {
        // Save to local storage
        for (final adjustment in apiAdjustments) {
          await _saveAdjustmentLocally(adjustment);
        }
        print('[StockAdjustmentService] Adjustments synced from API: ${apiAdjustments.length}');
      }
    } catch (e) {
      print('[StockAdjustmentService] Background sync error: $e');
      // Silent fail - local data is still available
    }
  }
}








