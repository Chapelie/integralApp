// lib/features/settings/business_mode_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/business_config_provider.dart';

class BusinessModeSelector extends ConsumerWidget {
  const BusinessModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(businessConfigProvider);

    final businessTypes = [
      _BusinessTypeOption(
        type: BusinessType.restaurant,
        displayName: 'Restaurant',
        icon: Icons.local_cafe,
        description: 'Gestion de tables, commandes et cuisine',
      ),
      _BusinessTypeOption(
        type: BusinessType.retail,
        displayName: 'Commerce de détail',
        icon: Icons.shopping_cart,
        description: 'Vente au détail et gestion de stock',
      ),
      _BusinessTypeOption(
        type: BusinessType.service,
        displayName: 'Services',
        icon: Icons.medical_services,
        description: 'Services professionnels et spécialisés',
      ),
      _BusinessTypeOption(
        type: BusinessType.other,
        displayName: 'Autre',
        icon: Icons.grid_view,
        description: 'Commerce général',
      ),
    ];

    return Semantics(
      label: 'Page sélection type de commerce',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Type de commerce'),
          backgroundColor: FTheme.of(context).colors.primary,
          foregroundColor: Colors.white,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Use grid for larger screens, list for mobile
            if (constraints.maxWidth > 600) {
              return _buildGrid(context, ref, businessTypes, currentConfig.type ?? BusinessType.retail);
            } else {
              return _buildList(context, ref, businessTypes, currentConfig.type ?? BusinessType.retail);
            }
          },
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<_BusinessTypeOption> businessTypes,
    BusinessType currentType,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: businessTypes.length,
      itemBuilder: (context, index) {
        final option = businessTypes[index];
        final isSelected = option.type == currentType;

        return InkWell(
          onTap: () => _selectBusinessType(context, ref, option.type),
          borderRadius: BorderRadius.circular(12),
          child: FCard.raw(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? FTheme.of(context).colors.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option.icon,
                      size: 48,
                      color: isSelected
                          ? FTheme.of(context).colors.primary
                          : Colors.grey[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      option.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? FTheme.of(context).colors.primary
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Icon(
                        Icons.check_circle,
                        color: FTheme.of(context).colors.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<_BusinessTypeOption> businessTypes,
    BusinessType currentType,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businessTypes.length,
      itemBuilder: (context, index) {
        final option = businessTypes[index];
        final isSelected = option.type == currentType;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FCard.raw(
            child: InkWell(
              onTap: () => _selectBusinessType(context, ref, option.type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? FTheme.of(context).colors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FTheme.of(context).colors.primary.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      option.icon,
                      size: 32,
                      color: isSelected
                          ? FTheme.of(context).colors.primary
                          : Colors.grey[700],
                    ),
                  ),
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? FTheme.of(context).colors.primary
                          : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: FTheme.of(context).colors.primary,
                          size: 28,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Colors.grey[400],
                          size: 28,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectBusinessType(BuildContext context, WidgetRef ref, BusinessType type) {
    ref.read(businessConfigProvider.notifier).setBusinessType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Type de commerce mis à jour'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

}

class _BusinessTypeOption {
  final BusinessType type;
  final String displayName;
  final IconData icon;
  final String description;

  const _BusinessTypeOption({
    required this.type,
    required this.displayName,
    required this.icon,
    required this.description,
  });
}
