// lib/features/sales/receipts_page.dart
// Page pour voir, modifier et régénérer les reçus

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../providers/sales_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../core/receipt_service.dart';
import '../../core/sales_service.dart';
import '../../core/refund_service.dart';
import '../../core/cash_register_service.dart';
import '../../core/pin_service.dart';
import '../../core/table_service.dart';
import '../../models/sale.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../core/responsive_helper.dart';
import '../pos/pos_page.dart';

class ReceiptsPage extends ConsumerStatefulWidget {
  const ReceiptsPage({super.key});

  @override
  ConsumerState<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends ConsumerState<ReceiptsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).loadSales();
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  List<Sale> _filterSales(List<Sale> sales) {
    // Créer une copie modifiable de la liste
    var filtered = List<Sale>.from(sales);

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sale) {
        final query = _searchQuery.toLowerCase();
        return sale.id.toLowerCase().contains(query) ||
            (sale.customerId?.toLowerCase().contains(query) ?? false) ||
            sale.items.any((item) => item.productName.toLowerCase().contains(query));
      }).toList();
    }

    // Filtrer par date
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((sale) {
        if (_startDate != null && sale.createdAt.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && sale.createdAt.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Trier par date (plus récent en premier)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final salesState = ref.watch(salesProvider);
    final isDesktop = Responsive.isDesktop(context);

    return MainLayout(
      currentRoute: '/receipts',
      appBar: UnifiedHeader(
        title: 'Reçus',
        showSearch: true,
        searchHint: 'ID vente, client, produit...',
        onSearch: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onFilter: () {
          _selectDateRange(context);
        },
      ),
      child: Column(
        children: [
          // Filtres de date (si nécessaire) - affichés sous forme de chips
          if (_startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_startDate != null)
                    Chip(
                      label: Text('Du: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    ),
                  if (_endDate != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Au: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                      onDeleted: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Liste des ventes
          Expanded(
            child: salesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : salesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: theme.colors.destructive),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: ${salesState.error}',
                              style: theme.typography.base,
                            ),
                            const SizedBox(height: 16),
                            FButton(
                              onPress: _loadSales,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _buildSalesList(salesState.sales, theme, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList(List<Sale> sales, FThemeData theme, bool isDesktop) {
    final filteredSales = _filterSales(sales);

    if (filteredSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.colors.mutedForeground),
            const SizedBox(height: 16),
            Text(
              'Aucun reçu trouvé',
              style: theme.typography.lg,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _startDate != null || _endDate != null
                  ? 'Aucun reçu ne correspond à vos critères'
                  : 'Les reçus apparaîtront ici après les ventes',
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
      itemCount: filteredSales.length,
      itemBuilder: (context, index) {
        final sale = filteredSales[index];
        return _buildSaleCard(sale, theme, isDesktop);
      },
    );
  }

  Widget _buildSaleCard(Sale sale, FThemeData theme, bool isDesktop) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vente #${sale.id.substring(0, 8)}',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(sale.total),
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sale.paymentStatus == 'completed'
                            ? theme.colors.primary.withValues(alpha: 0.1)
                            : theme.colors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sale.paymentMethod.toUpperCase(),
                        style: theme.typography.xs.copyWith(
                          color: sale.paymentStatus == 'completed'
                              ? theme.colors.primary
                              : theme.colors.destructive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (sale.tableNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.table_restaurant, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    'Table ${sale.tableNumber}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${sale.items.length} article(s)',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () => _viewReceipt(sale),
                    style: FButtonStyle.outline(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.preview, size: 16),
                        SizedBox(width: 4),
                        Text('Voir'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FButton(
                    onPress: () => _modifySale(sale),
                    style: FButtonStyle.outline(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 4),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () => _regenerateReceipt(sale),
                    style: FButtonStyle.outline(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 16),
                        SizedBox(width: 4),
                        Text('Reçu'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FButton(
                    onPress: () => _refundSale(sale),
                    style: FButtonStyle.primary(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.undo, size: 16),
                        SizedBox(width: 4),
                        Text('Rembourser'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewReceipt(Sale sale) async {
    try {
      final receiptService = ReceiptService();
      final pdfBytes = await receiptService.generatePdfBytes(sale);
      
      if (!mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: pdfBytes,
            title: 'Reçu #${sale.id.substring(0, 8)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _modifySale(Sale sale) async {
    try {
      if (!mounted) return;
      
      // Charger les produits dans le panier depuis la vente
      final productState = ref.read(productProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final customerState = ref.read(customerProvider);
      
      // Vider le panier
      cartNotifier.clearCart();
      
      // Ajouter les produits de la vente au panier
      for (final saleItem in sale.items) {
        try {
          final product = productState.products.firstWhere(
            (p) => p.id == saleItem.productId,
            orElse: () => Product(
              id: saleItem.productId,
              name: saleItem.productName,
              price: saleItem.price,
              stock: 0,
              sku: saleItem.productId.substring(0, 8),
              taxRate: saleItem.taxRate,
              categoryId: null,
              description: null,
              imageUrl: null,
              minStock: 0,
              maxStock: null,
              barcode: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          // Ajouter le produit avec la quantité de la vente
          for (int i = 0; i < saleItem.quantity; i++) {
            cartNotifier.addItem(product);
          }
        } catch (e) {
          print('[ReceiptsPage] Error adding item to cart: $e');
          // Continue avec les autres items
        }
      }
      
      // Restaurer les informations de la vente
      if (sale.customerId != null) {
        try {
          Customer? customer;
          try {
            customer = customerState.customers.firstWhere(
              (c) => c.id == sale.customerId,
            );
          } catch (e) {
            customer = null;
          }
          if (customer != null) {
            cartNotifier.setCustomer(customer);
          }
        } catch (e) {
          print('[ReceiptsPage] Error setting customer: $e');
        }
      }
      
      if (sale.tableId != null && sale.tableNumber != null) {
        cartNotifier.setTable(sale.tableId, sale.tableNumber);
      }
      
      if (sale.serviceType != null) {
        cartNotifier.setServiceType(sale.serviceType);
      }
      
      if (sale.notes != null && sale.notes!.isNotEmpty) {
        cartNotifier.setNotes(sale.notes);
      }
      
      if (!mounted) return;
      
      // Naviguer vers le POS pour modifier
      await Navigator.of(context).pushReplacementNamed('/pos');
      
      // Afficher un message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande chargée (${sale.items.length} article(s)). Modifiez-la puis validez pour créer un nouveau reçu.'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ReceiptsPage] Error modifying sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la commande: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _regenerateReceipt(Sale sale) async {
    try {
      final receiptService = ReceiptService();
      final pdfBytes = await receiptService.generatePdfBytes(sale);
      
      if (!mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: pdfBytes,
            title: 'Reçu #${sale.id.substring(0, 8)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refundSale(Sale sale) async {
    try {
      // 1. Demander le PIN pour sécurité
      final pinService = PinService();
      final pin = await _requestPinDialog();
      if (pin == null) {
        return; // User cancelled
      }

      final isValid = await pinService.verifyPin(pin);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Créer le remboursement (offline-first)
      final refundService = RefundService();
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? 'unknown';

      // Convertir les items de vente en items de remboursement
      final refundItems = sale.items.map((item) {
        return RefundItem(
          saleItemId: item.productId, // Utiliser productId comme saleItemId temporairement
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          price: item.price,
          refundAmount: item.lineTotal,
        );
      }).toList();

      final refund = await refundService.createRefund(
        saleId: sale.id,
        items: refundItems,
        totalAmount: sale.total,
        reason: 'Remboursement de la vente #${sale.id.substring(0, 8)}',
        userId: userId,
      );

      // 3. Traiter le remboursement (met à jour le stock et la caisse)
      await refundService.processRefund(refund.id);

      // 4. Enregistrer le remboursement dans la caisse
      final cashRegisterService = CashRegisterService();
      await cashRegisterService.recordRefund(
        sale.total,
        refundId: refund.id,
        saleId: sale.id,
        userId: userId,
      );

      // 5. Libérer la table si elle était occupée
      if (sale.tableId != null) {
        final tableService = TableService();
        await tableService.clearTable(sale.tableId!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remboursement effectué: ${_formatCurrency(sale.total)}'),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les ventes
      ref.read(salesProvider.notifier).loadSales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du remboursement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _requestPinDialog() async {
    final pinController = TextEditingController();
    final theme = FTheme.of(context);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN requis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez entrer votre code PIN pour confirmer le remboursement'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'Code PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(null),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          FButton(
            onPress: () {
              if (pinController.text.length == 4) {
                Navigator.of(context).pop(pinController.text);
              }
            },
            style: FButtonStyle.primary(),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}

