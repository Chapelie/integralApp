// restaurant_order_info.dart
// Widget for selecting service type, table, and waiter in restaurant mode
// On desktop: shows categories instead of service types
// On mobile: shows service types

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../models/service_type.dart';
import '../../../models/table.dart';
import '../../../models/waiter.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/waiter_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../core/business_config.dart';
import '../../../core/responsive_helper.dart';

class RestaurantOrderInfo extends ConsumerWidget {
  final bool showCategories; // Si true, affiche les catégories (seulement sur desktop dans la grille de produits)
  
  const RestaurantOrderInfo({
    super.key,
    this.showCategories = false, // Par défaut, affiche les types de services
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessConfig = BusinessConfig();
    final isDesktop = Responsive.isDesktop(context);
    final theme = FTheme.of(context);

    // Sur desktop et si showCategories est true: afficher les catégories
    // Sinon: afficher les types de services (comme avant)
    if (isDesktop && showCategories) {
      return _buildCategoriesSelector(context, ref, theme);
    }

    // On mobile: show service types (only for restaurant business type)
    if (!businessConfig.isFeatureEnabled('enableServiceTypes')) {
      return const SizedBox.shrink();
    }

    final cartState = ref.watch(cartProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type de service',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildServiceTypeSelector(context, ref, cartState, theme),
          if (cartState.serviceType == 'dine_in') ...[
            const SizedBox(height: 12),
            _buildTableSelector(context, ref, cartState, theme),
          ],
          if (cartState.tableId != null && cartState.serviceType == 'dine_in') ...[
            const SizedBox(height: 12),
            _buildWaiterSelector(context, ref, cartState, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSelector(BuildContext context, WidgetRef ref, FThemeData theme) {
    final categoryState = ref.watch(categoryProvider);
    final productState = ref.watch(productProvider);
    
    // Load categories if not loaded
    if (categoryState.categories.isEmpty && !categoryState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoryProvider.notifier).refreshCategories();
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catégories',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (categoryState.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ))
          else if (categoryState.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Aucune catégorie disponible',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Option "Tous"
                _buildCategoryChip(
                  context,
                  ref,
                  theme,
                  null,
                  'Tous',
                  categoryState.selectedCategory == null,
                ),
                // Catégories
                ...categoryState.categories.where((cat) => cat.isActive).map((category) {
                  return _buildCategoryChip(
                    context,
                    ref,
                    theme,
                    category,
                    category.name,
                    categoryState.selectedCategory?.id == category.id,
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    WidgetRef ref,
    FThemeData theme,
    dynamic category,
    String label,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(categoryProvider.notifier).selectCategory(category);
        // Filter products by category
        ref.read(productProvider.notifier).filterByCategory(category?.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colors.primary
                : theme.colors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: theme.typography.sm.copyWith(
            color: isSelected
                ? theme.colors.primary
                : theme.colors.foreground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelector(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    FThemeData theme,
  ) {
    return Row(
      children: ServiceType.values.map((type) {
        final isSelected = cartState.serviceType == type.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                ref.read(cartProvider.notifier).setServiceType(type.value);
                // Reset table/waiter if switching away from dine-in
                if (type != ServiceType.dineIn) {
                  ref.read(cartProvider.notifier).setTable(null, null);
                  ref.read(cartProvider.notifier).setWaiter(null, null);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getServiceTypeIcon(type),
                      size: 24,
                      color: isSelected
                          ? theme.colors.primary
                          : theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.label,
                      style: theme.typography.xs.copyWith(
                        color: isSelected
                            ? theme.colors.primary
                            : theme.colors.foreground,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableSelector(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    FThemeData theme,
  ) {
    final availableTablesAsync = ref.watch(availableTablesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Table',
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        availableTablesAsync.when(
          data: (tables) {
            if (tables.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aucune table disponible',
                  style: theme.typography.xs.copyWith(
                    color: Colors.orange,
                  ),
                ),
              );
            }

            return DropdownButtonFormField<String>(
              value: cartState.tableId,
              decoration: const InputDecoration(
                hintText: 'Sélectionner une table',
                isDense: true,
              ),
              items: tables.map((table) {
                return DropdownMenuItem(
                  value: table.id,
                  child: Text('Table ${table.number} (${table.capacity} pers.)'),
                );
              }).toList(),
              onChanged: (tableId) {
                if (tableId != null) {
                  final table = tables.firstWhere((t) => t.id == tableId);
                  ref.read(cartProvider.notifier).setTable(
                        table.id,
                        table.number,
                      );
                  // Auto-assign waiter if table has one
                  if (table.waiterId != null) {
                    ref.read(cartProvider.notifier).setWaiter(
                          table.waiterId,
                          table.waiterName,
                        );
                  }
                }
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'Erreur: $error',
            style: theme.typography.xs.copyWith(color: theme.colors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildWaiterSelector(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    FThemeData theme,
  ) {
    final activeWaitersAsync = ref.watch(activeWaitersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personnel',
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        activeWaitersAsync.when(
          data: (waiters) {
            return DropdownButtonFormField<String>(
              value: cartState.waiterId,
              decoration: const InputDecoration(
                hintText: 'Sélectionner un membre',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Aucun personnel assigné'),
                ),
                ...waiters.map((waiter) {
                  return DropdownMenuItem(
                    value: waiter.id,
                    child: Text(waiter.name),
                  );
                }),
              ],
              onChanged: (waiterId) {
                if (waiterId != null) {
                  final waiter = waiters.firstWhere((w) => w.id == waiterId);
                  ref.read(cartProvider.notifier).setWaiter(
                        waiter.id,
                        waiter.name,
                      );
                } else {
                  ref.read(cartProvider.notifier).setWaiter(null, null);
                }
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'Erreur: $error',
            style: theme.typography.xs.copyWith(color: theme.colors.error),
          ),
        ),
      ],
    );
  }

  IconData _getServiceTypeIcon(ServiceType type) {
    switch (type) {
      case ServiceType.dineIn:
        return Icons.restaurant;
      case ServiceType.takeaway:
        return Icons.shopping_bag;
      case ServiceType.delivery:
        return Icons.delivery_dining;
    }
  }
}
