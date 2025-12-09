import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'dart:io';
import '../../../models/product.dart';
import '../../../providers/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onOpenDetails;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLowStock = product.isLowStock();
    final productNotifier = ref.read(productProvider.notifier);

    return Semantics(
      label: 'Produit ${product.name}, prix ${product.formattedPrice}',
      button: true,
      child: GestureDetector(
        onTap: onAdd,
        onLongPress: onOpenDetails,
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Image
                Flexible(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FTheme.of(context).colors.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildProductImage(context, productNotifier),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Product Name
                Flexible(
                  flex: 2,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FTheme.of(context).typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Price and Stock Row
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Flexible(
                        child: Text(
                          product.formattedPrice,
                          style: FTheme.of(context).typography.sm.copyWith(
                            color: FTheme.of(context).colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Stock Badge
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.stock == 0
                                ? FTheme.of(context).colors.destructive
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.stock == 0 ? 'Rupture' : 'Stock bas',
                            style: FTheme.of(context).typography.xs.copyWith(
                              color: FTheme.of(context).colors.background,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, ProductNotifier productNotifier) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // Vérifier si l'image existe localement
    final localPath = productNotifier.getLocalImagePath(product.imageUrl);
    
    if (localPath != null && File(localPath).existsSync()) {
      // Afficher l'image locale
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        ),
      );
    } else if (product.imageUrl!.startsWith('http')) {
      // Télécharger et afficher l'image depuis l'URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Tenter de télécharger l'image en arrière-plan
            Future.microtask(() {
              productNotifier.downloadProductImage(product.id, product.imageUrl!);
            });
            return _buildPlaceholder(context);
          },
        ),
      );
    } else {
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 48,
        color: FTheme.of(context).colors.border,
      ),
    );
  }
}
