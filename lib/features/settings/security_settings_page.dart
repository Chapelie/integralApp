// lib/features/settings/security_settings_page.dart
// Page de configuration des paramètres de sécurité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/pin_service.dart';
import '../../core/constants.dart';
import '../auth/pin_screen.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  final PinService _pinService = PinService();
  bool _isPinEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    await _pinService.init();
    setState(() {
      _isLoading = false;
    });
    
    final isEnabled = await _pinService.isPinEnabled();
    setState(() {
      _isPinEnabled = isEnabled;
    });
  }

  Future<void> _enablePin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinScreen(isSetup: true),
      ),
    );

    if (result == true) {
      _checkPinStatus();
    }
  }

  Future<void> _changePin() async {
    // First verify current PIN
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinScreen(isSetup: false),
      ),
    );

    if (verified == true) {
      // Then set new PIN
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PinScreen(isSetup: true),
        ),
      );

      if (result == true) {
        _checkPinStatus();
      }
    }
  }

  Future<void> _disablePin() async {
    // First verify current PIN
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinScreen(isSetup: false),
      ),
    );

    if (verified == true) {
      // Disable PIN by setting it to empty
      await _pinService.setPin('');
      _checkPinStatus();
    }
  }

  Future<void> _unlockUser() async {
    // Placeholder for unlock user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de déverrouillage à implémenter')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de sécurité'),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Code PIN
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: theme.colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Code PIN',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Protégez l\'application avec un code PIN à 4 chiffres',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Statut du PIN
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isPinEnabled 
                                ? theme.colors.primary.withValues(alpha: 0.1)
                                : theme.colors.muted.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isPinEnabled 
                                  ? theme.colors.primary.withValues(alpha: 0.3)
                                  : theme.colors.muted.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPinEnabled ? Icons.check_circle : Icons.cancel,
                                color: _isPinEnabled 
                                    ? theme.colors.primary
                                    : theme.colors.mutedForeground,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPinEnabled 
                                      ? 'Code PIN activé'
                                      : 'Code PIN désactivé',
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: _isPinEnabled 
                                        ? theme.colors.primary
                                        : theme.colors.mutedForeground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Boutons d'action
                        if (!_isPinEnabled) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FButton(
                              onPress: _enablePin,
                              child: const Text('Activer le code PIN'),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: FButton(
                                  onPress: _changePin,
                                  style: FButtonStyle.outline(),
                                  child: const Text('Modifier'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FButton(
                                  onPress: _disablePin,
                                  style: FButtonStyle.destructive(),
                                  child: const Text('Désactiver'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Section Gestion des verrouillages
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Gestion des verrouillages',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gérer les verrouillages de sécurité et les tentatives de connexion',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: FButton(
                            onPress: _unlockUser,
                            style: FButtonStyle.outline(),
                            child: const Text('Déverrouiller l\'utilisateur'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Section Informations de sécurité
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: theme.colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations de sécurité',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildSecurityInfo(theme, 'Tentatives maximales', '${AppConstants.maxPinAttempts}'),
                        _buildSecurityInfo(theme, 'Durée de verrouillage', '${AppConstants.pinLockoutDurationSeconds} secondes'),
                        _buildSecurityInfo(theme, 'Longueur du PIN', '${AppConstants.pinLength} chiffres'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecurityInfo(FThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}