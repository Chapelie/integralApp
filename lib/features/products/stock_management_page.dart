// lib/features/products/stock_management_page.dart
// Page pour gérer le stock des produits

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../core/beep_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/mobile_header.dart';
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
  final TextEditingController _restockQuantityController = TextEditingController();
  final TextEditingController _restockReasonController = TextEditingController();
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
    _restockQuantityController.dispose();
    _restockReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final productState = ref.watch(productProvider);

    return MainLayout(
      currentRoute: '/inventory',
      appBar: MobileHeader(
        title: 'Gestion du Stock',
        actions: [
          IconButton(
            onPressed: () {
              ref.read(productProvider.notifier).refreshFromServer();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les stocks',
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
    final stockColor = _getStockColor(product.stock, product.minStock, theme);
    final isLowStock = product.minStock != null && product.stock <= product.minStock!;
    
    return GestureDetector(
      onTap: () {
        // Ouvrir la page de détails du stock sur mobile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockDetailPage(product: product),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.sku != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        color: stockColor,
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
          
          if (isLowStock) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 16, color: theme.colors.destructive),
                  const SizedBox(width: 6),
                  Text(
                    'Stock bas',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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

  void _showStockIncreaseDialog(Product product) {
    _selectedProduct = product;
    _stockController.clear();
    _reasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Augmenter le stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel: ${product.stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Quantité à ajouter',
                hintText: 'Ex: 10',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                hintText: 'Ex: Réception de marchandise',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: _increaseStock,
            style: FButtonStyle.primary(),
            child: const Text('Augmenter'),
          ),
        ],
      ),
    );
  }

  void _increaseStock() async {
    if (_selectedProduct == null) return;

    final quantityText = _stockController.text.trim();
    if (quantityText.isEmpty) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une quantité')),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être un nombre positif')),
      );
      return;
    }

    final newStock = _selectedProduct!.stock + quantity;

    try {
      await ref.read(productProvider.notifier).updateProductStock(
        _selectedProduct!.id,
        newStock,
        _reasonController.text.trim().isEmpty 
            ? 'Augmentation de stock (+$quantity)' 
            : _reasonController.text.trim(),
      );

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock augmenté: ${_selectedProduct!.name} (+$quantity)'),
            backgroundColor: theme.colors.primary,
          ),
        );
      }
    } catch (e) {
      // Play error beep
      BeepService().playError();

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
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: _updateStock,
            style: FButtonStyle.primary(),
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
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un stock valide')),
      );
      return;
    }

    final newStock = int.tryParse(newStockText);
    if (newStock == null || newStock < 0) {
      BeepService().playError();
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

      // Play success beep
      BeepService().playSuccess();

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
      // Play error beep
      BeepService().playError();

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

  void _showRestockDialog(Product product) {
    _selectedProduct = product;
    _restockQuantityController.clear();
    _restockReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ravitailler le stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel: ${product.stock}'),
            if (product.minStock != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stock minimum: ${product.minStock}',
                style: TextStyle(
                  color: product.stock <= product.minStock!
                      ? Colors.orange
                      : Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _restockQuantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité à ravitailler',
                hintText: 'Ex: 50',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _restockReasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du ravitaillement',
                hintText: 'Ex: Commande fournisseur, Réapprovisionnement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: _restockProduct,
            style: FButtonStyle.primary(),
            child: const Text('Ravitailler'),
          ),
        ],
      ),
    );
  }

  void _restockProduct() async {
    if (_selectedProduct == null) return;

    final quantityText = _restockQuantityController.text.trim();
    if (quantityText.isEmpty) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une quantité')),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être un nombre positif')),
      );
      return;
    }

    final newStock = _selectedProduct!.stock + quantity;
    final reason = _restockReasonController.text.trim().isEmpty
        ? 'Ravitaillement de stock (+$quantity)'
        : _restockReasonController.text.trim();

    try {
      await ref.read(productProvider.notifier).updateProductStock(
        _selectedProduct!.id,
        newStock,
        reason,
      );

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock ravitaillé: ${_selectedProduct!.name} (+$quantity)'),
            backgroundColor: theme.colors.primary,
          ),
        );
      }
    } catch (e) {
      // Play error beep
      BeepService().playError();

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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.sku != null) ...[
                Text('SKU: ${product.sku}'),
                const SizedBox(height: 8),
              ],
              if (product.description != null) ...[
                Text('Description: ${product.description}'),
                const SizedBox(height: 8),
              ],
              Text('Prix: ${product.price != null ? "${product.price} FCFA" : "Non défini"}'),
              const SizedBox(height: 8),
              Text('Stock actuel: ${product.stock}'),
              const SizedBox(height: 8),
              Text('Stock minimum: ${product.minStock}'),
              const SizedBox(height: 8),
              Text('Stock maximum: ${product.maxStock}'),
              const SizedBox(height: 8),
              Text('Taux de taxe: ${product.taxRate}%'),
              const SizedBox(height: 8),
              Text('Statut: ${product.isActive ? 'Actif' : 'Inactif'}'),
            ],
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.primary(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
