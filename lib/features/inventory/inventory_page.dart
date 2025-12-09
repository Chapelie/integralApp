import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../widgets/main_layout.dart';
import '../products/widgets/product_image_tile.dart';
import '../../widgets/mobile_header.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _searchQuery = '';
  bool _showLowStock = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('[InventoryPage] ===== INIT STATE =====');
    print('[InventoryPage] Chargement des produits...');

    // Charger les produits du stockage local immédiatement, puis rafraîchir depuis l'API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[InventoryPage] PostFrameCallback exécuté');
      // D'abord charger depuis le stockage local pour affichage immédiat
      print('[InventoryPage] Appel loadProductsFromStorage...');
      ref.read(productProvider.notifier).loadProductsFromStorage();
      // Puis essayer de faire une mise à jour depuis l'API en arrière-plan
      print('[InventoryPage] Appel _refreshProductsInBackground...');
      _refreshProductsInBackground();
    });
  }

  /// Rafraîchir les produits en arrière-plan sans bloquer l'interface
  Future<void> _refreshProductsInBackground() async {
    print('[InventoryPage] ===== DÉBUT _refreshProductsInBackground =====');
    try {
      print('[InventoryPage] Tentative de rafraîchissement depuis l\'API...');
      await ref.read(productProvider.notifier).loadProducts();
      print('[InventoryPage] ✅ Rafraîchissement réussi');
    } catch (e) {
      // Ignorer les erreurs de réseau en arrière-plan
      print('[InventoryPage] ❌ Background refresh failed: $e');
      print('[InventoryPage] Type d\'erreur: ${e.runtimeType}');
    }
    print('[InventoryPage] ===== FIN _refreshProductsInBackground =====');
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/inventory',
      appBar: MobileHeader(
        title: 'Gestion du Stock',
        actions: [
          IconButton(
            onPressed: () {
              setState(() { _showLowStock = !_showLowStock; });
            },
            icon: Icon(_showLowStock ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Filtrer stock faible',
            color: _showLowStock ? Colors.orange : null,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            tooltip: _showSearchBar ? 'Fermer la recherche' : 'Rechercher',
          ),
        ],
      ),
      child: Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Rechercher par nom, SKU...'),
                onChanged: (value) {
                  setState(() { _searchQuery = value.toLowerCase(); });
                },
              ),
            ),
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
                              'Erreur lors du chargement',
                              style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productState.error!,
                              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FButton(
                              onPress: () { ref.read(productProvider.notifier).loadProducts(); },
                              style: FButtonStyle.primary(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : productState.products.isEmpty
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
                                  'Aucun produit en stock',
                                  style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez des produits pour commencer',
                                  style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                                ),
                              ],
                            ),
                          )
                        : _buildInventoryList(context, _getFilteredProducts(productState.products), theme, productState.products),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary(BuildContext context, ProductState productState, FThemeData theme) {
    if (productState.isLoading || productState.error != null) {
      return const SizedBox.shrink();
    }

    final products = productState.products;
    final totalProducts = products.length;
    final inStockProducts = products.where((p) => p.stock > 0).length;
    final lowStockProducts = products.where((p) => p.isLowStock()).length;
    final outOfStockProducts = products.where((p) => p.stock == 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total',
              totalProducts.toString(),
              Icons.inventory_2,
              theme.colors.primary,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'En Stock',
              inStockProducts.toString(),
              Icons.check_circle,
              Colors.green,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Stock Faible',
              lowStockProducts.toString(),
              Icons.warning,
              Colors.orange,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Rupture',
              outOfStockProducts.toString(),
              Icons.error,
              Colors.red,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, FThemeData theme) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    List<dynamic> filteredProducts,
    FThemeData theme,
    List<dynamic> allProducts,
  ) {
    // Si aucun produit ne correspond aux filtres
    if (filteredProducts.isEmpty && allProducts.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouvé',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _showLowStock
                  ? 'Essayez de modifier votre recherche ou filtre'
                  : 'Aucun produit en stock',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si aucun produit du tout
    if (filteredProducts.isEmpty && allProducts.isEmpty) {
      return Center(
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
              'Aucun produit en stock',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des produits pour commencer',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final isLowStock = product.stock <= (product.minStock ?? 5);
        final isOutOfStock = product.stock == 0;

        return FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ProductImageTile(productId: product.id, size: 60),
                ),

                const SizedBox(width: 16),

                // Product Info
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
                      const SizedBox(height: 4),
                      Text(
                        product.description ?? 'Aucune description',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Stock: ',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${product.stock}',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOutOfStock
                                  ? theme.colors.destructive
                                  : isLowStock
                                      ? Colors.orange
                                      : theme.colors.foreground,
                            ),
                          ),
                          if (product.minStock != null) ...[
                            Text(
                              ' / Min: ${product.minStock}',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Stock Status
                Column(
                  children: [
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.destructive,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Rupture',
                          style: theme.typography.xs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock bas',
                          style: theme.typography.xs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En stock',
                          style: theme.typography.xs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      product.formattedPrice,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(FThemeData theme) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        color: theme.colors.mutedForeground,
        size: 24,
      ),
    );
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    return products.where((product) {
      if (_searchQuery.isEmpty && !_showLowStock) return true;

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
            (product.sku?.toLowerCase().contains(_searchQuery) ?? false);
      }

      bool matchesLowStock = true;
      if (_showLowStock) {
        matchesLowStock = product.isLowStock();
      }

      return matchesSearch && matchesLowStock;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
