import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/product_image.dart';

class ProductImageGallery extends StatefulWidget {
  final List<ProductImage> images;
  final bool editable;
  final ValueChanged<File>? onAddImage;
  final ValueChanged<ProductImage>? onDeleteImage;

  const ProductImageGallery({
    super.key,
    required this.images,
    this.editable = false,
    this.onAddImage,
    this.onDeleteImage,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _onPickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && widget.onAddImage != null) {
      widget.onAddImage!(File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.editable ? images.length + 1 : images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          if (widget.editable && idx == images.length) {
            // Add image button
            return GestureDetector(
              onTap: _onPickImage,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: const Center(child: Icon(Icons.add_a_photo, size: 36, color: Colors.blue)),
              ),
            );
          }
          final img = images[idx];
          Widget content;
          if (img.localPath != null && File(img.localPath!).existsSync()) {
            content = Image.file(File(img.localPath!), fit: BoxFit.cover, width: 96, height: 96);
          } else if (img.serverUrl != null) {
            content = Image.network(img.serverUrl!, fit: BoxFit.cover, width: 96, height: 96, errorBuilder: (_, __, ___) => Placeholder());
          } else {
            content = const Placeholder();
          }

          // Badge couleur pour syncStatus
          Color borderColor;
          switch (img.syncStatus) {
            case ImageSyncStatus.pending:
              borderColor = Colors.orange;
              break;
            case ImageSyncStatus.syncing:
              borderColor = Colors.blue;
              break;
            case ImageSyncStatus.failed:
              borderColor = Colors.red;
              break;
            case ImageSyncStatus.synced:
            default:
              borderColor = Colors.green;
          }

          return Stack(
            children: [
              Container(
                width: 96, height: 96,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: content,
              ),
              if (widget.editable) Positioned(
                top: 2, right: 2,
                child: GestureDetector(
                  onTap: () { if(widget.onDeleteImage != null) widget.onDeleteImage!(img); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ),
              ),
              if (img.syncStatus != ImageSyncStatus.synced)
                Positioned(
                  bottom: 2, left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      img.syncStatus.name,
                      style: const TextStyle(fontSize: 9, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
