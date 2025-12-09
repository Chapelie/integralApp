// lib/models/product_image.dart
import 'dart:io';

// Statut de synchronisation de l'image
enum ImageSyncStatus { pending, syncing, failed, synced }

class ProductImage {
  final String id; // UUID local ou backend
  final String? localPath; // File local temporaire si offline
  final String? serverUrl; // URL HTTP (après upload)
  final String productId; // ID backend du produit
  final ImageSyncStatus syncStatus;

  ProductImage({
    required this.id,
    this.localPath,
    this.serverUrl,
    required this.productId,
    required this.syncStatus,
  });

  // Conversion JSON
  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      localPath: json['localPath'] as String?,
      serverUrl: json['serverUrl'] as String?,
      productId: json['productId'] as String,
      syncStatus: ImageSyncStatus.values.firstWhere(
        (e) => e.toString() == json['syncStatus'],
        orElse: () => ImageSyncStatus.synced,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'serverUrl': serverUrl,
      'productId': productId,
      'syncStatus': syncStatus.toString(),
    };
  }

  ProductImage copyWith({
    String? id,
    String? localPath,
    String? serverUrl,
    String? productId,
    ImageSyncStatus? syncStatus,
  }) {
    return ProductImage(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      serverUrl: serverUrl ?? this.serverUrl,
      productId: productId ?? this.productId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
