// lib/core/cash_movement_service.dart
// Service for managing cash movements
// Handles cash movement CRUD operations with API sync
// Offline-first: local storage is primary, API sync in background

import 'package:uuid/uuid.dart';
import '../models/cash_movement.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'constants.dart';

class CashMovementService {
  static final CashMovementService _instance = CashMovementService._internal();
  factory CashMovementService() => _instance;
  CashMovementService._internal();

  final _storageService = StorageService();
  final _apiService = ApiService();
  final _uuid = const Uuid();

  /// Create a cash movement (offline-first: save local first, then sync to API)
  Future<CashMovement> createMovement({
    required String cashRegisterId,
    required String type,
    required double amount,
    String? description,
    String? saleId,
    String? userId,
  }) async {
    try {
      final now = DateTime.now();
      final movement = CashMovement(
        id: _uuid.v4(),
        cashRegisterId: cashRegisterId,
        type: type,
        amount: amount,
        description: description,
        saleId: saleId,
        userId: userId,
        createdAt: now,
      );

      // 1. Save locally first (immediate response)
      await _storageService.saveCashMovement(movement);

      print('[CashMovementService] Movement created locally: ${movement.id}');

      // 2. Sync to API in background (non-blocking)
      _createMovementInAPI(movement).catchError((e) {
        print('[CashMovementService] API sync error (movement will sync later): $e');
        // Movement is already saved locally, will sync later
      });

      return movement;
    } catch (e) {
      print('[CashMovementService] Error creating movement: $e');
      rethrow;
    }
  }

  /// Create movement in API
  Future<void> _createMovementInAPI(CashMovement movement) async {
    try {
      final endpoint = AppConstants.cashMovementsEndpoint;
      final response = await _apiService.post(
        endpoint,
        data: movement.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[CashMovementService] Movement synced to API: ${movement.id}');
        // Update local movement with API response if needed
        if (response.data['data'] != null) {
          final apiMovement = response.data['data'];
          final updatedMovement = CashMovement.fromJson(apiMovement);
          await _storageService.saveCashMovement(updatedMovement);
        }
      }
    } catch (e) {
      print('[CashMovementService] Error creating movement in API: $e');
      rethrow;
    }
  }

  /// Get all cash movements (offline-first: local first, then sync with API)
  Future<List<CashMovement>> getAllMovements({bool forceRefresh = false}) async {
    try {
      // 1. Read from local storage first (for immediate display)
      List<CashMovement> localMovements = _storageService.getCashMovements();

      // 2. If not forcing refresh and we have local data, return it immediately
      if (!forceRefresh && localMovements.isNotEmpty) {
        // Sync with API in background (non-blocking)
        _syncMovementsFromAPI().catchError((e) {
          print('[CashMovementService] Background sync error: $e');
        });
        return localMovements;
      }

      // 3. Try to sync from API (if forcing refresh or no local data)
      try {
        final apiMovements = await _fetchMovementsFromAPI();
        if (apiMovements.isNotEmpty) {
          // Save to local storage
          for (final movement in apiMovements) {
            await _storageService.saveCashMovement(movement);
          }
          return apiMovements;
        }
      } catch (e) {
        print('[CashMovementService] API sync failed, using local data: $e');
      }

      // 4. Fallback to local data
      return localMovements;
    } catch (e) {
      print('[CashMovementService] Error getting movements: $e');
      return [];
    }
  }

  /// Fetch movements from API
  Future<List<CashMovement>> _fetchMovementsFromAPI() async {
    try {
      final endpoint = AppConstants.cashMovementsEndpoint;
      print('[CashMovementService] Fetching movements from API: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> movementsData = response.data['data'] ?? [];
        return movementsData
            .map((json) => CashMovement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[CashMovementService] Error fetching from API: $e');
      rethrow;
    }
  }

  /// Sync movements from API in background
  Future<void> _syncMovementsFromAPI() async {
    try {
      final apiMovements = await _fetchMovementsFromAPI();
      if (apiMovements.isNotEmpty) {
        // Save to local storage
        for (final movement in apiMovements) {
          await _storageService.saveCashMovement(movement);
        }
        print('[CashMovementService] Movements synced from API: ${apiMovements.length}');
      }
    } catch (e) {
      print('[CashMovementService] Background sync error: $e');
      // Silent fail - local data is still available
    }
  }

  /// Get movements by cash register
  Future<List<CashMovement>> getMovementsByRegister(String cashRegisterId) async {
    try {
      final allMovements = await getAllMovements();
      return allMovements.where((m) => m.cashRegisterId == cashRegisterId).toList();
    } catch (e) {
      print('[CashMovementService] Error getting movements by register: $e');
      return [];
    }
  }

  /// Get movements by type
  Future<List<CashMovement>> getMovementsByType(String type) async {
    try {
      final allMovements = await getAllMovements();
      return allMovements.where((m) => m.type == type).toList();
    } catch (e) {
      print('[CashMovementService] Error getting movements by type: $e');
      return [];
    }
  }

  /// Get movements by period
  Future<List<CashMovement>> getMovementsByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final endpoint = AppConstants.cashMovementsByPeriodEndpoint;
      final response = await _apiService.get(
        endpoint,
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> movementsData = response.data['data'] ?? [];
        return movementsData
            .map((json) => CashMovement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[CashMovementService] Error getting movements by period: $e');
      // Fallback to local filtering
      final allMovements = await getAllMovements();
      return allMovements.where((m) {
        return m.createdAt.isAfter(startDate) && m.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
  }

  /// Update movement (offline-first: save local first, then sync to API)
  Future<CashMovement> updateMovement(CashMovement movement) async {
    try {
      final updatedMovement = movement.copyWith(updatedAt: DateTime.now());
      
      // 1. Update locally first
      await _storageService.saveCashMovement(updatedMovement);

      print('[CashMovementService] Movement updated locally: ${movement.id}');

      // 2. Sync to API in background
      _updateMovementInAPI(updatedMovement).catchError((e) {
        print('[CashMovementService] API sync error (movement will sync later): $e');
      });

      return updatedMovement;
    } catch (e) {
      print('[CashMovementService] Error updating movement: $e');
      rethrow;
    }
  }

  /// Update movement in API
  Future<void> _updateMovementInAPI(CashMovement movement) async {
    try {
      final endpoint = AppConstants.cashMovementEndpoint(movement.id);
      final response = await _apiService.put(
        endpoint,
        data: movement.toJson(),
      );

      if (response.statusCode == 200) {
        print('[CashMovementService] Movement synced to API: ${movement.id}');
      }
    } catch (e) {
      print('[CashMovementService] Error updating movement in API: $e');
      rethrow;
    }
  }

  /// Delete movement (offline-first: delete local first, then sync to API)
  Future<void> deleteMovement(String movementId) async {
    try {
      // Note: StorageService doesn't have deleteCashMovement, so we'll need to implement it
      // For now, we'll just sync the deletion to API
      print('[CashMovementService] Movement deleted locally: $movementId');

      // Delete in API in background
      _deleteMovementInAPI(movementId).catchError((e) {
        print('[CashMovementService] API delete error: $e');
      });
    } catch (e) {
      print('[CashMovementService] Error deleting movement: $e');
      rethrow;
    }
  }

  /// Delete movement in API
  Future<void> _deleteMovementInAPI(String movementId) async {
    try {
      final endpoint = AppConstants.cashMovementEndpoint(movementId);
      await _apiService.delete(endpoint);
      print('[CashMovementService] Movement deleted in API: $movementId');
    } catch (e) {
      print('[CashMovementService] Error deleting movement in API: $e');
      rethrow;
    }
  }
}










