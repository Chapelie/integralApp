import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/sales_provider.dart';
import '../../../providers/cash_register_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../core/cash_register_guard_service.dart';
import '../../../core/cash_register_service.dart';
import '../../../features/cash_register/force_open_register_dialog.dart';
import '../../../core/business_config.dart';
import '../../../core/beep_service.dart';
import '../../../providers/tab_provider.dart';
import '../tab_ticket_page.dart';
import 'customer_selection_widget.dart';
import '../../restaurant/widgets/restaurant_order_info.dart';

class OrderPanel extends ConsumerStatefulWidget {
  const OrderPanel({super.key});

  @override
  ConsumerState<OrderPanel> createState() => _OrderPanelState();
}

class _OrderPanelState extends ConsumerState<OrderPanel> {
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

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
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          left: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with Customer Button - Compact
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commande',
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${cartState.items.length}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Customer Selection Widget
                const CustomerSelectionWidget(),
              ],
            ),
          ),

          // Restaurant Order Info (only in restaurant mode)
          if (BusinessConfig().isFeatureEnabled('enableServiceTypes'))
            const RestaurantOrderInfo(),

          // Cart Items List
          Expanded(
            child: cartState.items.isEmpty
                ? _buildEmptyCart(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return _buildCartItem(context, item);
                    },
                  ),
          ),


          // Totals and Actions - Ultra Compact
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colors.muted.withValues(alpha: 0.3),
              border: Border(
                top: BorderSide(
                  color: theme.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Totals - Ultra Compact
                _buildTotalRow('Sous-total', cartState.subtotal, false),
                const SizedBox(height: 2),
                _buildTotalRow('TVA', cartState.taxAmount, false),
                const Divider(height: 8),
                _buildTotalRow('Total', cartState.total, true),
                
                const SizedBox(height: 8),
                
                // Actions - Ultra Compact buttons
                FButton(
                  onPress: cartState.items.isNotEmpty && !_isProcessing
                      ? _handleValidate
                      : null,
                  prefix: const Icon(FIcons.check, size: 14),
                  style: FButtonStyle.primary(),
                  child: Text(
                    _isProcessing ? 'Traitement...' : 'Valider',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        onPress: cartState.items.isNotEmpty && !_isProcessing
                            ? _handleCreateTab
                            : null,
                        prefix: const Icon(FIcons.receipt, size: 12),
                        style: FButtonStyle.outline(),
                        child: Text(
                          _isProcessing ? 'Traitement...' : 'Addition',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FButton(
                        onPress: _handleCancel,
                        prefix: const Icon(FIcons.x, size: 12),
                        style: FButtonStyle.outline(),
                        child: const Text('Annuler', style: TextStyle(fontSize: 11)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.shoppingBag,
            size: 64,
            color: theme.colors.border,
          ),
          const SizedBox(height: 16),
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

    return Semantics(
      label: '${item.product.name}, quantité ${item.quantity}, total ${_formatCurrency(lineTotal)}',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: FCard.raw(
          key: ValueKey(item.product.id),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls - Compact
                    Row(
                      children: [
                        FButton.icon(
                          onPress: () {
                            ref.read(cartProvider.notifier).updateQuantity(
                              item.product.id,
                              item.quantity - 1,
                            );
                          },
                          style: FButtonStyle.outline(),
                          child: const Icon(FIcons.minus, size: 12),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FButton.icon(
                          onPress: () {
                            ref.read(cartProvider.notifier).updateQuantity(
                              item.product.id,
                              item.quantity + 1,
                            );
                          },
                          style: FButtonStyle.outline(),
                          child: const Icon(FIcons.plus, size: 12),
                        ),
                      ],
                    ),

                    // Line Total
                    Text(
                      _formatCurrency(lineTotal),
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
          style: theme.typography.sm.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 13 : 12,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: theme.typography.sm.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colors.primary : null,
            fontSize: isBold ? 13 : 12,
          ),
        ),
      ],
    );
  }

  Future<void> _handleValidate() async {
    // Vérifier l'état de la caisse
    final cashRegisterState = ref.read(cashRegisterProvider);
    
    // Vérifier aussi dans le cache local
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
      
      // Recharger l'état après ouverture
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

    // Navigate to payment page (desktop also uses page, not modal)
    final cartState = ref.read(cartProvider);
    await Navigator.of(context).pushNamed(
      '/payment',
      arguments: cartState.total,
    );
  }

  void _handleCancel() {
    ref.read(cartProvider.notifier).clearCart();
    _notesController.clear();
  }

  Future<void> _handleCreateTab() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      _showError('Le panier est vide pour créer une addition');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final tabNotifier = ref.read(tabProvider.notifier);
      final newTab = await tabNotifier.createTabFromCart(cartState);

      if (newTab != null && mounted) {
        ref.read(cartProvider.notifier).clearCart();
        _notesController.clear();
        BeepService().playSuccess();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TabTicketPage(tab: newTab),
          ),
        );
      } else {
        _showError('Échec de la création de l\'addition');
      }
    } catch (e) {
      _showError('Erreur lors de la création de l\'addition: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
