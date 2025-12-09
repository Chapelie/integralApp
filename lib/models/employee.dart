// lib/models/employee.dart
/// Employee model representing system users/employees
///
/// This class manages employee information for user management
/// in the IntegralPOS system.
library;

class Employee {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role; // 'admin', 'manager', 'cashier', 'employee'
  final bool isActive;
  final String? companyId;
  final String? warehouseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.isActive = true,
    this.companyId,
    this.warehouseId,
    this.createdAt,
    this.updatedAt,
  });

  /// Converts Employee to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'company_id': companyId,
      'warehouse_id': warehouseId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates Employee from JSON map
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      companyId: json['company_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Creates a copy of this Employee with updated fields
  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    String? companyId,
    String? warehouseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      companyId: companyId ?? this.companyId,
      warehouseId: warehouseId ?? this.warehouseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

