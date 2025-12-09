/// Customer model representing clients in the IntegralPOS system
///
/// This class manages customer information including contact details
/// and timestamps for tracking customer activity.
library;

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Converts Customer to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates Customer from JSON map
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      companyId: json['companyId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Creates a copy of this Customer with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.address == address &&
        other.companyId == companyId &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        companyId.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
