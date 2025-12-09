// auth_provider.dart
// Provider for authentication management
// Handles user login, logout, and authentication state

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/auth_service.dart';
import '../core/company_warehouse_selection_service.dart';

part 'auth_provider.g.dart';

// Auth State
class AuthProviderState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthProviderState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthProviderState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthProviderState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  final AuthService _authService = AuthService();

  @override
  AuthProviderState build() {
    print('[AuthProvider] 🏗️ build() appelé');
    
    // Initialize auth service
    print('[AuthProvider] 🔧 Initialisation de _authService...');
    _authService.init();
    print('[AuthProvider] ✅ _authService initialisé');
    
    // Check auth status asynchronously
    ref.onDispose(() {
      print('[AuthProvider] 🧹 Nettoyage du provider');
    });
    
    Future.microtask(() {
      print('[AuthProvider] 🔄 Future.microtask exécuté');
      if (ref.mounted) {
        print('[AuthProvider] ✅ Widget monté, appel de checkAuth()...');
        checkAuth();
      } else {
        print('[AuthProvider] ⚠️ Widget non monté, abandon checkAuth');
      }
    });
    
    print('[AuthProvider] 📦 Retour de build() avec AuthProviderState initial');
    return AuthProviderState();
  }

  // Login with username and PIN
  Future<void> login(String username, String pin) async {
    if (!ref.mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(email: username, password: pin);
      if (!ref.mounted) return;
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  // Login with company/warehouse selection
  Future<bool> loginWithSelection(String username, String pin, BuildContext context) async {
    if (!ref.mounted) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(email: username, password: pin);
      if (!ref.mounted) return false;
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );

      print('[AuthProvider] Login successful, checking company/warehouse selection...');

      // Vérifier si l'utilisateur a déjà une sélection
      final selectionService = CompanyWarehouseSelectionService();
      final hasExistingSelection = await selectionService.hasExistingSelection();
      
      print('[AuthProvider] hasExistingSelection: $hasExistingSelection');
      
      if (hasExistingSelection) {
        print('[AuthProvider] User has existing selection, proceeding to app');
        return true;
      } else {
        print('[AuthProvider] No existing selection, redirecting to config page');
        // Rediriger vers la page de configuration
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/company-warehouse-config');
        }
        return false; // Retourner false car on redirige
      }
    } catch (e) {
      if (!ref.mounted) return false;
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
      return false;
    }
  }

  // Set user directly (for testing without API)
  void setUser(AuthUser user) {
    state = state.copyWith(
      user: user,
      isLoading: false,
      isAuthenticated: true,
      error: null,
    );
  }

  // Logout
  Future<void> logout(BuildContext? context) async {
    try {
      // Vérifier si le provider est encore monté
      if (!ref.mounted) {
        print('[AuthProvider] Provider disposed, skipping logout');
        return;
      }
      
      await _authService.logout();
      
      // Vérifier à nouveau si le provider est encore monté avant de modifier l'état
      if (!ref.mounted) {
        print('[AuthProvider] Provider disposed during logout, skipping state update');
        return;
      }
      
      state = AuthProviderState();
      
      // Rediriger vers la page de login après déconnexion
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Vérifier si le provider est encore monté avant de modifier l'état
      if (!ref.mounted) {
        print('[AuthProvider] Provider disposed during logout error, skipping state update');
        return;
      }
      
      state = state.copyWith(error: e.toString());
      
      // Rediriger vers la page de login même en cas d'erreur
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  // Check authentication status
  Future<void> checkAuth() async {
    print('[AuthProvider] 🔍 checkAuth appelé');
    
    if (!ref.mounted) {
      print('[AuthProvider] ⚠️ Widget non monté, abandon');
      return;
    }
    
    print('[AuthProvider] 📊 Mise à jour du state (isLoading=true)...');
    state = state.copyWith(isLoading: true);

    try {
      print('[AuthProvider] 👤 Récupération de currentUser...');
      final user = _authService.currentUser;
      print('[AuthProvider] 👤 User: ${user?.email ?? 'null'}');
      
      if (!ref.mounted) {
        print('[AuthProvider] ⚠️ Widget non monté pendant checkAuth, abandon');
        return;
      }
      
      print('[AuthProvider] 📊 Mise à jour du state final...');
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: user != null,
      );
      print('[AuthProvider] ✅ checkAuth terminé avec succès');
    } catch (e, stackTrace) {
      print('[AuthProvider] ❌ ERREUR dans checkAuth: $e');
      print('[AuthProvider] Stack trace: $stackTrace');
      
      if (!ref.mounted) {
        print('[AuthProvider] ⚠️ Widget non monté pendant l\'erreur, abandon');
        return;
      }
      
      print('[AuthProvider] 📊 Mise à jour du state avec l\'erreur...');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
    
    print('[AuthProvider] 🔚 FIN checkAuth');
  }
}
