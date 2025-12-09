// lib/features/auth/pin_screen.dart
// Écran de saisie de code PIN pour la sécurité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/pin_service.dart';
import '../../core/constants.dart';

class PinScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final String? title;
  final String? subtitle;
  final bool isSetup; // true pour la configuration, false pour la vérification

  const PinScreen({
    super.key,
    this.onSuccess,
    this.onCancel,
    this.title,
    this.subtitle,
    this.isSetup = false,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final PinService _pinService = PinService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isLocked = false;
  DateTime? _unlockTime;
  int _remainingAttempts = AppConstants.maxPinAttempts;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final isLocked = await _pinService.isLocked();
    final unlockTime = await _pinService.getUnlockTime();
    final remainingAttempts = await _pinService.getRemainingAttempts();
    
    setState(() {
      _isLocked = isLocked;
      _unlockTime = unlockTime;
      _remainingAttempts = remainingAttempts;
    });
  }

  void _onNumberPressed(String number) {
    if (_isLocked || _isLoading) return;
    
    setState(() {
      if (_enteredPin.length < AppConstants.pinLength) {
        _enteredPin += number;
        _errorMessage = '';
      }
    });

    // Auto-submit when PIN is complete
    if (_enteredPin.length == AppConstants.pinLength) {
      _handlePinComplete();
    }
  }

  void _onBackspacePressed() {
    if (_isLocked || _isLoading) return;
    
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      }
    });
  }

  Future<void> _handlePinComplete() async {
    if (_isLocked || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.isSetup) {
        // Configuration du PIN
        await _setupPin();
      } else {
        // Vérification du PIN
        await _verifyPin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setupPin() async {
    // Pour la configuration, on demande confirmation
    if (_pinController.text.isEmpty) {
      _pinController.text = _enteredPin;
      setState(() {
        _enteredPin = '';
        _isLoading = false;
      });
      return;
    }

    if (_pinController.text != _enteredPin) {
      setState(() {
        _errorMessage = 'Les codes PIN ne correspondent pas';
        _enteredPin = '';
        _pinController.clear();
        _isLoading = false;
      });
      return;
    }

    final success = await _pinService.setPin(_enteredPin);
    if (success) {
      widget.onSuccess?.call();
    } else {
      setState(() {
        _errorMessage = 'Erreur lors de la configuration du PIN';
        _enteredPin = '';
        _pinController.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await _pinService.verifyPin(_enteredPin);
    if (success) {
      widget.onSuccess?.call();
    } else {
      await _checkLockStatus();
      setState(() {
        _errorMessage = 'Code PIN incorrect';
        _enteredPin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 24.0 : 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              // Logo ou icône
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colors.primary,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.lock,
                  size: 40,
                  color: theme.colors.primaryForeground,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Titre
              Text(
                widget.title ?? (widget.isSetup ? 'Configurer le code PIN' : 'Code PIN requis'),
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Sous-titre
              Text(
                widget.subtitle ?? (widget.isSetup 
                  ? 'Choisissez un code PIN à 4 chiffres pour sécuriser l\'application'
                  : 'Entrez votre code PIN pour continuer'),
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Affichage du PIN
              _buildPinDisplay(theme),
              
              const SizedBox(height: 24),
              
              // Message d'erreur ou d'information
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              if (_isLocked && _unlockTime != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Trop de tentatives. Réessayez dans ${_getRemainingTime()}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              if (_remainingAttempts < AppConstants.maxPinAttempts && !_isLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Tentatives restantes: $_remainingAttempts',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Clavier numérique
              _buildNumberPad(theme, context),
              
              const SizedBox(height: 24),
              
              // Bouton d'annulation
              if (widget.onCancel != null)
                FButton(
                  onPress: _isLocked ? null : widget.onCancel,
                  style: FButtonStyle.outline(),
                  child: const Text('Annuler'),
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

  Widget _buildPinDisplay(FThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppConstants.pinLength, (index) {
        final isFilled = index < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? theme.colors.primary : theme.colors.muted,
            border: Border.all(
              color: theme.colors.border,
              width: 1,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad(FThemeData theme, BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Ligne 1-2-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((number) => _buildNumberButton(number, theme, isSmall)).toList(),
        ),
        const SizedBox(height: 16),
        
        // Ligne 4-5-6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((number) => _buildNumberButton(number, theme, isSmall)).toList(),
        ),
        const SizedBox(height: 16),
        
        // Ligne 7-8-9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((number) => _buildNumberButton(number, theme, isSmall)).toList(),
        ),
        const SizedBox(height: 16),
        
        // Ligne 0 et backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('0', theme, isSmall),
            _buildBackspaceButton(theme, isSmall),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number, FThemeData theme, bool isSmall) {
    final buttonSize = isSmall ? 60.0 : 70.0;
    
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: FButton(
        onPress: _isLocked || _isLoading ? null : () => _onNumberPressed(number),
        style: FButtonStyle.primary(),
        child: Text(
          number,
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.primaryForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(FThemeData theme, bool isSmall) {
    final buttonSize = isSmall ? 60.0 : 70.0;
    
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: FButton(
        onPress: _isLocked || _isLoading ? null : _onBackspacePressed,
        style: FButtonStyle.secondary(),
        child: Icon(
          Icons.backspace,
          color: theme.colors.foreground,
        ),
      ),
    );
  }

  String _getRemainingTime() {
    if (_unlockTime == null) return '';
    
    final now = DateTime.now();
    final remaining = _unlockTime!.difference(now);
    
    if (remaining.isNegative) return 'maintenant';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
