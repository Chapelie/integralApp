// lib/models/cash_movement.dart
/// Cash movement model representing cash register movements
///
/// This class manages cash movement information for tracking
/// all cash transactions in the IntegralPOS system.
library;

class CashMovement {
  final String id;
  final String cashRegisterId;
  final String type; // 'sale', 'manual_in', 'manual_out', 'opening', 'closing'
  final double amount;
  final String? description;
  final String? saleId; // Reference to sale if movement is from a sale
  final String? userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CashMovement({
    required this.id,
    required this.cashRegisterId,
    required this.type,
    required this.amount,
    this.description,
    this.saleId,
    this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Converts CashMovement to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cash_register_id': cashRegisterId,
      'type': type,
      'amount': amount,
      'description': description,
      'sale_id': saleId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates CashMovement from JSON map
  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: json['id'] as String,
      cashRegisterId: json['cash_register_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      saleId: json['sale_id'] as String?,
      userId: json['user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Creates a copy of this CashMovement with updated fields
  CashMovement copyWith({
    String? id,
    String? cashRegisterId,
    String? type,
    double? amount,
    String? description,
    String? saleId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashMovement(
      id: id ?? this.id,
      cashRegisterId: cashRegisterId ?? this.cashRegisterId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      saleId: saleId ?? this.saleId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

