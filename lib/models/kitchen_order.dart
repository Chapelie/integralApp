/// Kitchen order model for restaurant order tracking
///
/// Represents an order sent to the kitchen with preparation status
library;

import 'sale_item.dart';

enum KitchenOrderStatus {
  pending('pending', 'En attente'),
  preparing('preparing', 'En préparation'),
  ready('ready', 'Prêt'),
  served('served', 'Servi'),
  cancelled('cancelled', 'Annulé');

  final String value;
  final String label;

  const KitchenOrderStatus(this.value, this.label);

  static KitchenOrderStatus fromString(String value) {
    return KitchenOrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => KitchenOrderStatus.pending,
    );
  }
}

class KitchenOrder {
  final String id;
  final String saleId;
  final String? tableNumber;
  final String? waiterName;
  final List<SaleItem> items;
  final KitchenOrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final DateTime updatedAt;

  KitchenOrder({
    required this.id,
    required this.saleId,
    this.tableNumber,
    this.waiterName,
    required this.items,
    required this.status,
    this.notes,
    required this.createdAt,
    this.startedAt,
    this.readyAt,
    this.servedAt,
    required this.updatedAt,
  });

  /// Get duration in minutes since order was created
  int? getWaitingTime() {
    if (status == KitchenOrderStatus.served) {
      return servedAt?.difference(createdAt).inMinutes;
    }
    return DateTime.now().difference(createdAt).inMinutes;
  }

  /// Converts KitchenOrder to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'tableNumber': tableNumber,
      'waiterName': waiterName,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.value,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'servedAt': servedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates KitchenOrder from JSON map
  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      tableNumber: json['tableNumber'] as String?,
      waiterName: json['waiterName'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: KitchenOrderStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.parse(json['readyAt'] as String)
          : null,
      servedAt: json['servedAt'] != null
          ? DateTime.parse(json['servedAt'] as String)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Creates a copy of this KitchenOrder with updated fields
  KitchenOrder copyWith({
    String? id,
    String? saleId,
    String? tableNumber,
    String? waiterName,
    List<SaleItem>? items,
    KitchenOrderStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? readyAt,
    DateTime? servedAt,
    DateTime? updatedAt,
  }) {
    return KitchenOrder(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      tableNumber: tableNumber ?? this.tableNumber,
      waiterName: waiterName ?? this.waiterName,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      readyAt: readyAt ?? this.readyAt,
      servedAt: servedAt ?? this.servedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'KitchenOrder(table: $tableNumber, status: ${status.label}, items: ${items.length})';
  }
}
