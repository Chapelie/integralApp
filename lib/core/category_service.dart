// lib/core/category_service.dart
// Category management service for CRUD operations with the API
// Handles category creation, retrieval, updating, and deletion

import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final _apiService = ApiService();
  final _storageService = StorageService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _uuid = const Uuid();

  /// Get all categories from API
  Future<List<Category>> getCategories({String? warehouseId}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CategoryService] 📂 Récupération des catégories...');

      // Récupérer le warehouse_id
      final effectiveWarehouseId = warehouseId ?? await _companyWarehouseService.getSelectedWarehouseId();
      print('[CategoryService] 🏪 Warehouse ID: $effectiveWarehouseId');

      if (effectiveWarehouseId == null) {
        print('[CategoryService] ❌ Aucun warehouse_id disponible');
        print('[CategoryService] 🔄 Fallback sur stockage local...');
        print('═══════════════════════════════════════════════════════');
        return await _getCategoriesFromStorage();
      }

      final endpoint = AppConstants.categoriesEndpoint(effectiveWarehouseId);
      print('[CategoryService] 🌐 URL: $endpoint');
      print('[CategoryService] 📤 Envoi de la requête GET...');

      final response = await _apiService.get(endpoint);

      print('[CategoryService] 📥 Response status: ${response.statusCode}');
      print('[CategoryService] 📥 Response data: ${response.data}');
      print('[CategoryService] Response success field: ${response.data['success']}');
      print('[CategoryService] Response data field exists: ${response.data['data'] != null}');

      if (response.data['success'] == true) {
        final List<dynamic> categoriesData = response.data['data'] ?? [];
        print('[CategoryService] Raw categories data: $categoriesData');
        print('[CategoryService] Number of categories: ${categoriesData.length}');

        final categories = categoriesData
            .map((json) => Category.fromJson(json))
            .toList();

        print('[CategoryService] ✅ ${categories.length} catégories récupérées');

        // Save to local storage
        print('[CategoryService] 💾 Sauvegarde locale...');
        await _saveCategoriesToStorage(categories);
        print('[CategoryService] ✅ Sauvegarde terminée');
        print('═══════════════════════════════════════════════════════');

        return categories;
      } else {
        print('[CategoryService] ❌ Réponse API invalide');
        print('[CategoryService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Failed to load categories: ${response.data['message']}');
      }
    } catch (e) {
      print('[CategoryService] ❌ ERREUR récupération catégories: $e');
      print('[CategoryService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[CategoryService] 🔄 Fallback sur stockage local...');

      // Fallback to local storage
      final localCategories = await _getCategoriesFromStorage();
      print('[CategoryService] ✅ ${localCategories.length} catégories chargées depuis le stockage local');
      print('═══════════════════════════════════════════════════════');

      return localCategories;
    }
  }

  /// Get a specific category by ID
  Future<Category?> getCategory(String id) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CategoryService] 🔍 Récupération d\'une catégorie...');
      print('[CategoryService] 🆔 Category ID: $id');

      final endpoint = AppConstants.categoryEndpoint(id);
      print('[CategoryService] 🌐 URL: $endpoint');
      print('[CategoryService] 📤 Envoi de la requête GET...');

      final response = await _apiService.get(endpoint);

      print('[CategoryService] 📥 Response status: ${response.statusCode}');
      print('[CategoryService] 📥 Response data: ${response.data}');

      if (response.data['success'] == true) {
        final category = Category.fromJson(response.data['data']);
        print('[CategoryService] ✅ Catégorie récupérée: ${category.name}');
        print('═══════════════════════════════════════════════════════');
        return category;
      } else {
        print('[CategoryService] ❌ Réponse API invalide');
        print('[CategoryService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Failed to load category: ${response.data['message']}');
      }
    } catch (e) {
      print('[CategoryService] ❌ ERREUR récupération catégorie: $e');
      print('[CategoryService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[CategoryService] 🔄 Fallback sur stockage local...');

      // Fallback to local storage
      final categories = await _getCategoriesFromStorage();
      try {
        final category = categories.firstWhere((category) => category.id == id);
        print('[CategoryService] ✅ Catégorie trouvée dans le stockage local');
        print('═══════════════════════════════════════════════════════');
        return category;
      } catch (e) {
        print('[CategoryService] ❌ Catégorie non trouvée');
        print('═══════════════════════════════════════════════════════');
        return null;
      }
    }
  }

  /// Create a new category
  Future<Category> createCategory({
    required String name,
    String? description,
    String? companyId,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CategoryService] ➕ Création d\'une nouvelle catégorie...');
      print('[CategoryService] 📦 Données de la catégorie:');
      print('  - Nom: $name');
      print('  - Description: ${description ?? "(aucune)"}');
      print('  - Company ID: ${companyId ?? "(aucun)"}');

      // Récupérer le warehouse_id sélectionné
      print('[CategoryService] 🔍 Récupération du warehouse_id...');
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      print('[CategoryService] 🏪 Warehouse ID: $warehouseId');

      if (warehouseId == null) {
        print('[CategoryService] ❌ Aucun entrepôt sélectionné');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucun entrepôt sélectionné. Veuillez configurer votre compte.');
      }

      final categoryData = {
        'name': name,
        'description': description,
        'warehouse_id': warehouseId,
        'isActive': true,
      };

      print('[CategoryService] 🌐 URL: ${AppConstants.createCategoryEndpoint}');
      print('[CategoryService] 📄 JSON envoyé: $categoryData');
      print('[CategoryService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        AppConstants.createCategoryEndpoint,
        data: categoryData,
      );

      print('[CategoryService] 📥 Response status: ${response.statusCode}');
      print('[CategoryService] 📥 Response data: ${response.data}');

      if (response.data['success'] == true) {
        final category = Category.fromJson(response.data['data']);
        print('[CategoryService] ✅ Catégorie créée avec succès!');
        print('[CategoryService] 🆔 ID: ${category.id}');
        print('[CategoryService] 📦 Nom: ${category.name}');

        // Save to local storage
        print('[CategoryService] 💾 Sauvegarde locale...');
        await _saveCategoryToStorage(category);
        print('[CategoryService] ✅ Catégorie sauvegardée localement');
        print('═══════════════════════════════════════════════════════');

        return category;
      } else {
        print('[CategoryService] ❌ Réponse API invalide');
        print('[CategoryService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Failed to create category: ${response.data['message']}');
      }
    } catch (e) {
      print('[CategoryService] ❌ ERREUR création catégorie: $e');
      print('[CategoryService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[CategoryService] 🔄 Création d\'une catégorie locale en fallback...');

      // Create local category as fallback
      final category = Category(
        id: _uuid.v4(),
        name: name,
        description: description,
        companyId: companyId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      print('[CategoryService] 🆔 Catégorie locale créée avec ID: ${category.id}');
      print('[CategoryService] 💾 Sauvegarde de la catégorie locale...');
      await _saveCategoryToStorage(category);
      print('[CategoryService] ✅ Catégorie locale sauvegardée');
      print('═══════════════════════════════════════════════════════');

      return category;
    }
  }

  /// Update an existing category
  Future<Category> updateCategory({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CategoryService] 🔄 Mise à jour d\'une catégorie...');
      print('[CategoryService] 🆔 Category ID: $id');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;

      print('[CategoryService] 📄 Données à mettre à jour: $updateData');
      final endpoint = AppConstants.categoryEndpoint(id);
      print('[CategoryService] 🌐 URL: $endpoint');
      print('[CategoryService] 📤 Envoi de la requête PUT...');

      final response = await _apiService.put(
        endpoint,
        data: updateData,
      );

      print('[CategoryService] 📥 Response status: ${response.statusCode}');
      print('[CategoryService] 📥 Response data: ${response.data}');

      if (response.data['success'] == true) {
        final category = Category.fromJson(response.data['data']);
        print('[CategoryService] ✅ Catégorie mise à jour avec succès!');
        print('[CategoryService] 🆔 ID: ${category.id}');
        print('[CategoryService] 📦 Nom: ${category.name}');

        // Update in local storage
        print('[CategoryService] 💾 Mise à jour du stockage local...');
        await _updateCategoryInStorage(category);
        print('[CategoryService] ✅ Catégorie sauvegardée localement');
        print('═══════════════════════════════════════════════════════');

        return category;
      } else {
        print('[CategoryService] ❌ Réponse API invalide');
        print('[CategoryService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Failed to update category: ${response.data['message']}');
      }
    } catch (e) {
      print('[CategoryService] ❌ ERREUR mise à jour catégorie: $e');
      print('[CategoryService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[CategoryService] 🔄 Mise à jour locale en fallback...');

      // Update local category as fallback
      final existingCategory = await getCategory(id);
      if (existingCategory != null) {
        final updatedCategory = existingCategory.copyWith(
          name: name,
          description: description,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        print('[CategoryService] 💾 Mise à jour de la catégorie locale...');
        await _updateCategoryInStorage(updatedCategory);
        print('[CategoryService] ✅ Catégorie locale mise à jour');
        print('═══════════════════════════════════════════════════════');
        return updatedCategory;
      } else {
        print('[CategoryService] ❌ Catégorie introuvable: $id');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Category not found: $id');
      }
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CategoryService] 🗑️ Suppression d\'une catégorie...');
      print('[CategoryService] 🆔 Category ID: $id');

      final endpoint = AppConstants.categoryEndpoint(id);
      print('[CategoryService] 🌐 URL: $endpoint');
      print('[CategoryService] 📤 Envoi de la requête DELETE...');

      final response = await _apiService.delete(endpoint);

      print('[CategoryService] 📥 Response status: ${response.statusCode}');
      print('[CategoryService] 📥 Response data: ${response.data}');

      if (response.data['success'] == true) {
        print('[CategoryService] ✅ Catégorie supprimée avec succès via API');

        // Remove from local storage
        print('[CategoryService] 💾 Suppression du stockage local...');
        await _deleteCategoryFromStorage(id);
        print('[CategoryService] ✅ Catégorie supprimée du stockage local');
        print('═══════════════════════════════════════════════════════');
      } else {
        print('[CategoryService] ❌ Réponse API invalide');
        print('[CategoryService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Failed to delete category: ${response.data['message']}');
      }
    } catch (e) {
      print('[CategoryService] ❌ ERREUR suppression catégorie: $e');
      print('[CategoryService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[CategoryService] 🔄 Suppression locale en fallback...');

      // Remove from local storage as fallback
      await _deleteCategoryFromStorage(id);
      print('[CategoryService] ✅ Catégorie supprimée du stockage local');
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Save categories to local storage
  Future<void> _saveCategoriesToStorage(List<Category> categories) async {
    try {
      final categoriesData = categories.map((category) => category.toJson()).toList();
      await _storageService.writeSetting('categories', categoriesData);
      print('[CategoryService] Saved ${categories.length} categories to storage');
    } catch (e) {
      print('[CategoryService] Error saving categories to storage: $e');
    }
  }

  /// Get categories from local storage
  Future<List<Category>> _getCategoriesFromStorage() async {
    try {
      final categoriesData = await _storageService.readSetting('categories');
      if (categoriesData != null && categoriesData is List) {
        return categoriesData
            .map((json) => Category.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[CategoryService] Error getting categories from storage: $e');
      return [];
    }
  }

  /// Save a single category to local storage
  Future<void> _saveCategoryToStorage(Category category) async {
    try {
      final categories = await _getCategoriesFromStorage();
      categories.add(category);
      await _saveCategoriesToStorage(categories);
    } catch (e) {
      print('[CategoryService] Error saving category to storage: $e');
    }
  }

  /// Update a category in local storage
  Future<void> _updateCategoryInStorage(Category category) async {
    try {
      final categories = await _getCategoriesFromStorage();
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
        await _saveCategoriesToStorage(categories);
      }
    } catch (e) {
      print('[CategoryService] Error updating category in storage: $e');
    }
  }

  /// Delete a category from local storage
  Future<void> _deleteCategoryFromStorage(String id) async {
    try {
      final categories = await _getCategoriesFromStorage();
      categories.removeWhere((category) => category.id == id);
      await _saveCategoriesToStorage(categories);
    } catch (e) {
      print('[CategoryService] Error deleting category from storage: $e');
    }
  }
}

