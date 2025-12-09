// lib/features/pos/widgets/customer_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/customer.dart';

class CustomerSelectionWidget extends ConsumerStatefulWidget {
  const CustomerSelectionWidget({super.key});

  @override
  ConsumerState<CustomerSelectionWidget> createState() => _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends ConsumerState<CustomerSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.1),
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                'Client',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FButton(
                onPress: () => _showCustomerSelection(context),
                child: Text(
                  cartState.selectedCustomer != null ? 'Changer' : 'Sélectionner',
                ),
              ),
            ],
          ),
          if (cartState.selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartState.selectedCustomer!.name,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.primary,
                          ),
                        ),
                        if (cartState.selectedCustomer!.email != null)
                          Text(
                            cartState.selectedCustomer!.email!,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(cartProvider.notifier).setCustomer(null),
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCustomerSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CustomerSelectionModal(),
    );
  }
}
class CustomerSelectionModal extends ConsumerStatefulWidget {
  const CustomerSelectionModal({super.key});

  @override
  ConsumerState<CustomerSelectionModal> createState() => _CustomerSelectionModalState();
}

class _CustomerSelectionModalState extends ConsumerState<CustomerSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final theme = FTheme.of(context);

    // Filter customers based on search query
    final filteredCustomers = customerState.customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery) ||
          (customer.email?.toLowerCase().contains(_searchQuery) ?? false) ||
          (customer.phone?.contains(_searchQuery) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                'Sélectionner un client',
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher un client...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Customer list
          Expanded(
            child: customerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerState.error != null
                    ? Center(child: Text('Erreur: ${customerState.error}'))
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Aucun client trouvé'
                                      : 'Aucun client ne correspond à votre recherche',
                                  style: theme.typography.base.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return _buildCustomerItem(customer, theme);
                            },
                          ),
          ),

          // Add new customer button
          const SizedBox(height: 16),
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              // TODO: Navigate to add customer page
            },
            style: FButtonStyle.outline(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 8),
                Text('Ajouter un nouveau client'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(Customer customer, FThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
            style: TextStyle(
              color: theme.colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(customer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.email != null) Text(customer.email!),
            if (customer.phone != null) Text(customer.phone!),
          ],
        ),
        onTap: () {
          ref.read(cartProvider.notifier).setCustomer(customer);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}


