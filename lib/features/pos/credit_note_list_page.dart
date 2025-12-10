// lib/features/pos/credit_note_list_page.dart
// Liste des avoirs disponibles
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../providers/credit_note_provider.dart';
import '../../widgets/main_layout.dart';

class CreditNoteListPage extends ConsumerWidget {
  const CreditNoteListPage({super.key});

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
    final state = ref.watch(creditNoteProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/credit-notes',
      appBar: AppBar(
        title: const Text('Gestion des Avoirs'),
        actions: [
          IconButton(
            onPressed: () => ref.read(creditNoteProvider.notifier).load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erreur: ${state.error}'))
              : state.creditNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money_off, size: 48, color: theme.colors.mutedForeground),
                          const SizedBox(height: 12),
                          const Text('Aucun avoir disponible'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.creditNotes.length,
                      itemBuilder: (context, index) {
                        final note = state.creditNotes[index];
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
                              'Avoir #${note.id.substring(0, 6)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Montant initial: ${_formatCurrency(note.initialAmount)}'),
                                Text('Solde restant: ${_formatCurrency(note.remaining)}'),
                                if (note.customerId != null) Text('Client ID: ${note.customerId}'),
                                Text('Statut: ${note.status}'),
                                Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt)}'),
                              ],
                            ),
                            trailing: Text(
                              _formatCurrency(note.remaining),
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

