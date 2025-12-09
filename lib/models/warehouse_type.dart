/// Warehouse type enum representing different business types
///
/// Used to customize the UI and features based on the warehouse type
enum WarehouseType {
  restaurant('restaurant', 'Restaurant'),
  supermarket('supermarket', 'Supermarket'),
  pharmacie('pharmacie', 'Pharmacie'),
  electronique('electronique', 'Électronique');

  final String value;
  final String displayName;

  const WarehouseType(this.value, this.displayName);

  /// Get WarehouseType from string value
  static WarehouseType? fromString(String? value) {
    if (value == null) return null;

    try {
      return WarehouseType.values.firstWhere(
        (type) => type.value == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON value
  String toJson() => value;

  @override
  String toString() => displayName;
}