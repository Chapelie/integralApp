// lib/features/products/categories_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/main_layout.dart';
import 'category_form_page.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    // Refresh categories when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).refreshCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/products',
      child: Column(
        children: [
          // Header avec actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                bottom: BorderSide(
                  color: theme.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Catégories',
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FButton(
                  onPress: () => _navigateToCategoryForm(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Ajouter'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: _buildContent(categoryState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CategoryState state) {
    final theme = FTheme.of(context);

    if (state.isLoading && state.categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.categories.isEmpty) {
      return Center(
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
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () => ref.read(categoryProvider.notifier).refreshCategories(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune catégorie',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter une catégorie',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () => _navigateToCategoryForm(context),
              child: const Text('Ajouter une catégorie'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(categoryProvider.notifier).refreshCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final category = state.categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.isActive 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            Icons.category,
            color: category.isActive 
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: category.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                style: TextStyle(
                  color: category.isActive ? null : Colors.grey,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!category.isActive)
              FBadge(
                child: const Text('Inactive'),
                style: FBadgeStyle.secondary(),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, category),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: category.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        category.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(category.isActive ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _navigateToCategoryForm(context, category),
      ),
    );
  }

  void _handleMenuAction(String action, Category category) {
    switch (action) {
      case 'edit':
        _navigateToCategoryForm(context, category);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteDialog(category);
        break;
    }
  }

  void _navigateToCategoryForm(BuildContext context, [Category? category]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormPage(category: category),
      ),
    );
  }

  void _toggleCategoryStatus(Category category) {
    ref.read(categoryProvider.notifier).updateCategory(
      id: category.id,
      isActive: !category.isActive,
    );
  }

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}" ?',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              ref.read(categoryProvider.notifier).deleteCategory(category.id);
            },
            style: FButtonStyle.destructive(),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
