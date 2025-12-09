// waiter_provider.dart
// Provider for managing waiters state
// Uses Riverpod for state management

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/waiter.dart';
import '../core/waiter_service.dart';

part 'waiter_provider.g.dart';

/// Provider for WaiterService
@riverpod
WaiterService waiterService(Ref ref) {
  return WaiterService();
}

/// Provider for all waiters
@riverpod
class WaiterList extends _$WaiterList {
  @override
  Future<List<Waiter>> build() async {
    final service = ref.watch(waiterServiceProvider);
    return await service.getAllWaiters();
  }

  /// Refresh waiters list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(waiterServiceProvider);
      return await service.getAllWaiters();
    });
  }

  /// Create a new waiter
  Future<void> createWaiter({
    required String name,
    String? phone,
    String? email,
    bool isActive = true,
  }) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.createWaiter(
        name: name,
        phone: phone,
        email: email,
        isActive: isActive,
      );
      await refresh();
    } catch (e) {
      print('[WaiterList] Error creating waiter: $e');
      rethrow;
    }
  }

  /// Update waiter
  Future<void> updateWaiter(Waiter waiter) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.updateWaiter(waiter);
      await refresh();
    } catch (e) {
      print('[WaiterList] Error updating waiter: $e');
      rethrow;
    }
  }

  /// Assign table to waiter
  Future<void> assignTable(String waiterId, String tableId) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.assignTable(waiterId, tableId);
      await refresh();
    } catch (e) {
      print('[WaiterList] Error assigning table: $e');
      rethrow;
    }
  }

  /// Remove table from waiter
  Future<void> removeTable(String waiterId, String tableId) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.removeTable(waiterId, tableId);
      await refresh();
    } catch (e) {
      print('[WaiterList] Error removing table: $e');
      rethrow;
    }
  }

  /// Toggle waiter active status
  Future<void> toggleActive(String waiterId) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.toggleActive(waiterId);
      await refresh();
    } catch (e) {
      print('[WaiterList] Error toggling active: $e');
      rethrow;
    }
  }

  /// Delete waiter
  Future<void> deleteWaiter(String waiterId) async {
    try {
      final service = ref.read(waiterServiceProvider);
      await service.deleteWaiter(waiterId);
      await refresh();
    } catch (e) {
      print('[WaiterList] Error deleting waiter: $e');
      rethrow;
    }
  }
}

/// Provider for active waiters
@riverpod
Future<List<Waiter>> activeWaiters(Ref ref) async {
  final service = ref.watch(waiterServiceProvider);
  return await service.getActiveWaiters();
}

/// Provider for waiter by ID
@riverpod
Future<Waiter?> waiterById(Ref ref, String waiterId) async {
  final service = ref.watch(waiterServiceProvider);
  return await service.getWaiterById(waiterId);
}
