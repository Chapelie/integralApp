import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../models/product.dart';
import '../../../core/responsive_helper.dart';
import 'product_card.dart';

class ProductsGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductAdd;
  final Function(Product)? onProductDetails;

  const ProductsGrid({
    super.key,
    required this.products,
    required this.onProductAdd,
    this.onProductDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmptyState(context);
    }

    final gridColumns = Responsive.gridColumns(context);
    final spacing = Responsive.spacing(context);
    final padding = Responsive.pagePadding(context);

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 0.65, // Adjusted for larger cards with more content
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onAdd: () => onProductAdd(product),
          onOpenDetails: onProductDetails != null
              ? () => onProductDetails!(product)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: FTheme.of(context).colors.border,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit',
              style: FTheme.of(context).typography.lg.copyWith(
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des produits pour commencer',
              style: FTheme.of(context).typography.sm.copyWith(
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
