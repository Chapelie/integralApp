/// Enum representing different types of businesses supported by IntegralPOS
///
/// This enum defines the various business categories that can use the application,
/// each with its own display name and icon representation.
library;

enum BusinessType {
  restaurant,
  supermarket,
  pharmacy,
  electronics,
  fashion,
  other;

  /// Returns the localized display name for the business type
  ///
  /// [locale] - The locale code (e.g., 'fr', 'en')
  String displayName(String locale) {
    switch (this) {
      case BusinessType.restaurant:
        return locale == 'fr' ? 'Restaurant' : 'Restaurant';
      case BusinessType.supermarket:
        return locale == 'fr' ? 'Supermarché' : 'Supermarket';
      case BusinessType.pharmacy:
        return locale == 'fr' ? 'Pharmacie' : 'Pharmacy';
      case BusinessType.electronics:
        return locale == 'fr' ? 'Électronique' : 'Electronics';
      case BusinessType.fashion:
        return locale == 'fr' ? 'Mode' : 'Fashion';
      case BusinessType.other:
        return locale == 'fr' ? 'Autre' : 'Other';
    }
  }

  /// Returns the icon name/identifier for the business type
  ///
  /// Can be used with icon libraries or asset references
  String get icon {
    switch (this) {
      case BusinessType.restaurant:
        return 'restaurant';
      case BusinessType.supermarket:
        return 'shopping_cart';
      case BusinessType.pharmacy:
        return 'local_pharmacy';
      case BusinessType.electronics:
        return 'devices';
      case BusinessType.fashion:
        return 'checkroom';
      case BusinessType.other:
        return 'business';
    }
  }
}
