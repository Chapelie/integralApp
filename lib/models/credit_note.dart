// lib/models/credit_note.dart
// Modèle pour représenter un avoir (credit note)
library;

class CreditNote {
  final String id;
  final String? companyId;
  final String? warehouseId;
  final String? customerId; // Client lié (optionnel)
  final double initialAmount;
  final double remaining; // Solde restant
  final String currency;
  final String status; // 'open', 'consumed', 'expired'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? originSaleId; // Vente d'origine si créé à partir d'un remboursement
  final String? originRefundId; // Remboursement d'origine
  final bool isSynced;
  final DateTime? syncedAt;
  final String? syncHash;

  CreditNote({
    required this.id,
    this.companyId,
    this.warehouseId,
    this.customerId,
    required this.initialAmount,
    required this.remaining,
    this.currency = 'XOF',
    this.status = 'open',
    required this.createdAt,
    this.expiresAt,
    this.originSaleId,
    this.originRefundId,
    this.isSynced = false,
    this.syncedAt,
    this.syncHash,
  });

  bool get isActive => status == 'open' && remaining > 0;

  CreditNote copyWith({
    String? id,
    String? companyId,
    String? warehouseId,
    Object? customerId = const Object(),
    double? initialAmount,
    double? remaining,
    String? currency,
    String? status,
    DateTime? createdAt,
    Object? expiresAt = const Object(),
    Object? originSaleId = const Object(),
    Object? originRefundId = const Object(),
    bool? isSynced,
    Object? syncedAt = const Object(),
    Object? syncHash = const Object(),
  }) {
    return CreditNote(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      warehouseId: warehouseId ?? this.warehouseId,
      customerId: customerId == const Object() ? this.customerId : customerId as String?,
      initialAmount: initialAmount ?? this.initialAmount,
      remaining: remaining ?? this.remaining,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt == const Object() ? this.expiresAt : expiresAt as DateTime?,
      originSaleId: originSaleId == const Object() ? this.originSaleId : originSaleId as String?,
      originRefundId: originRefundId == const Object() ? this.originRefundId : originRefundId as String?,
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
      'initial_amount': initialAmount,
      'remaining': remaining,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'origin_sale_id': originSaleId,
      'origin_refund_id': originRefundId,
      'is_synced': isSynced,
      'synced_at': syncedAt?.toIso8601String(),
      'sync_hash': syncHash,
    };
  }

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      customerId: json['customer_id'] as String?,
      initialAmount: (json['initial_amount'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'XOF',
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      originSaleId: json['origin_sale_id'] as String?,
      originRefundId: json['origin_refund_id'] as String?,
      isSynced: json['is_synced'] as bool? ?? false,
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'] as String) : null,
      syncHash: json['sync_hash'] as String?,
    );
  }
}




