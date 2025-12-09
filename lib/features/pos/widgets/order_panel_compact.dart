/// Compact order panel widget for mobile POS
///
/// Bottom sheet version of order panel with collapsible sections

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:intl/intl.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/sales_provider.dart';
import '../../../providers/cash_register_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../core/cash_register_service.dart';
import '../../../core/cash_register_guard_service.dart';
import '../../../features/cash_register/force_open_register_dialog.dart';

class OrderPanelCompact extends ConsumerStatefulWidget {
  const OrderPanelCompact({super.key});

  @override
  ConsumerState<OrderPanelCompact> createState() => _OrderPanelCompactState();
}

class _OrderPanelCompactState extends ConsumerState<OrderPanelCompact> {
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;
  bool _showDetails = false;

  @override
  void dispose() {
    _notesController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final theme = FTheme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${cartState.items.length} articles',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      onPressed: () {
                        setState(() => _showDetails = !_showDetails);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cart Items
                  if (_showDetails && cartState.items.isNotEmpty)
                    ...cartState.items.map((item) => _buildCartItem(context, item)),

                  if (cartState.items.isEmpty)
                    _buildEmptyCart(context),

                  const SizedBox(height: 16),

                  // Quick Details Section
                  if (_showDetails) ...[
                    // Customer Selection
                    FButton(
                      prefix: const Icon(FIcons.user),
                      onPress: _selectCustomer,
                      style: FButtonStyle.outline(),
                      child: Text(cartState.selectedCustomer?.name ?? 'Client'),
                    ),

                    const SizedBox(height: 12),


                    // Notes Input
                    FTextField(
                      controller: _notesController,
                      label: const Text('Notes'),
                      hint: 'Notes de commande',
                      maxLines: 2,
                      onChange: (value) {
                        ref.read(cartProvider.notifier).setNotes(value);
                      },
                    ),

                    const SizedBox(height: 16),
                  ],

                  // Totals Summary
                  FCard.raw(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTotalRow('Sous-total', cartState.subtotal, false),
                          const SizedBox(height: 8),
                          _buildTotalRow('TVA', cartState.taxAmount, false),
                          const Divider(height: 24),
                          _buildTotalRow('Total', cartState.total, true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aller directement au paiement
                FButton(
                  prefix: const Icon(FIcons.check),
                  onPress: cartState.items.isNotEmpty && !_isProcessing
                      ? _goToPayment
                      : null,
                  style: FButtonStyle.primary(),
                  child: Text(_isProcessing ? 'Traitement...' : 'Payer'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        prefix: const Icon(FIcons.x),
                        onPress: _handleCancel,
                        style: FButtonStyle.outline(),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FButton(
                        prefix: const Icon(FIcons.undo),
                        onPress: _handleRefund,
                        style: FButtonStyle.destructive(),
                        child: const Text('Rembourser'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final theme = FTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            FIcons.shoppingBag,
            size: 48,
            color: theme.colors.border,
          ),
          const SizedBox(height: 12),
          Text(
            'Panier vide',
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    final theme = FTheme.of(context);
    final lineTotal = (item.product.price ?? 0.0) * item.quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FButton.icon(
                          child: const Icon(FIcons.minus, size: 14),
                          onPress: () {
                            ref.read(cartProvider.notifier).updateQuantity(
                              item.product.id,
                              item.quantity - 1,
                            );
                          },
                          style: FButtonStyle.outline(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item.quantity}'),
                        ),
                        FButton.icon(
                          child: const Icon(FIcons.plus, size: 14),
                          onPress: () {
                            ref.read(cartProvider.notifier).updateQuantity(
                              item.product.id,
                              item.quantity + 1,
                            );
                          },
                          style: FButtonStyle.outline(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(lineTotal),
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isBold) {
    final theme = FTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.base.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: theme.typography.base.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colors.primary : null,
          ),
        ),
      ],
    );
  }

  Future<void> _goToPayment() async {
    print('[OrderPanelCompact] 🚀 _goToPayment() appelé');
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Vérifier l'état de la caisse
      final cashRegisterState = ref.read(cashRegisterProvider);
      final cashRegisterService = CashRegisterService();
      final localRegister = cashRegisterService.getCurrentRegister();
      
      final hasRegister = (cashRegisterState.currentRegister != null && cashRegisterState.canSell) ||
                          (localRegister != null && localRegister.status == 'open');
      
      // Si aucune caisse n'est ouverte, afficher le dialog
      if (!hasRegister) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ForceOpenRegisterDialog(),
        );
        
        if (result != true) {
          return;
        }
        
        await ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
        return;
      }
      
      // Si on a un cache local mais pas dans le provider, mettre à jour le provider
      if (localRegister != null && cashRegisterState.currentRegister == null) {
        ref.read(cashRegisterProvider.notifier).state = CashRegisterState(
          currentRegister: localRegister,
          canSell: localRegister.status == 'open',
          isLoading: false,
        );
      }

      final cartState = ref.read(cartProvider);
      
      if (cartState.items.isEmpty) {
        if (mounted) {
          _showError('Le panier est vide');
        }
        return;
      }

      // Capturer le root navigator AVANT de fermer le bottom sheet
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      
      // Fermer le bottom sheet d'abord
      Navigator.of(context).pop();

      // Attendre que la fermeture se termine complètement
      await Future.delayed(const Duration(milliseconds: 200));

      // Vérifier que le widget est toujours monté avant de naviguer
      if (!mounted) {
        return;
      }

      // Naviguer directement vers la page de paiement
      await rootNavigator.pushNamed(
        '/payment',
        arguments: cartState.total,
      );
    } catch (e, stackTrace) {
      print('[OrderPanelCompact] ❌ ERREUR dans _goToPayment: $e');
      print('[OrderPanelCompact] Stack: $stackTrace');
      if (mounted) {
        _showError('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleCancel() {
    ref.read(cartProvider.notifier).clearCart();
    _notesController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _handleRefund() async {
    _showError('Fonction remboursement à implémenter');
  }

  Future<void> _selectCustomer() async {
    final customers = ref.read(customerProvider).customers;

    if (customers.isEmpty) {
      _showError('Aucun client disponible');
      return;
    }

    ref.read(cartProvider.notifier).setCustomer(customers.first);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
