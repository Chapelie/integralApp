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
import '../../widgets/main_layout.dart';
import 'tab_ticket_page.dart';
import 'payment_page.dart';

class TabListPage extends ConsumerWidget {
  const TabListPage({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tabProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/tabs',
      appBar: AppBar(
        title: const Text('Additions'),
        actions: [
          IconButton(
            onPressed: () => ref.read(tabProvider.notifier).load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erreur: ${state.error}'))
              : state.tabs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: theme.colors.mutedForeground),
                          const SizedBox(height: 12),
                          const Text('Aucune addition en attente'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.tabs.length,
                      itemBuilder: (context, index) {
                        final tab = state.tabs[index];
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

  Future<void> _handlePayTab(BuildContext context, WidgetRef ref, tab) async {
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

