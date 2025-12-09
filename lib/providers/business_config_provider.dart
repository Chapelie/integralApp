// business_config_provider.dart
// Provider for business configuration management
// Handles business type selection and feature toggles

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/business_config.dart' as core;

part 'business_config_provider.g.dart';

// Business Type enum
enum BusinessType {
  restaurant,
  retail,
  service,
  other,
}

// Business Config State
class BusinessConfigState {
  final BusinessType? type;
  final Map<String, bool> features;
  final bool isLoading;
  final String? error;

  BusinessConfigState({
    this.type,
    this.features = const {},
    this.isLoading = false,
    this.error,
  });

  BusinessConfigState copyWith({
    BusinessType? type,
    Map<String, bool>? features,
    bool? isLoading,
    String? error,
  }) {
    return BusinessConfigState(
      type: type ?? this.type,
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Business Config Notifier
@riverpod
class BusinessConfigNotifier extends _$BusinessConfigNotifier {
  final core.BusinessConfig _configService = core.BusinessConfig();

  @override
  BusinessConfigState build() {
    Future.microtask(() => _loadConfigAsync());
    return BusinessConfigState();
  }

  // Set business type
  Future<void> setBusinessType(BusinessType type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _configService.changeBusinessType(core.BusinessType.values.firstWhere((t) => t.value == type.name));
      state = state.copyWith(
        type: type,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Toggle feature
  Future<void> toggleFeature(String feature) async {
    try {
      final newFeatures = Map<String, bool>.from(state.features);
      newFeatures[feature] = !(newFeatures[feature] ?? false);

      await _configService.toggleFeature(feature, newFeatures[feature]!);

      state = state.copyWith(
        features: newFeatures,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Load configuration asynchronously
  Future<void> _loadConfigAsync() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final config = _configService.getConfig();
      
      // Convertir le businessType string vers BusinessType enum
      final businessTypeString = config['businessType'] as String?;
      BusinessType? businessType;
      
      if (businessTypeString != null) {
        // Convertir le string en enum
        switch (businessTypeString) {
          case 'restaurant':
            businessType = BusinessType.restaurant;
            break;
          case 'retail':
            businessType = BusinessType.retail;
            break;
          case 'service':
            businessType = BusinessType.service;
            break;
          case 'other':
            businessType = BusinessType.other;
            break;
          default:
            businessType = BusinessType.retail;
        }
      }
      
      state = state.copyWith(
        type: businessType,
        features: Map<String, bool>.from(config['features'] ?? {}),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load configuration (public method)
  Future<void> loadConfig() async {
    await _loadConfigAsync();
  }
}
