// table_service.dart
// Service for managing restaurant tables
// Handles CRUD operations for tables using local storage with API sync
// Offline-first: local storage is primary, API sync in background

import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/table.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';

class TableService {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  final _storageService = StorageService();
  final _apiService = ApiService();
  final _companyWarehouseService = CompanyWarehouseService();
  final _uuid = const Uuid();
  static const String _storageKey = 'restaurant_tables';

  /// Get all tables (API-first with local fallback)
  Future<List<RestaurantTable>> getAllTables({bool forceRefresh = false}) async {
    try {
      // 1. Always try API first
      try {
        final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
        if (warehouseId != null) {
          final apiTables = await _fetchTablesFromAPI(warehouseId);
          if (apiTables.isNotEmpty) {
            await _saveTables(apiTables);
            return apiTables;
          }
        } else {
          print('[TableService] No warehouse selected, skipping API fetch');
        }
      } catch (e) {
        print('[TableService] API fetch failed, will fallback to local: $e');
      }

      // 2. Fallback: read from local storage
      final tablesJson = _storageService.readSetting(_storageKey);
      if (tablesJson != null) {
        final List<dynamic> tablesList = jsonDecode(tablesJson as String);
        final localTables = tablesList
            .map((json) => RestaurantTable.fromJson(json as Map<String, dynamic>))
            .toList();
        if (localTables.isNotEmpty) return localTables;
      }

      return [];
    } catch (e) {
      print('[TableService] Error getting tables: $e');
      return [];
    }
  }

  /// Fetch tables from API
  Future<List<RestaurantTable>> _fetchTablesFromAPI(String warehouseId) async {
    try {
      final endpoint = AppConstants.tablesEndpoint(warehouseId);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 🔄 FETCHING TABLES FROM API');
      print('═══════════════════════════════════════════════════════');
      print('Warehouse ID: $warehouseId');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.get(endpoint);
      
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLES FETCHED SUCCESSFULLY');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> tablesData = response.data['data'] ?? [];
        print('Tables Count: ${tablesData.length}');
        print('═══════════════════════════════════════════════════════');
        print('');
        
        return tablesData
            .map((json) => RestaurantTable.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      print('⚠️ Response format unexpected or no data');
      print('Response: ${response.data}');
      print('═══════════════════════════════════════════════════════');
      print('');
      return [];
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR FETCHING TABLES FROM API');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Sync tables from API in background
  Future<void> _syncTablesFromAPI() async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) return;

      final apiTables = await _fetchTablesFromAPI(warehouseId);
      if (apiTables.isNotEmpty) {
        // Merge with local tables (keep local changes that aren't in API)
        final localTables = await getAllTables();
        final mergedTables = _mergeTables(localTables, apiTables);
        await _saveTables(mergedTables);
        print('[TableService] Tables synced from API: ${apiTables.length}');
      }
    } catch (e) {
      print('[TableService] Background sync error: $e');
      // Silent fail - local data is still available
    }
  }

  /// Sync tables from API (public method for manual sync)
  Future<void> syncTablesFromAPI() async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('No warehouse selected');
      }

      final apiTables = await _fetchTablesFromAPI(warehouseId);
      if (apiTables.isNotEmpty) {
        // Merge with local tables
        final localTables = await getAllTables();
        final mergedTables = _mergeTables(localTables, apiTables);
        await _saveTables(mergedTables);
        print('[TableService] Tables synced from API: ${apiTables.length}');
      }
    } catch (e) {
      print('[TableService] Sync error: $e');
      rethrow;
    }
  }

  /// Merge local and API tables (prioritize API, keep local if not in API)
  List<RestaurantTable> _mergeTables(List<RestaurantTable> local, List<RestaurantTable> api) {
    final Map<String, RestaurantTable> merged = {};
    
    // Add API tables first (they are the source of truth)
    for (final table in api) {
      merged[table.id] = table;
    }
    
    // Add local tables that aren't in API (pending sync)
    for (final table in local) {
      if (!merged.containsKey(table.id)) {
        merged[table.id] = table;
      }
    }
    
    return merged.values.toList();
  }

  /// Get table by ID
  Future<RestaurantTable?> getTableById(String id) async {
    try {
      final tables = await getAllTables();
      return tables.firstWhere((table) => table.id == id);
    } catch (e) {
      print('[TableService] Error getting table by ID: $e');
      return null;
    }
  }

  /// Get tables by status
  Future<List<RestaurantTable>> getTablesByStatus(TableStatus status) async {
    try {
      final tables = await getAllTables();
      return tables.where((table) => table.status == status).toList();
    } catch (e) {
      print('[TableService] Error getting tables by status: $e');
      return [];
    }
  }

  /// Get tables assigned to a waiter
  Future<List<RestaurantTable>> getTablesByWaiter(String waiterId) async {
    try {
      final tables = await getAllTables();
      return tables.where((table) => table.waiterId == waiterId).toList();
    } catch (e) {
      print('[TableService] Error getting tables by waiter: $e');
      return [];
    }
  }

  /// Create a new table (offline-first: save local first, then sync to API)
  Future<RestaurantTable> createTable({
    required String number,
    required int capacity,
    TableStatus? status,
    String? waiterId,
    String? waiterName,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final table = RestaurantTable(
        id: _uuid.v4(),
        number: number,
        capacity: capacity,
        status: status ?? TableStatus.available,
        waiterId: waiterId,
        waiterName: waiterName,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save locally first (immediate response)
      final tables = await getAllTables();
      tables.add(table);
      await _saveTables(tables);

      print('[TableService] Table created locally: ${table.number}');

      // 2. Sync to API in background (non-blocking)
      _createTableInAPI(table).catchError((e) {
        print('[TableService] API sync error (table will sync later): $e');
        // Table is already saved locally, will sync later
      });

      return table;
    } catch (e) {
      print('[TableService] Error creating table: $e');
      rethrow;
    }
  }

  /// Create table in API
  Future<void> _createTableInAPI(RestaurantTable table) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        print('[TableService] ⚠️ No warehouse ID, skipping API sync');
        return;
      }

      final endpoint = AppConstants.tablesEndpoint(warehouseId);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 📤 CREATING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number}');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('Data: ${table.toJson()}');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.post(
        endpoint,
        data: table.toJson(),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLE CREATED IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number}');
      print('Status Code: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR CREATING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number}');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Update table (offline-first: save local first, then sync to API)
  Future<RestaurantTable> updateTable(RestaurantTable table) async {
    try {
      final tables = await getAllTables();
      final index = tables.indexWhere((t) => t.id == table.id);

      if (index == -1) {
        throw Exception('Table not found');
      }

      final updatedTable = table.copyWith(updatedAt: DateTime.now());
      tables[index] = updatedTable;
      await _saveTables(tables);

      print('[TableService] Table updated locally: ${table.number}');

      // Sync to API in background
      _updateTableInAPI(updatedTable).catchError((e) {
        print('[TableService] API sync error (table will sync later): $e');
      });

      return updatedTable;
    } catch (e) {
      print('[TableService] Error updating table: $e');
      rethrow;
    }
  }

  /// Update table in API
  Future<void> _updateTableInAPI(RestaurantTable table) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        print('[TableService] ⚠️ No warehouse ID, skipping API sync');
        return;
      }

      final endpoint = AppConstants.tableEndpoint(warehouseId, table.id);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 📤 UPDATING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number} (ID: ${table.id})');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('Data: ${table.toJson()}');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.put(
        endpoint,
        data: table.toJson(),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLE UPDATED IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number}');
      print('Status Code: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR UPDATING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table: ${table.number}');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Assign waiter to table
  Future<RestaurantTable> assignWaiter(
    String tableId,
    String waiterId,
    String waiterName,
  ) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      return await updateTable(table.copyWith(
        waiterId: waiterId,
        waiterName: waiterName,
      ));
    } catch (e) {
      print('[TableService] Error assigning waiter: $e');
      rethrow;
    }
  }

  /// Update table status (offline-first: save local first, then sync to API)
  Future<RestaurantTable> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? currentOrderId,
  }) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      DateTime? occupiedSince = table.occupiedSince;
      if (status == TableStatus.occupied && table.status != TableStatus.occupied) {
        occupiedSince = DateTime.now();
      } else if (status == TableStatus.available) {
        occupiedSince = null;
      }

      final updatedTable = await updateTable(table.copyWith(
        status: status,
        currentOrderId: currentOrderId,
        occupiedSince: occupiedSince,
      ));

      // Use API endpoints for occupy/release if available
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId != null) {
        if (status == TableStatus.occupied) {
          _occupyTableInAPI(warehouseId, tableId).catchError((e) {
            print('[TableService] API occupy error: $e');
          });
        } else if (status == TableStatus.available) {
          _releaseTableInAPI(warehouseId, tableId).catchError((e) {
            print('[TableService] API release error: $e');
          });
        }
      }

      return updatedTable;
    } catch (e) {
      print('[TableService] Error updating table status: $e');
      rethrow;
    }
  }

  /// Occupy table in API
  Future<void> _occupyTableInAPI(String warehouseId, String tableId) async {
    try {
      final endpoint = AppConstants.occupyTableEndpoint(warehouseId, tableId);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 📤 OCCUPYING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.post(endpoint);
      
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLE OCCUPIED IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Status Code: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR OCCUPYING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Release table in API
  Future<void> _releaseTableInAPI(String warehouseId, String tableId) async {
    try {
      final endpoint = AppConstants.releaseTableEndpoint(warehouseId, tableId);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 📤 RELEASING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.post(endpoint);
      
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLE RELEASED IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Status Code: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR RELEASING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Clear table (set to available)
  Future<RestaurantTable> clearTable(String tableId) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      return await updateTable(table.copyWith(
        status: TableStatus.available,
        currentOrderId: null,
        occupiedSince: null,
      ));
    } catch (e) {
      print('[TableService] Error clearing table: $e');
      rethrow;
    }
  }

  /// Delete table (offline-first: delete local first, then sync to API)
  Future<void> deleteTable(String tableId) async {
    try {
      // 1. Delete locally first
      final tables = await getAllTables();
      tables.removeWhere((table) => table.id == tableId);
      await _saveTables(tables);

      print('[TableService] Table deleted locally: $tableId');

      // 2. Delete in API in background
      _deleteTableInAPI(tableId).catchError((e) {
        print('[TableService] API delete error (table deleted locally): $e');
        // Table is already deleted locally
      });
    } catch (e) {
      print('[TableService] Error deleting table: $e');
      rethrow;
    }
  }

  /// Delete table in API
  Future<void> _deleteTableInAPI(String tableId) async {
    try {
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        print('[TableService] ⚠️ No warehouse ID, skipping API sync');
        return;
      }

      final endpoint = AppConstants.tableEndpoint(warehouseId, tableId);
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] 📤 DELETING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Endpoint: $endpoint');
      print('Full URL: ${AppConstants.baseUrl}$endpoint');
      print('═══════════════════════════════════════════════════════');
      print('');
      
      final response = await _apiService.delete(endpoint);
      
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ✅ TABLE DELETED IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Status Code: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('[TableService] ❌ ERROR DELETING TABLE IN API');
      print('═══════════════════════════════════════════════════════');
      print('Table ID: $tableId');
      print('Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  /// Save tables to storage
  Future<void> _saveTables(List<RestaurantTable> tables) async {
    try {
      final tablesJson = jsonEncode(
        tables.map((table) => table.toJson()).toList(),
      );
      await _storageService.writeSetting(_storageKey, tablesJson);
    } catch (e) {
      print('[TableService] Error saving tables: $e');
      rethrow;
    }
  }

  /// Get table statistics
  Future<Map<String, dynamic>> getTableStatistics() async {
    try {
      final tables = await getAllTables();

      return {
        'total': tables.length,
        'available': tables.where((t) => t.status == TableStatus.available).length,
        'occupied': tables.where((t) => t.status == TableStatus.occupied).length,
        'reserved': tables.where((t) => t.status == TableStatus.reserved).length,
        'cleaning': tables.where((t) => t.status == TableStatus.cleaning).length,
      };
    } catch (e) {
      print('[TableService] Error getting statistics: $e');
      return {};
    }
  }

  /// Clear all tables
  Future<void> clearAllTables() async {
    try {
      await _storageService.deleteSetting(_storageKey);
      print('[TableService] All tables cleared');
    } catch (e) {
      print('[TableService] Error clearing all tables: $e');
      rethrow;
    }
  }
}
