// lib/models/company.dart
// Modèle pour les companies

class Company {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? logo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.logo,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logo: json['logo'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? logo,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



