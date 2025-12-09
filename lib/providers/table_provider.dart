// table_provider.dart
// Provider for managing restaurant tables state
// Uses Riverpod for state management

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/table.dart';
import '../core/table_service.dart';

part 'table_provider.g.dart';

/// Provider for TableService
@riverpod
TableService tableService(Ref ref) {
  return TableService();
}

/// Provider for all tables
@riverpod
class TableList extends _$TableList {
  @override
  Future<List<RestaurantTable>> build() async {
    final service = ref.watch(tableServiceProvider);
    // Force refresh from API on first load
    return await service.getAllTables(forceRefresh: true);
  }

  /// Refresh tables list (force from API)
  Future<void> refresh({bool forceFromAPI = true}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(tableServiceProvider);
      return await service.getAllTables(forceRefresh: forceFromAPI);
    });
  }

  /// Sync tables from API
  Future<void> syncFromAPI() async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.syncTablesFromAPI();
      await refresh(forceFromAPI: true);
    } catch (e) {
      print('[TableList] Error syncing from API: $e');
      rethrow;
    }
  }

  /// Create a new table
  Future<void> createTable({
    required String number,
    required int capacity,
    TableStatus? status,
    String? waiterId,
    String? waiterName,
    String? notes,
  }) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.createTable(
        number: number,
        capacity: capacity,
        status: status,
        waiterId: waiterId,
        waiterName: waiterName,
        notes: notes,
      );
      // Refresh to get updated list (including API sync)
      await refresh(forceFromAPI: false);
    } catch (e) {
      print('[TableList] Error creating table: $e');
      rethrow;
    }
  }

  /// Update table
  Future<void> updateTable(RestaurantTable table) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.updateTable(table);
      await refresh();
    } catch (e) {
      print('[TableList] Error updating table: $e');
      rethrow;
    }
  }

  /// Assign waiter to table
  Future<void> assignWaiter(
    String tableId,
    String waiterId,
    String waiterName,
  ) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.assignWaiter(tableId, waiterId, waiterName);
      await refresh();
    } catch (e) {
      print('[TableList] Error assigning waiter: $e');
      rethrow;
    }
  }

  /// Update table status
  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? currentOrderId,
  }) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.updateTableStatus(tableId, status,
          currentOrderId: currentOrderId);
      await refresh();
    } catch (e) {
      print('[TableList] Error updating table status: $e');
      rethrow;
    }
  }

  /// Clear table
  Future<void> clearTable(String tableId) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.clearTable(tableId);
      await refresh();
    } catch (e) {
      print('[TableList] Error clearing table: $e');
      rethrow;
    }
  }

  /// Delete table
  Future<void> deleteTable(String tableId) async {
    try {
      final service = ref.read(tableServiceProvider);
      await service.deleteTable(tableId);
      await refresh();
    } catch (e) {
      print('[TableList] Error deleting table: $e');
      rethrow;
    }
  }
}

/// Provider for available tables
@riverpod
Future<List<RestaurantTable>> availableTables(Ref ref) async {
  final service = ref.watch(tableServiceProvider);
  return await service.getTablesByStatus(TableStatus.available);
}

/// Provider for occupied tables
@riverpod
Future<List<RestaurantTable>> occupiedTables(Ref ref) async {
  final service = ref.watch(tableServiceProvider);
  return await service.getTablesByStatus(TableStatus.occupied);
}

/// Provider for table statistics
@riverpod
Future<Map<String, dynamic>> tableStatistics(Ref ref) async {
  final service = ref.watch(tableServiceProvider);
  return await service.getTableStatistics();
}

/// Provider for tables by waiter
@riverpod
Future<List<RestaurantTable>> tablesByWaiter(
  Ref ref,
  String waiterId,
) async {
  final service = ref.watch(tableServiceProvider);
  return await service.getTablesByWaiter(waiterId);
}
