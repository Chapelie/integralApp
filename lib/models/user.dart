/// User model representing system users and staff members
///
/// This class manages user information including authentication details,
/// roles, and warehouse/company associations.
library;

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? warehouseId;
  final String? companyId;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.warehouseId,
    this.companyId,
    this.isActive = true,
  });

  /// Converts User to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'warehouseId': warehouseId,
      'companyId': companyId,
      'isActive': isActive,
    };
  }

  /// Creates User from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      warehouseId: json['warehouseId'] as String?,
      companyId: json['companyId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Creates a copy of this User with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? warehouseId,
    String? companyId,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      warehouseId: warehouseId ?? this.warehouseId,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.warehouseId == warehouseId &&
        other.companyId == companyId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode ^
        warehouseId.hashCode ^
        companyId.hashCode ^
        isActive.hashCode;
  }
}
