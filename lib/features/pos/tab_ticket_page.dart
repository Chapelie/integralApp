// lib/features/pos/tab_ticket_page.dart
// Page pour afficher un aperçu d'un ticket d'addition (tab)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../models/tab.dart';
import '../../core/receipt_service.dart';
import '../../widgets/pdf_preview_page.dart';

class TabTicketPage extends ConsumerStatefulWidget {
  final TabModel tab;

  const TabTicketPage({
    super.key,
    required this.tab,
  });

  @override
  ConsumerState<TabTicketPage> createState() => _TabTicketPageState();
}

class _TabTicketPageState extends ConsumerState<TabTicketPage> {
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _generateAndShowPdf() async {
    try {
      final receiptService = ReceiptService();
      final pdfBytes = await receiptService.generateTabPdfBytes(widget.tab);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: pdfBytes,
            title: 'Addition #${widget.tab.id.substring(0, 6)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Addition #${widget.tab.id.substring(0, 6)}'),
        actions: [
          FButton(
            onPress: _generateAndShowPdf,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text('Imprimer'),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'IntegralPOS',
                        style: theme.typography.base.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(widget.tab.createdAt),
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      if (widget.tab.tableNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Table: ${widget.tab.tableNumber}',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.primary,
                          ),
                        ),
                      ],
                      if (widget.tab.waiterName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Serveur: ${widget.tab.waiterName}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 24,
                  color: theme.colors.border,
                ),
                Text(
                  'Articles:',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.tab.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: theme.typography.xs.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colors.foreground,
                              ),
                            ),
                            Text(
                              '${item.quantity} x ${_formatCurrency(item.price)}',
                              style: theme.typography.xs.copyWith(
                                color: theme.colors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCurrency(item.lineTotal),
                        style: theme.typography.xs.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                Divider(
                  height: 24,
                  color: theme.colors.border,
                ),
                _buildReceiptRow('Sous-total:', _formatCurrency(widget.tab.subtotal), theme, isTotal: false),
                const SizedBox(height: 4),
                _buildReceiptRow('TVA:', _formatCurrency(widget.tab.taxAmount), theme, isTotal: false),
                Divider(
                  height: 16,
                  color: theme.colors.border,
                ),
                _buildReceiptRow('TOTAL:', _formatCurrency(widget.tab.total), theme, isTotal: true),
                const SizedBox(height: 16),
                _buildReceiptRow('Déjà payé:', _formatCurrency(widget.tab.paidAmount), theme, isTotal: false),
                const SizedBox(height: 4),
                _buildReceiptRow('Reste à payer:', _formatCurrency(widget.tab.remaining), theme, isTotal: true),
                Divider(
                  height: 24,
                  color: theme.colors.border,
                ),
                Center(
                  child: Text(
                    'Merci de votre visite !',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      fontStyle: FontStyle.italic,
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

  Widget _buildReceiptRow(String label, String value, FThemeData theme, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.xs.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 12 : 10,
            color: theme.colors.foreground,
          ),
        ),
        Text(
          value,
          style: theme.typography.xs.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 12 : 10,
            color: isTotal ? theme.colors.primary : theme.colors.foreground,
          ),
        ),
      ],
    );
  }
}


