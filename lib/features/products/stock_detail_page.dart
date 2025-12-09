// lib/features/products/stock_detail_page.dart
// Page dédiée pour afficher et gérer le stock d'un produit (optimisée mobile)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../core/beep_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/mobile_header.dart';

class StockDetailPage extends ConsumerStatefulWidget {
  final Product product;

  const StockDetailPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends ConsumerState<StockDetailPage> {
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _restockQuantityController = TextEditingController();
  final TextEditingController _restockReasonController = TextEditingController();

  @override
  void dispose() {
    _stockController.dispose();
    _reasonController.dispose();
    _restockQuantityController.dispose();
    _restockReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    // Récupérer le produit à jour depuis le provider
    final productState = ref.watch(productProvider);
    final product = productState.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    return MainLayout(
      currentRoute: '/inventory',
      appBar: MobileHeader(
        title: 'Gestion du Stock',
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom du produit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.sku.isNotEmpty) ...[
                    const SizedBox(height: 8),
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

            const SizedBox(height: 24),

            // Affichage du stock actuel
            _buildStockInfoCard(product, theme),

            const SizedBox(height: 24),

            // Actions sur le stock
            Text(
              'Actions sur le stock',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Bouton Augmenter
            FButton(
              onPress: () => _showStockIncreaseDialog(product),
              style: FButtonStyle.primary(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text('Augmenter le stock'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bouton Ravitailler
            FButton(
              onPress: () => _showRestockDialog(product),
              style: FButtonStyle.primary(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 20),
                  SizedBox(width: 8),
                  Text('Ravitailler le stock'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bouton Modifier
            FButton(
              onPress: () => _showStockUpdateDialog(product),
              style: FButtonStyle.outline(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier le stock'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations complètes
            Text(
              'Informations du produit',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildProductInfoCard(product, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(Product product, FThemeData theme) {
    final stockColor = _getStockColor(product.stock, product.minStock, theme);
    final isLowStock = product.minStock != null && product.stock <= product.minStock!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        children: [
          Text(
            'Stock actuel',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: stockColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${product.stock}',
              style: theme.typography.xl.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ),
          if (product.minStock != null && product.minStock! > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 18,
                  color: isLowStock
                      ? theme.colors.destructive
                      : theme.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock minimum: ${product.minStock}',
                  style: theme.typography.sm.copyWith(
                    color: isLowStock
                        ? theme.colors.destructive
                        : theme.colors.mutedForeground,
                    fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(Product product, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Prix', product.price != null ? '${product.price} FCFA' : 'Non défini', theme),
          if (product.description != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Description', product.description!, theme),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('Stock actuel', '${product.stock}', theme),
          if (product.minStock != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Stock minimum', '${product.minStock}', theme),
          ],
          if (product.maxStock != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Stock maximum', '${product.maxStock}', theme),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('Taux de taxe', '${product.taxRate}%', theme),
          const SizedBox(height: 10),
          _buildInfoRow('Statut', product.isActive ? 'Actif' : 'Inactif', theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, FThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getStockColor(int currentStock, int? minStock, FThemeData theme) {
    if (currentStock <= 0) {
      return theme.colors.destructive;
    } else if (minStock != null && currentStock <= minStock) {
      return theme.colors.destructive;
    } else {
      return theme.colors.primary;
    }
  }

  void _showStockIncreaseDialog(Product product) {
    _stockController.clear();
    _reasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Augmenter le stock - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () => _increaseStock(product),
            style: FButtonStyle.primary(),
            child: const Text('Augmenter'),
          ),
        ],
      ),
    );
  }

  void _increaseStock(Product product) async {
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

    final newStock = product.stock + quantity;

    try {
      await ref.read(productProvider.notifier).updateProductStock(
        product.id,
        newStock,
        _reasonController.text.trim().isEmpty
            ? 'Augmentation de stock (+$quantity)'
            : _reasonController.text.trim(),
      );

      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock augmenté: ${product.name} (+$quantity)'),
            backgroundColor: theme.colors.primary,
          ),
        );
        // Rafraîchir la page
        setState(() {});
      }
    } catch (e) {
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
    _stockController.text = product.stock.toString();
    _reasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le stock - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actuel: ${product.stock}'),
              const SizedBox(height: 16),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau stock',
                  hintText: 'Ex: 50',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison du changement (optionnel)',
                  hintText: 'Ex: Correction d\'inventaire',
                  border: OutlineInputBorder(),
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
          const SizedBox(width: 8),
          FButton(
            onPress: () => _updateStock(product),
            style: FButtonStyle.primary(),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _updateStock(Product product) async {
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
        product.id,
        newStock,
        _reasonController.text.trim().isEmpty
            ? 'Modification manuelle du stock'
            : _reasonController.text.trim(),
      );

      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock mis à jour: ${product.name}'),
            backgroundColor: theme.colors.primary,
          ),
        );
        // Rafraîchir la page
        setState(() {});
      }
    } catch (e) {
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
    _restockQuantityController.clear();
    _restockReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ravitailler le stock - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () => _restockProduct(product),
            style: FButtonStyle.primary(),
            child: const Text('Ravitailler'),
          ),
        ],
      ),
    );
  }

  void _restockProduct(Product product) async {
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

    final newStock = product.stock + quantity;
    final reason = _restockReasonController.text.trim().isEmpty
        ? 'Ravitaillement de stock (+$quantity)'
        : _restockReasonController.text.trim();

    try {
      await ref.read(productProvider.notifier).updateProductStock(
        product.id,
        newStock,
        reason,
      );

      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock ravitaillé: ${product.name} (+$quantity)'),
            backgroundColor: theme.colors.primary,
          ),
        );
        // Rafraîchir la page
        setState(() {});
      }
    } catch (e) {
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
}

