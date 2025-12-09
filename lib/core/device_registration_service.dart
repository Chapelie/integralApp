// lib/core/device_registration_service.dart
// Service pour l'enregistrement automatique du device au backend

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';

class DeviceRegistrationService {
  static final DeviceRegistrationService _instance = DeviceRegistrationService._internal();
  factory DeviceRegistrationService() => _instance;
  DeviceRegistrationService._internal();

  final _deviceService = DeviceService();
  final _apiService = ApiService();
  final _storageService = StorageService();

  static const String _deviceRegisteredKey = 'device_registered';
  static const String _deviceRegistrationAttemptsKey = 'device_registration_attempts';
  static const String _lastRegistrationAttemptKey = 'last_registration_attempt';
  static const int _maxRegistrationAttempts = 5;
  static const Duration _retryInterval = Duration(minutes: 2); // Retry toutes les 2 minutes
  static const Duration _maxRetryDelay = Duration(minutes: 30); // Max 30 minutes entre tentatives
  static const Duration _pollingInterval = Duration(seconds: 3); // Polling toutes les 3 secondes
  static const Duration _minIntervalBetweenAttempts = Duration(seconds: 5); // Minimum 5 secondes entre tentatives

  Timer? _retryTimer;
  Timer? _pollingTimer;
  bool _isRetrying = false;
  bool _isPolling = false;

  /// Vérifier si le device est déjà enregistré
  Future<bool> isDeviceRegistered() async {
    try {
      final registered = await _storageService.readSetting(_deviceRegisteredKey);
      return registered == 'true';
    } catch (e) {
      print('[DeviceRegistrationService] Error checking registration status: $e');
      return false;
    }
  }

  /// Marquer le device comme enregistré
  Future<void> markDeviceAsRegistered() async {
    try {
      await _storageService.writeSetting(_deviceRegisteredKey, 'true');
      print('[DeviceRegistrationService] Device marked as registered');
    } catch (e) {
      print('[DeviceRegistrationService] Error marking device as registered: $e');
    }
  }

  /// Obtenir le nombre de tentatives d'enregistrement
  Future<int> getRegistrationAttempts() async {
    try {
      final attempts = await _storageService.readSetting(_deviceRegistrationAttemptsKey);
      return int.tryParse(attempts ?? '0') ?? 0;
    } catch (e) {
      print('[DeviceRegistrationService] Error getting registration attempts: $e');
      return 0;
    }
  }

  /// Incrémenter le nombre de tentatives d'enregistrement
  Future<void> incrementRegistrationAttempts() async {
    try {
      final currentAttempts = await getRegistrationAttempts();
      await _storageService.writeSetting(
        _deviceRegistrationAttemptsKey,
        (currentAttempts + 1).toString(),
      );
    } catch (e) {
      print('[DeviceRegistrationService] Error incrementing attempts: $e');
    }
  }

  /// Réinitialiser les tentatives d'enregistrement
  Future<void> resetRegistrationAttempts() async {
    try {
      await _storageService.writeSetting(_deviceRegistrationAttemptsKey, '0');
    } catch (e) {
      print('[DeviceRegistrationService] Error resetting attempts: $e');
    }
  }

  /// Enregistrer le device au backend
  Future<bool> registerDeviceToBackend() async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[DeviceRegistrationService] 📱 Starting device registration...');

      // Vérifier si déjà enregistré
      final isRegistered = await isDeviceRegistered();
      print('[DeviceRegistrationService] 🔍 Is device already registered? $isRegistered');

      if (isRegistered) {
        final backendId = await _storageService.readSetting('backend_device_id');
        print('[DeviceRegistrationService] ✅ Device already registered with backend ID: $backendId');
        print('═══════════════════════════════════════════════════════');
        return true;
      }

      // Obtenir les informations du device
      final deviceInfo = await _deviceService.getDeviceInfo();
      print('[DeviceRegistrationService] 📦 Device info:');
      print('  - deviceId: ${deviceInfo.deviceId}');
      print('  - deviceModel: ${deviceInfo.deviceModel}');
      print('  - deviceOS: ${deviceInfo.deviceOS}');
      print('  - osVersion: ${deviceInfo.osVersion}');

      // Obtenir l'ID de l'utilisateur actuel
      final userId = await _getCurrentUserId();
      print('[DeviceRegistrationService] 👤 User ID: $userId');

      if (userId == null) {
        print('[DeviceRegistrationService] ❌ No user ID available for device registration');
        await incrementRegistrationAttempts();
        print('═══════════════════════════════════════════════════════');
        return false;
      }

      // Obtenir le warehouseId depuis les paramètres de l'utilisateur
      final warehouseId = await _getCurrentWarehouseId();
      print('[DeviceRegistrationService] 🏪 Warehouse ID: $warehouseId');

      if (warehouseId == null) {
        print('[DeviceRegistrationService] ❌ No warehouse ID available for device registration');
        await incrementRegistrationAttempts();
        print('═══════════════════════════════════════════════════════');
        return false;
      }

      // Préparer les données d'enregistrement selon le format attendu par le backend
      final registrationData = {
        'user_id': userId,
        'warehouse_id': warehouseId,
        'status': 'active',
        'last_token': null,
        'last_active': DateTime.now().toIso8601String(),
        'device_id': deviceInfo.deviceId,
        'device_model': deviceInfo.deviceModel,
        'device_os': deviceInfo.deviceOS,
        'os_version': deviceInfo.osVersion,
        'app_version': deviceInfo.appVersion,
      };

      // Envoyer au backend
      print('[DeviceRegistrationService] 🌐 URL: ${AppConstants.deviceRegistrationEndpoint(warehouseId)}');
      print('[DeviceRegistrationService] 📤 Sending registration to backend...');

      final response = await _apiService.post(
        AppConstants.deviceRegistrationEndpoint(warehouseId),
        data: registrationData,
      );

      print('[DeviceRegistrationService] 📥 Response status: ${response.statusCode}');
      print('[DeviceRegistrationService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[DeviceRegistrationService] ✅ Device registered successfully!');

        // Extraire les données du device backend de la réponse
        final responseData = response.data;
        if (responseData != null && responseData['success'] == true && responseData['data'] != null) {
          final deviceData = responseData['data'];
          final backendDeviceId = deviceData['id'];

          print('[DeviceRegistrationService] 💾 Storing device data locally...');

          if (backendDeviceId != null) {
            // Stocker l'ID backend du device
            await _storageService.writeSetting('backend_device_id', backendDeviceId);
            print('[DeviceRegistrationService] 🆔 Backend device ID stored: $backendDeviceId');
          }

          // Stocker les données complètes du device
          await _storageService.writeSetting('device_data', deviceData);
          print('[DeviceRegistrationService] 📦 Complete device data stored');
        }

        await markDeviceAsRegistered();
        await resetRegistrationAttempts();

        // Mettre à jour les headers avec le nouveau backend_device_id
        print('[DeviceRegistrationService] 🔄 Updating API headers with backend device ID...');
        final updatedHeaders = await _deviceService.getDeviceHeaders();
        _apiService.setDeviceHeaders(updatedHeaders);
        print('[DeviceRegistrationService] ✅ API headers updated');

        // Arrêter complètement le retry et le polling
        await _stopRetryTimer();
        await _stopPollingTimer();
        print('[DeviceRegistrationService] ✅ All timers stopped - device registered successfully!');

        print('[DeviceRegistrationService] ✅ Device registration complete!');
        print('═══════════════════════════════════════════════════════');
        return true;
      } else {
        print('[DeviceRegistrationService] ❌ Registration failed with status: ${response.statusCode}');
        await incrementRegistrationAttempts();
        print('═══════════════════════════════════════════════════════');
        return false;
      }
    } catch (e) {
      print('[DeviceRegistrationService] Error registering device: $e');
      await incrementRegistrationAttempts();
      return false;
    }
  }

  /// Essayer d'enregistrer le device avec retry automatique
  /// Continue d'essayer jusqu'à ce que l'enregistrement réussisse
  Future<void> tryRegisterDevice() async {
    try {
      // Vérifier si déjà enregistré
      if (await isDeviceRegistered()) {
        print('[DeviceRegistrationService] Device already registered, skipping');
        return;
      }

      print('[DeviceRegistrationService] Attempting device registration...');

      final success = await registerDeviceToBackend();
      if (success) {
        print('[DeviceRegistrationService] Device registration successful');
        await _stopRetryTimer(); // Arrêter le retry si succès
      } else {
        print('[DeviceRegistrationService] Device registration failed, starting retry timer');
        await _startRetryTimer(); // Démarrer le retry automatique
      }
    } catch (e) {
      print('[DeviceRegistrationService] Error in tryRegisterDevice: $e');
      await _startRetryTimer(); // Démarrer le retry même en cas d'erreur
    }
  }

  /// Vérifier et tenter l'enregistrement du device si nécessaire
  /// Cette méthode est appelée avant chaque requête API importante
  /// pour s'assurer que le device est enregistré
  Future<bool> ensureDeviceRegistered() async {
    try {
      // Vérifier si déjà enregistré
      if (await isDeviceRegistered()) {
        return true;
      }

      print('[DeviceRegistrationService] 🔄 Device not registered, attempting registration...');
      
      // Tenter l'enregistrement immédiatement
      final success = await registerDeviceToBackend();
      if (success) {
        print('[DeviceRegistrationService] ✅ Device registered successfully!');
        return true;
      } else {
        print('[DeviceRegistrationService] ❌ Device registration failed, will retry later');
        // Démarrer le retry automatique en arrière-plan
        await _startRetryTimer();
        return false;
      }
    } catch (e) {
      print('[DeviceRegistrationService] Error ensuring device registration: $e');
      // Démarrer le retry même en cas d'erreur
      await _startRetryTimer();
      return false;
    }
  }

  /// Démarrer le timer de retry automatique
  Future<void> _startRetryTimer() async {
    if (_isRetrying) {
      print('[DeviceRegistrationService] Retry timer already running');
      return;
    }

    _isRetrying = true;
    print('[DeviceRegistrationService] 🔄 Starting automatic retry timer...');

    _retryTimer = Timer.periodic(_retryInterval, (timer) async {
      await _performRetryAttempt();
    });

    // Première tentative immédiate
    await _performRetryAttempt();
  }

  /// Arrêter le timer de retry
  Future<void> _stopRetryTimer() async {
    if (_retryTimer != null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _isRetrying = false;
      print('[DeviceRegistrationService] ✅ Retry timer stopped');
    }
  }

  /// Effectuer une tentative de retry
  Future<void> _performRetryAttempt() async {
    try {
      // Vérifier si déjà enregistré (au cas où)
      if (await isDeviceRegistered()) {
        print('[DeviceRegistrationService] Device registered during retry, stopping timer');
        await _stopRetryTimer();
        return;
      }

      // Vérifier le nombre de tentatives
      final attempts = await getRegistrationAttempts();
      if (attempts >= _maxRegistrationAttempts) {
        print('[DeviceRegistrationService] Max attempts reached ($attempts), stopping retry and starting polling');
        await _stopRetryTimer();
        await _startPollingTimer(); // Démarrer le polling après échec des retries
        return;
      }

      // Vérifier si assez de temps s'est écoulé depuis la dernière tentative
      final lastAttempt = await _getLastRegistrationAttempt();
      if (lastAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
        if (timeSinceLastAttempt < _retryInterval) {
          print('[DeviceRegistrationService] Too soon since last attempt, skipping');
          return;
        }
      }

      print('[DeviceRegistrationService] 🔄 Retry attempt ${attempts + 1}/$_maxRegistrationAttempts');
      
      // Enregistrer l'heure de cette tentative
      await _setLastRegistrationAttempt(DateTime.now());

      final success = await registerDeviceToBackend();
      if (success) {
        print('[DeviceRegistrationService] ✅ Device registration successful on retry!');
        await _stopRetryTimer();
      } else {
        print('[DeviceRegistrationService] ❌ Retry attempt failed, will try again in ${_retryInterval.inMinutes} minutes');
      }
    } catch (e) {
      print('[DeviceRegistrationService] Error in retry attempt: $e');
    }
  }

  /// Obtenir la dernière tentative d'enregistrement
  Future<DateTime?> _getLastRegistrationAttempt() async {
    try {
      final lastAttemptStr = await _storageService.readSetting(_lastRegistrationAttemptKey);
      if (lastAttemptStr != null) {
        return DateTime.parse(lastAttemptStr);
      }
      return null;
    } catch (e) {
      print('[DeviceRegistrationService] Error getting last attempt: $e');
      return null;
    }
  }

  /// Enregistrer la dernière tentative d'enregistrement
  Future<void> _setLastRegistrationAttempt(DateTime dateTime) async {
    try {
      await _storageService.writeSetting(_lastRegistrationAttemptKey, dateTime.toIso8601String());
    } catch (e) {
      print('[DeviceRegistrationService] Error setting last attempt: $e');
    }
  }

  /// Forcer la réinitialisation de l'enregistrement (pour les tests)
  Future<void> resetRegistration() async {
    try {
      await _stopRetryTimer(); // Arrêter le retry en cours
      await _storageService.writeSetting(_deviceRegisteredKey, 'false');
      await _storageService.writeSetting(_deviceRegistrationAttemptsKey, '0');
      await _storageService.writeSetting(_lastRegistrationAttemptKey, '');
      print('[DeviceRegistrationService] Registration reset');
    } catch (e) {
      print('[DeviceRegistrationService] Error resetting registration: $e');
    }
  }

  /// Démarrer le monitoring automatique de l'enregistrement
  /// À appeler au démarrage de l'app pour s'assurer que le device est enregistré
  Future<void> startRegistrationMonitoring() async {
    try {
      print('[DeviceRegistrationService] 🔍 Starting registration monitoring...');
      
      // Vérifier si déjà enregistré
      if (await isDeviceRegistered()) {
        print('[DeviceRegistrationService] ✅ Device already registered, no monitoring needed');
        return;
      }

      // Vérifier si on peut encore retry
      final attempts = await getRegistrationAttempts();
      if (attempts >= _maxRegistrationAttempts) {
        print('[DeviceRegistrationService] ❌ Max attempts reached, starting periodic polling...');
        await _startPollingTimer();
        return;
      }

      // Démarrer le retry automatique
      print('[DeviceRegistrationService] 🔄 Starting automatic retry...');
      await _startRetryTimer();
    } catch (e) {
      print('[DeviceRegistrationService] Error starting monitoring: $e');
    }
  }

  /// Arrêter le monitoring automatique
  Future<void> stopRegistrationMonitoring() async {
    await _stopRetryTimer();
    await _stopPollingTimer();
  }

  /// Démarrer le polling manuellement (pour les tests ou cas spéciaux)
  Future<void> startPolling() async {
    await _startPollingTimer();
  }

  /// Arrêter le polling manuellement
  Future<void> stopPolling() async {
    await _stopPollingTimer();
  }

  /// Démarrer le timer de polling périodique
  /// Vérifie périodiquement si le device est enregistré
  Future<void> _startPollingTimer() async {
    if (_isPolling) {
      print('[DeviceRegistrationService] Polling timer already running');
      return;
    }

    _isPolling = true;
    print('[DeviceRegistrationService] 🔄 Starting periodic polling every ${_pollingInterval.inSeconds} seconds...');

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await _performPollingCheck();
    });

    // Première vérification immédiate
    await _performPollingCheck();
  }

  /// Arrêter le timer de polling
  Future<void> _stopPollingTimer() async {
    if (_pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _isPolling = false;
      print('[DeviceRegistrationService] ✅ Polling timer stopped');
    }
  }

  /// Effectuer une vérification de polling
  Future<void> _performPollingCheck() async {
    try {
      print('[DeviceRegistrationService] 🔍 Performing periodic device registration check...');
      
      // Vérifier si déjà enregistré
      if (await isDeviceRegistered()) {
        print('[DeviceRegistrationService] ✅ Device is registered, continuing polling...');
        return;
      }

      // Vérifier si assez de temps s'est écoulé depuis la dernière tentative
      final lastAttempt = await _getLastRegistrationAttempt();
      if (lastAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
        if (timeSinceLastAttempt < _minIntervalBetweenAttempts) {
          print('[DeviceRegistrationService] Too soon since last attempt (${timeSinceLastAttempt.inSeconds}s), skipping polling check');
          return;
        }
      }

      // Vérifier si on peut encore retry
      final attempts = await getRegistrationAttempts();
      if (attempts >= _maxRegistrationAttempts) {
        print('[DeviceRegistrationService] ❌ Max attempts reached, resetting attempts for polling...');
        await resetRegistrationAttempts();
      }

      print('[DeviceRegistrationService] 🔄 Device not registered, attempting registration...');
      
      // Enregistrer l'heure de cette tentative
      await _setLastRegistrationAttempt(DateTime.now());
      
      // Tenter l'enregistrement
      final success = await registerDeviceToBackend();
      if (success) {
        print('[DeviceRegistrationService] ✅ Device registered successfully during polling!');
        await _stopPollingTimer(); // Arrêter le polling si succès
      } else {
        print('[DeviceRegistrationService] ❌ Device registration failed during polling, will retry in ${_pollingInterval.inSeconds} seconds');
      }
    } catch (e) {
      print('[DeviceRegistrationService] Error in polling check: $e');
    }
  }

  /// Obtenir l'ID de l'utilisateur actuel
  Future<String?> _getCurrentUserId() async {
    try {
      // Essayer de récupérer depuis les paramètres stockés
      final userId = await _storageService.readSetting('user_id');
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }

      // Si pas trouvé, essayer de récupérer depuis les paramètres de l'utilisateur
      final userData = await _storageService.readSetting('user_data');
      if (userData != null) {
        try {
        // Parser les données utilisateur pour extraire user_id
          final userJson = jsonDecode(userData);
          final userId = userJson['id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            print('[DeviceRegistrationService] User ID extracted from user_data: $userId');
            return userId;
          }
        } catch (e) {
          print('[DeviceRegistrationService] Error parsing user_data: $e');
        }
      }

      // Essayer depuis SharedPreferences (méthode AuthService)
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(AppConstants.userKey);
      if (userJsonStr != null) {
        try {
          final userJson = jsonDecode(userJsonStr);
          final userId = userJson['id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            print('[DeviceRegistrationService] User ID extracted from SharedPreferences: $userId');
            return userId;
          }
        } catch (e) {
          print('[DeviceRegistrationService] Error parsing SharedPreferences user data: $e');
        }
      }

      print('[DeviceRegistrationService] No user ID found in any storage location');
      return null;
    } catch (e) {
      print('[DeviceRegistrationService] Error getting user ID: $e');
      return null;
    }
  }

  /// Obtenir l'ID de l'entrepôt actuel
  Future<String?> _getCurrentWarehouseId() async {
    try {
      // Essayer de récupérer depuis la clé correcte (selected_warehouse_id)
      final warehouseId = await _storageService.readSetting('selected_warehouse_id');
      if (warehouseId != null && warehouseId.isNotEmpty) {
        print('[DeviceRegistrationService] Warehouse ID found in selected_warehouse_id: $warehouseId');
        return warehouseId;
      }

      // Essayer de récupérer depuis les paramètres stockés (ancienne clé)
      final warehouseIdOld = await _storageService.readSetting('current_warehouse_id');
      if (warehouseIdOld != null && warehouseIdOld.isNotEmpty) {
        print('[DeviceRegistrationService] Warehouse ID found in current_warehouse_id: $warehouseIdOld');
        return warehouseIdOld;
      }

      // Si pas trouvé, essayer de récupérer depuis les paramètres de l'utilisateur
      final userData = await _storageService.readSetting('user_data');
      if (userData != null) {
        try {
        // Parser les données utilisateur pour extraire warehouse_id
          final userJson = jsonDecode(userData);
          final warehouseId = userJson['warehouse_id']?.toString();
          if (warehouseId != null && warehouseId.isNotEmpty) {
            print('[DeviceRegistrationService] Warehouse ID extracted from user_data: $warehouseId');
            return warehouseId;
          }
        } catch (e) {
          print('[DeviceRegistrationService] Error parsing user_data for warehouse: $e');
        }
      }

      // Essayer depuis SharedPreferences (méthode AuthService)
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(AppConstants.userKey);
      if (userJsonStr != null) {
        try {
          final userJson = jsonDecode(userJsonStr);
          final warehouseId = userJson['warehouse_id']?.toString();
          if (warehouseId != null && warehouseId.isNotEmpty) {
            print('[DeviceRegistrationService] Warehouse ID extracted from SharedPreferences: $warehouseId');
            return warehouseId;
          }
        } catch (e) {
          print('[DeviceRegistrationService] Error parsing SharedPreferences for warehouse: $e');
        }
      }

      print('[DeviceRegistrationService] No warehouse ID found in any storage location');
      return null;
    } catch (e) {
      print('[DeviceRegistrationService] Error getting warehouse ID: $e');
      return null;
    }
  }

  /// Obtenir le statut d'enregistrement
  Future<Map<String, dynamic>> getRegistrationStatus() async {
    try {
      final isRegistered = await isDeviceRegistered();
      final attempts = await getRegistrationAttempts();
      final deviceInfo = await _deviceService.getDeviceInfo();
      final lastAttempt = await _getLastRegistrationAttempt();
      final backendId = await _storageService.readSetting('backend_device_id');

      return {
        'isRegistered': isRegistered,
        'attempts': attempts,
        'maxAttempts': _maxRegistrationAttempts,
        'deviceId': deviceInfo.deviceId,
        'backendDeviceId': backendId,
        'canRetry': attempts < _maxRegistrationAttempts,
        'isRetrying': _isRetrying,
        'isPolling': _isPolling,
        'pollingInterval': _pollingInterval.inMinutes,
        'lastAttempt': lastAttempt?.toIso8601String(),
        'nextRetryIn': lastAttempt != null 
            ? _retryInterval.inMinutes - DateTime.now().difference(lastAttempt).inMinutes
            : 0,
      };
    } catch (e) {
      print('[DeviceRegistrationService] Error getting status: $e');
      return {
        'isRegistered': false,
        'attempts': 0,
        'maxAttempts': _maxRegistrationAttempts,
        'deviceId': 'unknown',
        'backendDeviceId': null,
        'canRetry': true,
        'isRetrying': false,
        'isPolling': false,
        'pollingInterval': _pollingInterval.inMinutes,
        'lastAttempt': null,
        'nextRetryIn': 0,
      };
    }
  }

  /// Méthode de debug pour simuler un warehouse_id (pour les tests)
  Future<void> setDebugWarehouseId(String warehouseId) async {
    try {
      await _storageService.writeSetting('selected_warehouse_id', warehouseId);
      print('[DeviceRegistrationService] 🧪 Debug warehouse ID set: $warehouseId');
    } catch (e) {
      print('[DeviceRegistrationService] Error setting debug warehouse ID: $e');
    }
  }
}


