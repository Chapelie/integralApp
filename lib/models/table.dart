/// Restaurant table model
///
/// Represents a table in a restaurant with its status and assigned waiter
library;

enum TableStatus {
  available('available', 'Disponible'),
  occupied('occupied', 'Occupée'),
  reserved('reserved', 'Réservée'),
  cleaning('cleaning', 'En nettoyage');

  final String value;
  final String label;

  const TableStatus(this.value, this.label);

  static TableStatus fromString(String value) {
    return TableStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TableStatus.available,
    );
  }
}

class RestaurantTable {
  final String id;
  final String number;
  final int capacity;
  final TableStatus status;
  final String? waiterId;
  final String? waiterName;
  final String? currentOrderId;
  final DateTime? occupiedSince;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.waiterId,
    this.waiterName,
    this.currentOrderId,
    this.occupiedSince,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts RestaurantTable to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'status': status.value,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'currentOrderId': currentOrderId,
      'occupiedSince': occupiedSince?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates RestaurantTable from JSON map
  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] as String,
      number: json['number'] as String,
      capacity: json['capacity'] as int,
      status: TableStatus.fromString(json['status'] as String),
      waiterId: json['waiterId'] as String?,
      waiterName: json['waiterName'] as String?,
      currentOrderId: json['currentOrderId'] as String?,
      occupiedSince: json['occupiedSince'] != null
          ? DateTime.parse(json['occupiedSince'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Creates a copy of this RestaurantTable with updated fields
  RestaurantTable copyWith({
    String? id,
    String? number,
    int? capacity,
    TableStatus? status,
    String? waiterId,
    String? waiterName,
    String? currentOrderId,
    DateTime? occupiedSince,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RestaurantTable(number: $number, status: ${status.label}, capacity: $capacity, waiter: $waiterName)';
  }
}
