import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/sales_provider.dart';
import '../../../providers/cash_register_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../models/customer.dart';
import '../../../core/receipt_service.dart';
import '../../../core/printer_service.dart';
import '../../../core/printer_config_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/sync_service.dart';
import '../../../core/device_service.dart';
import '../../../core/beep_service.dart';
import '../../../widgets/pdf_preview_page.dart';

enum PaymentMethod {
  cash,
  card,
  mobile,
  check,
}

class PaymentModal extends ConsumerStatefulWidget {
  final double total;
  final VoidCallback onPaymentComplete;

  const PaymentModal({
    super.key,
    required this.total,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  void _updateChange() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final change = amount - widget.total;
    _changeController.text = change > 0 ? change.toStringAsFixed(2) : '0.00';
    setState(() {}); // Mettre à jour l'affichage
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

    return Dialog(
      child: Container(
        width: 900,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: theme.colors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: theme.colors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Paiement',
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
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

                          const SizedBox(height: 16),

                          // Amount Input with Numeric Pad
                          _buildAmountInput(theme),
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
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    onPress: () => Navigator.of(context).pop(),
                    style: FButtonStyle.outline(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    onPress: _isProcessing ? null : _processPayment,
                    style: FButtonStyle.primary(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isProcessing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        const Text('Confirmer le paiement'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleAmountInput(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant reçu',
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: 'Montant reçu',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _updateChange(),
        ),
        const SizedBox(height: 8),
        Text(
          'Monnaie rendue: ${_formatCurrency(double.tryParse(_changeController.text) ?? 0.0)}',
          style: theme.typography.sm.copyWith(
            color: theme.colors.primary,
            fontWeight: FontWeight.bold,
          ),
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
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        FButton(
          onPress: () => _showCustomerSelection(theme),
          style: FButtonStyle.outline(),
          child: Row(
            children: [
              const Icon(Icons.person, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cartState.selectedCustomer?.name ?? 'Sélectionner un client',
                  style: theme.typography.sm.copyWith(fontSize: 12),
                ),
              ),
              if (cartState.selectedCustomer != null)
                IconButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).setCustomer(null);
                  },
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
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

  Widget _buildOrderSummary(FThemeData theme, dynamic cartState) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Articles:', style: theme.typography.sm.copyWith(fontSize: 10)),
                Text('${cartState.items.length}', style: theme.typography.sm.copyWith(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total:', style: theme.typography.sm.copyWith(fontSize: 10)),
                Text(_formatCurrency(cartState.subtotal), style: theme.typography.sm.copyWith(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TVA:', style: theme.typography.sm.copyWith(fontSize: 10)),
                Text(_formatCurrency(cartState.taxAmount), style: theme.typography.sm.copyWith(fontSize: 10)),
              ],
            ),
            const Divider(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatCurrency(widget.total),
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.primary,
                    fontSize: 11,
                  ),
                ),
              ],
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
          'Paiement',
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: PaymentMethod.values.map((method) {
            final isSelected = _selectedMethod == method;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMethod = method;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colors.primary : theme.colors.muted,
                  borderRadius: BorderRadius.circular(4),
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
                      color: isSelected ? Colors.white : theme.colors.foreground,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPaymentLabel(method),
                      style: theme.typography.sm.copyWith(
                        color: isSelected ? Colors.white : theme.colors.foreground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
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

  Widget _buildAmountInput(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Montant reçu et Monnaie rendue en haut
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
        children: [
          // Ligne 1: 1, 2, 3, C
          Row(
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
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(FThemeData theme, dynamic cartState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.now().toString().substring(0, 16),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Items List
            Text(
              'Articles:',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
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
                    ),
                  ),
                ],
              ),
            )).toList(),

            const Divider(height: 24),

            // Totals
            _buildReceiptRow('Sous-total:', _formatCurrency(cartState.subtotal), theme, isTotal: false),
            const SizedBox(height: 4),
            _buildReceiptRow('TVA:', _formatCurrency(cartState.taxAmount), theme, isTotal: false),
            const Divider(height: 16),
            _buildReceiptRow('TOTAL:', _formatCurrency(widget.total), theme, isTotal: true),

            const SizedBox(height: 16),

            // Payment info
            if (_amountController.text.isNotEmpty) ...[
              _buildReceiptRow('Montant reçu:', _formatCurrency(double.tryParse(_amountController.text) ?? 0.0), theme, isTotal: false),
              const SizedBox(height: 4),
              _buildReceiptRow('Monnaie:', _formatCurrency(double.tryParse(_changeController.text) ?? 0.0), theme, isTotal: false),
            ],

            const Divider(height: 24),

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
          ),
        ),
        Text(
          value,
          style: theme.typography.xs.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 12 : 10,
            color: isTotal ? theme.colors.primary : null,
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
    print('═══════════════════════════════════════════════════════');
    print('[PaymentModal] 💳 DÉBUT processus de paiement');
    print('[PaymentModal] 💰 Total à payer: ${widget.total}');
    
    setState(() {
      _isProcessing = true;
    });
    print('[PaymentModal] ✅ État: _isProcessing = true');

    try {
      // Calculate change
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final change = amount - widget.total;
      print('[PaymentModal] 💵 Montant reçu: $amount');
      print('[PaymentModal] 💰 Total: ${widget.total}');
      print('[PaymentModal] 💸 Monnaie à rendre: $change');
      
      if (amount < widget.total) {
        print('[PaymentModal] ❌ Montant insuffisant: $amount < ${widget.total}');
        throw Exception('Le montant reçu est insuffisant');
      }

      // Record the sale
      if (!mounted) {
        print('[PaymentModal] ❌ Widget non monté, abandon');
        return;
      }
      
      // Sauvegarder les providers AVANT les opérations asynchrones
      print('[PaymentModal] 📦 Récupération des providers...');
      final cartState = ref.read(cartProvider);
      print('[PaymentModal]   - Cart: ${cartState.items.length} articles, total=${cartState.total}');
      
      final salesNotifier = ref.read(salesProvider.notifier);
      final cashRegisterNotifier = ref.read(cashRegisterProvider.notifier);
      final productNotifier = ref.read(productProvider.notifier);
      final cartNotifier = ref.read(cartProvider.notifier);
      print('[PaymentModal] ✅ Providers récupérés');

      // Get current cash register ID
      final cashRegisterState = ref.read(cashRegisterProvider);
      final cashRegisterId = cashRegisterState.currentRegister?.id;
      print('[PaymentModal] 💵 Cash Register ID: $cashRegisterId');

      // Create sale record with selected customer
      print('[PaymentModal] 📞 Appel de salesNotifier.createSale()...');
      print('[PaymentModal]   - Payment Method: ${_selectedMethod.name}');
      print('[PaymentModal]   - User ID: user1');
      print('[PaymentModal]   - Device ID: device1');
      print('[PaymentModal]   - Cash Register ID: $cashRegisterId');
      
      final sale = await salesNotifier.createSale(
        cartState,
        _selectedMethod.name,
        'user1', // TODO: Get actual user ID
        'device1', // TODO: Get actual device ID
        cashRegisterId: cashRegisterId,
      );
      
      if (sale == null) {
        print('[PaymentModal] ❌❌❌ VENTE NULL - CRÉATION ÉCHOUÉE ❌❌❌');
        throw Exception('Échec de la création de la vente');
      }
      
      print('[PaymentModal] ✅ Vente créée: ${sale.id}');

      // Record in cash register
      print('[PaymentModal] 💵 Enregistrement de la vente dans la caisse...');
      if (sale != null && mounted) {
        await cashRegisterNotifier.recordSale(sale);
        print('[PaymentModal] ✅ Vente enregistrée dans la caisse');
        
        // Update stock for all items in the sale
        print('[PaymentModal] 📦 Mise à jour du stock...');
        final productQuantities = <String, int>{};
        for (final item in cartState.items) {
          productQuantities[item.product.id] = item.quantity;
          print('[PaymentModal]   - ${item.product.name}: -${item.quantity}');
        }
        
        await productNotifier.updateStockForSale(productQuantities);
        print('[PaymentModal] ✅ Stock mis à jour');
      }

      // Capturer le rootNavigator AVANT toute opération qui pourrait fermer le modal
      print('[PaymentModal] 📱 Capture du rootNavigator...');
      final rootNavigator = mounted ? Navigator.of(context, rootNavigator: true) : null;
      print('[PaymentModal] ✅ RootNavigator capturé: ${rootNavigator != null}');
      
      // Afficher l'aperçu PDF après paiement (comme pour les rapports)
      if (sale != null && mounted && rootNavigator != null) {
        print('[PaymentModal] 📄 Ouverture de l\'aperçu PDF...');
        await _printReceipt(sale, rootNavigator: rootNavigator);
        print('[PaymentModal] ✅ Aperçu PDF ouvert');
      } else {
        print('[PaymentModal] ⚠️ Impossible d\'ouvrir l\'aperçu PDF');
        print('[PaymentModal]   - sale: ${sale != null}');
        print('[PaymentModal]   - mounted: $mounted');
        print('[PaymentModal]   - rootNavigator: ${rootNavigator != null}');
      }

      // Clear cart (utiliser le notifier sauvegardé)
      print('[PaymentModal] 🛒 Vidage du panier...');
      if (mounted) {
        cartNotifier.clearCart();
        print('[PaymentModal] ✅ Panier vidé');
      }

      // Play success beep
      BeepService().playSuccess();

      // Show success message with change
      if (mounted) {
        final changeText = change > 0 ? '\nMonnaie rendue: ${_formatCurrency(change)}' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement effectué avec succès$changeText'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        print('[PaymentModal] ✅ Message de succès affiché');
      }

      // Close modal and callback
      // Attendre un peu pour laisser le temps au PDF de s'ouvrir si nécessaire
      print('[PaymentModal] ⏳ Attente de 500ms avant fermeture du modal...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        print('[PaymentModal] 🚪 Fermeture du modal...');
        Navigator.of(context).pop();
        widget.onPaymentComplete();
        print('[PaymentModal] ✅ Modal fermé');
      }
      
      print('[PaymentModal] ✅✅✅ PAIEMENT TERMINÉ AVEC SUCCÈS ✅✅✅');
      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('[PaymentModal] ❌❌❌ ERREUR DANS LE PROCESSUS DE PAIEMENT ❌❌❌');
      print('[PaymentModal] Erreur: $e');
      print('[PaymentModal] Type: ${e.runtimeType}');
      print('[PaymentModal] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      
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
        print('[PaymentModal] ✅ État final: _isProcessing = false');
      }
    }
  }

  Future<void> _printReceipt(dynamic sale, {required NavigatorState rootNavigator}) async {
    print('[PaymentModal] ==========================================');
    print('[PaymentModal] 🖨️ DÉBUT aperçu reçu après paiement');
    print('[PaymentModal] Sale ID: ${sale?.id}');
    
    try {
      print('[PaymentModal] Création ReceiptService...');
      final receiptService = ReceiptService();
      print('[PaymentModal] ✅ ReceiptService créé');
      
      print('[PaymentModal] 📝 Génération du PDF...');
      final pdfBytes = await receiptService.generatePdfBytes(sale);
      print('[PaymentModal] ✅ PDF généré: ${pdfBytes.length} bytes');
      
      // Toujours ouvrir l'aperçu PDF après paiement (comme pour le test d'imprimante et les rapports)
      print('[PaymentModal] 📄 Ouverture de l\'aperçu PDF...');
      print('[PaymentModal] Utilisation du rootNavigator capturé...');
      
      // Utiliser le rootNavigator passé en paramètre (capturé avant la fermeture du modal)
      await rootNavigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: pdfBytes,
            title: 'Reçu de vente #${sale.id}',
          ),
        ),
      );
      print('[PaymentModal] ✅ Page d\'aperçu ouverte');
    } catch (e, stackTrace) {
      // Log error but don't fail the payment
      print('[PaymentModal] ❌ ERREUR aperçu reçu: $e');
      print('[PaymentModal] Stack trace: $stackTrace');
      print('[PaymentModal] ⚠️ Le paiement continue malgré l\'erreur d\'aperçu');
    }
    print('[PaymentModal] ==========================================');
  }
}
