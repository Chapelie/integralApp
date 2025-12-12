// lib/features/employees/employees_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee.dart';
import 'employee_form_page.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).loadEmployees();
    });
  }

  void _navigateToEmployeeForm(BuildContext context, {Employee? employee}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeFormPage(employee: employee),
      ),
    );
  }

  void _handleMenuAction(String value, Employee employee) async {
    switch (value) {
      case 'edit':
        _navigateToEmployeeForm(context, employee: employee);
        break;
      case 'toggle_active':
        await ref.read(employeeProvider.notifier).updateEmployee(
          employee.copyWith(isActive: !employee.isActive),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Voulez-vous vraiment supprimer l\'employé "${employee.name}" ?'),
            actions: [
              FButton(
                onPress: () => Navigator.of(context).pop(false),
                style: FButtonStyle.outline(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () => Navigator.of(context).pop(true),
                style: FButtonStyle.destructive(),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(employeeProvider.notifier).deleteEmployee(employee.id);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);

    return MainLayout(
      currentRoute: '/employees',
      appBar: UnifiedHeader(
        title: 'Gestion des Employés',
        actions: [
          FButton(
            onPress: () => _navigateToEmployeeForm(context),
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
      child: _buildContent(employeeState),
    );
  }

  Widget _buildContent(EmployeeState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('Erreur: ${state.error}'));
    }
    if (state.employees.isEmpty) {
      return const Center(child: Text('Aucun employé trouvé.'));
    }

    return ListView.builder(
      itemCount: state.employees.length,
      itemBuilder: (context, index) {
        final employee = state.employees[index];
        final theme = FTheme.of(context);

        return FCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colors.primary.withOpacity(0.1),
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
                style: TextStyle(
                  color: theme.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(employee.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.email),
                if (employee.phone != null) Text(employee.phone!),
                if (employee.role != null) 
                  Text(
                    'Rôle: ${employee.role}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!employee.isActive)
                  FBadge(
                    child: const Text('Inactif'),
                    style: FBadgeStyle.secondary(),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, employee),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(employee.isActive ? 'Désactiver' : 'Activer'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}








