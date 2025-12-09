// lib/core/sync_service.dart
// Service de synchronisation avec le backend selon la documentation API

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'constants.dart';
import 'storage_service.dart';
import 'device_registration_service.dart';
import 'device_service.dart';
import 'image_service.dart';
import 'auth_service.dart';

/// État de synchronisation
class SyncState {
  final bool isSyncing;
  final bool isOnline;
  final String? currentSession;
  final double progress;
  final String? status;
  final String? error;
  final DateTime? lastSync;
  final Map<String, int> stats;
  final int pendingCount;

  SyncState({
    this.isSyncing = false,
    this.isOnline = false,
    this.currentSession,
    this.progress = 0.0,
    this.status,
    this.error,
    this.lastSync,
    this.stats = const {},
    this.pendingCount = 0,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isOnline,
    String? currentSession,
    double? progress,
    String? status,
    String? error,
    DateTime? lastSync,
    Map<String, int>? stats,
    int? pendingCount,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      currentSession: currentSession ?? this.currentSession,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error,
      lastSync: lastSync ?? this.lastSync,
      stats: stats ?? this.stats,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

/// Service de synchronisation
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final ImageService _imageService = ImageService();
  
  StreamController<SyncState>? _syncController;
  StreamSubscription? _syncStream;
  Timer? _heartbeatTimer;

  /// Démarrer une session de synchronisation
  Future<String> startSyncSession() async {
    try {
      print('[SyncService] Starting sync session...');
      
      // Obtenir le device_id pour l'envoyer au backend (backend_device_id si disponible)
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceIdForApi();
      print('[SyncService] Device ID (API format): $deviceId');
      
      // Préparer les données pour la requête
      final syncData = {
        'device_id': deviceId,
      };
      
      print('[SyncService] 📤 Sync data: $syncData');
      
      final response = await _apiService.post(
        AppConstants.syncStartEndpoint,
        data: syncData,
      );
      
      print('[SyncService] 📥 Response status: ${response.statusCode}');
      print('[SyncService] 📥 Response data: ${response.data}');
      
      if (response.data['success'] == true) {
        final sessionId = response.data['data']['session_id'] as String;
        print('[SyncService] Sync session started: $sessionId');
        return sessionId;
      } else {
        throw Exception('Failed to start sync session: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error starting sync session: $e');
      rethrow;
    }
  }

  /// Suivre la progression de synchronisation via SSE
  Stream<SyncState> watchSyncProgress(String sessionId) {
    _syncController ??= StreamController<SyncState>.broadcast();
    
    // Simuler le stream SSE (en réalité, vous utiliseriez un package SSE)
    _syncStream = Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        final response = await _apiService.get(AppConstants.syncStatusEndpoint(sessionId));
        
        if (response.data['success'] == true) {
          final data = response.data['data'];
          return SyncState(
            isSyncing: data['is_syncing'] ?? false,
            isOnline: true,
            currentSession: sessionId,
            progress: (data['progress'] ?? 0.0).toDouble(),
            status: data['status'],
            lastSync: data['last_sync'] != null ? DateTime.parse(data['last_sync']) : null,
            stats: Map<String, int>.from(data['stats'] ?? {}),
          );
        } else {
          return SyncState(
            isOnline: false,
            error: response.data['message'],
          );
        }
      } catch (e) {
        return SyncState(
          isOnline: false,
          error: e.toString(),
        );
      }
    }).listen((state) {
      _syncController?.add(state);
    });

    return _syncController!.stream;
  }

  /// Upload des changements client vers serveur
  Future<Map<String, dynamic>> pushChanges() async {
    try {
      print('[SyncService] Pushing changes to server...');
      
      // Récupérer les données en attente de synchronisation
      final pendingSales = _storageService.getPendingSales();
      final syncQueue = _storageService.getSyncQueue();
      
      final payload = {
        'sales': pendingSales,
        'queue': syncQueue,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.post(
        AppConstants.syncPushEndpoint,
        data: payload,
      );

      if (response.data['success'] == true) {
        print('[SyncService] Changes pushed successfully');
        return response.data['data'];
      } else {
        throw Exception('Failed to push changes: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error pushing changes: $e');
      rethrow;
    }
  }

  /// Download des changements serveur vers client
  Future<Map<String, dynamic>> pullChanges() async {
    try {
      print('[SyncService] Pulling changes from server...');
      
      final response = await _apiService.post(AppConstants.syncPullEndpoint);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('[SyncService] Changes pulled successfully');
        
        // Appliquer les changements localement
        await _applyPulledChanges(data);
        
        return data;
      } else {
        throw Exception('Failed to pull changes: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error pulling changes: $e');
      rethrow;
    }
  }

  /// Appliquer les changements téléchargés
  Future<void> _applyPulledChanges(Map<String, dynamic> data) async {
    try {
      // Mettre à jour les produits
      if (data['products'] != null) {
        for (final productData in data['products']) {
          await _storageService.saveProduct(productData);
        }
      }

      // Mettre à jour les clients
      if (data['customers'] != null) {
        for (final customerData in data['customers']) {
          await _storageService.saveCustomer(customerData);
        }
      }

      // Mettre à jour les ventes
      if (data['sales'] != null) {
        for (final saleData in data['sales']) {
          await _storageService.saveSale(saleData);
        }
      }

      // Mettre à jour les caisses
      if (data['cash_registers'] != null) {
        for (final cashRegisterData in data['cash_registers']) {
          await _storageService.saveCashRegister(cashRegisterData);
        }
      }

      print('[SyncService] Pulled changes applied successfully');
    } catch (e) {
      print('[SyncService] Error applying pulled changes: $e');
      rethrow;
    }
  }

  /// Synchronisation complète avec priorité POS
  Future<void> fullSync() async {
    try {
      print('[SyncService] Starting smart sync with POS priority...');
      
      // Enregistrer le device d'abord
      await _registerDeviceIfNeeded();
      
      // Démarrer la session
      final sessionId = await startSyncSession();
      
      // Suivre la progression
      watchSyncProgress(sessionId);
      
      // 1. PRIORITÉ POS : Envoyer d'abord les données créées/modifiées localement
      await _syncLocalDataToServer();
      
      // 2. Récupérer ensuite les données du serveur
      await pullChanges();
      
      // 3. Nettoyer les images orphelines
      await _cleanupOrphanedImages();
      
      // Marquer la synchronisation comme terminée
      await _storageService.setLastSyncTime(DateTime.now());
      
      print('[SyncService] Smart sync completed successfully');
    } catch (e) {
      print('[SyncService] Smart sync failed: $e');
      rethrow;
    }
  }

  /// Synchronisation forcée complète
  Future<void> forceFullSync() async {
    try {
      print('[SyncService] Starting forced full sync...');
      
      // Obtenir le device_id pour l'envoyer au backend (backend_device_id si disponible)
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceIdForApi();
      print('[SyncService] Device ID (API format): $deviceId');
      
      // Préparer les données pour la requête
      final syncData = {
        'device_id': deviceId,
      };
      
      print('[SyncService] 📤 Sync data: $syncData');
      
      final response = await _apiService.post(
        AppConstants.syncForceFullEndpoint,
        data: syncData,
      );
      
      print('[SyncService] 📥 Response status: ${response.statusCode}');
      print('[SyncService] 📥 Response data: ${response.data}');
      
      if (response.data['success'] == true) {
        print('[SyncService] Forced full sync completed');
      } else {
        throw Exception('Failed to force full sync: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error in forced full sync: $e');
      rethrow;
    }
  }

  /// Récupérer les conflits de synchronisation
  Future<List<Map<String, dynamic>>> getConflicts() async {
    try {
      final response = await _apiService.get(AppConstants.syncConflictsEndpoint);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to get conflicts: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error getting conflicts: $e');
      rethrow;
    }
  }

  /// Résoudre un conflit
  Future<void> resolveConflict(String conflictId, Map<String, dynamic> resolution) async {
    try {
      final response = await _apiService.post(
        AppConstants.resolveConflictEndpoint(conflictId),
        data: resolution,
      );
      
      if (response.data['success'] == true) {
        print('[SyncService] Conflict resolved: $conflictId');
      } else {
        throw Exception('Failed to resolve conflict: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error resolving conflict: $e');
      rethrow;
    }
  }

  /// Récupérer les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final response = await _apiService.get(AppConstants.syncStatsEndpoint);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to get sync stats: ${response.data['message']}');
      }
    } catch (e) {
      print('[SyncService] Error getting sync stats: $e');
      rethrow;
    }
  }

  /// Vérifier la connectivité
  Future<bool> checkConnectivity() async {
    try {
      await _apiService.get(AppConstants.authMeEndpoint);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Démarrer le monitoring de connectivité
  void startConnectivityMonitoring() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final isOnline = await checkConnectivity();
      _syncController?.add(SyncState(isOnline: isOnline));
    });
  }

  /// Arrêter le monitoring de connectivité
  void stopConnectivityMonitoring() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Obtenir le nombre d'éléments en attente de synchronisation
  Future<int> getPendingCount() async {
    try {
      final storageService = StorageService();
      final queue = await storageService.getSyncQueue();
      return queue.length;
    } catch (e) {
      print('[SyncService] Error getting pending count: $e');
      return 0;
    }
  }

  /// Enregistrer le device si nécessaire
  /// Only attempts registration if user is authenticated
  Future<void> _registerDeviceIfNeeded() async {
    try {
      // Vérifier si l'utilisateur est connecté
      if (!AuthService().isAuthenticated) {
        print('[SyncService] User not authenticated - skipping device registration');
        return;
      }

      print('[SyncService] User authenticated - attempting device registration');
      final deviceRegistrationService = DeviceRegistrationService();
      await deviceRegistrationService.tryRegisterDevice();
    } catch (e) {
      print('[SyncService] Error registering device: $e');
      // Ne pas faire échouer la synchronisation si l'enregistrement du device échoue
    }
  }

  /// Synchroniser les données locales vers le serveur (PRIORITÉ POS)
  Future<void> _syncLocalDataToServer() async {
    try {
      print('[SyncService] Syncing local data to server (POS priority)...');
      
      // 1. Envoyer les produits créés/modifiés localement
      await _syncLocalProductsToServer();
      
      // 2. Envoyer les ventes en attente
      await pushChanges();
      
      print('[SyncService] Local data synced to server successfully');
    } catch (e) {
      print('[SyncService] Error syncing local data to server: $e');
      // Ne pas faire échouer la synchronisation complète
    }
  }

  /// Synchroniser les produits locaux vers le serveur
  Future<void> _syncLocalProductsToServer() async {
    try {
      print('[SyncService] Syncing local products to server...');
      
      // Récupérer tous les produits locaux
      final localProducts = _storageService.getProducts();
      
      for (final productData in localProducts) {
        try {
          // Vérifier si le produit a été créé/modifié localement
          if (_isProductModifiedLocally(productData)) {
            // Envoyer le produit vers le serveur
            await _sendProductToServer(productData);
            
            // Télécharger l'image si nécessaire
            if (productData['imageUrl'] != null && 
                productData['imageUrl'].toString().startsWith('http')) {
              await _downloadProductImage(productData);
            }
            
            print('[SyncService] Product synced to server: ${productData['name']}');
          }
        } catch (e) {
          print('[SyncService] Error syncing product ${productData['name']}: $e');
        }
      }
    } catch (e) {
      print('[SyncService] Error in local products sync: $e');
    }
  }

  /// Envoyer un produit vers le serveur
  Future<void> _sendProductToServer(Map<String, dynamic> productData) async {
    try {
      // TODO: Implémenter l'API pour envoyer un produit
      // final response = await _apiService.post(
      //   AppConstants.productsEndpoint(warehouseId),
      //   data: productData,
      // );
      
      print('[SyncService] Sending product to server: ${productData['name']}');
    } catch (e) {
      print('[SyncService] Error sending product to server: $e');
      rethrow;
    }
  }

  /// Télécharger l'image d'un produit
  Future<void> _downloadProductImage(Map<String, dynamic> productData) async {
    try {
      final imageUrl = productData['imageUrl']?.toString();
      final productId = productData['id']?.toString();
      
      if (imageUrl != null && productId != null && imageUrl.startsWith('http')) {
        final imagePath = await _imageService.downloadAndSaveImage(imageUrl, productId);
        if (imagePath != null) {
          // Mettre à jour le produit avec le chemin local
          productData['imageUrl'] = imagePath;
          await _storageService.saveProduct(productData);
          print('[SyncService] Product image downloaded: $imagePath');
        }
      }
    } catch (e) {
      print('[SyncService] Error downloading product image: $e');
    }
  }

  /// Vérifier si un produit a été modifié localement
  bool _isProductModifiedLocally(Map<String, dynamic> productData) {
    // TODO: Implémenter la logique pour détecter les modifications locales
    // Par exemple, vérifier si isSynced est false ou si syncedAt est null
    return true; // Pour l'instant, on considère que tous les produits sont modifiés
  }

  /// Nettoyer les images orphelines
  Future<void> _cleanupOrphanedImages() async {
    try {
      print('[SyncService] Cleaning up orphaned images...');
      
      // Récupérer toutes les URLs d'images utilisées
      final products = _storageService.getProducts();
      final usedImageUrls = products
          .where((data) => data['imageUrl'] != null)
          .map((data) => data['imageUrl'].toString())
          .toList();
      
      await _imageService.cleanupOrphanedImages(usedImageUrls);
      print('[SyncService] Orphaned images cleaned up');
    } catch (e) {
      print('[SyncService] Error cleaning up images: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _syncStream?.cancel();
    _syncController?.close();
    stopConnectivityMonitoring();
  }
}

// Les providers Riverpod seront définis dans un fichier séparé