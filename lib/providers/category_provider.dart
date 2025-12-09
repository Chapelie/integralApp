// lib/providers/category_provider.dart
// Riverpod provider for category management
// Handles category state and operations

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../core/category_service.dart';

part 'category_provider.g.dart';

// Category State
class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final Category? selectedCategory;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
    Category? selectedCategory,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// Category Notifier
@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  final _categoryService = CategoryService();

  @override
  CategoryState build() {
    // Don't call _loadCategories here to avoid circular dependency
    // Instead, load categories when the provider is first accessed
    return CategoryState();
  }

  /// Load categories from API
  Future<void> _loadCategories() async {
    print('═══════════════════════════════════════════════════════');
    print('[CategoryProvider] 📂 Chargement des catégories...');

    state = state.copyWith(isLoading: true, error: null);
    print('[CategoryProvider] État: isLoading=true');

    try {
      print('[CategoryProvider] 🌐 Appel CategoryService.getCategories()...');
      final categories = await _categoryService.getCategories();

      print('[CategoryProvider] ✅ ${categories.length} catégories récupérées');
      state = state.copyWith(
        categories: categories,
        isLoading: false,
        error: null,
      );
      print('[CategoryProvider] État mis à jour: ${categories.length} catégories, isLoading=false');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('[CategoryProvider] ❌ ERREUR chargement: $e');
      print('[CategoryProvider] 📋 Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[CategoryProvider] État: isLoading=false, error=${e.toString()}');
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Refresh categories
  Future<void> refreshCategories() async {
    await _loadCategories();
  }

  /// Create a new category
  Future<void> createCategory({
    required String name,
    String? description,
    String? companyId,
  }) async {
    print('═══════════════════════════════════════════════════════');
    print('[CategoryProvider] ➕ Création d\'une catégorie...');
    print('[CategoryProvider] 📦 Paramètres:');
    print('  - Nom: $name');
    print('  - Description: ${description ?? "(aucune)"}');
    print('  - Company ID: ${companyId ?? "(aucun)"}');

    state = state.copyWith(isLoading: true, error: null);
    print('[CategoryProvider] État: isLoading=true');

    try {
      print('[CategoryProvider] 🌐 Appel CategoryService.createCategory()...');
      final category = await _categoryService.createCategory(
        name: name,
        description: description,
        companyId: companyId,
      );

      print('[CategoryProvider] ✅ Catégorie créée avec succès!');
      print('[CategoryProvider] 🆔 ID: ${category.id}');
      print('[CategoryProvider] 📦 Nom: ${category.name}');

      final updatedCategories = [...state.categories, category];
      print('[CategoryProvider] 💾 Mise à jour de l\'état...');
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        error: null,
      );
      print('[CategoryProvider] État mis à jour: ${updatedCategories.length} catégories, isLoading=false');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('[CategoryProvider] ❌ ERREUR création: $e');
      print('[CategoryProvider] 📋 Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[CategoryProvider] État: isLoading=false, error=${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Update an existing category
  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    print('═══════════════════════════════════════════════════════');
    print('[CategoryProvider] 🔄 Mise à jour d\'une catégorie...');
    print('[CategoryProvider] 🆔 Category ID: $id');
    print('[CategoryProvider] 📦 Paramètres à mettre à jour:');
    if (name != null) print('  - Nom: $name');
    if (description != null) print('  - Description: $description');
    if (isActive != null) print('  - Active: $isActive');

    state = state.copyWith(isLoading: true, error: null);
    print('[CategoryProvider] État: isLoading=true');

    try {
      print('[CategoryProvider] 🌐 Appel CategoryService.updateCategory()...');
      final updatedCategory = await _categoryService.updateCategory(
        id: id,
        name: name,
        description: description,
        isActive: isActive,
      );

      print('[CategoryProvider] ✅ Catégorie mise à jour avec succès!');
      print('[CategoryProvider] 🆔 ID: ${updatedCategory.id}');
      print('[CategoryProvider] 📦 Nom: ${updatedCategory.name}');

      final updatedCategories = state.categories.map((category) {
        return category.id == id ? updatedCategory : category;
      }).toList();

      print('[CategoryProvider] 💾 Mise à jour de l\'état...');
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        error: null,
      );
      print('[CategoryProvider] État mis à jour: ${updatedCategories.length} catégories, isLoading=false');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('[CategoryProvider] ❌ ERREUR mise à jour: $e');
      print('[CategoryProvider] 📋 Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[CategoryProvider] État: isLoading=false, error=${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    print('═══════════════════════════════════════════════════════');
    print('[CategoryProvider] 🗑️ Suppression d\'une catégorie...');
    print('[CategoryProvider] 🆔 Category ID: $id');

    state = state.copyWith(isLoading: true, error: null);
    print('[CategoryProvider] État: isLoading=true');

    try {
      print('[CategoryProvider] 🌐 Appel CategoryService.deleteCategory()...');
      await _categoryService.deleteCategory(id);

      print('[CategoryProvider] ✅ Catégorie supprimée avec succès!');

      final updatedCategories = state.categories
          .where((category) => category.id != id)
          .toList();

      print('[CategoryProvider] 💾 Mise à jour de l\'état...');
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        error: null,
      );
      print('[CategoryProvider] État mis à jour: ${updatedCategories.length} catégories, isLoading=false');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('[CategoryProvider] ❌ ERREUR suppression: $e');
      print('[CategoryProvider] 📋 Type d\'erreur: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[CategoryProvider] État: isLoading=false, error=${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Select a category
  void selectCategory(Category? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Get active categories only
  List<Category> get activeCategories {
    return state.categories.where((category) => category.isActive).toList();
  }

  /// Get category by ID
  Category? getCategoryById(String id) {
    try {
      return state.categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
