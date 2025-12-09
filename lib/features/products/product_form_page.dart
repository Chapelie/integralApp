// lib/features/products/product_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/beep_service.dart';
import '../../widgets/main_layout.dart';
import '../../core/image_service.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormPage({
    super.key,
    this.product,
  });

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _taxRateController = TextEditingController();

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock?.toString() ?? '';
      _maxStockController.text = widget.product!.maxStock?.toString() ?? '';
      _barcodeController.text = widget.product!.barcode ?? '';
      _taxRateController.text = widget.product!.taxRate.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _isActive = widget.product!.isActive;
      _imageUrl = widget.product!.imageUrl;
    } else {
      _taxRateController.text = '0.0';
    }

    // Load categories when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).refreshCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _barcodeController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  /// Sélectionner une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// Prendre une photo avec l'appareil photo
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la prise de photo: $e');
    }
  }

  /// Supprimer l'image sélectionnée
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });
  }

  /// Afficher un dialogue d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.primary(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Afficher le dialogue de création de catégorie
  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Nouvelle catégorie'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie *',
                  hintText: 'Ex: Boissons, Électronique',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Description de la catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(dialogContext).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              try {
                // Créer la catégorie
                await ref.read(categoryProvider.notifier).createCategory(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                // Rafraîchir les catégories
                await ref.read(categoryProvider.notifier).refreshCategories();

                // Sélectionner automatiquement la nouvelle catégorie
                final categoryState = ref.read(categoryProvider);
                if (categoryState.categories.isNotEmpty) {
                  final newCategory = categoryState.categories.last;
                  setState(() {
                    _selectedCategoryId = newCategory.id;
                  });
                }

                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "${nameController.text}" créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final categoryState = ref.watch(categoryProvider);

    return MainLayout(
      currentRoute: '/product-form',
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            FButton(
              onPress: _isLoading ? null : _saveProduct,
              child: Text(isEditing ? 'Modifier' : 'Créer'),
            ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de base',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du produit *',
                          hintText: 'Ex: iPhone 15 Pro',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      if (isEditing) ...[
                        TextFormField(
                          initialValue: widget.product?.sku,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'SKU (auto-généré)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnel)',
                          hintText: 'Description du produit',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category and Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catégorie et statut',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown with create button
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Aucune catégorie'),
                                ),
                                ...categoryState.categories.where((category) => category.isActive).map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }),
                              ],
                              onChanged: _isLoading ? null : (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isLoading ? null : _showCreateCategoryDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Créer une catégorie',
                            iconSize: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active status
                      SwitchListTile(
                        title: const Text('Produit actif'),
                        subtitle: const Text('Le produit est visible et peut être vendu'),
                        value: _isActive,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image du produit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Image preview
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FButton(
                            onPress: _isLoading ? null : _pickImageFromGallery,
                            style: FButtonStyle.primary(),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library),
                                SizedBox(width: 8),
                                Text('Galerie'),
                              ],
                            ),
                          ),
                          FButton(
                            onPress: _isLoading ? null : _takePicture,
                            style: FButtonStyle.primary(),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt),
                                SizedBox(width: 8),
                                Text('Appareil'),
                              ],
                            ),
                          ),
                          if (_selectedImage != null || _imageUrl != null)
                            FButton(
                              onPress: _isLoading ? null : _removeImage,
                              style: FButtonStyle.destructive(),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete),
                                  SizedBox(width: 8),
                                  Text('Supprimer'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pricing Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix et taxes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Prix de vente *',
                          hintText: '0.0',
                          border: OutlineInputBorder(),
                          prefixText: 'FCFA ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prix est obligatoire';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _taxRateController,
                        decoration: const InputDecoration(
                          labelText: 'Taux de taxe (%)',
                          hintText: '0.0',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inventory Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventaire',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock actuel *',
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le stock est obligatoire';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Stock invalide';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock minimum',
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _maxStockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock maximum',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Additional Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations supplémentaires',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code-barres',
                          hintText: 'Ex: 1234567890123',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              FButton(
                onPress: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Enregistrement...'),
                        ],
                      )
                    : Text(isEditing ? 'Modifier le produit' : 'Créer le produit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final sku = widget.product != null ? widget.product!.sku : null;
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      final minStock = _minStockController.text.trim().isEmpty
          ? null
          : int.parse(_minStockController.text);
      final maxStock = _maxStockController.text.trim().isEmpty
          ? null
          : int.parse(_maxStockController.text);
      final barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();
      final taxRate = double.parse(_taxRateController.text);

      print('═══════════════════════════════════════════════════════');
      print('[ProductFormPage] 📝 Données du produit à créer:');
      print('  - Nom: $name');
      print('  - SKU: ${sku ?? "(auto)"}');
      print('  - Prix: $price');
      print('  - Stock: $stock');
      print('  - Catégorie ID: $_selectedCategoryId');
      print('  - Actif: $_isActive');
      print('═══════════════════════════════════════════════════════');

      // Gérer l'image
      String? imageUrl = _imageUrl;
      if (_selectedImage != null) {
        final imageService = ImageService();
        final imageBytes = await _selectedImage!.readAsBytes();
        final productId = widget.product?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await imageService.saveImageFromBytes(imageBytes, productId);
      }

      if (widget.product != null) {
        // Update existing product
        await ref.read(productProvider.notifier).updateProduct(
          id: widget.product!.id,
          name: name,
          sku: sku,
          description: description,
          price: price,
          stock: stock,
          minStock: minStock,
          maxStock: maxStock,
          barcode: barcode,
          taxRate: taxRate,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
          imageUrl: imageUrl,
        );
      } else {
        // Create new product (SKU auto-généré côté provider)
        await ref.read(productProvider.notifier).createProduct(
          name: name,
          sku: null,
          description: description,
          price: price,
          stock: stock,
          minStock: minStock,
          maxStock: maxStock,
          barcode: barcode,
          taxRate: taxRate,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
          imageUrl: imageUrl,
        );
      }

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'Produit modifié avec succès'
                  : 'Produit créé avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Play error beep
      BeepService().playError();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}