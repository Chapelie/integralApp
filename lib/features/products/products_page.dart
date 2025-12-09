// lib/features/products/products_page.dart
// Page de gestion des produits

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/main_layout.dart';
import '../../core/responsive_helper.dart';
import 'stock_management_page.dart';
import 'categories_page.dart';
import 'product_form_page.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  @override
  void initState() {
    super.initState();
    print('[ProductsPage] ===== INIT STATE =====');
    print('[ProductsPage] Chargement des produits...');

    // Charger les produits du stockage local immédiatement, puis rafraîchir depuis l'API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[ProductsPage] PostFrameCallback exécuté');
      // D'abord charger depuis le stockage local pour affichage immédiat
      print('[ProductsPage] Appel loadProductsFromStorage...');
      ref.read(productProvider.notifier).loadProductsFromStorage();
      // Puis essayer de faire une mise à jour depuis l'API en arrière-plan
      print('[ProductsPage] Appel _refreshProductsInBackground...');
      _refreshProductsInBackground();
    });
  }

  /// Rafraîchir les produits en arrière-plan sans bloquer l'interface
  Future<void> _refreshProductsInBackground() async {
    print('[ProductsPage] ===== DÉBUT _refreshProductsInBackground =====');
    try {
      print('[ProductsPage] Tentative de rafraîchissement depuis l\'API...');
      await ref.read(productProvider.notifier).loadProducts();
      print('[ProductsPage] ✅ Rafraîchissement réussi');
    } catch (e) {
      // Ignorer les erreurs de réseau en arrière-plan
      print('[ProductsPage] ❌ Background refresh failed: $e');
      print('[ProductsPage] Type d\'erreur: ${e.runtimeType}');
    }
    print('[ProductsPage] ===== FIN _refreshProductsInBackground =====');
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/products',
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoriesPage(),
                ),
              );
            },
            icon: const Icon(Icons.category),
            tooltip: 'Gérer les catégories',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StockManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Gestion du stock',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un produit',
          ),
        ],
      ),
      child: _buildBody(context, productState, theme),
    );
  }

  Widget _buildBody(BuildContext context, ProductState productState, FThemeData theme) {
    if (productState.isLoading && productState.products.isEmpty) {
      return _buildLoadingState(context, theme);
    }

    if (productState.error != null && productState.products.isEmpty) {
      return _buildErrorState(context, productState.error!, theme);
    }

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques
          _buildHeader(context, productState, theme),
          
          const SizedBox(height: 24),
          
          // Liste des produits
          Expanded(
            child: _buildProductsList(context, productState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProductState productState, FThemeData theme) {
    final isDesktop = Responsive.isDesktop(context);
    
    return isDesktop
        ? Row(
            children: [
              Expanded(
                child: Text(
                  '${productState.products.length} produits au total',
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
              // Statistiques rapides
              Row(
                children: [
                  _buildStatCard(
                    'En stock',
                    '${productState.products.where((p) => p.stock > 0).length}',
                    Icons.inventory,
                    Colors.green,
                    theme,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Rupture',
                    '${productState.products.where((p) => p.stock <= 0).length}',
                    Icons.warning,
                    Colors.orange,
                    theme,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Stock bas',
                    '${productState.products.where((p) => p.isLowStock()).length}',
                    Icons.trending_down,
                    Colors.red,
                    theme,
                  ),
                ],
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${productState.products.length} produits au total',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              // Statistiques rapides en vertical sur mobile
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                    'En stock',
                    '${productState.products.where((p) => p.stock > 0).length}',
                    Icons.inventory,
                    Colors.green,
                    theme,
                  ),
                  _buildStatCard(
                    'Rupture',
                    '${productState.products.where((p) => p.stock <= 0).length}',
                    Icons.warning,
                    Colors.orange,
                    theme,
                  ),
                  _buildStatCard(
                    'Stock bas',
                    '${productState.products.where((p) => p.isLowStock()).length}',
                    Icons.trending_down,
                    Colors.red,
                    theme,
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, ProductState productState, FThemeData theme) {
    return ListView.builder(
      itemCount: productState.products.length,
      itemBuilder: (context, index) {
        final product = productState.products[index];
        return _buildProductCard(context, product, theme);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, product, FThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colors.primary.withOpacity(0.1),
          child: Icon(
            Icons.inventory_2,
            color: theme.colors.primary,
          ),
        ),
        title: Text(
          product.name,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku}'),
            Text('Prix: ${product.formattedPrice}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.stock > 0 
                    ? (product.isLowStock() ? Colors.orange : Colors.green)
                    : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Stock: ${product.stock}',
                style: theme.typography.xs.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Implémenter les détails du produit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Détails de ${product.name} - À implémenter')),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des produits...',
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, FThemeData theme) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: () {
                ref.read(productProvider.notifier).loadProducts();
              },
              style: FButtonStyle.primary(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
