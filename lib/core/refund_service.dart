// lib/core/refund_service.dart
// Service for managing refunds
// Handles refund CRUD operations with API sync
// Offline-first: local storage is primary, API sync in background

import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';
import '../models/sale_item.dart';

class RefundItem {
  final String saleItemId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double refundAmount;

  RefundItem({
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.refundAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'sale_item_id': saleItemId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'refund_amount': refundAmount,
    };
  }

  factory RefundItem.fromJson(Map<String, dynamic> json) {
    return RefundItem(
      saleItemId: json['sale_item_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      refundAmount: (json['refund_amount'] as num).toDouble(),
    );
  }
}

class Refund {
  final String id;
  final String warehouseId;
  final String saleId;
  final List<RefundItem> items;
  final double totalAmount;
  final String reason;
  final String status; // 'pending', 'processed'
  final String userId;
  final DateTime createdAt;
  final DateTime? processedAt;

  Refund({
    required this.id,
    required this.warehouseId,
    required this.saleId,
    required this.items,
    required this.totalAmount,
    required this.reason,
    this.status = 'pending',
    required this.userId,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'sale_id': saleId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'reason': reason,
      'status': status,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String,
      saleId: json['sale_id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => RefundItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'pending',
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }
}

class RefundService {
  static final RefundService _instance = RefundService._internal();
  factory RefundService() => _instance;
  RefundService._internal();

  final _storageService = StorageService();
  final _apiService = ApiService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _uuid = const Uuid();
  static const String _storageKey = 'refunds';

  /// Create a refund (offline-first: save local first, then sync to API)
  Future<Refund> createRefund({
    required String saleId,
    required List<RefundItem> items,
    required double totalAmount,
    required String reason,
    required String userId,
  }) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('No warehouse selected');
      }

      final now = DateTime.now();
      final refund = Refund(
        id: _uuid.v4(),
        warehouseId: warehouseId,
        saleId: saleId,
        items: items,
        totalAmount: totalAmount,
        reason: reason,
        userId: userId,
        createdAt: now,
      );

      // 1. Save locally first (immediate response)
      await _saveRefundLocally(refund);

      print('[RefundService] Refund created locally: ${refund.id}');

      // 2. Sync to API in background (non-blocking)
      _createRefundInAPI(refund).catchError((e) {
        print('[RefundService] API sync error (refund will sync later): $e');
        // Refund is already saved locally, will sync later
      });

      return refund;
    } catch (e) {
      print('[RefundService] Error creating refund: $e');
      rethrow;
    }
  }

  /// Create refund in API
  Future<void> _createRefundInAPI(Refund refund) async {
    try {
      final endpoint = AppConstants.refundsEndpoint(refund.warehouseId);
      final response = await _apiService.post(
        endpoint,
        data: refund.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[RefundService] Refund synced to API: ${refund.id}');
        // Update local refund with API response if needed
        if (response.data['data'] != null) {
          final apiRefund = Refund.fromJson(response.data['data']);
          await _saveRefundLocally(apiRefund);
        }
      }
    } catch (e) {
      print('[RefundService] Error creating refund in API: $e');
      rethrow;
    }
  }

  /// Process a refund (offline-first: save local first, then sync to API)
  Future<Refund> processRefund(String refundId) async {
    try {
      // 1. Update locally first
      final refund = await _getRefundLocally(refundId);
      if (refund == null) {
        throw Exception('Refund not found');
      }

      final processedRefund = Refund(
        id: refund.id,
        warehouseId: refund.warehouseId,
        saleId: refund.saleId,
        items: refund.items,
        totalAmount: refund.totalAmount,
        reason: refund.reason,
        status: 'processed',
        userId: refund.userId,
        createdAt: refund.createdAt,
        processedAt: DateTime.now(),
      );

      await _saveRefundLocally(processedRefund);

      print('[RefundService] Refund processed locally: $refundId');

      // 2. Sync to API in background
      _processRefundInAPI(refund.warehouseId, refundId).catchError((e) {
        print('[RefundService] API sync error: $e');
      });

      return processedRefund;
    } catch (e) {
      print('[RefundService] Error processing refund: $e');
      rethrow;
    }
  }

  /// Process refund in API
  Future<void> _processRefundInAPI(String warehouseId, String refundId) async {
    try {
      final endpoint = AppConstants.processRefundEndpoint(warehouseId, refundId);
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        print('[RefundService] Refund processed in API: $refundId');
      }
    } catch (e) {
      print('[RefundService] Error processing refund in API: $e');
      rethrow;
    }
  }

  /// Save refund locally
  Future<void> _saveRefundLocally(Refund refund) async {
    try {
      final refunds = await _getAllRefundsLocally();
      final index = refunds.indexWhere((r) => r.id == refund.id);
      
      if (index >= 0) {
        refunds[index] = refund;
      } else {
        refunds.add(refund);
      }

      final refundsJson = refunds.map((r) => r.toJson()).toList();
      await _storageService.writeSetting(_storageKey, refundsJson);
    } catch (e) {
      print('[RefundService] Error saving refund locally: $e');
      rethrow;
    }
  }

  /// Get refund locally
  Future<Refund?> _getRefundLocally(String refundId) async {
    try {
      final refunds = await _getAllRefundsLocally();
      return refunds.firstWhere((r) => r.id == refundId);
    } catch (e) {
      return null;
    }
  }

  /// Get all refunds locally
  Future<List<Refund>> _getAllRefundsLocally() async {
    try {
      final refundsData = _storageService.readSetting(_storageKey);
      if (refundsData == null || refundsData is! List) {
        return [];
      }
      return refundsData
          .map((json) => Refund.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[RefundService] Error getting refunds locally: $e');
      return [];
    }
  }

  /// Get all refunds (offline-first: local first, then sync with API)
  Future<List<Refund>> getAllRefunds({bool forceRefresh = false}) async {
    try {
      // 1. Read from local storage first
      List<Refund> localRefunds = await _getAllRefundsLocally();

      // 2. If not forcing refresh and we have local data, return it immediately
      if (!forceRefresh && localRefunds.isNotEmpty) {
        // Sync with API in background (non-blocking)
        _syncRefundsFromAPI().catchError((e) {
          print('[RefundService] Background sync error: $e');
        });
        return localRefunds;
      }

      // 3. Try to sync from API (if forcing refresh or no local data)
      try {
        final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
        if (warehouseId != null) {
          final apiRefunds = await _fetchRefundsFromAPI(warehouseId);
          if (apiRefunds.isNotEmpty) {
            // Save to local storage
            for (final refund in apiRefunds) {
              await _saveRefundLocally(refund);
            }
            return apiRefunds;
          }
        }
      } catch (e) {
        print('[RefundService] API sync failed, using local data: $e');
      }

      // 4. Fallback to local data
      return localRefunds;
    } catch (e) {
      print('[RefundService] Error getting refunds: $e');
      return [];
    }
  }

  /// Fetch refunds from API
  Future<List<Refund>> _fetchRefundsFromAPI(String warehouseId) async {
    try {
      final endpoint = AppConstants.refundsEndpoint(warehouseId);
      print('[RefundService] Fetching refunds from API: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> refundsData = response.data['data'] ?? [];
        return refundsData
            .map((json) => Refund.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[RefundService] Error fetching from API: $e');
      rethrow;
    }
  }

  /// Sync refunds from API in background
  Future<void> _syncRefundsFromAPI() async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) return;

      final apiRefunds = await _fetchRefundsFromAPI(warehouseId);
      if (apiRefunds.isNotEmpty) {
        // Save to local storage
        for (final refund in apiRefunds) {
          await _saveRefundLocally(refund);
        }
        print('[RefundService] Refunds synced from API: ${apiRefunds.length}');
      }
    } catch (e) {
      print('[RefundService] Background sync error: $e');
      // Silent fail - local data is still available
    }
  }

  /// Get refund by ID
  Future<Refund?> getRefundById(String refundId) async {
    try {
      final refunds = await getAllRefunds();
      return refunds.firstWhere((r) => r.id == refundId);
    } catch (e) {
      return null;
    }
  }

  /// Get refunds by sale ID
  Future<List<Refund>> getRefundsBySaleId(String saleId) async {
    try {
      final refunds = await getAllRefunds();
      return refunds.where((r) => r.saleId == saleId).toList();
    } catch (e) {
      return [];
    }
  }
}










