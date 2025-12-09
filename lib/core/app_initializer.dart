// lib/core/app_initializer.dart
// Application initializer for IntegralPOS
// Handles initialization of all core services in the correct order

import 'services.dart';

/// Application initializer
class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize all core services
  static Future<void> init() async {
    if (_isInitialized) {
      print('[AppInitializer] Already initialized');
      return;
    }

    print('[AppInitializer] Starting initialization...');

    try {
      // 1. Initialize storage service (required by most other services)
      print('[AppInitializer] Step 1/6: Initializing StorageService...');
      await StorageService().init();

      // 2. Initialize device service
      print('[AppInitializer] Step 2/6: Initializing DeviceService...');
      await DeviceService().init();

      // 3. Initialize API service
      print('[AppInitializer] Step 3/6: Initializing ApiService...');
      ApiService().init();

      // Set device headers
      final deviceHeaders = await DeviceService().getDeviceHeaders();
      ApiService().setDeviceHeaders(deviceHeaders);

      // 4. Initialize business configuration
      print('[AppInitializer] Step 4/6: Initializing BusinessConfig...');
      await BusinessConfig().init();

      // 5. Check authentication state
      print('[AppInitializer] Step 5/6: Checking authentication...');
      final isAuthenticated = AuthService().isAuthenticated;
      if (isAuthenticated) {
        print('[AppInitializer] User is authenticated');
      } else {
        print('[AppInitializer] User is not authenticated');
      }

      _isInitialized = true;
      print('[AppInitializer] Initialization completed successfully');
    } catch (e) {
      print('[AppInitializer] Initialization failed: $e');
      rethrow;
    }
  }

  /// Dispose all services
  static Future<void> dispose() async {
    print('[AppInitializer] Disposing services...');

    try {
      SyncService().dispose();
      await StorageService().dispose();

      _isInitialized = false;
      print('[AppInitializer] Services disposed');
    } catch (e) {
      print('[AppInitializer] Error disposing services: $e');
    }
  }

  /// Check if app is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
  }
}
