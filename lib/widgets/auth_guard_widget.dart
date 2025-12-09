// lib/widgets/auth_guard_widget.dart
// Widget de protection d'authentification

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_guard_service.dart';
import '../core/pin_service.dart';
import '../features/auth/pin_screen.dart';
import '../features/auth/login_page.dart';

class AuthGuardWidget extends ConsumerStatefulWidget {
  final Widget child;
  final bool requirePin;
  final String? title;
  final String? subtitle;

  const AuthGuardWidget({
    super.key,
    required this.child,
    this.requirePin = true,
    this.title,
    this.subtitle,
  });

  @override
  ConsumerState<AuthGuardWidget> createState() => _AuthGuardWidgetState();
}

class _AuthGuardWidgetState extends ConsumerState<AuthGuardWidget> {
  final AuthGuardService _authGuardService = AuthGuardService();
  final PinService _pinService = PinService();
  
  bool _isChecking = true;
  bool _isAuthenticated = false;
  bool _needsPin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Vérifier l'authentification de base
      final authState = await _authGuardService.getAuthState();
      
      setState(() {
        _isAuthenticated = authState.isAuthenticated;
        _needsPin = authState.needsPin && widget.requirePin;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _needsPin = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Rediriger vers la connexion si pas authentifié
    if (!_isAuthenticated) {
      return const LoginPage();
    }

    // Demander le PIN si nécessaire
    if (_needsPin) {
      return PinScreen(
        onSuccess: () {
          setState(() {
            _needsPin = false;
          });
        },
        onCancel: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        title: widget.title ?? 'Code PIN requis',
        subtitle: widget.subtitle ?? 'Entrez votre code PIN pour continuer',
      );
    }

    // Afficher le contenu protégé
    return widget.child;
  }
}

/// Widget de protection pour les actions sensibles
class ProtectedActionWidget extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onUnauthorized;
  final String? title;
  final String? subtitle;

  const ProtectedActionWidget({
    super.key,
    required this.child,
    this.onUnauthorized,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: child,
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    final authGuardService = AuthGuardService();
    final pinService = PinService();
    
    // Vérifier l'authentification
    final isAuthenticated = await authGuardService.checkAuthForAction();
    if (!isAuthenticated) {
      onUnauthorized?.call();
      return;
    }

    // Vérifier le PIN si nécessaire
    final isPinEnabled = await pinService.isPinEnabled();
    if (isPinEnabled) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            title: title ?? 'Authentification requise',
            subtitle: subtitle ?? 'Entrez votre code PIN pour continuer',
          ),
        ),
      );
      
      if (result != true) {
        onUnauthorized?.call();
        return;
      }
    }

    // Action autorisée
    onUnauthorized?.call();
  }
}


















