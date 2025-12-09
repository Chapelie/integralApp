// lib/features/employees/employee_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/main_layout.dart';

class EmployeeFormPage extends ConsumerStatefulWidget {
  final Employee? employee; // Optional: for editing existing employee
  const EmployeeFormPage({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends ConsumerState<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  bool _isActive = true;
  String? _errorMessage;
  String? _selectedRole;

  final List<String> _availableRoles = [
    'admin',
    'manager',
    'cashier',
    'employee',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _selectedRole = widget.employee?.role;
    _isActive = widget.employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employee = Employee(
        id: widget.employee?.id ?? '', // Use existing ID or placeholder for new
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
      );

      if (widget.employee == null) {
        // Create new employee
        await ref.read(employeeProvider.notifier).addEmployee(employee);
      } else {
        // Update existing employee
        await ref.read(employeeProvider.notifier).updateEmployee(employee);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Go back to employees list
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'enregistrement de l\'employé: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return MainLayout(
      currentRoute: '/employees',
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'employé' : 'Nouvel employé'),
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
              onPress: _isLoading ? null : _saveEmployee,
              child: Text(isEditing ? 'Modifier' : 'Créer'),
            ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cashier', child: Text('Caissier')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Employé actif'),
                subtitle: const Text('L\'employé peut se connecter au système'),
                value: _isActive,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
