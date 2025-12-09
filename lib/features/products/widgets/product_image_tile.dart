import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/product_service.dart';
import '../../../models/product_image.dart';

class ProductImageTile extends StatelessWidget {
  final String productId;
  final double size;

  const ProductImageTile({super.key, required this.productId, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductImage?>(
      future: ProductService().getPrimaryImage(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder();
        }
        final img = snapshot.data;
        if (img == null) return _placeholder();
        if (img.localPath != null && File(img.localPath!).existsSync()) {
          return _wrap(Image.file(
            File(img.localPath!), width: size, height: size, fit: BoxFit.cover,
          ));
        }
        if (img.serverUrl != null) {
          return _wrap(Image.network(
            img.serverUrl!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ));
        }
        return _placeholder();
      },
    );
  }

  Widget _wrap(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: child,
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
