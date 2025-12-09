// lib/core/auth_service.dart
// Service d'authentification selon la documentation API

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'constants.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import 'device_registration_service.dart';
import 'warehouse_type_service.dart';

/// Modèle utilisateur - conforme à l'API Laravel
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? number;
  final String? companyId;
  final DateTime? createdAt;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.number,
    this.companyId,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      number: json['number']?.toString(),
      companyId: json['company_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'number': number,
      'company_id': companyId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// État d'authentification
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final AuthUser? user;
  final String? token;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    AuthUser? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

/// Service d'authentification
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  AuthState _state = AuthState();
  AuthState get state => _state;

  /// Initialiser le service
  Future<void> init() async {
    _apiService.init();
    await _storageService.init();
    
    // Vérifier si l'utilisateur est déjà connecté
    await _loadStoredAuth();
  }

  /// Charger l'authentification stockée
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userJson = prefs.getString(AppConstants.userKey);

      if (token != null && userJson != null) {
        _apiService.setToken(token);
        final user = AuthUser.fromJson(jsonDecode(userJson));

        _state = _state.copyWith(
          isAuthenticated: true,
          user: user,
          token: token,
        );

        print('[AuthService] User loaded from storage: ${user.email}');
      }
    } catch (e) {
      print('[AuthService] Error loading stored auth: $e');
      await logout();
    }
  }

  /// Sauvegarder l'authentification
  Future<void> _saveAuth(AuthUser user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));

      _apiService.setToken(token);

      _state = _state.copyWith(
        isAuthenticated: true,
        user: user,
        token: token,
        error: null,
      );

      print('[AuthService] Auth saved: ${user.email}');
    } catch (e) {
      print('[AuthService] Error saving auth: $e');
      throw Exception('Erreur lors de la sauvegarde de l\'authentification');
    }
  }

  /// Inscription
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[AuthService] ✍️ Tentative d\'inscription...');
      print('[AuthService] 👤 Nom: $name');
      print('[AuthService] 📧 Email: $email');

      _state = _state.copyWith(isLoading: true, error: null);

      print('[AuthService] 🌐 URL: ${AppConstants.authRegisterEndpoint}');
      print('[AuthService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        AppConstants.authRegisterEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      print('[AuthService] 📥 Response status: ${response.statusCode}');
      print('[AuthService] 📥 Response data: ${response.data}');
      print('[AuthService] Response success field: ${response.data['success']}');
      print('[AuthService] Response data field exists: ${response.data['data'] != null}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('[AuthService] Raw user data: ${data['user']}');
        print('[AuthService] Access token présent: ${data['access_token'] != null}');

        final user = AuthUser.fromJson(data['user']);
        final token = data['access_token'] as String;

        print('[AuthService] 💾 Sauvegarde de l\'authentification...');
        await _saveAuth(user, token);

        print('[AuthService] ✅ Inscription réussie!');
        print('[AuthService] 👤 Utilisateur: ${user.name} (${user.email})');
        print('[AuthService] 🆔 User ID: ${user.id}');
        print('═══════════════════════════════════════════════════════');
        return user;
      } else {
        print('[AuthService] ❌ Réponse API invalide');
        print('[AuthService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw Exception(response.data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[AuthService] ❌ ERREUR inscription: $e');
      print('[AuthService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    } finally {
      _state = _state.copyWith(isLoading: false);
    }
  }

  /// Connexion
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[AuthService] 🔐 Tentative de connexion...');
      print('[AuthService] 📧 Email: $email');

      _state = _state.copyWith(isLoading: true, error: null);

      print('[AuthService] 🌐 URL: ${AppConstants.authLoginEndpoint}');
      print('[AuthService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        AppConstants.authLoginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('[AuthService] 📥 Response status: ${response.statusCode}');
      print('[AuthService] 📥 Response data: ${response.data}');
      print('[AuthService] Response success field: ${response.data['success']}');
      print('[AuthService] Response data field exists: ${response.data['data'] != null}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('[AuthService] Raw user data: ${data['user']}');
        print('[AuthService] Access token présent: ${data['access_token'] != null}');

        final user = AuthUser.fromJson(data['user']);
        final token = data['access_token'] as String;

        print('[AuthService] 💾 Sauvegarde de l\'authentification...');
        await _saveAuth(user, token);

        // Vérifier si l'utilisateur a des companies et warehouses
        print('[AuthService] 🏢 Vérification company/warehouse...');
        await _checkAndSetupCompanyWarehouse(user);

        // Enregistrer le device après connexion réussie
        print('[AuthService] 📱 Starting device registration monitoring...');
        // Démarrer l'enregistrement automatique du device en arrière-plan (seulement si pas déjà enregistré)
        print('[AuthService] 📱 Vérification de l\'enregistrement du device...');
        try {
          final deviceRegistrationService = DeviceRegistrationService();
          final isAlreadyRegistered = await deviceRegistrationService.isDeviceRegistered();
          
          if (!isAlreadyRegistered) {
            print('[AuthService] 📱 Device non enregistré, démarrage du monitoring...');
            await deviceRegistrationService.startRegistrationMonitoring();
            print('[AuthService] ✅ Device registration monitoring started');
          } else {
            print('[AuthService] ✅ Device déjà enregistré, pas de monitoring nécessaire');
          }
        } catch (deviceError) {
          print('[AuthService] ⚠️ Erreur lors du démarrage du monitoring device: $deviceError');
          // Ne pas bloquer le login si l'enregistrement du device échoue
        }

        // Récupérer et stocker le type de warehouse en arrière-plan
        print('[AuthService] 📦 Récupération du type de warehouse...');
        _fetchWarehouseTypeInBackground();

        print('[AuthService] ✅ Connexion réussie!');
        print('[AuthService] 👤 Utilisateur: ${user.name} (${user.email})');
        print('[AuthService] 🆔 User ID: ${user.id}');
        print('═══════════════════════════════════════════════════════');
        return user;
      } else {
        print('[AuthService] ❌ Réponse API invalide');
        print('[AuthService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        throw ApiException(
          response.data['message'] ?? 'Erreur lors de la connexion',
          statusCode: response.statusCode ?? 500,
          data: response.data,
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[AuthService] ❌ ERREUR connexion: $e');
      print('[AuthService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }


  /// Récupérer les informations de l'utilisateur connecté
  Future<AuthUser> getMe() async {
    try {
      final response = await _apiService.get(AppConstants.authMeEndpoint);

      if (response.data['success'] == true) {
        final user = AuthUser.fromJson(response.data['data']);

        _state = _state.copyWith(user: user);

        // Mettre à jour le stockage local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));

        print('[AuthService] User info updated: ${user.email}');
        return user;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la récupération des informations');
      }
    } catch (e) {
      print('[AuthService] Error getting user info: $e');
      rethrow;
    }
  }

  /// Rafraîchir le token
  Future<String> refreshToken() async {
    try {
      final response = await _apiService.post(AppConstants.authRefreshEndpoint);
      
      if (response.data['success'] == true) {
        final token = response.data['data']['access_token'] as String;
        
        _apiService.setToken(token);
        _state = _state.copyWith(token: token);
        
        // Mettre à jour le stockage local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        
        print('[AuthService] Token refreshed');
        return token;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors du rafraîchissement du token');
      }
    } catch (e) {
      print('[AuthService] Error refreshing token: $e');
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[AuthService] 🚪 Déconnexion...');

      if (_state.isAuthenticated) {
        print('[AuthService] 👤 Utilisateur: ${_state.user?.email}');
        print('[AuthService] 🌐 URL: ${AppConstants.authLogoutEndpoint}');
        print('[AuthService] 📤 Envoi de la requête POST...');

        // Appeler l'endpoint de déconnexion
        try {
          final response = await _apiService.post(AppConstants.authLogoutEndpoint);
          print('[AuthService] 📥 Response status: ${response.statusCode}');
          print('[AuthService] ✅ Déconnexion API réussie');
        } catch (e) {
          print('[AuthService] ⚠️ Erreur lors de l\'appel API de déconnexion: $e');
          print('[AuthService] 🔄 Continuation de la déconnexion locale...');
          // Continuer même si l'API échoue
        }
      }

      // Nettoyer le stockage local
      print('[AuthService] 🧹 Nettoyage du stockage local...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);

      // Nettoyer l'API service
      print('[AuthService] 🔑 Suppression du token...');
      _apiService.clearToken();

      // Réinitialiser l'état
      _state = AuthState();

      print('[AuthService] ✅ Déconnexion réussie!');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('[AuthService] ❌ ERREUR déconnexion: $e');
      print('[AuthService] 🔄 Forçage de la déconnexion...');
      // Forcer la déconnexion même en cas d'erreur
      _state = AuthState();
      print('[AuthService] ✅ Déconnexion forcée terminée');
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => _state.isAuthenticated;

  /// Obtenir l'utilisateur actuel
  AuthUser? get currentUser => _state.user;

  /// Obtenir le token actuel
  String? get currentToken => _state.token;

  /// Obtenir l'erreur actuelle
  String? get currentError => _state.error;

  /// Vérifier si le service est en cours de chargement
  bool get isLoading => _state.isLoading;

  /// Vérifier et configurer company/warehouse après login
  Future<void> _checkAndSetupCompanyWarehouse(AuthUser user) async {
    try {
      final companyWarehouseService = CompanyWarehouseService();

      // Vérifier si une sélection existe déjà
      final hasSelection = await companyWarehouseService.hasSelection();
      if (hasSelection) {
        print('[AuthService] Company/Warehouse already selected');
        return;
      }

      // Obtenir les companies de l'utilisateur
      final companies = await companyWarehouseService.getUserCompanies();

      if (companies.isEmpty) {
        print('[AuthService] No companies found for user');
        return;
      }

      // Si une seule company, la sélectionner automatiquement
      if (companies.length == 1) {
        final company = companies.first;
        await companyWarehouseService.selectCompany(company.id);

        // Obtenir les warehouses de cette company
        final warehouses = await companyWarehouseService.getCompanyWarehouses(company.id);

        if (warehouses.isNotEmpty) {
          // Si un seul warehouse, le sélectionner automatiquement
          if (warehouses.length == 1) {
            await companyWarehouseService.selectWarehouse(warehouses.first.id);
            print('[AuthService] Auto-selected company and warehouse');
          } else {
            // Plusieurs warehouses, l'utilisateur devra choisir
            print('[AuthService] Multiple warehouses available, user needs to select');
          }
        }
      } else {
        // Plusieurs companies, l'utilisateur devra choisir
        print('[AuthService] Multiple companies available, user needs to select');
      }
    } catch (e) {
      print('[AuthService] Error setting up company/warehouse: $e');
      // Ne pas faire échouer le login pour cette erreur
    }
  }

  /// Récupérer le type de warehouse en arrière-plan
  void _fetchWarehouseTypeInBackground() {
    // Exécuter en arrière-plan sans bloquer le login
    Future.microtask(() async {
      try {
        final warehouseTypeService = WarehouseTypeService();
        final warehouseType = await warehouseTypeService.fetchAndStoreWarehouseType();

        if (warehouseType != null) {
          print('[AuthService] ✅ Warehouse type récupéré: ${warehouseType.displayName}');
        } else {
          print('[AuthService] ⚠️ Aucun type de warehouse disponible');
        }
      } catch (e) {
        print('[AuthService] ⚠️ Erreur récupération warehouse type: $e');
        // Ne pas bloquer l'app si la récupération échoue
      }
    });
  }
}