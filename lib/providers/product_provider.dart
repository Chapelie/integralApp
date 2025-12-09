// product_provider.dart
// Provider for product management
// Handles product listing, search, CRUD operations, and sync

import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product.dart';
import '../core/storage_service.dart';
import '../core/api_service.dart';
import '../core/image_service.dart';
import '../core/sync_service.dart';
import '../core/product_service.dart';
import '../core/stock_adjustment_service.dart';
import '../providers/auth_provider.dart';

part 'product_provider.g.dart';

// Product State
class ProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  ProductState({
    this.products = const [],
    this.filteredProducts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  ProductState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ProductState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Product Notifier
@riverpod
class ProductNotifier extends _$ProductNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();
  final ProductService _productService = ProductService();

  @override
  ProductState build() {
    // Charger les produits immédiatement au démarrage
    Future.microtask(() {
      if (ref.mounted) {
        loadProducts();
      }
    });
    return ProductState();
  }

  // Load products from API and local storage
  Future<void> loadProducts() async {
    print('[ProductProvider] ===== DÉBUT loadProducts =====');
    print('[ProductProvider] État actuel - isLoading: ${state.isLoading}, products: ${state.products.length}, error: ${state.error}');
    
    state = state.copyWith(isLoading: true, error: null);
    print('[ProductProvider] État mis à jour - isLoading: true, error: null');

    try {
      print('[ProductProvider] Tentative de chargement depuis l\'API...');
      
      // Essayer de charger depuis l'API d'abord
      final products = await _productService.getProducts();
      
      print('[ProductProvider] ✅ Succès API - ${products.length} produits récupérés');
      
      state = state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );
      
      print('[ProductProvider] État final - isLoading: false, products: ${state.products.length}, error: ${state.error}');
      print('[ProductProvider] ===== FIN loadProducts (API) =====');
    } catch (e) {
      print('[ProductProvider] ❌ Erreur API: $e');
      print('[ProductProvider] Type d\'erreur: ${e.runtimeType}');
      print('[ProductProvider] Tentative de fallback sur le stockage local...');
      
      // Fallback sur le stockage local
      try {
        print('[ProductProvider] Récupération des données du stockage local...');
        final productsData = _storageService.getProducts();
        print('[ProductProvider] Données brutes du stockage: ${productsData.length} éléments');
        
        final products = productsData.map((data) {
          print('[ProductProvider] Conversion JSON vers Product: ${data['name'] ?? 'Sans nom'}');
          return Product.fromJson(data);
        }).toList();
        
        print('[ProductProvider] ✅ Succès stockage local - ${products.length} produits convertis');
        
        state = state.copyWith(
          products: products,
          filteredProducts: products,
          isLoading: false,
          error: null, // Pas d'erreur si on a réussi à charger depuis le stockage local
        );
        
        print('[ProductProvider] État final - isLoading: false, products: ${state.products.length}, error: ${state.error}');
        print('[ProductProvider] ===== FIN loadProducts (Stockage local) =====');
      } catch (storageError) {
        print('[ProductProvider] ❌ Erreur stockage local: $storageError');
        print('[ProductProvider] Type d\'erreur stockage: ${storageError.runtimeType}');
        
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur de chargement: ${e.toString()}',
        );
        
        print('[ProductProvider] État final - isLoading: false, products: ${state.products.length}, error: ${state.error}');
        print('[ProductProvider] ===== FIN loadProducts (Erreur) =====');
      }
    }
  }

  // Charger les produits depuis le stockage local uniquement
  Future<void> loadProductsFromStorage() async {
    print('[ProductProvider] ===== DÉBUT loadProductsFromStorage =====');
    print('[ProductProvider] État actuel - isLoading: ${state.isLoading}, products: ${state.products.length}, error: ${state.error}');
    
    try {
      print('[ProductProvider] Récupération des données du stockage local...');
      
      final productsData = _storageService.getProducts();
      print('[ProductProvider] Données brutes du stockage: ${productsData.length} éléments');
      
      if (productsData.isEmpty) {
        print('[ProductProvider] ⚠️ Aucune donnée dans le stockage local');
      }
      
      final products = productsData.map((data) {
        print('[ProductProvider] Conversion JSON vers Product: ${data['name'] ?? 'Sans nom'} (ID: ${data['id'] ?? 'Sans ID'})');
        return Product.fromJson(data);
      }).toList();
      
      print('[ProductProvider] ✅ Succès - ${products.length} produits convertis depuis le stockage local');
      
      state = state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );
      
      print('[ProductProvider] État final - isLoading: false, products: ${state.products.length}, error: ${state.error}');
      print('[ProductProvider] ===== FIN loadProductsFromStorage =====');
    } catch (e) {
      print('[ProductProvider] ❌ Erreur stockage local: $e');
      print('[ProductProvider] Type d\'erreur: ${e.runtimeType}');
      print('[ProductProvider] Stack trace: ${e.toString()}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      
      print('[ProductProvider] État final - isLoading: false, products: ${state.products.length}, error: ${state.error}');
      print('[ProductProvider] ===== FIN loadProductsFromStorage (Erreur) =====');
    }
  }

  // Search products
  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);

    List<Product> baseProducts = state.products;

    // Apply category filter if active (check if category provider has selection)
    // Note: This will be handled by filterByCategory when category changes
    // For now, we just filter by search

    if (query.isEmpty) {
      state = state.copyWith(filteredProducts: baseProducts);
      return;
    }

    final filtered = baseProducts.where((product) {
      final nameLower = product.name.toLowerCase();
      final skuLower = product.sku?.toLowerCase() ?? '';
      final queryLower = query.toLowerCase();

      return nameLower.contains(queryLower) || skuLower.contains(queryLower);
    }).toList();

    state = state.copyWith(filteredProducts: filtered);
  }

  /// Filter products by category
  void filterByCategory(String? categoryId) {
    print('[ProductProvider] Filtering by category: $categoryId');

    List<Product> baseProducts = state.products;

    // Apply category filter
    if (categoryId != null) {
      baseProducts = baseProducts.where((product) {
        return product.categoryId == categoryId;
      }).toList();
    }

    // Re-apply search if active
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      baseProducts = baseProducts.where((product) {
        final nameLower = product.name.toLowerCase();
        final skuLower = product.sku?.toLowerCase() ?? '';
        final queryLower = state.searchQuery!.toLowerCase();

        return nameLower.contains(queryLower) || skuLower.contains(queryLower);
      }).toList();
    }

    print('[ProductProvider] Filtered ${baseProducts.length} products for category $categoryId');
    state = state.copyWith(filteredProducts: baseProducts);
  }

  // Add product
  Future<void> addProduct(Product product) async {
    try {
      print('[ProductProvider] Adding product: ${product.name}');
      
      // Créer via l'API
      final createdProduct = await _productService.createProduct(product);
      
      final updatedProducts = [...state.products, createdProduct];
      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        error: null,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }
      
      print('[ProductProvider] Product added successfully: ${createdProduct.name}');
    } catch (e) {
      print('[ProductProvider] Error adding product: $e');
      state = state.copyWith(error: e.toString());
    }
  }


  // Update product stock after sale
  Future<void> updateStockAfterSale(String productId, int quantitySold) async {
    try {
      final product = state.products.firstWhere((p) => p.id == productId);
      final newStock = product.stock - quantitySold;
      
      if (newStock < 0) {
        throw Exception('Stock insuffisant pour ${product.name}');
      }
      
      final updatedProduct = product.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      
      await _storageService.saveProduct(updatedProduct.toJson());
      
      final updatedProducts = state.products.map((p) {
        return p.id == productId ? updatedProduct : p;
      }).toList();

      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        error: null,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Update stock for multiple products (batch operation)
  Future<void> updateStockForSale(Map<String, int> productQuantities) async {
    try {
      final updatedProducts = <Product>[];
      
      for (final product in state.products) {
        if (productQuantities.containsKey(product.id)) {
          final quantitySold = productQuantities[product.id]!;
          final newStock = product.stock - quantitySold;
          
          if (newStock < 0) {
            throw Exception('Stock insuffisant pour ${product.name}');
          }
          
          final updatedProduct = product.copyWith(
            stock: newStock,
            updatedAt: DateTime.now(),
          );
          
          await _storageService.saveProduct(updatedProduct.toJson());
          updatedProducts.add(updatedProduct);
        } else {
          updatedProducts.add(product);
        }
      }

      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        error: null,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      print('[ProductProvider] Deleting product: $id');
      
      // Supprimer via l'API
      await _productService.deleteProduct(id);
      
      final updatedProducts = state.products.where((p) => p.id != id).toList();
      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        error: null,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }
      
      print('[ProductProvider] Product deleted successfully: $id');
    } catch (e) {
      print('[ProductProvider] Error deleting product: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Refresh from server
  Future<void> refreshFromServer() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[ProductProvider] Refreshing products from server...');
      
      // Charger depuis l'API
      final products = await _productService.getProducts();
      
      state = state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }
      
      print('[ProductProvider] Refreshed ${products.length} products from server');
    } catch (e) {
      print('[ProductProvider] Error refreshing from server: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Ajouter une image à un produit
  Future<void> addProductImage(String productId, Uint8List imageBytes) async {
    try {
      final imagePath = await _imageService.saveImageFromBytes(imageBytes, productId);
      if (imagePath != null) {
        // Mettre à jour le produit avec le chemin de l'image
        final productIndex = state.products.indexWhere((p) => p.id == productId);
        if (productIndex != -1) {
          final product = state.products[productIndex];
          final updatedProduct = product.copyWith(imageUrl: imagePath);
          
          await _storageService.saveProduct(updatedProduct.toJson());
          
          final updatedProducts = List<Product>.from(state.products);
          updatedProducts[productIndex] = updatedProduct;
          
          state = state.copyWith(
            products: updatedProducts,
            filteredProducts: updatedProducts,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'ajout de l\'image: ${e.toString()}');
    }
  }

  /// Télécharger et sauvegarder une image depuis une URL
  Future<void> downloadProductImage(String productId, String imageUrl) async {
    try {
      final imagePath = await _imageService.downloadAndSaveImage(imageUrl, productId);
      if (imagePath != null) {
        // Mettre à jour le produit avec le chemin de l'image
        final productIndex = state.products.indexWhere((p) => p.id == productId);
        if (productIndex != -1) {
          final product = state.products[productIndex];
          final updatedProduct = product.copyWith(imageUrl: imagePath);
          
          await _storageService.saveProduct(updatedProduct.toJson());
          
          final updatedProducts = List<Product>.from(state.products);
          updatedProducts[productIndex] = updatedProduct;
          
          state = state.copyWith(
            products: updatedProducts,
            filteredProducts: updatedProducts,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du téléchargement de l\'image: ${e.toString()}');
    }
  }

  /// Obtenir le chemin local d'une image
  String? getLocalImagePath(String? imageUrl) {
    return _imageService.getLocalImagePath(imageUrl);
  }

  /// Vérifier si une image existe localement
  bool imageExists(String? imageUrl) {
    return _imageService.imageExists(imageUrl);
  }

  /// Mettre à jour le stock d'un produit
  Future<void> updateProductStock(String productId, int newStock, String reason) async {
    try {
      print('[ProductProvider] Updating stock for product: $productId, new stock: $newStock');
      
      // 1. Get current product to calculate adjustment
      final product = state.products.firstWhere((p) => p.id == productId);
      final currentStock = product.stock;
      final adjustmentQuantity = newStock - currentStock;
      
      // 2. Update locally first (immediate response)
      final updatedProduct = product.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      
      await _storageService.saveProduct(updatedProduct.toJson());
      
      final updatedProducts = state.products.map((p) {
        return p.id == productId ? updatedProduct : p;
      }).toList();

      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        error: null,
      );

      // Re-apply search if active
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        searchProducts(state.searchQuery!);
      }

      print('[ProductProvider] Stock updated locally for product: $productId');
      
      // 3. Create stock adjustment via API in background (non-blocking)
      if (adjustmentQuantity != 0) {
        _createStockAdjustment(productId, adjustmentQuantity, reason).catchError((e) {
          print('[ProductProvider] Stock adjustment error: $e');
          // Stock is already updated locally
        });
      }
      
      // 4. Also update via ProductService for backward compatibility
      _productService.updateProductStock(productId, newStock, reason).catchError((e) {
        print('[ProductProvider] ProductService update error: $e');
      });
      
      print('[ProductProvider] Stock updated successfully for product: $productId');
    } catch (e) {
      print('[ProductProvider] Error updating stock: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Génère un SKU simple basé sur le nom et un suffixe horodaté
  String _generateSku(String name) {
    final normalized = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '-')
        .replaceAll(RegExp('-+'), '-')
        .trim();
    final base = normalized.isEmpty ? 'PROD' : normalized;
    final shortBase = base.length > 12 ? base.substring(0, 12) : base;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = timestamp.substring(timestamp.length - 4);
    return '$shortBase-$suffix';
  }

  /// Create stock adjustment via API (background)
  Future<void> _createStockAdjustment(String productId, int quantity, String reason) async {
    try {
      final stockAdjustmentService = StockAdjustmentService();
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? 'unknown';
      
      await stockAdjustmentService.createAdjustment(
        items: [
          StockAdjustmentItem(
            productId: productId,
            quantity: quantity,
            reason: reason,
          ),
        ],
        notes: reason,
        userId: userId,
      );
      
      print('[ProductProvider] Stock adjustment created: $productId, quantity: $quantity');
    } catch (e) {
      print('[ProductProvider] Error creating stock adjustment: $e');
      // Silent fail - stock is already updated locally
    }
  }

  /// Synchronisation intelligente avec priorité POS
  Future<void> smartSync() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Utiliser le SyncService existant pour la synchronisation intelligente
      final syncService = SyncService();
      await syncService.fullSync();
      
      // Recharger les produits après synchronisation
      await loadProducts();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de synchronisation: ${e.toString()}',
      );
    }
  }

  /// Créer un nouveau produit
  Future<void> createProduct({
    required String name,
    String? sku,
    String? description,
    double? price, // Prix optionnel (peut être null pour produits sans prix)
    required int stock,
    int? minStock,
    int? maxStock,
    String? barcode,
    double taxRate = 0.0,
    String? categoryId,
    bool isActive = true,
    String? imageUrl,
  }) async {
    print('[ProductProvider] ===== DÉBUT createProduct =====');
    print('[ProductProvider] Paramètres reçus:');
    print('[ProductProvider]   - Nom: $name');
      print('[ProductProvider]   - SKU: ${sku ?? "(auto)"}');
    print('[ProductProvider]   - Prix: $price');
    print('[ProductProvider]   - Stock: $stock');
    print('[ProductProvider]   - Catégorie ID: $categoryId');

    state = state.copyWith(isLoading: true, error: null);
    print('[ProductProvider] État mis à jour - isLoading: true');

    try {
      print('[ProductProvider] Création de l\'objet Product...');
      final generatedSku = (sku != null && sku.trim().isNotEmpty)
          ? sku.trim()
          : _generateSku(name);

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        sku: generatedSku,
        description: description,
        price: price,
        stock: stock,
        minStock: minStock,
        maxStock: maxStock,
        barcode: barcode,
        taxRate: taxRate,
        categoryId: categoryId,
        isActive: isActive,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('[ProductProvider] Produit créé localement - ID temporaire: ${product.id}');
      print('[ProductProvider] SKU utilisé: ${product.sku}');
      print('[ProductProvider] Appel ProductService.createProduct()...');

      // Créer via l'API
      final createdProduct = await _productService.createProduct(product);

      print('[ProductProvider] ✅ Produit créé via API - ID final: ${createdProduct.id}');
      print('[ProductProvider] Mise à jour de l\'état du provider...');

      final updatedProducts = [...state.products, createdProduct];
      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        isLoading: false,
        error: null,
      );

      print('[ProductProvider] ✅ État mis à jour - ${updatedProducts.length} produits totaux');
      print('[ProductProvider] ===== FIN createProduct (Succès) =====');
    } catch (e) {
      print('[ProductProvider] ❌ Erreur création produit: $e');
      print('[ProductProvider] Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[ProductProvider] ===== FIN createProduct (Erreur) =====');
    }
  }

  /// Mettre à jour un produit existant
  Future<void> updateProduct({
    required String id,
    String? name,
    String? sku,
    String? description,
    double? price,
    int? stock,
    int? minStock,
    int? maxStock,
    String? barcode,
    double? taxRate,
    String? categoryId,
    bool? isActive,
    String? imageUrl,
  }) async {
    print('[ProductProvider] ===== DÉBUT updateProduct =====');
    print('[ProductProvider] ID du produit: $id');
    print('[ProductProvider] Paramètres à mettre à jour:');
    if (name != null) print('[ProductProvider]   - Nom: $name');
    if (sku != null) print('[ProductProvider]   - SKU: $sku');
    if (price != null) print('[ProductProvider]   - Prix: $price');
    if (stock != null) print('[ProductProvider]   - Stock: $stock');
    if (categoryId != null) print('[ProductProvider]   - Catégorie ID: $categoryId');

    state = state.copyWith(isLoading: true, error: null);
    print('[ProductProvider] État mis à jour - isLoading: true');

    try {
      print('[ProductProvider] Recherche du produit existant...');
      final existingProduct = state.products.firstWhere((p) => p.id == id);
      print('[ProductProvider] Produit existant trouvé: ${existingProduct.name}');

      print('[ProductProvider] Création du produit mis à jour...');
      final updatedProduct = existingProduct.copyWith(
        name: name ?? existingProduct.name,
        sku: sku ?? existingProduct.sku,
        description: description ?? existingProduct.description,
        price: price ?? existingProduct.price,
        stock: stock ?? existingProduct.stock,
        minStock: minStock ?? existingProduct.minStock,
        maxStock: maxStock ?? existingProduct.maxStock,
        barcode: barcode ?? existingProduct.barcode,
        taxRate: taxRate ?? existingProduct.taxRate,
        categoryId: categoryId ?? existingProduct.categoryId,
        isActive: isActive ?? existingProduct.isActive,
        imageUrl: imageUrl ?? existingProduct.imageUrl,
        updatedAt: DateTime.now(),
      );

      print('[ProductProvider] Appel ProductService.updateProduct()...');

      // Mettre à jour via l'API
      final apiUpdatedProduct = await _productService.updateProduct(updatedProduct);

      print('[ProductProvider] ✅ Produit mis à jour via API');
      print('[ProductProvider] Mise à jour de l\'état du provider...');

      final updatedProducts = state.products.map((p) {
        return p.id == id ? apiUpdatedProduct : p;
      }).toList();

      state = state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedProducts,
        isLoading: false,
        error: null,
      );

      print('[ProductProvider] ✅ État mis à jour - ${updatedProducts.length} produits totaux');
      print('[ProductProvider] ===== FIN updateProduct (Succès) =====');
    } catch (e) {
      print('[ProductProvider] ❌ Erreur mise à jour produit: $e');
      print('[ProductProvider] Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[ProductProvider] ===== FIN updateProduct (Erreur) =====');
    }
  }

}
