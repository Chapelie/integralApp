// lib/features/customers/customer_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/main_layout.dart';
import 'customer_form_page.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Customers are loaded automatically by the provider
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/customers',
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Clients',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FButton(
                  onPress: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerFormPage(),
                      ),
                    );
                  },
                  style: FButtonStyle.primary(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FIcons.plus, size: 20),
                      SizedBox(width: 8),
                      Text('Ajouter'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FTextField(
              hint: 'Rechercher un client...',
              onChange: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Body
          Expanded(
            child: _buildBody(customerState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CustomerState customerState, FThemeData theme) {
    if (customerState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (customerState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colors.destructive),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${customerState.error}',
              style: theme.typography.lg.copyWith(
                color: theme.colors.destructive,
              ),
            ),
          ],
        ),
      );
    }

    final filteredCustomers = customerState.customers.where((customer) {
      if (_searchQuery.isEmpty) return true;
      return customer.name.toLowerCase().contains(_searchQuery) ||
          (customer.email?.toLowerCase().contains(_searchQuery) ?? false) ||
          (customer.phone?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FIcons.users,
              size: 64,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun client enregistré'
                  : 'Aucun client trouvé',
              style: theme.typography.lg.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Appuyez sur + pour ajouter un client'
                  : 'Essayez une autre recherche',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FCard.raw(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colors.primary,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: theme.colors.primaryForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                customer.name,
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customer.email != null && customer.email!.isNotEmpty)
                    Row(
                      children: [
                        Icon(FIcons.mail, size: 16, color: theme.colors.mutedForeground),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.email!,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(FIcons.phone, size: 16, color: theme.colors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(FIcons.moveHorizontal, color: theme.colors.foreground),
                onSelected: (value) async {
                  if (value == 'edit') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerFormPage(customer: customer),
                      ),
                    );
                    // Customers are automatically refreshed by the provider
                  } else if (value == 'delete') {
                    _showDeleteDialog(customer.id, theme);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(FIcons.trash2, color: theme.colors.destructive),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: theme.colors.destructive),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerFormPage(customer: customer),
                  ),
                );
                // Customers are automatically refreshed by the provider
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String customerId, FThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le client',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce client ?',
          style: theme.typography.base,
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.outline(),
            child: Text(
              'Annuler',
              style: theme.typography.base,
            ),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () async {
              Navigator.pop(context);
              await ref.read(customerProvider.notifier).deleteCustomer(customerId);
            },
            style: FButtonStyle.destructive(),
            child: Text(
              'Supprimer',
              style: theme.typography.base.copyWith(
                color: theme.colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
