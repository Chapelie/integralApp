// kitchen_page.dart
// Kitchen display page for managing order preparation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/kitchen_order.dart';
import '../../models/sale_item.dart';
import '../../models/product.dart';
import '../../providers/kitchen_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import '../../core/responsive_helper.dart';

class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeKitchenOrdersProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/kitchen',
      appBar: UnifiedHeader(
        title: 'Cuisine',
        onRefresh: () async {
          // Force refresh of kitchen orders
          await ref.read(kitchenOrderListProvider.notifier).refresh(forceRefresh: true);
          // Invalidate active orders provider to force refresh
          ref.invalidate(activeKitchenOrdersProvider);
        },
      ),
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return _buildKitchenBoard(context, ref, orders, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: theme.colors.destructive),
              const SizedBox(height: 16),
              Text(
                'Erreur: $error',
                style: theme.typography.base,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande',
            style: theme.typography.xl,
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes apparaîtront ici',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenBoard(
    BuildContext context,
    WidgetRef ref,
    List<KitchenOrder> orders,
    FThemeData theme,
  ) {
    final pendingOrders = orders
        .where((o) => o.status == KitchenOrderStatus.pending)
        .toList();
    final preparingOrders = orders
        .where((o) => o.status == KitchenOrderStatus.preparing)
        .toList();
    final readyOrders = orders
        .where((o) => o.status == KitchenOrderStatus.ready)
        .toList();

    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      // Desktop: 3 colonnes côte à côte
      return Row(
        children: [
          Expanded(
            child: _buildOrderColumn(
              context,
              ref,
              'En attente',
              pendingOrders,
              theme,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildOrderColumn(
              context,
              ref,
              'En préparation',
              preparingOrders,
              theme,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildOrderColumn(
              context,
              ref,
              'Prêt',
              readyOrders,
              theme,
            ),
          ),
        ],
      );
    } else {
      // Mobile: Tabs verticales
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('En attente'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colors.destructive,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pendingOrders.length}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.primaryForeground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('En préparation'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${preparingOrders.length}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.primaryForeground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Prêt'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${readyOrders.length}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.primaryForeground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderColumn(
                    context,
                    ref,
                    'En attente',
                    pendingOrders,
                    theme,
                  ),
                  _buildOrderColumn(
                    context,
                    ref,
                    'En préparation',
                    preparingOrders,
                    theme,
                  ),
                  _buildOrderColumn(
                    context,
                    ref,
                    'Prêt',
                    readyOrders,
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOrderColumn(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<KitchenOrder> orders,
    FThemeData theme,
  ) {
    // Déterminer la couleur en fonction du titre
    Color headerColor;
    switch (title) {
      case 'En attente':
        headerColor = theme.colors.destructive; // Rouge pour l'urgence
        break;
      case 'En préparation':
        headerColor = theme.colors.primary; // Bleu pour en cours
        break;
      case 'Prêt':
        headerColor = theme.colors.primary; // Vert/Bleu pour prêt
        break;
      default:
        headerColor = theme.colors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: headerColor.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${orders.length}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.primaryForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, ref, orders[index], headerColor, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    KitchenOrder order,
    Color statusColor,
    FThemeData theme,
  ) {
    final waitTime = order.getWaitingTime();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FCard.raw(
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.tableNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Table ${order.tableNumber}',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                if (waitTime != null)
                  Text(
                    '${waitTime} min',
                    style: theme.typography.sm.copyWith(
                      color: waitTime > 15 ? theme.colors.destructive : theme.colors.mutedForeground,
                      fontWeight: waitTime > 15 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
              ],
            ),
            if (order.waiterName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Serveur: ${order.waiterName}',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
            const Divider(height: 16),
            // Items
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.typography.sm,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (order.notes != null) ...[
              const Divider(height: 16),
              Text(
                'Note: ${order.notes}',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Bouton pour ajouter des produits
            if (order.status != KitchenOrderStatus.served && 
                order.status != KitchenOrderStatus.cancelled)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FButton(
                  onPress: () => _showAddItemsDialog(context, ref, order, theme),
                  style: FButtonStyle.outline(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Ajouter des produits'),
                    ],
                  ),
                ),
              ),
            // Actions
            _buildOrderActions(context, ref, order, theme),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildOrderActions(
    BuildContext context,
    WidgetRef ref,
    KitchenOrder order,
    FThemeData theme,
  ) {
    switch (order.status) {
      case KitchenOrderStatus.pending:
        return FButton(
          onPress: () async {
            await ref.read(kitchenOrderListProvider.notifier).startPreparing(order.id);
            // Le provider gère déjà le refresh et l'invalidation
          },
          style: FButtonStyle.primary(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 8),
              Text('Commencer'),
            ],
          ),
        );

      case KitchenOrderStatus.preparing:
        return FButton(
          onPress: () async {
            await ref.read(kitchenOrderListProvider.notifier).markAsReady(order.id);
            // Le provider gère déjà le refresh et l'invalidation
          },
          style: FButtonStyle.primary(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 18),
              SizedBox(width: 8),
              Text('Marquer prêt'),
            ],
          ),
        );

      case KitchenOrderStatus.ready:
        return FButton(
          onPress: () async {
            await ref.read(kitchenOrderListProvider.notifier).markAsServed(order.id);
            // Le provider gère déjà le refresh et l'invalidation
          },
          style: FButtonStyle.outline(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_all, size: 18),
              SizedBox(width: 8),
              Text('Servi'),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showAddItemsDialog(
    BuildContext context,
    WidgetRef ref,
    KitchenOrder order,
    FThemeData theme,
  ) {
    final productState = ref.read(productProvider);
    final selectedProducts = <Product, int>{};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter des produits'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionnez les produits à ajouter à la commande',
                  style: theme.typography.sm,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: productState.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productState.filteredProducts[index];
                      final quantity = selectedProducts[product] ?? 0;
                      
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('${product.formattedPrice} - Stock: ${product.stock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: quantity > 0
                                  ? () {
                                      setDialogState(() {
                                        if (quantity == 1) {
                                          selectedProducts.remove(product);
                                        } else {
                                          selectedProducts[product] = quantity - 1;
                                        }
                                      });
                                    }
                                  : null,
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setDialogState(() {
                                  selectedProducts[product] = (selectedProducts[product] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FButton(
              onPress: () => Navigator.of(context).pop(),
              style: FButtonStyle.outline(),
              child: const Text('Annuler'),
            ),
            FButton(
              onPress: () async {
                if (selectedProducts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner au moins un produit')),
                  );
                  return;
                }

                // Convertir les produits sélectionnés en SaleItem
                final itemsToAdd = <SaleItem>[];
                for (final entry in selectedProducts.entries) {
                  final product = entry.key;
                  final quantity = entry.value;
                  
                  itemsToAdd.add(SaleItem(
                    productId: product.id,
                    productName: product.name,
                    quantity: quantity,
                    price: product.price ?? 0.0,
                    taxRate: product.taxRate,
                    lineTotal: (product.price ?? 0.0) * quantity,
                  ));
                }

                try {
                  await ref.read(kitchenOrderListProvider.notifier).addItemsToOrder(
                    order.id,
                    itemsToAdd,
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${itemsToAdd.length} produit(s) ajouté(s) à la commande'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: FButtonStyle.primary(),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
