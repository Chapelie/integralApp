// settings_provider.dart
// Provider for application settings management
// Handles theme, locale, currency, and sync preferences

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage_service.dart';

part 'settings_provider.g.dart';

// Theme options
enum AppThemeType {
  neutral,
  zinc,
  slate,
  blue,
  green,
  orange, // Nouveau thème orange, noir et blanc
}

// Settings State
class SettingsState {
  final bool darkMode;
  final AppThemeType themeType;
  final String locale;
  final String currency;
  final bool autoSync;
  final int syncInterval;
  final bool enableTax; // Activer/désactiver les taxes
  final double defaultTaxRate; // Taux de taxe par défaut en pourcentage
  final bool isLoading;
  final String? error;

  SettingsState({
    this.darkMode = false,
    this.themeType = AppThemeType.orange,
    this.locale = 'fr',
    this.currency = 'XOF',
    this.autoSync = true,
    this.syncInterval = 15,
    this.enableTax = false, // Par défaut, les taxes sont désactivées
    this.defaultTaxRate = 0.0, // Taux par défaut à 0%
    this.isLoading = true,
    this.error,
  });

  SettingsState copyWith({
    bool? darkMode,
    AppThemeType? themeType,
    String? locale,
    String? currency,
    bool? autoSync,
    int? syncInterval,
    bool? enableTax,
    double? defaultTaxRate,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      themeType: themeType ?? this.themeType,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      enableTax: enableTax ?? this.enableTax,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Settings Notifier
@riverpod
class SettingsNotifier extends _$SettingsNotifier {

  @override
  SettingsState build() {
    // Load settings asynchronously
    Future.microtask(() => _loadSettingsAsync());
    return SettingsState();
  }

  // Async method to load settings without modifying state during build
  Future<void> _loadSettingsAsync() async {
    try {
      // Load settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      state = state.copyWith(
        darkMode: prefs.getBool('darkMode') ?? false,
        themeType: AppThemeType.values.firstWhere(
          (e) => e.name == prefs.getString('themeType'),
          orElse: () => AppThemeType.orange,
        ),
        locale: prefs.getString('locale') ?? 'fr',
        currency: prefs.getString('currency') ?? 'XOF',
        autoSync: prefs.getBool('autoSync') ?? true,
        syncInterval: prefs.getInt('syncInterval') ?? 15,
        enableTax: prefs.getBool('enableTax') ?? false,
        defaultTaxRate: prefs.getDouble('defaultTaxRate') ?? 0.0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    final newValue = !state.darkMode;
    state = state.copyWith(darkMode: newValue);
    await saveSettings();
  }

  // Set locale
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await saveSettings();
  }

  // Set currency
  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    await saveSettings();
  }

  // Set theme type
  Future<void> setThemeType(AppThemeType themeType) async {
    state = state.copyWith(themeType: themeType);
    await saveSettings();
  }

  // Toggle auto sync
  Future<void> toggleAutoSync() async {
    final newValue = !state.autoSync;
    state = state.copyWith(autoSync: newValue);
    await saveSettings();
  }

  // Set sync interval
  Future<void> setSyncInterval(int minutes) async {
    if (minutes < 1) return;

    state = state.copyWith(syncInterval: minutes);
    await saveSettings();
  }

  // Toggle tax
  Future<void> toggleTax() async {
    final newValue = !state.enableTax;
    state = state.copyWith(enableTax: newValue);
    await saveSettings();
  }

  // Set default tax rate
  Future<void> setDefaultTaxRate(double rate) async {
    if (rate < 0 || rate > 100) return;

    state = state.copyWith(defaultTaxRate: rate);
    await saveSettings();
  }


  // Save settings
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', state.darkMode);
      await prefs.setString('themeType', state.themeType.name);
      await prefs.setString('locale', state.locale);
      await prefs.setString('currency', state.currency);
      await prefs.setBool('autoSync', state.autoSync);
      await prefs.setInt('syncInterval', state.syncInterval);
      await prefs.setBool('enableTax', state.enableTax);
      await prefs.setDouble('defaultTaxRate', state.defaultTaxRate);

      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
