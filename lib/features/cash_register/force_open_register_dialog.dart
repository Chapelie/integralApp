// lib/features/cash_register/force_open_register_dialog.dart
// Dialog pour forcer l'ouverture de caisse

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/cash_register_api_service.dart';
import '../../core/cash_register_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/device_service.dart';
import '../../core/storage_service.dart';
import 'open_register_page.dart';

class ForceOpenRegisterDialog extends ConsumerStatefulWidget {
  const ForceOpenRegisterDialog({super.key});

  @override
  ConsumerState<ForceOpenRegisterDialog> createState() => _ForceOpenRegisterDialogState();
}

class _ForceOpenRegisterDialogState extends ConsumerState<ForceOpenRegisterDialog> {
  final TextEditingController _openingBalanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return PopScope(
      canPop: false, // Empêcher la fermeture du dialog
      child: AlertDialog(
        title: const Text('Caisse fermée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message d'information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colors.destructive.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colors.destructive,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune caisse n\'est ouverte. Vous devez ouvrir une caisse pour effectuer des ventes.',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.destructive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Champ solde d'ouverture
            FTextField(
              controller: _openingBalanceController,
              label: const Text('Solde d\'ouverture (FCFA)'),
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Champ notes
            FTextField(
              controller: _notesController,
              label: const Text('Notes (optionnel)'),
              hint: 'Notes sur l\'ouverture de caisse...',
              maxLines: 3,
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: theme.colors.destructive,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          FButton(
            onPress: _isLoading ? null : _handleOpenRegister,
            style: FButtonStyle.primary(),
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ouvrir la caisse'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOpenRegister() async {
    if (_openingBalanceController.text.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir le solde d\'ouverture';
      });
      return;
    }

    final openingBalance = double.tryParse(_openingBalanceController.text);
    if (openingBalance == null || openingBalance < 0) {
      setState(() {
        _error = 'Veuillez saisir un solde valide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Vérifier que l'utilisateur est connecté
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null) {
        setState(() {
          _error = 'Une connexion est obligatoire pour ouvrir la caisse. Veuillez vous connecter.';
          _isLoading = false;
        });
        return;
      }

      // Récupérer le device ID backend (ou local en fallback)
      final deviceId = await DeviceService().getDeviceIdForApi();

      // Récupérer le warehouse ID du storage
      final storageService = StorageService();
      final warehouseId = await storageService.readSetting('selected_warehouse_id');

      if (warehouseId == null || warehouseId.isEmpty) {
        setState(() {
          _error = 'Aucun entrepôt sélectionné. Veuillez sélectionner un entrepôt avant d\'ouvrir la caisse.';
          _isLoading = false;
        });
        return;
      }

      // Ouvrir via l'API (obligatoire - pas de mode local)
      final cashRegisterApiService = CashRegisterApiService();
      await cashRegisterApiService.openRegister(
        openingBalance: openingBalance,
        userId: user.id,
        deviceId: deviceId,
        warehouseId: warehouseId,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      print('[ForceOpenRegisterDialog] Register opened via API');

      // Mettre à jour le service local après succès API
      final cashRegisterService = CashRegisterService();
      await cashRegisterService.openRegister(
        openingBalance: openingBalance,
        userId: user.id,
        deviceId: deviceId,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Fermer le dialog
      if (mounted) {
        Navigator.of(context).pop(true);
      }

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Caisse ouverte avec succès (${openingBalance.toStringAsFixed(0)} FCFA)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'ouverture de la caisse: ${e.toString()}\n\nVérifiez votre connexion internet.';
        _isLoading = false;
      });
    }
  }
}
