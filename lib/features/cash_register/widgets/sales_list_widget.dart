// lib/features/cash_register/widgets/sales_list_widget.dart
// Widget pour afficher la liste des ventes d'une caisse

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/sales_service.dart';
import '../../../models/sale.dart';
import '../../../core/responsive_helper.dart';
import '../../../core/utils/currency_formatter.dart';

class SalesListWidget extends ConsumerStatefulWidget {
  final String? cashRegisterId;
  final DateTime? openedAt;
  final DateTime? closedAt;

  const SalesListWidget({
    super.key,
    this.cashRegisterId,
    this.openedAt,
    this.closedAt,
  });

  @override
  ConsumerState<SalesListWidget> createState() => _SalesListWidgetState();
}

class _SalesListWidgetState extends ConsumerState<SalesListWidget> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salesService = SalesService();
      final allSales = salesService.getSales();

      // Filtrer les ventes par période et caisse
      List<Sale> filteredSales = allSales;

      if (widget.cashRegisterId != null) {
        filteredSales = filteredSales.where((sale) {
          return sale.cashRegisterId == widget.cashRegisterId;
        }).toList();
      }

      if (widget.openedAt != null) {
        filteredSales = filteredSales.where((sale) {
          return sale.createdAt.isAfter(widget.openedAt!) ||
              sale.createdAt.isAtSameMomentAs(widget.openedAt!);
        }).toList();
      }

      if (widget.closedAt != null) {
        filteredSales = filteredSales.where((sale) {
          return sale.createdAt.isBefore(widget.closedAt!) ||
              sale.createdAt.isAtSameMomentAs(widget.closedAt!);
        }).toList();
      }

      // Trier par date (plus récent en premier)
      filteredSales.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _sales = filteredSales;
        _isLoading = false;
      });
    } catch (e) {
      print('[SalesListWidget] Error loading sales: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(
            color: theme.colors.primary,
          ),
        ),
      );
    }

    if (_sales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune vente enregistrée',
                style: theme.typography.base.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Ventes (${_sales.length})',
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sales.length > 10 ? 10 : _sales.length,
          itemBuilder: (context, index) {
            final sale = _sales[index];
            return _buildSaleItem(context, sale, theme);
          },
        ),
        if (_sales.length > 10)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                '... et ${_sales.length - 10} autres ventes',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaleItem(BuildContext context, Sale sale, FThemeData theme) {
    final dateFormat = DateFormat('HH:mm');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt,
                size: 20,
                color: theme.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vente #${sale.id.substring(0, 8)}',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(sale.createdAt),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sale.items.length} article(s)',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(sale.total),
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}










