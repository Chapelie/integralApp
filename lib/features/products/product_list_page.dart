// lib/features/products/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/product_provider.dart';
import '../../core/utils/currency_formatter.dart';
import 'product_form_page.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/mobile_header.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  String _searchQuery = '';
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    print('[ProductListPage] ===== INIT STATE =====');
    print('[ProductListPage] Chargement des produits...');

    // Charger les produits du stockage local immédiatement, puis rafraîchir depuis l'API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[ProductListPage] PostFrameCallback exécuté');
      // D'abord charger depuis le stockage local pour affichage immédiat
      print('[ProductListPage] Appel loadProductsFromStorage...');
      ref.read(productProvider.notifier).loadProductsFromStorage();
      // Puis essayer de faire une mise à jour depuis l'API en arrière-plan
      print('[ProductListPage] Appel _refreshProductsInBackground...');
      _refreshProductsInBackground();
    });
  }

  /// Rafraîchir les produits en arrière-plan sans bloquer l'interface
  Future<void> _refreshProductsInBackground() async {
    print('[ProductListPage] ===== DÉBUT _refreshProductsInBackground =====');
    try {
      print('[ProductListPage] Tentative de rafraîchissement depuis l\'API...');
      await ref.read(productProvider.notifier).loadProducts();
      print('[ProductListPage] ✅ Rafraîchissement réussi');
    } catch (e) {
      // Ignorer les erreurs de réseau en arrière-plan
      print('[ProductListPage] ❌ Background refresh failed: $e');
      print('[ProductListPage] Type d\'erreur: ${e.runtimeType}');
    }
    print('[ProductListPage] ===== FIN _refreshProductsInBackground =====');
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);

    return MainLayout(
      currentRoute: '/products',
      appBar: MobileHeader(
        title: 'Produits',
        actions: [
          IconButton(
            icon: Icon(
              _showLowStock ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            tooltip: 'Filtrer stock faible',
            onPressed: () {
              setState(() { _showLowStock = !_showLowStock; });
            },
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FTextField(
              hint: 'Rechercher par nom, SKU ou code-barre...',
              onChange: (value) {
                setState(() { _searchQuery = value.toLowerCase(); });
              },
            ),
          ),
          Expanded(child: _buildBody(productState)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormPage(),
            ),
          );
          ref.read(productProvider.notifier).loadProducts();
        },
        icon: const Icon(FIcons.plus),
        label: const Text('Ajouter produit'),
        backgroundColor: FTheme.of(context).colors.primary,
      ),
    );
  }

  Widget _buildBody(ProductState productState) {
    if (productState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (productState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${productState.error}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    var filteredProducts = productState.products.where((product) {
      if (_searchQuery.isEmpty && !_showLowStock) return true;

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
            product.sku.toLowerCase().contains(_searchQuery) ||
            (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
      }

      bool matchesLowStock = true;
      if (_showLowStock) {
        matchesLowStock = product.stock <= (product.minStock ?? 0);
      }

      return matchesSearch && matchesLowStock;
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && !_showLowStock
                  ? 'Aucun produit enregistré'
                  : 'Aucun produit trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty && !_showLowStock
                  ? 'Appuyez sur + pour ajouter un produit'
                  : 'Essayez une autre recherche ou filtre',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Responsive: Use table for larger screens, cards for mobile
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildTable(filteredProducts);
        } else {
          return _buildCards(filteredProducts);
        }
      },
    );
  }

  Widget _buildTable(List filteredProducts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Prix', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredProducts.map((product) {
            final isLowStock = product.stock <= product.minStock;
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(FIcons.package),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!product.isActive)
                        const Text(
                          'Inactif',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                DataCell(Text(product.sku)),
                DataCell(Text(product.price != null ? CurrencyFormatter.format(product.price!) : 'Non défini')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.stock}',
                      style: TextStyle(
                        color: isLowStock ? Colors.red[900] : Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductFormPage(product: product),
                            ),
                          );
                          ref.read(productProvider.notifier).loadProducts();
                        },
                      ),
                      IconButton(
                        icon: const Icon(FIcons.trash2, size: 20, color: Colors.red),
                        onPressed: () => _showDeleteDialog(product.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCards(List filteredProducts) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredProducts.length,
      itemBuilder: (_, i) {
        final product = filteredProducts[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('SKU: ${product.sku} • Stock: ${product.stock}'),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () async {
              Navigator.pop(context);
              await ref.read(productProvider.notifier).deleteProduct(productId);
            },
            style: FButtonStyle.destructive(),
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
