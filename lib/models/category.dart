/// Category model representing product categories in the IntegralPOS system
///
/// This class manages category information for organizing products
/// and providing better product management capabilities.
library;

class Category {
  final String id;
  final String name;
  final String? description;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Converts Category to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates Category from JSON map
  factory Category.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime
    DateTime? safeParseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      companyId: json['company_id'] as String? ?? json['companyId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: safeParseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: safeParseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Creates a copy of this Category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

