// lib/models/warehouse.dart
// Modèle pour les warehouses

class Warehouse {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warehouse({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.type,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      type: json['type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Warehouse copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



