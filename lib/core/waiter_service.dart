// waiter_service.dart
// Service for managing restaurant waiters/servers
// Handles CRUD operations for waiters using local storage

import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/waiter.dart';
import 'storage_service.dart';

class WaiterService {
  static final WaiterService _instance = WaiterService._internal();
  factory WaiterService() => _instance;
  WaiterService._internal();

  final _storageService = StorageService();
  final _uuid = const Uuid();
  static const String _storageKey = 'restaurant_waiters';

  /// Get all waiters
  Future<List<Waiter>> getAllWaiters() async {
    try {
      final waitersJson = _storageService.readSetting(_storageKey);

      if (waitersJson == null) {
        return [];
      }

      final List<dynamic> waitersList = jsonDecode(waitersJson as String);
      return waitersList
          .map((json) => Waiter.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[WaiterService] Error getting waiters: $e');
      return [];
    }
  }

  /// Get active waiters
  Future<List<Waiter>> getActiveWaiters() async {
    try {
      final waiters = await getAllWaiters();
      return waiters.where((waiter) => waiter.isActive).toList();
    } catch (e) {
      print('[WaiterService] Error getting active waiters: $e');
      return [];
    }
  }

  /// Get waiter by ID
  Future<Waiter?> getWaiterById(String id) async {
    try {
      final waiters = await getAllWaiters();
      return waiters.firstWhere((waiter) => waiter.id == id);
    } catch (e) {
      print('[WaiterService] Error getting waiter by ID: $e');
      return null;
    }
  }

  /// Create a new waiter
  Future<Waiter> createWaiter({
    required String name,
    String? phone,
    String? email,
    bool isActive = true,
  }) async {
    try {
      final now = DateTime.now();
      final waiter = Waiter(
        id: _uuid.v4(),
        name: name,
        phone: phone,
        email: email,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      final waiters = await getAllWaiters();
      waiters.add(waiter);
      await _saveWaiters(waiters);

      print('[WaiterService] Waiter created: $name');
      return waiter;
    } catch (e) {
      print('[WaiterService] Error creating waiter: $e');
      rethrow;
    }
  }

  /// Update waiter
  Future<Waiter> updateWaiter(Waiter waiter) async {
    try {
      final waiters = await getAllWaiters();
      final index = waiters.indexWhere((w) => w.id == waiter.id);

      if (index == -1) {
        throw Exception('Waiter not found');
      }

      final updatedWaiter = waiter.copyWith(updatedAt: DateTime.now());
      waiters[index] = updatedWaiter;
      await _saveWaiters(waiters);

      print('[WaiterService] Waiter updated: ${waiter.name}');
      return updatedWaiter;
    } catch (e) {
      print('[WaiterService] Error updating waiter: $e');
      rethrow;
    }
  }

  /// Assign table to waiter
  Future<Waiter> assignTable(String waiterId, String tableId) async {
    try {
      final waiter = await getWaiterById(waiterId);
      if (waiter == null) {
        throw Exception('Waiter not found');
      }

      final updatedTables = [...waiter.assignedTableIds];
      if (!updatedTables.contains(tableId)) {
        updatedTables.add(tableId);
      }

      return await updateWaiter(waiter.copyWith(
        assignedTableIds: updatedTables,
      ));
    } catch (e) {
      print('[WaiterService] Error assigning table: $e');
      rethrow;
    }
  }

  /// Remove table from waiter
  Future<Waiter> removeTable(String waiterId, String tableId) async {
    try {
      final waiter = await getWaiterById(waiterId);
      if (waiter == null) {
        throw Exception('Waiter not found');
      }

      final updatedTables = [...waiter.assignedTableIds];
      updatedTables.remove(tableId);

      return await updateWaiter(waiter.copyWith(
        assignedTableIds: updatedTables,
      ));
    } catch (e) {
      print('[WaiterService] Error removing table: $e');
      rethrow;
    }
  }

  /// Toggle waiter active status
  Future<Waiter> toggleActive(String waiterId) async {
    try {
      final waiter = await getWaiterById(waiterId);
      if (waiter == null) {
        throw Exception('Waiter not found');
      }

      return await updateWaiter(waiter.copyWith(
        isActive: !waiter.isActive,
      ));
    } catch (e) {
      print('[WaiterService] Error toggling active: $e');
      rethrow;
    }
  }

  /// Delete waiter
  Future<void> deleteWaiter(String waiterId) async {
    try {
      final waiters = await getAllWaiters();
      waiters.removeWhere((waiter) => waiter.id == waiterId);
      await _saveWaiters(waiters);

      print('[WaiterService] Waiter deleted: $waiterId');
    } catch (e) {
      print('[WaiterService] Error deleting waiter: $e');
      rethrow;
    }
  }

  /// Save waiters to storage
  Future<void> _saveWaiters(List<Waiter> waiters) async {
    try {
      final waitersJson = jsonEncode(
        waiters.map((waiter) => waiter.toJson()).toList(),
      );
      await _storageService.writeSetting(_storageKey, waitersJson);
    } catch (e) {
      print('[WaiterService] Error saving waiters: $e');
      rethrow;
    }
  }

  /// Clear all waiters
  Future<void> clearAllWaiters() async {
    try {
      await _storageService.deleteSetting(_storageKey);
      print('[WaiterService] All waiters cleared');
    } catch (e) {
      print('[WaiterService] Error clearing all waiters: $e');
      rethrow;
    }
  }
}
