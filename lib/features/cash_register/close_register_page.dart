import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../core/responsive_helper.dart';
import '../../core/beep_service.dart';
import '../auth/login_page.dart';
import '../auth/pin_screen.dart';
import 'widgets/register_summary.dart';
import '../../widgets/unified_header.dart';
import '../../widgets/main_layout.dart';

/// Page de fermeture de caisse
///
/// Affiche le résumé de la caisse et permet à l'utilisateur
/// de saisir le montant réel et fermer la caisse avec validation PIN.
class CloseRegisterPage extends ConsumerStatefulWidget {
  const CloseRegisterPage({super.key});

  static const String routeName = '/close-register';

  @override
  ConsumerState<CloseRegisterPage> createState() => _CloseRegisterPageState();
}

class _CloseRegisterPageState extends ConsumerState<CloseRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _actualCashController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Valide que le montant réel est >= 0
  String? _validateActualCash(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le montant réel est requis';
    }

    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null) {
      return 'Montant invalide';
    }

    if (amount < 0) {
      return 'Le montant ne peut pas être négatif';
    }

    return null;
  }

  /// Calcule la différence entre le montant attendu et le montant réel
  double _calculateDifference(double expectedCash, double actualCash) {
    return actualCash - expectedCash;
  }

  /// Ferme la caisse après validation PIN
  Future<void> _handleCloseRegister() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate user is connected
    final authState = ref.read(authProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Une connexion est obligatoire pour fermer la caisse. Veuillez vous connecter.';
      });
      return;
    }

    // Request PIN confirmation
    final pinConfirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinScreen(
          title: 'Confirmez votre PIN pour fermer la caisse',
        ),
      ),
    );

    if (pinConfirmed != true) {
      if (mounted) {
        setState(() {
          _errorMessage = 'PIN incorrect ou annulé';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final actualCashStr = _actualCashController.text.trim().replaceAll(',', '.');
      final actualCash = double.parse(actualCashStr);
      final notes = _notesController.text.trim();

      // Close register using the provider (which uses the API)
      await ref.read(cashRegisterProvider.notifier).closeRegister(
            actualCash,
            notes.isNotEmpty ? notes : null,
          );

      // Play success beep
      BeepService().playSuccess();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Caisse fermée avec succès',
            style: FTheme.of(context).typography.base.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: FTheme.of(context).colors.primary,
        ),
      );

      // Logout and navigate to login page
      await ref.read(authProvider.notifier).logout(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la fermeture de la caisse: ${e.toString()}\n\nVérifiez que vous êtes connecté et que votre connexion internet fonctionne.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final registerState = ref.watch(cashRegisterProvider);

    // Get current register data
    final openingBalance = registerState.currentRegister?.openingBalance ?? 0.0;
    final totalSales = registerState.currentRegister?.totalSales ?? 0.0;
    final salesCount = registerState.currentRegister?.salesCount ?? 0;
    final expectedCash = openingBalance + totalSales;

    // Calculate actual cash if entered
    final actualCashStr = _actualCashController.text.trim().replaceAll(',', '.');
    final actualCash = double.tryParse(actualCashStr) ?? 0.0;
    final difference = _actualCashController.text.isNotEmpty
        ? _calculateDifference(expectedCash, actualCash)
        : 0.0;

    return MainLayout(
      currentRoute: '/close-register',
      appBar: UnifiedHeader(
        title: 'Fermeture de caisse',
        color: FTheme.of(context).colors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Retour',
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.isMobile(context) ? double.infinity : 700,
            ),
            child: Semantics(
              label: 'Page de fermeture de caisse',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Register summary
                    RegisterSummary(
                      openingBalance: openingBalance,
                      totalSales: totalSales,
                      salesCount: salesCount,
                      expectedCash: expectedCash,
                      actualCash: _actualCashController.text.isNotEmpty ? actualCash : null,
                      cashRegisterId: registerState.currentRegister?.id,
                      openedAt: registerState.currentRegister?.openedAt,
                      showSalesList: true,
                      difference: _actualCashController.text.isNotEmpty ? difference : null,
                    ),

                    SizedBox(height: Responsive.spacing(context, multiplier: 4)),

                    // Input card
                    FCard.raw(
                      child: Padding(
                        padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            Text(
                              'Saisie du montant réel',
                              style: theme.typography.xl.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                            ),

                            SizedBox(height: Responsive.spacing(context, multiplier: 4)),

                            // Error message display
                            if (_errorMessage != null) ...[
                              Semantics(
                                label: 'Erreur',
                                liveRegion: true,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: FTheme.of(context).colors.destructive,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: FTheme.of(context).colors.destructiveForeground,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: Responsive.spacing(context, multiplier: 3)),
                            ],

                            // Actual cash field
                            Semantics(
                              label: 'Champ montant réel en francs CFA',
                              child: FTextField(
                                controller: _actualCashController,
                                label: const Text('Montant réel (XOF)'),
                                hint: '0.00',
                                enabled: !_isLoading,
                                maxLines: 1,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                error: _validateActualCash(_actualCashController.text) != null
                                    ? Text(_validateActualCash(_actualCashController.text)!)
                                    : null,
                              ),
                            ),

                            SizedBox(height: Responsive.spacing(context, multiplier: 4)),

                            // Notes field (optional)
                            Semantics(
                              label: 'Champ notes optionnel',
                              child: FTextField(
                                controller: _notesController,
                                label: const Text('Notes (optionnel)'),
                                hint: 'Remarques sur la fermeture...',
                                enabled: !_isLoading,
                                maxLines: 3,
                              ),
                            ),

                            SizedBox(height: Responsive.spacing(context, multiplier: 6)),

                            // Warning message
                            Semantics(
                              label: 'Avertissement validation PIN',
                              child: FCard.raw(
                                child: Padding(
                                  padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 3)),
                                  child: Row(
                                    children: [
                                      Icon(
                                        FIcons.info,
                                        color: theme.colors.primary,
                                      ),
                                      SizedBox(width: Responsive.spacing(context, multiplier: 2)),
                                      Expanded(
                                        child: Text(
                                          'Votre PIN sera requis pour confirmer la fermeture',
                                          style: theme.typography.sm.copyWith(
                                            color: theme.colors.secondaryForeground,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.spacing(context, multiplier: 6)),

                            // Close button
                            Semantics(
                              label: 'Bouton fermer la caisse',
                              button: true,
                              enabled: !_isLoading,
                              child: FButton(
                                onPress: _isLoading ? null : _handleCloseRegister,
                                style: FButtonStyle.primary(),
                                child: _isLoading
                                    ? const Text('Fermeture en cours...')
                                    : const Text('Fermer la caisse'),
                                prefix: _isLoading
                                    ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                      )
                                    : const Icon(Icons.lock),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
