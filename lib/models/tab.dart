// lib/models/tab.dart
// Modèle pour représenter une addition (tab) en attente de paiement
library;

import 'sale_item.dart';

class TabModel {
  final String id;
  final String? companyId;
  final String? warehouseId;
  final String? customerId;
  final String? tableId;
  final String? tableNumber;
  final String? waiterId;
  final String? waiterName;
  final List<SaleItem> items;
  final double subtotal;
  final double taxAmount;
  final double total;
  final double paidAmount; // Montant déjà payé sur cette addition
  final double remaining; // Reste à payer
  final String status; // 'open', 'settled', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final DateTime? settledAt;
  final bool isSynced;
  final DateTime? syncedAt;
  final String? syncHash;

  TabModel({
    required this.id,
    this.companyId,
    this.warehouseId,
    this.customerId,
    this.tableId,
    this.tableNumber,
    this.waiterId,
    this.waiterName,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.paidAmount = 0.0,
    required this.remaining,
    this.status = 'open',
    this.notes,
    required this.createdAt,
    this.settledAt,
    this.isSynced = false,
    this.syncedAt,
    this.syncHash,
  });

  TabModel copyWith({
    String? id,
    String? companyId,
    String? warehouseId,
    Object? customerId = const Object(),
    Object? tableId = const Object(),
    Object? tableNumber = const Object(),
    Object? waiterId = const Object(),
    Object? waiterName = const Object(),
    List<SaleItem>? items,
    double? subtotal,
    double? taxAmount,
    double? total,
    double? paidAmount,
    double? remaining,
    String? status,
    Object? notes = const Object(),
    DateTime? createdAt,
    Object? settledAt = const Object(),
    bool? isSynced,
    Object? syncedAt = const Object(),
    Object? syncHash = const Object(),
  }) {
    return TabModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      warehouseId: warehouseId ?? this.warehouseId,
      customerId: customerId == const Object() ? this.customerId : customerId as String?,
      tableId: tableId == const Object() ? this.tableId : tableId as String?,
      tableNumber: tableNumber == const Object() ? this.tableNumber : tableNumber as String?,
      waiterId: waiterId == const Object() ? this.waiterId : waiterId as String?,
      waiterName: waiterName == const Object() ? this.waiterName : waiterName as String?,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
      notes: notes == const Object() ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt == const Object() ? this.settledAt : settledAt as DateTime?,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt == const Object() ? this.syncedAt : syncedAt as DateTime?,
      syncHash: syncHash == const Object() ? this.syncHash : syncHash as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'warehouse_id': warehouseId,
      'customer_id': customerId,
      'table_id': tableId,
      'table_number': tableNumber,
      'waiter_id': waiterId,
      'waiter_name': waiterName,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      'paid_amount': paidAmount,
      'remaining': remaining,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'settled_at': settledAt?.toIso8601String(),
      'is_synced': isSynced,
      'synced_at': syncedAt?.toIso8601String(),
      'sync_hash': syncHash,
    };
  }

  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      customerId: json['customer_id'] as String?,
      tableId: json['table_id'] as String?,
      tableNumber: json['table_number'] as String?,
      waiterId: json['waiter_id'] as String?,
      waiterName: json['waiter_name'] as String?,
      items: (json['items'] as List<dynamic>).map((e) => SaleItem.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num).toDouble(),
      status: json['status'] as String? ?? 'open',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      settledAt: json['settled_at'] != null ? DateTime.parse(json['settled_at'] as String) : null,
      isSynced: json['is_synced'] as bool? ?? false,
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'] as String) : null,
      syncHash: json['sync_hash'] as String?,
    );
  }
}




