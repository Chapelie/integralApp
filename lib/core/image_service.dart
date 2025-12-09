// lib/core/image_service.dart
// Service pour la gestion des images des produits

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  /// Répertoire de stockage des images
  Directory? _imagesDirectory;

  /// Initialise le service d'images
  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _imagesDirectory = Directory(path.join(appDir.path, 'product_images'));
      
      if (!await _imagesDirectory!.exists()) {
        await _imagesDirectory!.create(recursive: true);
      }
      
      print('[ImageService] Initialized with directory: ${_imagesDirectory!.path}');
    } catch (e) {
      print('[ImageService] Error initializing: $e');
    }
  }

  /// Sauvegarde une image locale
  Future<String?> saveImageFromBytes(Uint8List imageBytes, String productId) async {
    try {
      if (_imagesDirectory == null) await init();
      
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(_imagesDirectory!.path, fileName);
      final file = File(filePath);
      
      await file.writeAsBytes(imageBytes);
      
      print('[ImageService] Image saved: $filePath');
      return filePath;
    } catch (e) {
      print('[ImageService] Error saving image: $e');
      return null;
    }
  }

  /// Télécharge et sauvegarde une image depuis une URL
  Future<String?> downloadAndSaveImage(String imageUrl, String productId) async {
    try {
      if (_imagesDirectory == null) await init();
      
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(_imagesDirectory!.path, fileName);
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        
        print('[ImageService] Image downloaded and saved: $filePath');
        return filePath;
      } else {
        print('[ImageService] Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ImageService] Error downloading image: $e');
      return null;
    }
  }

  /// Récupère le chemin d'une image locale
  String? getLocalImagePath(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    // Si c'est déjà un chemin local
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      return imageUrl.replaceFirst('file://', '');
    }
    
    // Si c'est une URL, chercher le fichier local correspondant
    if (imageUrl.startsWith('http')) {
      final fileName = path.basename(imageUrl);
      final localPath = path.join(_imagesDirectory?.path ?? '', fileName);
      if (File(localPath).existsSync()) {
        return localPath;
      }
    }
    
    return null;
  }

  /// Vérifie si une image existe localement
  bool imageExists(String? imageUrl) {
    final localPath = getLocalImagePath(imageUrl);
    return localPath != null && File(localPath).existsSync();
  }

  /// Supprime une image locale
  Future<bool> deleteImage(String? imageUrl) async {
    try {
      final localPath = getLocalImagePath(imageUrl);
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          print('[ImageService] Image deleted: $localPath');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('[ImageService] Error deleting image: $e');
      return false;
    }
  }

  /// Nettoie les images orphelines (non utilisées par les produits)
  Future<void> cleanupOrphanedImages(List<String> usedImageUrls) async {
    try {
      if (_imagesDirectory == null) return;
      
      final files = _imagesDirectory!.listSync();
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          final isUsed = usedImageUrls.any((url) => 
            path.basename(url) == fileName || 
            file.path == url.replaceFirst('file://', '')
          );
          
          if (!isUsed) {
            await file.delete();
            print('[ImageService] Cleaned up orphaned image: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('[ImageService] Error cleaning up images: $e');
    }
  }

  /// Obtient la taille du dossier d'images
  Future<int> getImagesDirectorySize() async {
    try {
      if (_imagesDirectory == null) return 0;
      
      int totalSize = 0;
      final files = _imagesDirectory!.listSync(recursive: true);
      
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('[ImageService] Error calculating directory size: $e');
      return 0;
    }
  }
}



