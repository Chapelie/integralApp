/// Waiter model for restaurant service
///
/// Represents a waiter/server in a restaurant
library;

class Waiter {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final bool isActive;
  final List<String> assignedTableIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Waiter({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isActive = true,
    this.assignedTableIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts Waiter to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'assignedTableIds': assignedTableIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates Waiter from JSON map
  factory Waiter.fromJson(Map<String, dynamic> json) {
    return Waiter(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      assignedTableIds: (json['assignedTableIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Creates a copy of this Waiter with updated fields
  Waiter copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isActive,
    List<String>? assignedTableIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Waiter(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      assignedTableIds: assignedTableIds ?? this.assignedTableIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Waiter(name: $name, isActive: $isActive, tables: ${assignedTableIds.length})';
  }
}
