import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../core/responsive_helper.dart';
import '../../core/storage_service.dart';
import '../../core/device_service.dart';
import '../../core/beep_service.dart';

/// Page d'ouverture de caisse
///
/// Permet à l'utilisateur de saisir le montant initial de la caisse
/// et d'ouvrir une nouvelle session de caisse.
class OpenRegisterPage extends ConsumerStatefulWidget {
  const OpenRegisterPage({super.key});

  static const String routeName = '/open-register';

  @override
  ConsumerState<OpenRegisterPage> createState() => _OpenRegisterPageState();
}

class _OpenRegisterPageState extends ConsumerState<OpenRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _deviceName;

  @override
  void initState() {
    super.initState();
    _loadDeviceName();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  /// Charge le nom du device
  Future<void> _loadDeviceName() async {
    try {
      final deviceService = DeviceService();
      final deviceInfo = await deviceService.getDeviceInfo();
      final backendDeviceId = await deviceService.getBackendDeviceId();
      
      // Utiliser le backend device ID s'il existe, sinon le device ID local
      final deviceId = backendDeviceId ?? deviceInfo.deviceId;
      
      setState(() {
        _deviceName = deviceId.length > 20 ? '${deviceId.substring(0, 20)}...' : deviceId;
      });
    } catch (e) {
      print('[OpenRegisterPage] Error loading device name: $e');
      setState(() {
        _deviceName = 'Inconnu';
      });
    }
  }

  /// Valide que le montant est >= 0
  String? _validateBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le montant initial est requis';
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

  /// Ouvre la caisse
  Future<void> _handleOpenRegister() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if widget is still mounted before async operation
      if (!mounted) return;

      // Get current user
      final authState = ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Une connexion est obligatoire pour ouvrir la caisse. Veuillez vous connecter.';
          _isLoading = false;
        });
        return;
      }

      // Get device ID - utilise le backend_device_id si disponible
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceIdForApi();

      // Get warehouse ID from storage
      final storageService = StorageService();
      final warehouseId = await storageService.readSetting('selected_warehouse_id');

      if (warehouseId == null || warehouseId.isEmpty) {
        setState(() {
          _errorMessage = 'Aucun entrepôt sélectionné. Veuillez sélectionner un entrepôt avant d\'ouvrir la caisse.';
          _isLoading = false;
        });
        return;
      }

      // Get opening balance
      final openingBalance = double.parse(_balanceController.text.replaceAll(',', '.'));

      // Open register using the provider (which uses the API)
      print('[OpenRegisterPage] Opening cash register...');
      print('[OpenRegisterPage] Params: openingBalance=$openingBalance, userId=${currentUser.id}, deviceId=$deviceId, warehouseId=$warehouseId');
      
      try {
        await ref.read(cashRegisterProvider.notifier).openRegister(
          openingBalance,
          currentUser.id,
          deviceId,
          warehouseId,
          notes: null,
        );
        
        print('[OpenRegisterPage] Cash register opened successfully');

        // Play success beep
        BeepService().playSuccess();

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Caisse ouverte avec succès',
              style: FTheme.of(context).typography.base.copyWith(
                    color: Colors.white,
                  ),
            ),
            backgroundColor: FTheme.of(context).colors.primary,
          ),
        );

        // Navigate to POS page only if successful
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/pos');
        }
      } catch (e, stackTrace) {
        print('[OpenRegisterPage] Error opening cash register: $e');
        print('[OpenRegisterPage] Stack trace: $stackTrace');
        
        // Play error beep
        BeepService().playError();
        
        String errorMessage = 'Erreur lors de l\'ouverture de la caisse';
        
        // Parse error message from DioException
        if (e.toString().contains('Une caisse est déjà ouverte')) {
          errorMessage = '⚠️ Une caisse est déjà ouverte pour cet appareil.\n\nVeuillez fermer la caisse actuelle avant d\'en ouvrir une nouvelle.';
        } else if (e.toString().contains('warehouse_id')) {
          errorMessage = '⚠️ Aucun entrepôt sélectionné.\n\nVeuillez sélectionner un entrepôt avant d\'ouvrir la caisse.';
        } else if (e.toString().contains('user_id')) {
          errorMessage = '⚠️ Connexion requise.\n\nVeuillez vous connecter avant d\'ouvrir la caisse.';
        } else if (e.toString().contains('500')) {
          errorMessage = '⚠️ Erreur du serveur.\n\nUne erreur est survenue lors de l\'ouverture de la caisse.';
        } else {
          errorMessage = 'Erreur: ${e.toString()}';
        }
        
        // Don't navigate, just show the error in the UI
        setState(() {
          _errorMessage = errorMessage;
        });
        
        // Re-throw to be caught by outer catch block
        rethrow;
      }
    } catch (e) {
      print('[OpenRegisterPage] Outer error: $e');
      setState(() {
        _errorMessage = 'Erreur lors de l\'ouverture de la caisse.\n\nVérifiez que vous êtes connecté et que votre connexion internet fonctionne.';
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
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ouverture de caisse'),
        backgroundColor: FTheme.of(context).colors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout(context);
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 600 ? double.infinity : 600,
            ),
            child: Semantics(
              label: 'Page d\'ouverture de caisse',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main card
                    FCard.raw(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Icon
                            Semantics(
                              label: 'Icône caisse enregistreuse',
                              child: Icon(
                                FIcons.package,
                                size: 48,
                                color: theme.colors.primary,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Title
                            Text(
                              'Ouverture de caisse',
                              style: theme.typography.xl2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Saisissez le montant initial de la caisse',
                              style: theme.typography.base.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 48),

                            // User info (auto-filled)
                            Semantics(
                              label: 'Informations utilisateur',
                              child: FCard.raw(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      Icon(
                                        FIcons.user,
                                        size: 20,
                                        color: theme.colors.secondaryForeground,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Utilisateur',
                                              style: theme.typography.xs.copyWith(
                                                color: theme.colors.mutedForeground,
                                              ),
                                            ),
                                            Text(
                                              currentUser?.name ?? 'Inconnu',
                                              style: theme.typography.base.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colors.secondaryForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Device info (auto-filled)
                            Semantics(
                              label: 'Informations périphérique',
                              child: FCard.raw(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      Icon(
                                        FIcons.tablet,
                                        size: 20,
                                        color: theme.colors.secondaryForeground,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Périphérique',
                                              style: theme.typography.xs.copyWith(
                                                color: theme.colors.mutedForeground,
                                              ),
                                            ),
                                            Text(
                                              _deviceName ?? 'Chargement...',
                                              style: theme.typography.base.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colors.secondaryForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Error message display
                            if (_errorMessage != null) ...[
                              Semantics(
                                label: 'Erreur',
                                liveRegion: true,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: FTheme.of(context).colors.destructive,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: FTheme.of(context).colors.destructiveForeground,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (_errorMessage!.contains('déjà ouverte')) ...[
                                        const SizedBox(height: 12),
                                        FButton(
                                          onPress: () {
                                            Navigator.of(context).pushReplacementNamed('/pos');
                                          },
                                          style: FButtonStyle.outline(),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.shopping_cart, size: 20),
                                              const SizedBox(width: 8),
                                              Text('Aller à la page de vente'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Opening balance field
                            Semantics(
                              label: 'Champ montant initial en francs CFA',
                              child: FTextField(
                                controller: _balanceController,
                                label: const Text('Montant initial (XOF)'),
                                hint: '0.00',
                                enabled: !_isLoading,
                                maxLines: 1,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                error: _validateBalance(_balanceController.text) != null
                                    ? Text(_validateBalance(_balanceController.text)!)
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 32),


                            // Open button
                            Semantics(
                              label: 'Bouton ouvrir la caisse',
                              button: true,
                              enabled: !_isLoading,
                              child: FButton(
                                onPress: _isLoading ? null : _handleOpenRegister,
                                style: FButtonStyle.primary(),
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Ouverture en cours...'),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle),
                                          SizedBox(width: 8),
                                          Text('Ouvrir la caisse'),
                                        ],
                                      ),
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
