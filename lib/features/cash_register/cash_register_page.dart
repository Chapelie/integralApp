import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/sidebar_provider.dart';
import '../../widgets/main_layout.dart';
import '../../core/responsive_helper.dart';
import '../../widgets/unified_header.dart';

class CashRegisterPage extends ConsumerStatefulWidget {
  const CashRegisterPage({super.key});

  @override
  ConsumerState<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends ConsumerState<CashRegisterPage> {
  final String _currentRoute = '/cash-register';

  @override
  void initState() {
    super.initState();
    // Load current register when page is initialized
    Future.microtask(() {
      if (mounted) {
        ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterState = ref.watch(cashRegisterProvider);
    final theme = FTheme.of(context);
    final isCollapsed = ref.watch(sidebarProvider);
    final isDesktop = Responsive.isDesktop(context);

    if (cashRegisterState.isLoading) {
      return MainLayout(
        currentRoute: _currentRoute,
        appBar: UnifiedHeader(title: 'Caisse'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cashRegisterState.error != null) {
      return MainLayout(
        currentRoute: _currentRoute,
        appBar: UnifiedHeader(title: 'Caisse'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colors.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cashRegisterState.error!,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FButton(
                onPress: () {
                  ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
                },
                style: FButtonStyle.outline(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return MainLayout(
      currentRoute: _currentRoute,
      appBar: UnifiedHeader(
        title: 'Caisse',
        onRefresh: () {
          ref.read(cashRegisterProvider.notifier).refreshRegisterState();
        },
      ),
      child: _buildRegisterContent(context, cashRegisterState, theme),
    );
  }

  Widget _buildRegisterContent(BuildContext context, dynamic cashRegisterState, FThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Register Status
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: theme.colors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'État de la Caisse',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Badge d'état principal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(cashRegisterState.currentRegister?.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(cashRegisterState.currentRegister?.status),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(cashRegisterState.currentRegister?.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusText(cashRegisterState.currentRegister?.status),
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(cashRegisterState.currentRegister?.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cashRegisterState.currentRegister != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ouverte le: ${_formatDate(cashRegisterState.currentRegister!.openedAt)}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      'Solde d\'ouverture: ${_formatCurrency(cashRegisterState.currentRegister!.openingBalance)}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          if (cashRegisterState.currentRegister == null)
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ouvrir la Caisse',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pour commencer les ventes, vous devez d\'abord ouvrir la caisse.',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FButton(
                      onPress: () {
                        Navigator.of(context).pushNamed('/open-register');
                      },
                      style: FButtonStyle.primary(),
                      child: const Text('Ouvrir la Caisse'),
                    ),
                  ],
                ),
              ),
            )
          else
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Actions Disponibles',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Responsive.isDesktop(context)
                        ? Row(
                            children: [
                              Expanded(
                                child: FButton(
                                  onPress: () {
                                    Navigator.of(context).pushNamed('/pos');
                                  },
                                  style: FButtonStyle.primary(),
                                  child: const Text('Aller aux Ventes'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FButton(
                                  onPress: () {
                                    Navigator.of(context).pushNamed('/close-register');
                                  },
                                  style: FButtonStyle.outline(),
                                  child: const Text('Fermer la Caisse'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              FButton(
                                onPress: () {
                                  Navigator.of(context).pushNamed('/pos');
                                },
                                style: FButtonStyle.primary(),
                                child: const Text('Aller aux Ventes'),
                              ),
                              const SizedBox(height: 12),
                              FButton(
                                onPress: () {
                                  Navigator.of(context).pushNamed('/close-register');
                                },
                                style: FButtonStyle.outline(),
                                child: const Text('Fermer la Caisse'),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Recent Activity
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activité Récente',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    context,
                    'Caisse ouverte',
                    'Solde d\'ouverture: ${_formatCurrency(cashRegisterState.currentRegister?.openingBalance ?? 0)}',
                    Icons.lock_open,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActivityItem(
                    context,
                    'Ventes du jour',
                    '${_getTodaySalesCount(cashRegisterState)} transactions',
                    Icons.shopping_cart,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActivityItem(
                    context,
                    'Chiffre d\'affaires',
                    _formatCurrency(_getTodaySalesTotal(cashRegisterState)),
                    Icons.attach_money,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, IconData icon, FThemeData theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }

  int _getTodaySalesCount(dynamic cashRegisterState) {
    // For now, return a placeholder value
    // In a real implementation, this would calculate from sales data
    return 0;
  }

  double _getTodaySalesTotal(dynamic cashRegisterState) {
    // For now, return a placeholder value
    // In a real implementation, this would calculate from sales data
    return 0.0;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'open':
        return 'Caisse ouverte';
      case 'closed':
        return 'Caisse fermée';
      default:
        return 'Aucune caisse active';
    }
  }
}
