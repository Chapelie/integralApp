// lib/features/products/stock_management_page.dart
// Page pour gérer le stock des produits

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import 'stock_detail_page.dart';

class StockManagementPage extends ConsumerStatefulWidget {
  const StockManagementPage({super.key});

  @override
  ConsumerState<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends ConsumerState<StockManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Charger les produits au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stockController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final productState = ref.watch(productProvider);

    return MainLayout(
      currentRoute: '/stock',
      appBar: UnifiedHeader(
        title: 'Gestion du Stock',
        actions: [
          IconButton(
            onPressed: () {
              ref.read(productProvider.notifier).refreshFromServer();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(productProvider.notifier).searchProducts(value);
              },
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: productState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colors.destructive,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productState.error!,
                              textAlign: TextAlign.center,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FButton(
                              onPress: () {
                                ref.read(productProvider.notifier).loadProducts();
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : productState.filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun produit trouvé',
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun produit ne correspond à votre recherche',
                                  textAlign: TextAlign.center,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: productState.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productState.filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = FTheme.of(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockDetailPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colors.border),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.sku != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku}',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Stock actuel',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStockColor(product.stock, product.minStock, theme),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${product.stock}',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (product.minStock != null && product.minStock! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: product.stock <= product.minStock!
                      ? theme.colors.destructive
                      : theme.colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock minimum: ${product.minStock}',
                  style: theme.typography.sm.copyWith(
                    color: product.stock <= product.minStock!
                        ? theme.colors.destructive
                        : theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _getStockColor(int currentStock, int? minStock, FThemeData theme) {
    if (currentStock <= 0) {
      return theme.colors.destructive;
    } else if (minStock != null && currentStock <= minStock) {
      return theme.colors.destructive; // Orange similaire dans le thème
    } else {
      return theme.colors.primary;
    }
  }

  void _showStockUpdateDialog(Product product) {
    _selectedProduct = product;
    _stockController.text = product.stock.toString();
    _reasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel: ${product.stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(
                hintText: 'Nouveau stock',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Raison du changement (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FButton(
            onPress: _updateStock,
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _updateStock() async {
    if (_selectedProduct == null) return;

    final newStockText = _stockController.text.trim();
    if (newStockText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un stock valide')),
      );
      return;
    }

    final newStock = int.tryParse(newStockText);
    if (newStock == null || newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le stock doit être un nombre positif')),
      );
      return;
    }

    try {
      await ref.read(productProvider.notifier).updateProductStock(
        _selectedProduct!.id,
        newStock,
        _reasonController.text.trim().isEmpty 
            ? 'Modification manuelle du stock' 
            : _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock mis à jour: ${_selectedProduct!.name}'),
            backgroundColor: theme.colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    }
  }

}
