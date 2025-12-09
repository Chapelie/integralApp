/// Service type enum for restaurant orders
///
/// Represents different types of service for restaurant orders
library;

enum ServiceType {
  dineIn('dine_in', 'Sur place'),
  takeaway('takeaway', 'À emporter'),
  delivery('delivery', 'Livraison');

  final String value;
  final String label;

  const ServiceType(this.value, this.label);

  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ServiceType.dineIn,
    );
  }

  String displayName(String locale) {
    switch (this) {
      case ServiceType.dineIn:
        return locale == 'fr' ? 'Sur place' : 'Dine In';
      case ServiceType.takeaway:
        return locale == 'fr' ? 'À emporter' : 'Takeaway';
      case ServiceType.delivery:
        return locale == 'fr' ? 'Livraison' : 'Delivery';
    }
  }
}