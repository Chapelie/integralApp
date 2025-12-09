// lib/features/pos/payment_page.dart
// Page de paiement complète avec toutes les fonctionnalités

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../core/receipt_service.dart';
import '../../core/device_service.dart';
import '../../core/beep_service.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../core/responsive_helper.dart';

enum PaymentMethod {
  cash,
  card,
  mobile,
  check,
}

class PaymentPage extends ConsumerStatefulWidget {
  final double total;

  const PaymentPage({
    super.key,
    required this.total,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Ne pas pré-remplir le montant reçu - c'est l'argent donné par le client
    _amountController.text = '';
    _updateChange();
    _amountController.addListener(_updateChange);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateChange);
    _amountController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  void _updateChange() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final change = amount - widget.total;
    _changeController.text = change > 0 ? change.toStringAsFixed(2) : '0.00';
    setState(() {});
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final cartState = ref.watch(cartProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
        title: const Text('Paiement'),
        leading: _isProcessing
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout(theme, cartState) : _buildMobileLayout(theme, cartState),
      ),
    );
  }

  Widget _buildDesktopLayout(FThemeData theme, dynamic cartState) {
    return Row(
      children: [
        // Left side: Payment details
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Methods
                _buildPaymentMethods(theme),
                const SizedBox(height: 24),
                // Customer Selection
                _buildCustomerSelection(theme),
                const SizedBox(height: 24),
                // Amount Input with Numeric Pad
                _buildAmountInput(theme),
              ],
            ),
          ),
        ),
        // Right side: Receipt preview
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                left: BorderSide(color: theme.colors.border),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildReceiptPreview(theme, cartState),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(FThemeData theme, dynamic cartState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total à payer
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Total à payer',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(widget.total),
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: theme.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Aperçu du reçu (mobile) - visible immédiatement
          _buildReceiptPreview(theme, cartState),
          const SizedBox(height: 24),
          // Méthodes de paiement
          _buildPaymentMethods(theme),
          const SizedBox(height: 24),
          // Sélection client
          _buildCustomerSelection(theme),
          const SizedBox(height: 24),
          // Montant reçu avec clavier numérique
          if (_selectedMethod == PaymentMethod.cash) _buildAmountInput(theme),
          // Le bouton ✓ du clavier numérique sert à valider le paiement
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaymentMethod.values.map((method) {
            final isSelected = _selectedMethod == method;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMethod = method;
                  if (method != PaymentMethod.cash) {
                    _amountController.text = widget.total.toStringAsFixed(2);
                    _updateChange();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colors.primary : theme.colors.muted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? theme.colors.primary : theme.colors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPaymentIcon(method),
                      color: isSelected ? theme.colors.primaryForeground : theme.colors.foreground,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentLabel(method),
                      style: theme.typography.sm.copyWith(
                        color: isSelected ? theme.colors.primaryForeground : theme.colors.foreground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomerSelection(FThemeData theme) {
    final customerState = ref.watch(customerProvider);
    final cartState = ref.watch(cartProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FButton(
          onPress: () => _showCustomerSelection(theme),
          style: FButtonStyle.outline(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  cartState.selectedCustomer?.name ?? 'Sélectionner un client',
                  style: theme.typography.base,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cartState.selectedCustomer != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ref.read(cartProvider.notifier).setCustomer(null);
                  },
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showCustomerSelection(FThemeData theme) {
    final customerState = ref.read(customerProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sélectionner un client',
          style: theme.typography.base.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: customerState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : customerState.customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 48, color: theme.colors.mutedForeground),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun client enregistré',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: customerState.customers.length,
                      itemBuilder: (context, index) {
                        final customer = customerState.customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              color: theme.colors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: theme.typography.sm,
                          ),
                          subtitle: customer.phone != null
                              ? Text(
                                  customer.phone!,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          onTap: () {
                            ref.read(cartProvider.notifier).setCustomer(customer);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Montant reçu et Monnaie rendue
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant reçu',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(double.tryParse(_amountController.text) ?? 0.0),
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monnaie rendue',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(double.tryParse(_changeController.text) ?? 0.0),
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Pad numérique
        _buildNumericPad(theme),
      ],
    );
  }

  Widget _buildNumericPad(FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne 1: 1, 2, 3, C
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildNumericButton('1', theme),
              _buildNumericButton('2', theme),
              _buildNumericButton('3', theme),
              _buildActionButton('C', theme, () {
                _amountController.clear();
                _updateChange();
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 2: 4, 5, 6, ←
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildNumericButton('4', theme),
              _buildNumericButton('5', theme),
              _buildNumericButton('6', theme),
              _buildActionButton('←', theme, () {
                if (_amountController.text.isNotEmpty) {
                  _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
                  _updateChange();
                }
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 3: 7, 8, 9, =
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildNumericButton('7', theme),
              _buildNumericButton('8', theme),
              _buildNumericButton('9', theme),
              _buildActionButton('=', theme, () {
                _amountController.text = widget.total.toStringAsFixed(2);
                _updateChange();
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 4: ., 0, 00, ✓
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildNumericButton('.', theme),
              _buildNumericButton('0', theme),
              _buildNumericButton('00', theme),
              _buildActionButton('✓', theme, () {
                _processPayment();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumericButton(String text, FThemeData theme) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: FButton(
          onPress: () {
            if (text == '00') {
              _amountController.text += '00';
            } else {
              _amountController.text += text;
            }
            _updateChange();
          },
          style: FButtonStyle.outline(),
          child: Text(
            text,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, FThemeData theme, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: FButton(
          onPress: onPressed,
          style: FButtonStyle.primary(),
          child: Text(
            text,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(FThemeData theme, dynamic cartState) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info
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
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 24,
              color: theme.colors.border,
            ),
            // Items List
            Text(
              'Articles:',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: theme.typography.xs.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colors.foreground,
                          ),
                        ),
                        Text(
                          '${item.quantity} x ${_formatCurrency(item.product.price ?? 0.0)}',
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
                    _formatCurrency(item.quantity * (item.product.price ?? 0.0)),
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
            // Totals
            _buildReceiptRow('Sous-total:', _formatCurrency(cartState.subtotal), theme, isTotal: false),
            const SizedBox(height: 4),
            _buildReceiptRow('TVA:', _formatCurrency(cartState.taxAmount), theme, isTotal: false),
            Divider(
              height: 16,
              color: theme.colors.border,
            ),
            _buildReceiptRow('TOTAL:', _formatCurrency(widget.total), theme, isTotal: true),
            const SizedBox(height: 16),
            // Payment info
            if (_amountController.text.isNotEmpty && _selectedMethod == PaymentMethod.cash) ...[
              _buildReceiptRow('Montant reçu:', _formatCurrency(double.tryParse(_amountController.text) ?? 0.0), theme, isTotal: false),
              const SizedBox(height: 4),
              _buildReceiptRow('Monnaie:', _formatCurrency(double.tryParse(_changeController.text) ?? 0.0), theme, isTotal: false),
            ],
            Divider(
              height: 24,
              color: theme.colors.border,
            ),
            // Footer
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

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.mobile:
        return Icons.phone_android;
      case PaymentMethod.check:
        return Icons.receipt;
    }
  }

  String _getPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobile:
        return 'Mobile';
      case PaymentMethod.check:
        return 'Chèque';
    }
  }

  Future<void> _processPayment() async {
    print('[PaymentPage] 💳 DÉBUT processus de paiement');
    print('[PaymentPage] 💰 Total à payer: ${widget.total}');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Calculate change
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final change = amount - widget.total;

      if (_selectedMethod == PaymentMethod.cash && amount < widget.total) {
        throw Exception('Le montant reçu est insuffisant');
      }

      // Record the sale
      if (!mounted) return;

      final cartState = ref.read(cartProvider);
      final salesNotifier = ref.read(salesProvider.notifier);
      final cashRegisterNotifier = ref.read(cashRegisterProvider.notifier);
      final productNotifier = ref.read(productProvider.notifier);
      final cartNotifier = ref.read(cartProvider.notifier);
      final authState = ref.read(authProvider);

      print('[PaymentPage] 📦 Enregistrement de la vente...');

      // Get current cash register ID
      final cashRegisterState = ref.read(cashRegisterProvider);
      final cashRegisterId = cashRegisterState.currentRegister?.id;
      
      // Get device ID
      final deviceService = DeviceService();
      final deviceId = deviceService.deviceId;
      
      // Get user ID
      final userId = authState.user?.id ?? 'user1';
      
      // Create sale
      final sale = await salesNotifier.createSale(
        cartState,
        _selectedMethod.name,
        userId,
        deviceId,
        cashRegisterId: cashRegisterId,
      );

      if (sale == null) {
        throw Exception('Échec de la création de la vente');
      }

      print('[PaymentPage] ✅ Vente créée: ${sale.id}');

      // Record in cash register
      await cashRegisterNotifier.recordSale(sale);
      print('[PaymentPage] ✅ Vente enregistrée dans la caisse');

      // Update product stock
      final productQuantities = <String, int>{};
      for (final item in cartState.items) {
        productQuantities[item.product.id] = item.quantity;
      }
      await productNotifier.updateStockForSale(productQuantities);
      print('[PaymentPage] ✅ Stock mis à jour');

      // Clear cart
      cartNotifier.clearCart();

      // Play success beep
      BeepService().playSuccess();

      // Capturer le rootNavigator AVANT toute opération qui pourrait fermer la page
      final rootNavigator = mounted ? Navigator.of(context, rootNavigator: true) : null;

      // Générer et afficher l'aperçu PDF du reçu (sans imprimer)
      try {
        final receiptService = ReceiptService();
        final pdfBytes = await receiptService.generatePdfBytes(sale);
        
        // Afficher uniquement l'aperçu PDF après paiement (pas d'impression automatique)
        if (sale != null && mounted && rootNavigator != null) {
          await rootNavigator.push(
            MaterialPageRoute(
              builder: (context) => PdfPreviewPage(
                pdfBytes: pdfBytes,
                title: 'Reçu de vente #${sale.id}',
              ),
            ),
          );
        }
      } catch (e) {
        print('[PaymentPage] ⚠️ Erreur génération PDF: $e');
        // Ne pas bloquer le processus de paiement si l'aperçu PDF échoue
      }

      // Show success and navigate back
      if (mounted) {
        final changeText = change > 0 ? ' - Monnaie: ${_formatCurrency(change)}' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement effectué avec succès$changeText'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to POS
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      print('[PaymentPage] ❌ ERREUR: $e');
      print('[PaymentPage] Stack: $stackTrace');
      
      // Play error beep
      BeepService().playError();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
