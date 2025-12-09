// lib/features/settings/tax_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_layout.dart';

class TaxSettingsPage extends ConsumerStatefulWidget {
  const TaxSettingsPage({super.key});

  @override
  ConsumerState<TaxSettingsPage> createState() => _TaxSettingsPageState();
}

class _TaxSettingsPageState extends ConsumerState<TaxSettingsPage> {
  late TextEditingController _taxRateController;

  @override
  void initState() {
    super.initState();
    final settingsState = ref.read(settingsProvider);
    _taxRateController = TextEditingController(
      text: settingsState.defaultTaxRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final settingsState = ref.watch(settingsProvider);

    return MainLayout(
      currentRoute: '/tax-settings',
      appBar: AppBar(
        title: const Text('Configuration des Taxes'),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section activation des taxes
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: theme.colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Activation des Taxes',
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: settingsState.enableTax,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleTax();
                      },
                      title: const Text('Activer les taxes'),
                      subtitle: const Text(
                        'Activez cette option pour calculer et afficher les taxes sur les ventes',
                      ),
                      activeColor: theme.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section taux de taxe par défaut
            if (settingsState.enableTax)
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.percent, color: theme.colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Taux de Taxe par Défaut',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Définissez le taux de taxe par défaut qui sera appliqué aux produits sans taxe spécifique.',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FTextField(
                        controller: _taxRateController,
                        label: const Text('Taux de taxe (%)'),
                        hint: 'Ex: 18',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChange: (value) {
                          final taxRate = double.tryParse(value) ?? 0.0;
                          if (taxRate >= 0 && taxRate <= 100) {
                            ref.read(settingsProvider.notifier).setDefaultTaxRate(taxRate);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Taux actuel: ${settingsState.defaultTaxRate.toStringAsFixed(2)}%',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (settingsState.enableTax) const SizedBox(height: 16),

            // Section information
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Informations',
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      settingsState.enableTax
                          ? 'Les taxes seront calculées automatiquement sur tous les produits lors des ventes. Si un produit a un taux de taxe spécifique, ce taux sera utilisé. Sinon, le taux par défaut sera appliqué.'
                          : 'Les taxes sont désactivées. Aucun calcul ni affichage de taxes ne sera effectué dans les ventes, rapports ou factures.',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
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
}
