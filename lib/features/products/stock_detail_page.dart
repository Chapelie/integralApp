// lib/features/products/stock_detail_page.dart
// Page de détail du stock d'un produit

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';

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
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedAction = 'increase'; // 'increase', 'restock', 'update'

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final productState = ref.watch(productProvider);
    final product = productState.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    return MainLayout(
      currentRoute: '/inventory',
      appBar: UnifiedHeader(
        title: 'Gestion du Stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du produit
            _buildStockInfoCard(theme, product),
            const SizedBox(height: 16),
            
            // Actions de gestion du stock
            _buildActionSection(theme, product),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(FThemeData theme, Product product) {
    final stockColor = product.stock <= 0
        ? theme.colors.destructive
        : (product.minStock != null && product.stock <= product.minStock!)
            ? theme.colors.destructive
            : theme.colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (product.sku != null) ...[
            const SizedBox(height: 8),
            Text(
              'SKU: ${product.sku}',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: stockColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product.stock}',
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Stock actuel',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          if (product.minStock != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock minimum',
                  style: theme.typography.sm,
                ),
                Text(
                  '${product.minStock}',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(FThemeData theme, Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sélection de l'action
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'increase',
                label: Text('Augmenter'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: 'restock',
                label: Text('Ravitailler'),
                icon: Icon(Icons.refresh),
              ),
              ButtonSegment(
                value: 'update',
                label: Text('Modifier'),
                icon: Icon(Icons.edit),
              ),
            ],
            selected: {_selectedAction},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedAction = newSelection.first;
                _quantityController.clear();
                _reasonController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Champ quantité
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: _selectedAction == 'update' ? 'Nouveau stock' : 'Quantité',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Champ raison (optionnel)
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Raison (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // Bouton d'action
          FButton(
            onPress: _handleAction,
            style: FButtonStyle.primary(),
            child: Text(_getActionButtonText()),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText() {
    switch (_selectedAction) {
      case 'increase':
        return 'Augmenter le stock';
      case 'restock':
        return 'Ravitailler';
      case 'update':
        return 'Mettre à jour le stock';
      default:
        return 'Valider';
    }
  }

  Future<void> _handleAction() async {
    final quantityText = _quantityController.text.trim();
    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une quantité')),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être un nombre positif')),
      );
      return;
    }

    final theme = FTheme.of(context);
    final reason = _reasonController.text.trim().isEmpty
        ? _getDefaultReason()
        : _reasonController.text.trim();

    try {
      final currentProduct = ref.read(productProvider).products.firstWhere(
        (p) => p.id == widget.product.id,
        orElse: () => widget.product,
      );
      
      int newStock;
      switch (_selectedAction) {
        case 'increase':
          newStock = currentProduct.stock + quantity;
          break;
        case 'restock':
          newStock = currentProduct.stock + quantity;
          break;
        case 'update':
          newStock = quantity;
          break;
        default:
          newStock = currentProduct.stock;
      }
      
      await ref.read(productProvider.notifier).updateProductStock(
        widget.product.id,
        newStock,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock mis à jour: ${widget.product.name}'),
            backgroundColor: theme.colors.primary,
          ),
        );
        _quantityController.clear();
        _reasonController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    }
  }

  String _getDefaultReason() {
    switch (_selectedAction) {
      case 'increase':
        return 'Augmentation manuelle du stock';
      case 'restock':
        return 'Ravitaillement';
      case 'update':
        return 'Modification manuelle du stock';
      default:
        return 'Modification du stock';
    }
  }
}
