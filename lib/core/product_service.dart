// lib/core/product_service.dart
// Service pour gérer les produits via API

import 'constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import '../models/product.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/product_image.dart';
import 'api_service.dart';
import 'constants.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final _apiService = ApiService();
  final _storageService = StorageService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _imageBoxKey = 'product_images';
  final Uuid _uuid = const Uuid();
  final ApiService _api = ApiService();


  /// Récupérer tous les produits du warehouse actuel
  Future<List<Product>> getProducts() async {
    try {
      print('[ProductService] Getting products...');
      
      // Obtenir le company ID et warehouse ID actuels
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      
      if (companyId == null || warehouseId == null) {
        throw Exception('Aucune company ou warehouse sélectionnée');
      }
      
      final endpoint = AppConstants.productsEndpoint(companyId, warehouseId);
      print('[ProductService] API Endpoint: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      print('[ProductService] API Response Status: ${response.statusCode}');
      print('[ProductService] API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[ProductService] Response success field: ${data['success']}');
        print('[ProductService] Response data field exists: ${data['data'] != null}');
        print('[ProductService] Type de response.data[\'data\']: ${data['data']?.runtimeType}');

        if (data['success'] == true && data['data'] != null) {
          // Vérifier la structure de la réponse
          final dataField = data['data'];
          print('[ProductService] Contenu de data field: $dataField');

          List<dynamic> productsData;
          if (dataField is List) {
            // Si data est déjà une liste
            print('[ProductService] data est une liste directe');
            productsData = dataField;
          } else if (dataField is Map) {
            // Si data est un objet avec pagination
            print('[ProductService] data est un objet (probablement paginé)');
            print('[ProductService] Clés disponibles: ${dataField.keys.toList()}');
            productsData = dataField['data'] ?? [];
          } else {
            print('[ProductService] ❌ Structure de data inconnue');
            throw Exception('Structure de réponse inattendue');
          }

          print('[ProductService] Raw products data: $productsData');
          print('[ProductService] Number of products in response: ${productsData.length}');

          final products = productsData
              .map((json) {
                print('[ProductService] Processing product: $json');
                return Product.fromJson(json as Map<String, dynamic>);
              })
              .toList();
          
          print('[ProductService] Successfully parsed ${products.length} products');
          for (int i = 0; i < products.length; i++) {
            final product = products[i];
            print('[ProductService] Product $i: ID=${product.id}, Name=${product.name}, Stock=${product.stock}');
          }
          
          // Sauvegarder localement
          try {
            await _saveProductsToStorage(products);
            print('[ProductService] Products saved to local storage successfully');
          } catch (storageError) {
            print('[ProductService] Error saving products to storage: $storageError');
          }
          
          print('[ProductService] Found ${products.length} products');
          return products;
        } else {
          print('[ProductService] API response indicates failure or no data');
          print('[ProductService] Success field: ${data['success']}');
          print('[ProductService] Data field: ${data['data']}');
        }
      } else {
        print('[ProductService] API returned non-200 status: ${response.statusCode}');
      }
      
      throw Exception('Erreur lors de la récupération des produits');
    } catch (e) {
      print('[ProductService] Error getting products: $e');
      
      // Essayer de récupérer depuis le stockage local
      try {
        final productsData = _storageService.getProducts();
        if (productsData.isNotEmpty) {
          final products = productsData
              .map((json) => Product.fromJson(json))
              .toList();
          print('[ProductService] Loaded ${products.length} products from storage');
          return products;
        }
      } catch (storageError) {
        print('[ProductService] Error loading from storage: $storageError');
      }
      
      rethrow;
    }
  }

  /// Récupérer un produit par ID
  Future<Product?> getProduct(String productId) async {
    try {
      print('[ProductService] Getting product: $productId');
      
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      
      if (companyId == null || warehouseId == null) {
        throw Exception('Aucune company ou warehouse sélectionnée');
      }
      
      final endpoint = AppConstants.productEndpoint(companyId, warehouseId, productId);
      print('[ProductService] API Endpoint: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final product = Product.fromJson(data['data'] as Map<String, dynamic>);
          print('[ProductService] Product retrieved: ${product.name}');
          return product;
        }
      }
      
      return null;
    } catch (e) {
      print('[ProductService] Error getting product: $e');
      return null;
    }
  }

  /// Créer un nouveau produit
  Future<Product> createProduct(Product product) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[ProductService] ➕ Création d\'un nouveau produit...');
      print('[ProductService] 📦 Données du produit:');
      print('  - Nom: ${product.name}');
      print('  - SKU: ${product.sku}');
      print('  - Prix: ${product.price} FCFA');
      print('  - Stock: ${product.stock}');
      print('  - Catégorie ID: ${product.categoryId}');

      print('[ProductService] 🔍 Récupération des IDs entreprise/entrepôt...');
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();

      print('[ProductService] 🏢 Company ID: $companyId');
      print('[ProductService] 🏪 Warehouse ID: $warehouseId');

      if (companyId == null || warehouseId == null) {
        print('[ProductService] ❌ Aucune company ou warehouse sélectionnée');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucune company ou warehouse sélectionnée');
      }

      final endpoint = AppConstants.productsEndpoint(companyId, warehouseId);
      print('[ProductService] 🌐 URL: $endpoint');

      final productJson = product.toApiJson();
      print('[ProductService] 📄 JSON envoyé: $productJson');
      print('[ProductService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        endpoint,
        data: productJson,
      );

      print('[ProductService] 📥 Response status: ${response.statusCode}');
      print('[ProductService] 📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final createdProduct = Product.fromJson(data['data'] as Map<String, dynamic>);
          print('[ProductService] ✅ Produit créé avec succès!');
          print('[ProductService] 🆔 ID: ${createdProduct.id}');
          print('[ProductService] 📦 Nom: ${createdProduct.name}');
          print('[ProductService] 🔖 SKU: ${createdProduct.sku}');

          // Sauvegarder localement
          print('[ProductService] 💾 Sauvegarde locale...');
          await _storageService.saveProduct(createdProduct.toJson());
          print('[ProductService] ✅ Produit sauvegardé localement');
          print('═══════════════════════════════════════════════════════');

          return createdProduct;
        } else {
          print('[ProductService] ❌ Réponse API invalide');
          print('[ProductService] Success: ${data['success']}, Data: ${data['data']}');
          print('═══════════════════════════════════════════════════════');
        }
      } else {
        print('[ProductService] ❌ Status code inattendu: ${response.statusCode}');
        print('═══════════════════════════════════════════════════════');
      }

      throw Exception('Erreur lors de la création du produit');
    } catch (e) {
      print('[ProductService] ❌ ERREUR création produit: $e');
      print('[ProductService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[ProductService] 📍 Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Mettre à jour un produit
  Future<Product> updateProduct(Product product) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[ProductService] 🔄 Mise à jour d\'un produit...');
      print('[ProductService] 📦 Données du produit:');
      print('  - ID: ${product.id}');
      print('  - Nom: ${product.name}');
      print('  - SKU: ${product.sku}');
      print('  - Prix: ${product.price} FCFA');
      print('  - Stock: ${product.stock}');

      print('[ProductService] 🔍 Récupération des IDs entreprise/entrepôt...');
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();

      print('[ProductService] 🏢 Company ID: $companyId');
      print('[ProductService] 🏪 Warehouse ID: $warehouseId');

      if (companyId == null || warehouseId == null) {
        print('[ProductService] ❌ Aucune company ou warehouse sélectionnée');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucune company ou warehouse sélectionnée');
      }

      final endpoint = AppConstants.productEndpoint(companyId, warehouseId, product.id);
      print('[ProductService] 🌐 URL: $endpoint');

      final productJson = product.toApiJson();
      print('[ProductService] 📄 JSON envoyé: $productJson');
      print('[ProductService] 📤 Envoi de la requête PUT...');

      final response = await _apiService.put(
        endpoint,
        data: productJson,
      );

      print('[ProductService] 📥 Response status: ${response.statusCode}');
      print('[ProductService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final updatedProduct = Product.fromJson(data['data'] as Map<String, dynamic>);
          print('[ProductService] ✅ Produit mis à jour avec succès!');
          print('[ProductService] 🆔 ID: ${updatedProduct.id}');
          print('[ProductService] 📦 Nom: ${updatedProduct.name}');
          print('[ProductService] 📊 Stock: ${updatedProduct.stock}');

          // Sauvegarder localement
          print('[ProductService] 💾 Sauvegarde locale...');
          await _storageService.saveProduct(updatedProduct.toJson());
          print('[ProductService] ✅ Produit sauvegardé localement');
          print('═══════════════════════════════════════════════════════');

          return updatedProduct;
        } else {
          print('[ProductService] ❌ Réponse API invalide');
          print('[ProductService] Success: ${data['success']}, Data: ${data['data']}');
          print('═══════════════════════════════════════════════════════');
        }
      } else {
        print('[ProductService] ❌ Status code inattendu: ${response.statusCode}');
        print('═══════════════════════════════════════════════════════');
      }

      throw Exception('Erreur lors de la mise à jour du produit');
    } catch (e) {
      print('[ProductService] ❌ ERREUR mise à jour produit: $e');
      print('[ProductService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[ProductService] 📍 Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[ProductService] 🗑️ Suppression d\'un produit...');
      print('[ProductService] 🆔 Product ID: $productId');

      print('[ProductService] 🔍 Récupération des IDs entreprise/entrepôt...');
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();

      print('[ProductService] 🏢 Company ID: $companyId');
      print('[ProductService] 🏪 Warehouse ID: $warehouseId');

      if (companyId == null || warehouseId == null) {
        print('[ProductService] ❌ Aucune company ou warehouse sélectionnée');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucune company ou warehouse sélectionnée');
      }

      final endpoint = AppConstants.productEndpoint(companyId, warehouseId, productId);
      print('[ProductService] 🌐 URL: $endpoint');
      print('[ProductService] 📤 Envoi de la requête DELETE...');

      final response = await _apiService.delete(endpoint);

      print('[ProductService] 📥 Response status: ${response.statusCode}');
      print('[ProductService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        print('[ProductService] ✅ Produit supprimé avec succès via API');

        // Supprimer du stockage local
        print('[ProductService] 💾 Suppression du stockage local...');
        await _storageService.deleteProduct(productId);
        print('[ProductService] ✅ Produit supprimé du stockage local');
        print('═══════════════════════════════════════════════════════');
      } else {
        print('[ProductService] ❌ Status code inattendu: ${response.statusCode}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Erreur lors de la suppression du produit');
      }
    } catch (e) {
      print('[ProductService] ❌ ERREUR suppression produit: $e');
      print('[ProductService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[ProductService] 📍 Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Mettre à jour le stock d'un produit
  Future<Product> updateProductStock(String productId, int newStock, String reason) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[ProductService] 📊 Mise à jour du stock...');
      print('[ProductService] 🆔 Product ID: $productId');
      print('[ProductService] 📦 Nouveau stock: $newStock');
      print('[ProductService] 📝 Raison: $reason');

      print('[ProductService] 🔍 Récupération des IDs entreprise/entrepôt...');
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();

      print('[ProductService] 🏢 Company ID: $companyId');
      print('[ProductService] 🏪 Warehouse ID: $warehouseId');

      if (companyId == null || warehouseId == null) {
        print('[ProductService] ❌ Aucune entreprise ou warehouse sélectionné');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucune entreprise ou warehouse sélectionné');
      }

      final endpoint = AppConstants.inventoryMovementsEndpoint(companyId, warehouseId);
      print('[ProductService] 🌐 URL: $endpoint');

      final movementData = {
        'product_id': productId,
        'movement_type': 'adjustment',
        'quantity': newStock,
        'reason': reason,
        'movement_date': DateTime.now().toIso8601String(),
      };

      print('[ProductService] 📄 Données du mouvement: $movementData');
      print('[ProductService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        endpoint,
        data: movementData,
      );

      print('[ProductService] 📥 Response status: ${response.statusCode}');
      print('[ProductService] 📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('[ProductService] ✅ Mouvement d\'inventaire créé avec succès');

        // Récupérer le produit mis à jour
        print('[ProductService] 🔄 Récupération du produit mis à jour...');
        final updatedProduct = await getProduct(productId);
        if (updatedProduct != null) {
          print('[ProductService] ✅ Produit récupéré avec succès:');
          print('[ProductService] 📦 Nom: ${updatedProduct.name}');
          print('[ProductService] 📊 Nouveau stock: ${updatedProduct.stock}');
          print('═══════════════════════════════════════════════════════');
          return updatedProduct;
        } else {
          print('[ProductService] ❌ Impossible de récupérer le produit mis à jour');
          print('═══════════════════════════════════════════════════════');
        }
      } else {
        print('[ProductService] ❌ Status code inattendu: ${response.statusCode}');
        print('═══════════════════════════════════════════════════════');
      }

      throw Exception('Erreur lors de la mise à jour du stock');
    } catch (e) {
      print('[ProductService] ❌ ERREUR mise à jour stock: $e');
      print('[ProductService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[ProductService] 📍 Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Sauvegarder les produits en local
  Future<void> _saveProductsToStorage(List<Product> products) async {
    try {
      for (final product in products) {
        await _storageService.saveProduct(product.toJson());
      }
      print('[ProductService] ${products.length} products saved to storage');
    } catch (e) {
      print('[ProductService] Error saving products to storage: $e');
      rethrow;
    }
  }

  Future<List<ProductImage>> _loadAllImages() async {
    final raw = await StorageService().readSetting(_imageBoxKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => ProductImage.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> _saveAllImages(List<ProductImage> images) async {
    final jsonList = images.map((e) => e.toJson()).toList();
    await StorageService().writeSetting(_imageBoxKey, jsonEncode(jsonList));
  }

  /// Récupère la liste locale des images d'un produit
  Future<List<ProductImage>> getLocalImages(String productId) async {
    final images = await _loadAllImages();
    return images.where((img) => img.productId == productId).toList();
  }

  /// Ajoute une image produit en local (offline d'abord)
  Future<void> addLocalImage(File file, String productId) async {
    final id = _uuid.v4();
    final appDir = await getApplicationDocumentsDirectory();
    final imgPath = '${appDir.path}/products/$productId/$id.jpg';
    await Directory('${appDir.path}/products/$productId').create(recursive: true);
    await file.copy(imgPath);
    // Lire/mettre à jour la file
    final all = await _loadAllImages();
    all.add(ProductImage(
      id: id, localPath: imgPath, serverUrl: null,
      productId: productId, syncStatus: ImageSyncStatus.pending));
    await _saveAllImages(all);
  }

  /// Tente la synchronisation (upload) de toutes les images locales en attente
  Future<void> syncPendingImages(String productId) async {
    final all = await _loadAllImages();
    bool changed = false;
    for (int i = 0; i < all.length; i++) {
      final img = all[i];
      if (img.productId != productId) continue;
      if (img.syncStatus != ImageSyncStatus.pending) continue;
      if (img.localPath == null) continue;
      try {
        all[i] = img.copyWith(syncStatus: ImageSyncStatus.syncing);
        changed = true;

        final form = FormData.fromMap({
          'image': await MultipartFile.fromFile(img.localPath!, filename: '${img.id}.jpg'),
        });
        final endpoint = '${AppConstants.baseUrl}/products/${img.productId}/images';
        final response = await _api.post(endpoint, data: form, options: Options(contentType: 'multipart/form-data'));

        // Attendu: { id: ..., url: ... }
        final data = response.data is Map ? response.data as Map : {};
        final serverId = data['id']?.toString();
        final url = data['url']?.toString();
        if (serverId != null && url != null) {
          all[i] = img.copyWith(
            syncStatus: ImageSyncStatus.synced,
            serverUrl: url,
            id: serverId,
          );
          changed = true;
        } else {
          all[i] = img.copyWith(syncStatus: ImageSyncStatus.failed);
          changed = true;
        }
      } catch (_) {
        all[i] = img.copyWith(syncStatus: ImageSyncStatus.failed);
        changed = true;
      }
    }
    if (changed) {
      await _saveAllImages(all);
    }
  }

  /// Supprime une image locale et programme la suppression côté serveur si nécessaire
  Future<void> deleteLocalImage(ProductImage image) async {
    final all = await _loadAllImages();
    all.removeWhere((e) => e.id == image.id);
    // Nettoyage fichier local
    if (image.localPath != null) {
      final f = File(image.localPath!);
      if (await f.exists()) {
        try { await f.delete(); } catch (_) {}
      }
    }
    // TODO: si image.synced => ajouter une entrée de suppression à une queue (DELETE /products/{productId}/images/{id})
    await _saveAllImages(all);
  }

  /// Retourne l'image prioritaire à afficher pour un produit
  /// Priorité: image locale pending/syncing > image distante synced > null
  Future<ProductImage?> getPrimaryImage(String productId) async {
    final images = await getLocalImages(productId);
    // 1) locale
    final local = images.firstWhere(
      (i) => i.localPath != null,
      orElse: () => images.isNotEmpty ? images.first : ProductImage(
        id: '', productId: productId, localPath: null, serverUrl: null, syncStatus: ImageSyncStatus.failed,
      ),
    );
    if (local.id.isNotEmpty && local.localPath != null) {
      return local;
    }
    // 2) distante
    final remote = images.firstWhere(
      (i) => i.serverUrl != null,
      orElse: () => ProductImage(
        id: '', productId: productId, localPath: null, serverUrl: null, syncStatus: ImageSyncStatus.failed,
      ),
    );
    if (remote.id.isNotEmpty && remote.serverUrl != null) {
      return remote;
    }
    return null;
  }
}
