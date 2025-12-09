// lib/core/device_service.dart
// Singleton device service for device identification and registration
// Manages device ID generation, device info retrieval, and API registration

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';
import 'device_registration_service.dart';
import 'storage_service.dart';

/// Device information model
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String deviceOS;
  final String osVersion;
  final String appVersion;

  DeviceInfo({
    required this.deviceId,
    required this.deviceModel,
    required this.deviceOS,
    required this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_model': deviceModel,
        'device_os': deviceOS,
        'os_version': osVersion,
        'app_version': appVersion,
      };
}

/// Device service for managing device identification
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _deviceInfoPlugin = DeviceInfoPlugin();
  final _uuid = const Uuid();

  String? _cachedDeviceId;
  DeviceInfo? _cachedDeviceInfo;

  /// Initialize device service and generate device ID if needed
  Future<void> init() async {
    try {
      print('[DeviceService] Initializing...');

      // Check if device ID exists in secure storage
      _cachedDeviceId = await _secureStorage.read(key: AppConstants.deviceIdKey);

      if (_cachedDeviceId == null || _cachedDeviceId!.isEmpty) {
        // Generate new device ID
        _cachedDeviceId = _uuid.v4();
        await _secureStorage.write(
          key: AppConstants.deviceIdKey,
          value: _cachedDeviceId,
        );
        print('[DeviceService] Generated new device ID: $_cachedDeviceId');
      } else {
        print('[DeviceService] Loaded existing device ID: $_cachedDeviceId');
      }

      // Cache device info
      _cachedDeviceInfo = await getDeviceInfo();

      print('[DeviceService] Initialized successfully');
    } catch (e) {
      print('[DeviceService] Initialization error: $e');
      rethrow;
    }
  }

  /// Get device ID
  String get deviceId {
    if (_cachedDeviceId == null) {
      throw Exception('DeviceService not initialized');
    }
    return _cachedDeviceId!;
  }

  /// Get detailed device information
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      if (_cachedDeviceInfo != null) {
        return _cachedDeviceInfo!;
      }

      String deviceModel = 'Unknown';
      String deviceOS = 'Unknown';
      String osVersion = 'Unknown';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        deviceOS = 'Android';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.model;
        deviceOS = 'iOS';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceModel = windowsInfo.computerName;
        deviceOS = 'Windows';
        osVersion = windowsInfo.productName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceModel = linuxInfo.name;
        deviceOS = 'Linux';
        osVersion = linuxInfo.version ?? 'Unknown';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        deviceModel = macInfo.model;
        deviceOS = 'macOS';
        osVersion = macInfo.osRelease;
      }

      final deviceInfo = DeviceInfo(
        deviceId: deviceId,
        deviceModel: deviceModel,
        deviceOS: deviceOS,
        osVersion: osVersion,
        appVersion: AppConstants.appVersion,
      );

      print('[DeviceService] Device Info: ${deviceInfo.toJson()}');
      return deviceInfo;
    } catch (e) {
      print('[DeviceService] Error getting device info: $e');
      rethrow;
    }
  }

  /// Register device with API server
  /// If network is unavailable, enqueues registration for later sync
  Future<bool> registerDevice() async {
    try {
      print('[DeviceService] Registering device...');

      // Utiliser le service d'enregistrement dédié
      final deviceRegistrationService = DeviceRegistrationService();
      return await deviceRegistrationService.registerDeviceToBackend();
    } catch (e) {
      print('[DeviceService] Error registering device: $e');
      return false;
    }
  }

  /// Get device headers for API requests
  Future<Map<String, String>> getDeviceHeaders() async {
    try {
      final deviceInfo = await getDeviceInfo();

      // Get backend device ID (used by middleware for verification)
      final backendDeviceId = await getBackendDeviceId();

      final localIdDisplay = deviceInfo.deviceId.length > 20
          ? '${deviceInfo.deviceId.substring(0, 20)}...'
          : deviceInfo.deviceId;
      final backendIdDisplay = backendDeviceId != null
          ? (backendDeviceId.length > 20 ? '${backendDeviceId.substring(0, 20)}...' : backendDeviceId)
          : 'NOT YET REGISTERED';

      print('');
      print('┌─────────────────────────────────────────────────────┐');
      print('│ [DeviceService] 🔍 Building Device Headers         │');
      print('├─────────────────────────────────────────────────────┤');
      print('│ Local Device ID:   $localIdDisplay');
      print('│ Backend Device ID: $backendIdDisplay');
      print('│ Using for X-Device-Id: ${backendDeviceId != null ? 'BACKEND ID ✅' : 'LOCAL ID (fallback) ⚠️'}');
      print('└─────────────────────────────────────────────────────┘');
      print('');

      return {
        // Backend device ID (Laravel 'id' field) - used by middleware
        'X-Device-Id': backendDeviceId ?? deviceInfo.deviceId,
        // Local device UUID (Laravel 'device_id' field) - used in requests
        'X-Local-Device-Id': deviceInfo.deviceId,
        'X-Device-Model': deviceInfo.deviceModel,
        'X-Device-OS': '${deviceInfo.deviceOS} ${deviceInfo.osVersion}',
        'X-App-Version': deviceInfo.appVersion,
      };
    } catch (e) {
      print('[DeviceService] Error getting device headers: $e');
      return {};
    }
  }

  /// Reset device ID (for testing or device transfer)
  Future<void> resetDeviceId() async {
    try {
      print('[DeviceService] Resetting device ID...');

      await _secureStorage.delete(key: AppConstants.deviceIdKey);
      _cachedDeviceId = null;
      _cachedDeviceInfo = null;

      // Reinitialize
      await init();

      print('[DeviceService] Device ID reset successfully');
    } catch (e) {
      print('[DeviceService] Error resetting device ID: $e');
      rethrow;
    }
  }

  /// Clear cached data
  void clearCache() {
    _cachedDeviceInfo = null;
    print('[DeviceService] Cache cleared');
  }

  /// Get backend device ID (the ID returned by the server after registration)
  /// Returns the UUID generated by the backend, not the local device UUID
  Future<String?> getBackendDeviceId() async {
    try {
      final storageService = StorageService();
      final backendDeviceId = await storageService.readSetting('backend_device_id');

      if (backendDeviceId != null && backendDeviceId.isNotEmpty) {
        print('[DeviceService] Backend device ID found: $backendDeviceId');
        return backendDeviceId;
      }

      print('[DeviceService] No backend device ID found - device may not be registered yet');
      return null;
    } catch (e) {
      print('[DeviceService] Error getting backend device ID: $e');
      return null;
    }
  }

  /// Get backend device ID or fallback to local device ID
  /// Use this method when you need a device ID for API requests
  Future<String> getDeviceIdForApi() async {
    try {
      // Try to get backend device ID first
      final backendId = await getBackendDeviceId();
      if (backendId != null) {
        return backendId;
      }

      // Fallback to local device ID
      print('[DeviceService] Using local device ID as fallback');
      return deviceId;
    } catch (e) {
      print('[DeviceService] Error getting device ID for API: $e');
      return deviceId;
    }
  }
}
