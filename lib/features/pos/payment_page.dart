// lib/features/pos/payment_page.dart
// Page de paiement complète avec génération de reçu
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/credit_note_provider.dart';
import '../../core/receipt_service.dart';
import '../../core/beep_service.dart';
import '../../core/device_service.dart';
import '../../core/credit_note_service.dart';
import '../../widgets/pdf_preview_page.dart';

enum PaymentMethod {
  cash,
  card,
  mobile,
  check,
}

class PaymentPage extends ConsumerStatefulWidget {
  final double? totalToPay; // Total à payer (peut être différent du total du panier si c'est pour une addition)

  const PaymentPage({
    super.key,
    this.totalToPay,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  bool _createCreditNote = false; // Option pour créer un avoir au lieu de rendre la monnaie (non automatique)

  @override
  void initState() {
    super.initState();
    _amountController.text = '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  double get _totalToPay {
    if (widget.totalToPay != null) {
      return widget.totalToPay!;
    }
    final cartState = ref.read(cartProvider);
    return cartState.total;
  }

  double get _change {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return (amount - _totalToPay).clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Payment details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Methods
                  _buildPaymentMethods(theme),

                  const SizedBox(height: 24),

                  // Amount Input
                  _buildAmountInput(theme),

                  const SizedBox(height: 24),

                  // Process Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: _isProcessing ? null : _processPayment,
                      style: FButtonStyle.primary(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isProcessing)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(_isProcessing ? 'Traitement...' : 'Confirmer le paiement'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Right side: Receipt preview
            Expanded(
              flex: 1,
              child: _buildReceiptPreview(theme, cartState),
            ),
          ],
        ),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPaymentMethodButton(theme, PaymentMethod.cash, Icons.money, 'Espèces'),
            _buildPaymentMethodButton(theme, PaymentMethod.card, Icons.credit_card, 'Carte'),
            _buildPaymentMethodButton(theme, PaymentMethod.mobile, Icons.phone_android, 'Mobile'),
            _buildPaymentMethodButton(theme, PaymentMethod.check, Icons.receipt, 'Chèque'),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton(FThemeData theme, PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colors.primary : theme.colors.background,
          border: Border.all(
            color: isSelected ? theme.colors.primary : theme.colors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colors.primaryForeground : theme.colors.foreground,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.typography.sm.copyWith(
                color: isSelected ? theme.colors.primaryForeground : theme.colors.foreground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant reçu',
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(
            hintText: 'Entrez le montant reçu',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total à payer:',
                    style: theme.typography.sm,
                  ),
                  Text(
                    _formatCurrency(_totalToPay),
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monnaie rendue:',
                    style: theme.typography.sm,
                  ),
                  Text(
                    _formatCurrency(_change),
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _change > 0 ? theme.colors.primary : theme.colors.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Option pour créer un avoir au lieu de rendre la monnaie (non automatique)
        if (_change > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _createCreditNote,
                onChanged: (value) {
                  setState(() {
                    _createCreditNote = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _createCreditNote = !_createCreditNote;
                    });
                  },
                  child: Text(
                    'Créer un avoir au lieu de rendre la monnaie',
                    style: theme.typography.sm,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Numeric Pad
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
        children: [
          // Ligne 1: 1, 2, 3, C
          Row(
            children: [
              _buildNumericButton('1', theme),
              _buildNumericButton('2', theme),
              _buildNumericButton('3', theme),
              _buildActionButton('C', theme, () {
                _amountController.clear();
                setState(() {});
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 2: 4, 5, 6, ←
          Row(
            children: [
              _buildNumericButton('4', theme),
              _buildNumericButton('5', theme),
              _buildNumericButton('6', theme),
              _buildActionButton('←', theme, () {
                if (_amountController.text.isNotEmpty) {
                  _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
                  setState(() {});
                }
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 3: 7, 8, 9, =
          Row(
            children: [
              _buildNumericButton('7', theme),
              _buildNumericButton('8', theme),
              _buildNumericButton('9', theme),
              _buildActionButton('=', theme, () {
                _amountController.text = _totalToPay.toStringAsFixed(0);
                setState(() {});
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 4: ., 0, 00, Entrée
          Row(
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
            setState(() {});
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
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(FThemeData theme, CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu du reçu',
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...cartState.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.product.name}',
                    style: theme.typography.sm,
                  ),
                ),
                Text(
                  _formatCurrency((item.product.price ?? 0.0) * item.quantity),
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )).toList(),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sous-total:',
                style: theme.typography.sm,
              ),
              Text(
                _formatCurrency(cartState.subtotal),
                style: theme.typography.sm,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TVA:',
                style: theme.typography.sm,
              ),
              Text(
                _formatCurrency(cartState.taxAmount),
                style: theme.typography.sm,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL:',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatCurrency(_totalToPay),
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount < _totalToPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le montant reçu est insuffisant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartState = ref.read(cartProvider);
      final salesNotifier = ref.read(salesProvider.notifier);
      final cashRegisterNotifier = ref.read(cashRegisterProvider.notifier);
      final productNotifier = ref.read(productProvider.notifier);
      final cartNotifier = ref.read(cartProvider.notifier);

      // Get user ID and device ID
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? '';
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceIdForApi();

      // Create sale
      final sale = await salesNotifier.createSale(
        cartState,
        _getPaymentMethodString(_selectedMethod),
        userId,
        deviceId,
      );

      // Record in cash register
      if (sale != null) {
        await cashRegisterNotifier.recordSale(sale);

        // Update stock
        final productQuantities = <String, int>{};
        for (final item in cartState.items) {
          productQuantities[item.product.id] = item.quantity;
        }
        await productNotifier.updateStockForSale(productQuantities);
      }

      // Create credit note if user explicitly selected the option (not automatic)
      if (_change > 0 && _createCreditNote && sale != null) {
        try {
          final creditNoteService = CreditNoteService();
          final creditNoteNotifier = ref.read(creditNoteProvider.notifier);
          
          final creditNote = await creditNoteService.createCreditNote(
            customerId: cartState.selectedCustomer?.id,
            initialAmount: _change,
            originSaleId: sale.id,
          );
          
          // Refresh credit notes list
          await creditNoteNotifier.load();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Avoir créé: ${_formatCurrency(_change)}'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('[PaymentPage] Error creating credit note: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la création de l\'avoir: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Generate and show receipt
      if (sale != null && mounted) {
        final receiptService = ReceiptService();
        final pdfBytes = await receiptService.generatePdfBytes(sale);

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PdfPreviewPage(
                pdfBytes: pdfBytes,
                title: 'Reçu de vente #${sale.id}',
              ),
            ),
          );
        }
      }

      // Clear cart
      cartNotifier.clearCart();

      // Play success beep
      BeepService().playSuccess();

      // Show success message
      if (mounted) {
        final changeText = _change > 0 && !_createCreditNote 
            ? '\nMonnaie rendue: ${_formatCurrency(_change)}' 
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement effectué avec succès$changeText'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
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

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.mobile:
        return 'mobile';
      case PaymentMethod.check:
        return 'check';
    }
  }
}
