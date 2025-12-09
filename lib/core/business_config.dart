// lib/core/business_config.dart
// Business configuration singleton for managing business types and feature toggles
// Controls which features are enabled based on business type

import 'storage_service.dart';
import 'constants.dart';

/// Business type enum
enum BusinessType {
  retail('retail', 'Commerce de détail'),
  restaurant('restaurant', 'Restaurant'),
  service('service', 'Service'),
  wholesale('wholesale', 'Vente en gros'),
  other('other', 'Autre');

  final String value;
  final String label;

  const BusinessType(this.value, this.label);

  static BusinessType fromString(String value) {
    return BusinessType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BusinessType.other,
    );
  }
}

/// Business configuration singleton
class BusinessConfig {
  static final BusinessConfig _instance = BusinessConfig._internal();
  factory BusinessConfig() => _instance;
  BusinessConfig._internal();

  final _storageService = StorageService();

  BusinessType _currentType = BusinessType.retail;
  final Map<String, bool> _featureToggles = {};

  /// Initialize with business type
  Future<void> init([BusinessType? type]) async {
    try {
      print('[BusinessConfig] Initializing...');

      // Load business type from storage or use provided type
      if (type != null) {
        _currentType = type;
        await _storageService.writeSetting(
          AppConstants.businessTypeKey,
          type.value,
        );
      } else {
        final savedType = _storageService.readSetting(
          AppConstants.businessTypeKey,
          defaultValue: BusinessType.retail.value,
        ) as String;
        print('[BusinessConfig] Saved type retrieved: $savedType');
        _currentType = BusinessType.fromString(savedType);
        print('[BusinessConfig] Parsed type: ${_currentType.label} (${_currentType.value})');
      }

      // Configure features based on business type
      _configureFeatures();

      print('[BusinessConfig] Initialized with type: ${_currentType.label}');
      print('[BusinessConfig] Features: ${_featureToggles.keys.where((k) => _featureToggles[k] == true).join(', ')}');
    } catch (e) {
      print('[BusinessConfig] Initialization error: $e');
      rethrow;
    }
  }

  /// Configure features based on business type
  void _configureFeatures() {
    _featureToggles.clear();

    switch (_currentType) {
      case BusinessType.retail:
        _featureToggles['enableInventory'] = true;
        _featureToggles['enableCustomers'] = true;
        _featureToggles['enableEmployees'] = true;
        _featureToggles['enableReports'] = true;
        _featureToggles['enableDiscounts'] = true;
        _featureToggles['enableBarcode'] = true;
        _featureToggles['enableLoyalty'] = true;
        _featureToggles['enableMultiplePayments'] = true;
        _featureToggles['enableCategories'] = true;
        _featureToggles['enableSuppliers'] = false;
        _featureToggles['enableTables'] = false;
        _featureToggles['enableAppointments'] = false;
        break;

      case BusinessType.restaurant:
        _featureToggles['enableInventory'] = true;
        _featureToggles['enableCustomers'] = false;
        _featureToggles['enableEmployees'] = true;
        _featureToggles['enableReports'] = true;
        _featureToggles['enableDiscounts'] = false;
        _featureToggles['enableBarcode'] = false;
        _featureToggles['enableLoyalty'] = false;
        _featureToggles['enableMultiplePayments'] = true;
        _featureToggles['enableCategories'] = true;
        _featureToggles['enableSuppliers'] = false;
        _featureToggles['enableTables'] = true;
        _featureToggles['enableWaiters'] = true;
        _featureToggles['enableKitchen'] = true;
        _featureToggles['enableServiceTypes'] = true; // Sur place / À emporter
        _featureToggles['enableAppointments'] = false;
        _featureToggles['enableKitchenPrinting'] = true;
        _featureToggles['enableModifiers'] = true;
        break;

      case BusinessType.service:
        _featureToggles['enableInventory'] = false;
        _featureToggles['enableCustomers'] = true;
        _featureToggles['enableEmployees'] = true;
        _featureToggles['enableReports'] = true;
        _featureToggles['enableDiscounts'] = true;
        _featureToggles['enableBarcode'] = false;
        _featureToggles['enableLoyalty'] = false;
        _featureToggles['enableMultiplePayments'] = true;
        _featureToggles['enableCategories'] = true;
        _featureToggles['enableSuppliers'] = false;
        _featureToggles['enableTables'] = false;
        _featureToggles['enableAppointments'] = true;
        _featureToggles['enableServicePackages'] = true;
        break;

      case BusinessType.wholesale:
        _featureToggles['enableInventory'] = true;
        _featureToggles['enableCustomers'] = true;
        _featureToggles['enableEmployees'] = true;
        _featureToggles['enableReports'] = true;
        _featureToggles['enableDiscounts'] = true;
        _featureToggles['enableBarcode'] = true;
        _featureToggles['enableLoyalty'] = false;
        _featureToggles['enableMultiplePayments'] = true;
        _featureToggles['enableCategories'] = true;
        _featureToggles['enableSuppliers'] = true;
        _featureToggles['enableTables'] = false;
        _featureToggles['enableAppointments'] = false;
        _featureToggles['enableBulkPricing'] = true;
        _featureToggles['enablePurchaseOrders'] = true;
        break;

      case BusinessType.other:
        // Enable basic features for other business types
        _featureToggles['enableInventory'] = true;
        _featureToggles['enableCustomers'] = true;
        _featureToggles['enableEmployees'] = true;
        _featureToggles['enableReports'] = true;
        _featureToggles['enableDiscounts'] = true;
        _featureToggles['enableBarcode'] = false;
        _featureToggles['enableLoyalty'] = false;
        _featureToggles['enableMultiplePayments'] = true;
        _featureToggles['enableCategories'] = true;
        _featureToggles['enableSuppliers'] = false;
        _featureToggles['enableTables'] = false;
        _featureToggles['enableAppointments'] = false;
        break;
    }
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureName) {
    final enabled = _featureToggles[featureName] ?? false;
    return enabled;
  }

  /// Get current business type
  BusinessType get currentType => _currentType;

  /// Get all feature toggles
  Map<String, bool> get featureToggles => Map.unmodifiable(_featureToggles);

  /// Get configuration summary
  Map<String, dynamic> getConfig() {
    return {
      'businessType': _currentType.value,
      'businessLabel': _currentType.label,
      'features': _featureToggles,
      'enabledFeatures': _featureToggles.keys
          .where((k) => _featureToggles[k] == true)
          .toList(),
      'disabledFeatures': _featureToggles.keys
          .where((k) => _featureToggles[k] == false)
          .toList(),
    };
  }

  /// Change business type
  Future<void> changeBusinessType(BusinessType type) async {
    try {
      print('[BusinessConfig] Changing business type to: ${type.label}');

      _currentType = type;

      // Save to storage
      await _storageService.writeSetting(
        AppConstants.businessTypeKey,
        type.value,
      );

      // Reconfigure features
      _configureFeatures();

      print('[BusinessConfig] Business type changed successfully');
    } catch (e) {
      print('[BusinessConfig] Error changing business type: $e');
      rethrow;
    }
  }

  /// Manually toggle a feature (for admin/testing)
  Future<void> toggleFeature(String featureName, bool enabled) async {
    try {
      print('[BusinessConfig] Toggling feature: $featureName = $enabled');

      _featureToggles[featureName] = enabled;

      // Could save custom toggles to storage if needed
      print('[BusinessConfig] Feature toggled successfully');
    } catch (e) {
      print('[BusinessConfig] Error toggling feature: $e');
      rethrow;
    }
  }

  /// Get all available business types
  static List<BusinessType> get availableTypes => BusinessType.values;

  /// Reset to default configuration
  Future<void> reset() async {
    try {
      print('[BusinessConfig] Resetting to default...');

      await init(BusinessType.retail);

      print('[BusinessConfig] Reset successful');
    } catch (e) {
      print('[BusinessConfig] Reset error: $e');
      rethrow;
    }
  }
}
