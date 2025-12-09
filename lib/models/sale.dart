
/// Sale model representing complete sales transactions
///
/// This class manages the entire sale transaction including items,
/// payment information, sync status, and financial calculations.
/// library;

import 'sale_item.dart';

class Sale {
  final String id;
  final String? warehouseId;
  final String? customerId;
  final String userId;
  final String deviceId;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final bool isSynced;
  final DateTime? syncedAt;
  final String? syncHash;
  final List<SaleItem> items;
  final DateTime createdAt;
  final String? cashRegisterId;

  // Restaurant-specific fields
  final String? serviceType; // 'dine_in', 'takeaway', 'delivery'
  final String? tableId;
  final String? tableNumber;
  final String? waiterId;
  final String? waiterName;
  final String? kitchenOrderId;
  final String? kitchenStatus; // 'pending', 'preparing', 'ready', 'served'

  Sale({
    required this.id,
    this.warehouseId,
    this.customerId,
    required this.userId,
    required this.deviceId,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    this.isSynced = false,
    this.syncedAt,
    this.syncHash,
    required this.items,
    required this.createdAt,
    this.cashRegisterId,
    // Restaurant fields
    this.serviceType,
    this.tableId,
    this.tableNumber,
    this.waiterId,
    this.waiterName,
    this.kitchenOrderId,
    this.kitchenStatus,
  });

  /// Calculates the total amount for the sale
  ///
  /// Formula: subtotal + taxAmount
  double calculateTotal() {
    return subtotal + taxAmount;
  }

  /// Calculates the subtotal from all sale items
  double calculateSubtotal() {
    return items.fold(0.0, (sum, item) {
      final itemSubtotal = item.quantity * item.price;
      final itemDiscount = item.discount ?? 0.0;
      return sum + (itemSubtotal - itemDiscount);
    });
  }

  /// Calculates the total tax amount from all sale items
  double calculateTax() {
    return items.fold(0.0, (sum, item) {
      final itemSubtotal = item.quantity * item.price;
      final itemDiscount = item.discount ?? 0.0;
      final taxableAmount = itemSubtotal - itemDiscount;
      final itemTax = taxableAmount * (item.taxRate / 100);
      return sum + itemTax;
    });
  }

  /// Converts Sale to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'customerId': customerId,
      'userId': userId,
      'deviceId': deviceId,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'isSynced': isSynced,
      'syncedAt': syncedAt?.toIso8601String(),
      'syncHash': syncHash,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'cashRegisterId': cashRegisterId,
      // Restaurant fields
      'serviceType': serviceType,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'kitchenOrderId': kitchenOrderId,
      'kitchenStatus': kitchenStatus,
    };
  }

  /// Converts Sale to API JSON map (snake_case for backend)
  Map<String, dynamic> toApiJson() {
    return {
      'warehouse_id': warehouseId,
      'customer_id': customerId,
      'user_id': userId,
      'device_id': deviceId,
      'total': total,
      'payment_method': paymentMethod,
      'items': items.map((item) => item.toApiJson(deviceId: deviceId)).toList(),
    };
  }

  /// Creates Sale from JSON map
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      warehouseId: json['warehouseId'] as String?,
      customerId: json['customerId'] as String?,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      syncHash: json['syncHash'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      cashRegisterId: json['cashRegisterId'] as String?,
      // Restaurant fields
      serviceType: json['serviceType'] as String?,
      tableId: json['tableId'] as String?,
      tableNumber: json['tableNumber'] as String?,
      waiterId: json['waiterId'] as String?,
      waiterName: json['waiterName'] as String?,
      kitchenOrderId: json['kitchenOrderId'] as String?,
      kitchenStatus: json['kitchenStatus'] as String?,
    );
  }

  /// Creates a copy of this Sale with updated fields
  Sale copyWith({
    String? id,
    String? warehouseId,
    String? customerId,
    String? userId,
    String? deviceId,
    double? subtotal,
    double? taxAmount,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    bool? isSynced,
    DateTime? syncedAt,
    String? syncHash,
    List<SaleItem>? items,
    DateTime? createdAt,
    String? cashRegisterId,
    String? serviceType,
    String? tableId,
    String? tableNumber,
    String? waiterId,
    String? waiterName,
    String? kitchenOrderId,
    String? kitchenStatus,
  }) {
    return Sale(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncHash: syncHash ?? this.syncHash,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      cashRegisterId: cashRegisterId ?? this.cashRegisterId,
      serviceType: serviceType ?? this.serviceType,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      kitchenOrderId: kitchenOrderId ?? this.kitchenOrderId,
      kitchenStatus: kitchenStatus ?? this.kitchenStatus,
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, total: $total, paymentStatus: $paymentStatus, itemCount: ${items.length}, isSynced: $isSynced)';
  }
}
