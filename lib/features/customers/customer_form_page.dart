// lib/features/customers/customer_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../core/beep_service.dart';
import '../../widgets/main_layout.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerFormPage({super.key, this.customer});

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Email invalide';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Téléphone invalide';
      }
    }
    return null;
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      BeepService().playError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: widget.customer?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.customer == null) {
        await ref.read(customerProvider.notifier).addCustomer(customer);
      } else {
        await ref.read(customerProvider.notifier).updateCustomer(customer);
      }

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer == null
                  ? 'Client ajouté avec succès'
                  : 'Client mis à jour avec succès',
            ),
            backgroundColor: theme.colors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Play error beep
      BeepService().playError();

      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: theme.colors.destructive,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/customers',
      child: Semantics(
        label: isEdit ? 'Page modification client' : 'Page ajout client',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(FIcons.user),
                            SizedBox(width: 8),
                            Text(
                              'Informations du client',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom *',
                            hintText: 'Entrez le nom complet',
                            prefixIcon: Icon(FIcons.user),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateName,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'exemple@email.com',
                            prefixIcon: Icon(FIcons.mail),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            hintText: '+225 XX XX XX XX XX',
                            prefixIcon: Icon(FIcons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            hintText: 'Adresse complète',
                            prefixIcon: Icon(FIcons.mapPin),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FButton(
                    onPress: _isLoading ? null : _saveCustomer,
                    style: FButtonStyle.primary(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Mettre à jour' : 'Enregistrer',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}