// lib/core/auth_guard_service.dart
// Service de protection d'authentification et de gestion des accès

import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'pin_service.dart';
import 'constants.dart';
import '../features/auth/pin_screen.dart';
import '../features/auth/login_page.dart';
import '../features/pos/pos_page.dart';

/// Service de protection d'authentification
class AuthGuardService {
  static final AuthGuardService _instance = AuthGuardService._internal();
  factory AuthGuardService() => _instance;
  AuthGuardService._internal();

  final AuthService _authService = AuthService();
  final PinService _pinService = PinService();

  /// Vérifier l'authentification et rediriger si nécessaire
  Future<Widget> checkAuthAndRedirect(BuildContext context) async {
    // Vérifier si l'utilisateur est authentifié
    if (!_authService.isAuthenticated) {
      return const LoginPage();
    }

    // Vérifier si le PIN est activé
    final isPinEnabled = await _pinService.isPinEnabled();
    if (isPinEnabled) {
      // Vérifier si l'utilisateur est verrouillé
      final isLocked = await _pinService.isLocked();
      if (isLocked) {
        return _buildLockedScreen(context);
      }

      // Demander le PIN
      return _buildPinVerificationScreen(context);
    }

    // Accès direct au POS si pas de PIN
    return const PosPage();
  }

  /// Vérifier l'authentification pour une action spécifique
  Future<bool> checkAuthForAction() async {
    // Vérifier l'authentification de base
    if (!_authService.isAuthenticated) {
      return false;
    }

    // Vérifier le PIN si activé
    final isPinEnabled = await _pinService.isPinEnabled();
    if (isPinEnabled) {
      final isLocked = await _pinService.isLocked();
      if (isLocked) {
        return false;
      }
    }

    return true;
  }

  /// Demander l'authentification pour une action
  Future<bool> requestAuthForAction(BuildContext context) async {
    final isAuthenticated = await checkAuthForAction();
    if (isAuthenticated) {
      return true;
    }

    // Afficher l'écran de PIN si nécessaire
    final isPinEnabled = await _pinService.isPinEnabled();
    if (isPinEnabled) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PinScreen(
            title: 'Authentification requise',
            subtitle: 'Entrez votre code PIN pour continuer',
          ),
        ),
      );
      return result == true;
    }

    return false;
  }

  /// Vérifier et rafraîchir le token si nécessaire
  Future<bool> checkAndRefreshToken() async {
    try {
      // Vérifier si le token est valide
      if (_authService.currentToken == null) {
        return false;
      }

      // Essayer de rafraîchir le token
      await _authService.refreshToken();
      return true;
    } catch (e) {
      print('[AuthGuardService] Token refresh failed: $e');
      return false;
    }
  }

  /// Vérifier la connectivité et la validité du token
  Future<bool> checkConnectivityAndToken() async {
    try {
      // Vérifier et rafraîchir le token
      return await checkAndRefreshToken();
    } catch (e) {
      print('[AuthGuardService] Connectivity check failed: $e');
      return false;
    }
  }

  /// Obtenir l'état d'authentification complet
  Future<AuthState> getAuthState() async {
    final isAuthenticated = _authService.isAuthenticated;
    final isPinEnabled = await _pinService.isPinEnabled();
    final isLocked = await _pinService.isLocked();
    final remainingAttempts = await _pinService.getRemainingAttempts();
    final unlockTime = await _pinService.getUnlockTime();

    return AuthState(
      isAuthenticated: isAuthenticated,
      isPinEnabled: isPinEnabled,
      isLocked: isLocked,
      remainingAttempts: remainingAttempts,
      unlockTime: unlockTime,
    );
  }

  /// Écran de vérification du PIN
  Widget _buildPinVerificationScreen(BuildContext context) {
    return PinScreen(
      onSuccess: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PosPage()),
        );
      },
      onCancel: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      title: 'Code PIN requis',
      subtitle: 'Entrez votre code PIN pour accéder au POS',
    );
  }

  /// Écran de verrouillage
  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Compte verrouillé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Trop de tentatives de connexion. Veuillez attendre avant de réessayer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              FButton(
                onPress: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: FButtonStyle.primary(),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// État d'authentification
class AuthState {
  final bool isAuthenticated;
  final bool isPinEnabled;
  final bool isLocked;
  final int remainingAttempts;
  final DateTime? unlockTime;

  AuthState({
    required this.isAuthenticated,
    required this.isPinEnabled,
    required this.isLocked,
    required this.remainingAttempts,
    this.unlockTime,
  });

  bool get canAccess => isAuthenticated && !isLocked;
  bool get needsPin => isAuthenticated && isPinEnabled && !isLocked;
}
