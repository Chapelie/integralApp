// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/settings_provider.dart';
import '../../providers/business_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warehouse_type_provider.dart';
import '../../widgets/main_layout.dart';
import 'business_mode_selector.dart';
import 'security_settings_page.dart';
import 'simple_connection_test.dart';
import 'debug_auth_page.dart';
import '../settings/tax_settings_page.dart';
import '../../widgets/unified_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final businessConfig = ref.watch(businessConfigProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/settings',
      appBar: UnifiedHeader(title: 'Paramètres'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Appearance Section
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette),
                          SizedBox(width: 8),
                          Text(
                            'Apparence',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dark Mode Toggle
                      ListTile(
                        leading: Icon(
                          settingsState.darkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        title: const Text('Mode sombre'),
                        subtitle: Text(
                          settingsState.darkMode ? 'Activé' : 'Désactivé',
                        ),
                        trailing: Switch(
                          value: settingsState.darkMode,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleDarkMode();
                          },
                        ),
                      ),
                      const Divider(),
                      // Theme Selector
                      ListTile(
                        leading: const Icon(Icons.palette),
                        title: const Text('Thème'),
                        subtitle: Text(_getThemeName(settingsState.themeType)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showThemeDialog(context, ref, settingsState.themeType);
                        },
                      ),
                      const Divider(),
                      // Language Selector
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Langue'),
                        subtitle: Text(_getLanguageName(settingsState.locale)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showLanguageDialog(context, ref, settingsState.locale);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Synchronization Section
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync),
                          SizedBox(width: 8),
                          Text(
                            'Synchronisation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Auto Sync Toggle
                      ListTile(
                        leading: const Icon(FIcons.refreshCw),
                        title: const Text('Synchronisation automatique'),
                        subtitle: Text(
                          settingsState.autoSync ? 'Activée' : 'Désactivée',
                        ),
                        trailing: Switch(
                          value: settingsState.autoSync,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleAutoSync();
                          },
                        ),
                      ),
                      const Divider(),
                      // Sync Interval
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(FIcons.clock, size: 20),
                                const SizedBox(width: 8),
                                const Text('Intervalle de synchronisation'),
                                const Spacer(),
                                Text(
                                  '${settingsState.syncInterval} min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: settingsState.syncInterval.toDouble(),
                              min: 5,
                              max: 60,
                              divisions: 11,
                              label: '${settingsState.syncInterval} min',
                              onChanged: (value) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setSyncInterval(value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Manual Sync Button
                      ListTile(
                        leading: const Icon(FIcons.refreshCw),
                        title: const Text('Synchroniser maintenant'),
                        subtitle: const Text('Dernière sync: Il y a 2 heures'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showSyncDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Warehouse Information Section
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warehouse),
                          SizedBox(width: 8),
                          Text(
                            'Entrepôt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Warehouse Type
                      Consumer(
                        builder: (context, ref, child) {
                          final warehouseTypeState = ref.watch(warehouseTypeProvider);
                          return warehouseTypeState.when(
                            data: (type) => ListTile(
                              leading: Icon(_getWarehouseTypeIcon(type)),
                              title: const Text('Type d\'entrepôt'),
                              subtitle: Text(_getWarehouseTypeName(type)),
                              enabled: false,
                            ),
                            loading: () => const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Chargement...'),
                            ),
                            error: (err, stack) => ListTile(
                              leading: const Icon(Icons.error_outline),
                              title: const Text('Type d\'entrepôt'),
                              subtitle: const Text('Non disponible'),
                              enabled: false,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Business Section
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(FIcons.store),
                          SizedBox(width: 8),
                          Text(
                            'Business',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Business Type
                      ListTile(
                        leading: Icon(_getBusinessTypeIcon(businessConfig.type)),
                        title: const Text('Type de commerce'),
                        subtitle: Text(_getBusinessTypeName(businessConfig.type)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessModeSelector(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      // Tax Settings
                      ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: const Text('Configuration des Taxes'),
                        subtitle: Text(
                          settingsState.enableTax
                              ? 'Taxes activées (${settingsState.defaultTaxRate.toStringAsFixed(2)}%)'
                              : 'Taxes désactivées',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TaxSettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Printer Configuration
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.print),
                          SizedBox(width: 8),
                          Text(
                            'Imprimantes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.print),
                        title: const Text('Configuration des imprimantes'),
                        subtitle: const Text('Configurer les imprimantes et interfaces'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/printer-config');
                        },
                      ),
                      
                      // Connection Test
                      ListTile(
                        leading: const Icon(Icons.wifi),
                        title: const Text('Test de Connexion'),
                        subtitle: const Text('Tester la connexion avec le backend'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SimpleConnectionTest(),
                            ),
                          );
                        },
                      ),
                      
                      // Debug Auth
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Debug Authentification'),
                        subtitle: const Text('Diagnostiquer les problèmes de login'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DebugAuthPage(),
                            ),
                          );
                        },
                      ),
                      
                      // Security Settings
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Sécurité'),
                        subtitle: const Text('Code PIN et protection de l\'application'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SecuritySettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Section
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(FIcons.info),
                          SizedBox(width: 8),
                          Text(
                            'Application',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Version
                      const ListTile(
                        leading: Icon(FIcons.code),
                        title: Text('Version'),
                        subtitle: Text('1.0.0'),
                      ),
                      const Divider(),
                      // About
                      ListTile(
                        leading: const Icon(FIcons.fileText),
                        title: const Text('À propos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                      const Divider(),
                      // Privacy Policy
                      ListTile(
                        leading: const Icon(FIcons.shield),
                        title: const Text('Politique de confidentialité'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Open privacy policy
                        },
                      ),
                      const Divider(),
                      // Terms of Service
                      ListTile(
                        leading: const Icon(FIcons.fileText),
                        title: const Text('Conditions d\'utilisation'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Open terms of service
                        },
                      ),
                      const Divider(),
                      // Logout
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          _showLogoutDialog(context, ref);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String currentLanguage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Simulate sync
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Synchronisation réussie'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });

        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Synchronisation en cours...'),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IntegralPOS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Un système de point de vente moderne et intégral pour gérer votre commerce efficacement.',
            ),
            SizedBox(height: 16),
            Text('© 2025 IntegralPOS. Tous droits réservés.'),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.primary(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getWarehouseTypeName(String? type) {
    if (type == null) return 'Non défini';
    
    switch (type.toLowerCase()) {
      case 'restaurant':
        return 'Restaurant';
      case 'retail':
        return 'Commerce de détail';
      case 'wholesale':
        return 'Vente en gros';
      case 'service':
        return 'Services';
      default:
        return type;
    }
  }

  IconData _getWarehouseTypeIcon(String? type) {
    if (type == null) return Icons.help_outline;
    
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.local_cafe;
      case 'retail':
        return Icons.shopping_cart;
      case 'wholesale':
        return Icons.warehouse;
      case 'service':
        return Icons.medical_services;
      default:
        return Icons.warehouse;
    }
  }

  String _getBusinessTypeName(BusinessType? type) {
    switch (type) {
      case BusinessType.restaurant:
        return 'Restaurant';
      case BusinessType.retail:
        return 'Commerce de détail';
      case BusinessType.service:
        return 'Services';
      case BusinessType.other:
        return 'Autre';
      case null:
        return 'Non défini';
    }
  }

  IconData _getBusinessTypeIcon(BusinessType? type) {
    switch (type) {
      case BusinessType.restaurant:
        return Icons.local_cafe;
      case BusinessType.retail:
        return Icons.shopping_cart;
      case BusinessType.service:
        return Icons.medical_services;
      case BusinessType.other:
        return Icons.grid_view;
      case null:
        return Icons.help_outline;
    }
  }

  String _getThemeName(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.neutral:
        return 'Neutre (Personnalisé)';
      case AppThemeType.zinc:
        return 'Zinc';
      case AppThemeType.slate:
        return 'Ardoise';
      case AppThemeType.blue:
        return 'Bleu';
      case AppThemeType.green:
        return 'Vert';
      case AppThemeType.orange:
        return 'Orange, Noir & Blanc';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppThemeType currentTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeType.values.map((theme) {
            return RadioListTile<AppThemeType>(
              title: Text(_getThemeName(theme)),
              value: theme,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeType(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.primary(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout(context);
            },
            style: FButtonStyle.destructive(),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
