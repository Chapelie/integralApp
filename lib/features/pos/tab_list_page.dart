// lib/features/pos/tab_list_page.dart
// Liste des additions en attente de paiement
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../providers/tab_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../models/tab.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import 'tab_ticket_page.dart';
import 'payment_page.dart';

class TabListPage extends ConsumerStatefulWidget {
  const TabListPage({super.key});

  @override
  ConsumerState<TabListPage> createState() => _TabListPageState();
}

class _TabListPageState extends ConsumerState<TabListPage> {
  String _searchQuery = '';

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  List<TabModel> _filterTabs(List<TabModel> tabs, String query) {
    if (query.isEmpty) return tabs;
    final lowerQuery = query.toLowerCase();
    return tabs.where((tab) {
      return tab.id.toLowerCase().contains(lowerQuery) ||
          (tab.tableNumber != null && tab.tableNumber!.toLowerCase().contains(lowerQuery)) ||
          (tab.waiterName != null && tab.waiterName!.toLowerCase().contains(lowerQuery)) ||
          _formatCurrency(tab.total).toLowerCase().contains(lowerQuery) ||
          _formatCurrency(tab.remaining).toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tabProvider);
    final theme = FTheme.of(context);
    final filteredTabs = _filterTabs(state.tabs, _searchQuery);

    return MainLayout(
      currentRoute: '/tabs',
      appBar: UnifiedHeader(
        title: 'Additions',
        showSearch: true,
        searchHint: 'Rechercher par ID, table, serveur, montant...',
        onSearch: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onRefresh: () => ref.read(tabProvider.notifier).load(forceRefresh: true),
      ),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erreur: ${state.error}'))
              : filteredTabs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(_searchQuery.isNotEmpty
                              ? 'Aucune addition trouvée pour "$_searchQuery"'
                              : 'Aucune addition en attente'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTabs.length,
                      itemBuilder: (context, index) {
                        final tab = filteredTabs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colors.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.receipt_long,
                                color: theme.colors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Addition #${tab.id.substring(0, 6)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total: ${_formatCurrency(tab.total)}'),
                                Text('Déjà payé: ${_formatCurrency(tab.paidAmount)}'),
                                Text('Reste à payer: ${_formatCurrency(tab.remaining)}'),
                                if (tab.tableNumber != null) Text('Table: ${tab.tableNumber}'),
                                if (tab.waiterName != null) Text('Serveur: ${tab.waiterName}'),
                                Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(tab.createdAt)}'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCurrency(tab.remaining),
                                  style: theme.typography.base.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, size: 18),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TabTicketPage(tab: tab),
                                          ),
                                        );
                                      },
                                      tooltip: 'Voir le ticket',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.payment, size: 18),
                                      onPressed: () => _handlePayTab(context, ref, tab),
                                      tooltip: 'Payer',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _handlePayTab(context, ref, tab),
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _handlePayTab(BuildContext context, WidgetRef ref, TabModel tab) async {
    final cartState = ref.read(cartProvider);
    // Load tab items into cart
    ref.read(cartProvider.notifier).clearCart();
    for (final item in tab.items) {
      final product = Product(
        id: item.productId,
        name: item.productName,
        sku: '',
        price: item.price,
        stock: 9999,
        taxRate: item.taxRate,
      );
      // Add item multiple times to get the correct quantity
      for (int i = 0; i < item.quantity; i++) {
        ref.read(cartProvider.notifier).addItem(product);
      }
    }
    // Navigate to payment with remaining total
    await Navigator.of(context).pushNamed(
      '/payment',
      arguments: tab.remaining,
    );
    // Refresh tabs after potential settlement
    ref.read(tabProvider.notifier).load(forceRefresh: true);
  }
}

