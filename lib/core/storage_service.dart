// lib/core/storage_service.dart
// Singleton Hive-based storage service for local data persistence
// Handles products, sales, customers, cash registers, sync queue, and settings

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import '../models/sale.dart';
import '../models/cash_movement.dart';
import '../models/employee.dart';

/// Storage service for managing local data persistence
/// Uses Hive for complex data structures and SharedPreferences for simple settings
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Hive boxes
  Box? _productsBox;
  Box? _salesBox;
  Box? _salesPendingBox;
  Box? _syncQueueBox;
  Box? _settingsBox;
  Box? _customersBox;
  Box? _cashRegistersBox;
  Box? _cashMovementsBox;
  Box? _employeesBox;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  bool _isInitialized = false;

  /// Initialize storage service and open all Hive boxes
  Future<void> init() async {
    if (_isInitialized) {
      print('[StorageService] Already initialized');
      return;
    }

    try {
      print('[StorageService] Initializing Hive...');
      await Hive.initFlutter();

      // Open all boxes
      _productsBox = await Hive.openBox(AppConstants.productsBox);
      _salesBox = await Hive.openBox(AppConstants.salesBox);
      _salesPendingBox = await Hive.openBox(AppConstants.salesPendingBox);
      _syncQueueBox = await Hive.openBox(AppConstants.syncQueueBox);
      _settingsBox = await Hive.openBox(AppConstants.settingsBox);
      _customersBox = await Hive.openBox(AppConstants.customersBox);
      _cashRegistersBox = await Hive.openBox(AppConstants.cashRegistersBox);
      _cashMovementsBox = await Hive.openBox(AppConstants.cashMovementsBox);
      _employeesBox = await Hive.openBox(AppConstants.employeesBox);

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      _isInitialized = true;
      print('[StorageService] Initialized successfully');
      print('[StorageService] Products: ${_productsBox?.length ?? 0}');
      print('[StorageService] Pending Sales: ${_salesPendingBox?.length ?? 0}');
      print('[StorageService] Sync Queue: ${_syncQueueBox?.length ?? 0}');
    } catch (e) {
      print('[StorageService] Initialization error: $e');
      rethrow;
    }
  }

  /// Save a product to storage
  Future<void> saveProduct(Map<String, dynamic> product) async {
    try {
      if (_productsBox == null) {
        print('[StorageService] ❌ Storage not initialized, cannot save product');
        throw Exception('Storage not initialized');
      }

      final String id = product['id'] ?? product['sku'];
      final String name = product['name'] ?? 'Sans nom';
      final int stock = product['stock'] ?? 0;

      await _productsBox!.put(id, product);

      print('[StorageService] ✅ Produit sauvegardé: $name (ID: $id, Stock: $stock)');
      print('[StorageService] Total produits en stockage: ${_productsBox!.length}');
    } catch (e) {
      print('[StorageService] ❌ Erreur sauvegarde produit: $e');
      print('[StorageService] Type d\'erreur: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Get all products from storage
  List<Map<String, dynamic>> getProducts() {
    print('[StorageService] ===== DÉBUT getProducts =====');
    try {
      if (_productsBox == null) {
        print('[StorageService] ❌ Storage not initialized');
        throw Exception('Storage not initialized');
      }

      print('[StorageService] Récupération des produits depuis Hive...');
      final rawValues = _productsBox!.values;
      print('[StorageService] Valeurs brutes de Hive: ${rawValues.length} éléments');
      
      final products = rawValues
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      
      print('[StorageService] ✅ Produits convertis: ${products.length} éléments');
      for (int i = 0; i < products.length && i < 3; i++) {
        print('[StorageService] Produit $i: ${products[i]['name'] ?? 'Sans nom'} (ID: ${products[i]['id'] ?? 'Sans ID'})');
      }
      if (products.length > 3) {
        print('[StorageService] ... et ${products.length - 3} autres produits');
      }
      
      print('[StorageService] ===== FIN getProducts =====');
      return products;
    } catch (e) {
      print('[StorageService] ❌ Erreur getProducts: $e');
      print('[StorageService] Type d\'erreur: ${e.runtimeType}');
      print('[StorageService] ===== FIN getProducts (Erreur) =====');
      return [];
    }
  }

  /// Delete a product from storage
  Future<void> deleteProduct(String id) async {
    try {
      if (_productsBox == null) throw Exception('Storage not initialized');

      await _productsBox!.delete(id);
      print('[StorageService] Product deleted: $id');
    } catch (e) {
      print('[StorageService] Error deleting product: $e');
      rethrow;
    }
  }

  /// Save a sale to pending sales (for backward compatibility - redirects to Sale version)
  Future<void> saveSaleMap(Map<String, dynamic> sale) async {
    try {
      if (_salesPendingBox == null) throw Exception('Storage not initialized');

      final String id = sale['id'];
      await _salesPendingBox!.put(id, sale);
      print('[StorageService] Sale saved: $id');
    } catch (e) {
      print('[StorageService] Error saving sale: $e');
      rethrow;
    }
  }

  /// Get all pending sales as maps (for backward compatibility)
  List<Map<String, dynamic>> getSalesMaps() {
    try {
      if (_salesPendingBox == null) throw Exception('Storage not initialized');

      return _salesPendingBox!.values
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print('[StorageService] Error getting sales: $e');
      return [];
    }
  }

  /// Save a customer to storage
  Future<void> saveCustomer(Map<String, dynamic> customer) async {
    try {
      if (_customersBox == null) throw Exception('Storage not initialized');

      final String id = customer['id'];
      await _customersBox!.put(id, customer);
      print('[StorageService] Customer saved: $id');
    } catch (e) {
      print('[StorageService] Error saving customer: $e');
      rethrow;
    }
  }

  /// Get all customers from storage
  List<Map<String, dynamic>> getCustomers() {
    try {
      if (_customersBox == null) throw Exception('Storage not initialized');

      return _customersBox!.values
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print('[StorageService] Error getting customers: $e');
      return [];
    }
  }

  /// Delete a customer from storage
  Future<void> deleteCustomer(String customerId) async {
    try {
      if (_customersBox == null) throw Exception('Storage not initialized');

      await _customersBox!.delete(customerId);
      print('[StorageService] Customer deleted: $customerId');
    } catch (e) {
      print('[StorageService] Error deleting customer: $e');
      rethrow;
    }
  }

  /// Save a sync queue entry
  Future<void> saveSyncQueue(Map<String, dynamic> entry) async {
    try {
      if (_syncQueueBox == null) throw Exception('Storage not initialized');

      final String id = entry['id'];
      await _syncQueueBox!.put(id, entry);
      print('[StorageService] Sync queue entry saved: $id');
    } catch (e) {
      print('[StorageService] Error saving sync queue entry: $e');
      rethrow;
    }
  }

  /// Get all sync queue entries
  List<Map<String, dynamic>> getSyncQueue() {
    try {
      if (_syncQueueBox == null) throw Exception('Storage not initialized');

      return _syncQueueBox!.values
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print('[StorageService] Error getting sync queue: $e');
      return [];
    }
  }

  /// Delete a sync queue entry
  Future<void> deleteSyncQueueEntry(String id) async {
    try {
      if (_syncQueueBox == null) throw Exception('Storage not initialized');

      await _syncQueueBox!.delete(id);
      print('[StorageService] Sync queue entry deleted: $id');
    } catch (e) {
      print('[StorageService] Error deleting sync queue entry: $e');
      rethrow;
    }
  }

  /// Save a cash register
  Future<void> saveCashRegister(Map<String, dynamic> cashRegister) async {
    try {
      if (_cashRegistersBox == null) throw Exception('Storage not initialized');

      final String id = cashRegister['id'];
      await _cashRegistersBox!.put(id, cashRegister);
      print('[StorageService] Cash register saved: $id');
    } catch (e) {
      print('[StorageService] Error saving cash register: $e');
      rethrow;
    }
  }

  /// Get current active cash register
  Map<String, dynamic>? getCurrentCashRegister() {
    try {
      if (_cashRegistersBox == null) throw Exception('Storage not initialized');

      // Find the open cash register
      for (var entry in _cashRegistersBox!.values) {
        final cashRegister = Map<String, dynamic>.from(entry as Map);
        if (cashRegister['status'] == 'open') {
          return cashRegister;
        }
      }
      return null;
    } catch (e) {
      print('[StorageService] Error getting current cash register: $e');
      return null;
    }
  }

  /// Get all cash registers
  List<Map<String, dynamic>> getCashRegisters() {
    try {
      if (_cashRegistersBox == null) throw Exception('Storage not initialized');

      return _cashRegistersBox!.values
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print('[StorageService] Error getting cash registers: $e');
      return [];
    }
  }

  /// Write a setting value
  Future<void> writeSetting(String key, dynamic value) async {
    try {
      if (_prefs == null) throw Exception('Storage not initialized');

      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
      } else if (value is List) {
        // Pour les listes d'objets complexes, on les stocke dans Hive
        if (_settingsBox == null) throw Exception('Settings box not initialized');
        await _settingsBox!.put(key, value);
      } else {
        // Pour les autres types, on les stocke dans Hive
        if (_settingsBox == null) throw Exception('Settings box not initialized');
        await _settingsBox!.put(key, value);
      }

      print('[StorageService] Setting written: $key');
    } catch (e) {
      print('[StorageService] Error writing setting: $e');
      rethrow;
    }
  }

  /// Read a setting value
  dynamic readSetting(String key, {dynamic defaultValue}) {
    try {
      if (_prefs == null) throw Exception('Storage not initialized');

      // D'abord essayer SharedPreferences
      final prefsValue = _prefs!.get(key);
      if (prefsValue != null) {
        return prefsValue;
      }

      // Si pas trouvé, essayer dans Hive
      if (_settingsBox != null) {
        final hiveValue = _settingsBox!.get(key);
        if (hiveValue != null) {
          return hiveValue;
        }
      }

      return defaultValue;
    } catch (e) {
      print('[StorageService] Error reading setting: $e');
      return defaultValue;
    }
  }

  /// Delete a setting value
  Future<void> deleteSetting(String key) async {
    try {
      // Supprimer de SharedPreferences
      if (_prefs != null) {
        await _prefs!.remove(key);
      }

      // Supprimer de Hive
      if (_settingsBox != null) {
        await _settingsBox!.delete(key);
      }

      print('[StorageService] Setting deleted: $key');
    } catch (e) {
      print('[StorageService] Error deleting setting: $e');
      rethrow;
    }
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAll() async {
    try {
      await _productsBox?.clear();
      await _salesPendingBox?.clear();
      await _syncQueueBox?.clear();
      await _settingsBox?.clear();
      await _customersBox?.clear();
      await _cashRegistersBox?.clear();
      await _prefs?.clear();

      print('[StorageService] All data cleared');
    } catch (e) {
      print('[StorageService] Error clearing data: $e');
      rethrow;
    }
  }

  /// Close all boxes
  Future<void> dispose() async {
    try {
      await _productsBox?.close();
      await _salesPendingBox?.close();
      await _syncQueueBox?.close();
      await _settingsBox?.close();
      await _customersBox?.close();
      await _cashRegistersBox?.close();

      _isInitialized = false;
      print('[StorageService] Disposed');
    } catch (e) {
      print('[StorageService] Error disposing: $e');
    }
  }

  /// Récupérer les ventes en attente de synchronisation
  List<Map<String, dynamic>> getPendingSales() {
    try {
      return _salesPendingBox?.values
          .map((sale) => Map<String, dynamic>.from(sale))
          .toList() ?? [];
    } catch (e) {
      print('[StorageService] Error getting pending sales: $e');
      return [];
    }
  }

  /// Ajouter un élément à la file de synchronisation
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _syncQueueBox?.put(id, {...item, 'id': id});
      print('[StorageService] Item added to sync queue: $id');
    } catch (e) {
      print('[StorageService] Error adding to sync queue: $e');
      rethrow;
    }
  }

  /// Vider la file de synchronisation
  Future<void> clearSyncQueue() async {
    try {
      await _syncQueueBox?.clear();
      print('[StorageService] Sync queue cleared');
    } catch (e) {
      print('[StorageService] Error clearing sync queue: $e');
      rethrow;
    }
  }

  /// Définir l'heure de la dernière synchronisation
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      await _prefs?.setString('last_sync_time', time.toIso8601String());
      print('[StorageService] Last sync time set: $time');
    } catch (e) {
      print('[StorageService] Error setting last sync time: $e');
      rethrow;
    }
  }

  /// Récupérer l'heure de la dernière synchronisation
  DateTime? getLastSyncTime() {
    try {
      final timeString = _prefs?.getString('last_sync_time');
      return timeString != null ? DateTime.parse(timeString) : null;
    } catch (e) {
      print('[StorageService] Error getting last sync time: $e');
      return null;
    }
  }

  // ==========================
  // SALES MANAGEMENT
  // ==========================

  /// Sauvegarder une vente
  Future<void> saveSale(Sale sale) async {
    print('═══════════════════════════════════════════════════════');
    print('[StorageService] 💾 DÉBUT sauvegarde de la vente');
    print('[StorageService] 🆔 Sale ID: ${sale.id}');
    print('[StorageService] 💰 Total: ${sale.total}');
    print('[StorageService] 📦 Nombre d\'articles: ${sale.items.length}');
    print('[StorageService] 💳 Méthode de paiement: ${sale.paymentMethod}');
    
    try {
      if (_salesBox == null) {
        print('[StorageService] ❌ _salesBox est null - Storage non initialisé');
        throw Exception('Storage not initialized');
      }
      
      print('[StorageService] 📝 Conversion de la vente en JSON...');
      final saleJson = sale.toJson();
      print('[StorageService] ✅ JSON créé: ${saleJson.keys.length} clés');
      
      print('[StorageService] 💾 Sauvegarde dans Hive (_salesBox.put)...');
      await _salesBox!.put(sale.id, saleJson);
      print('[StorageService] ✅ Vente sauvegardée dans Hive: ${sale.id}');
      
      // Vérifier que la vente est bien sauvegardée
      final savedSale = _salesBox!.get(sale.id);
      if (savedSale != null) {
        print('[StorageService] ✅ Vérification: vente trouvée dans Hive');
        print('[StorageService] 📊 Nombre total de ventes dans Hive: ${_salesBox!.length}');
      } else {
        print('[StorageService] ❌❌❌ PROBLÈME: vente non trouvée après sauvegarde! ❌❌❌');
      }
      
      print('[StorageService] ✅✅✅ SAUVEGARDE TERMINÉE AVEC SUCCÈS ✅✅✅');
      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('[StorageService] ❌❌❌ ERREUR SAUVEGARDE VENTE ❌❌❌');
      print('[StorageService] Erreur: $e');
      print('[StorageService] Type: ${e.runtimeType}');
      print('[StorageService] Stack trace: $stackTrace');
      print('[StorageService] Sale ID: ${sale.id}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Récupérer toutes les ventes
  List<Sale> getSales() {
    try {
      if (_salesBox == null) {
        print('[StorageService] Sales box not initialized');
        return [];
      }

      final salesData = _salesBox!.values.toList();
      return salesData.map((json) {
        try {
          // Convertir Map<dynamic, dynamic> vers Map<String, dynamic>
          final Map<String, dynamic> saleMap;
          if (json is Map<dynamic, dynamic>) {
            saleMap = Map<String, dynamic>.from(json);
          } else if (json is Map<String, dynamic>) {
            saleMap = json;
          } else {
            print('[StorageService] Unexpected type for sale: ${json.runtimeType}');
            throw Exception('Invalid sale data type: ${json.runtimeType}');
          }
          
          // Convertir récursivement les items qui peuvent aussi être Map<dynamic, dynamic>
          if (saleMap['items'] != null && saleMap['items'] is List) {
            final itemsList = saleMap['items'] as List;
            saleMap['items'] = itemsList.map((item) {
              if (item is Map<dynamic, dynamic>) {
                return Map<String, dynamic>.from(item);
              } else if (item is Map<String, dynamic>) {
                return item;
              } else {
                throw Exception('Invalid item type: ${item.runtimeType}');
              }
            }).toList();
          }
          
          return Sale.fromJson(saleMap);
        } catch (e) {
          print('[StorageService] Error parsing sale: $e');
          print('[StorageService] Sale data: $json');
          rethrow;
        }
      }).where((sale) => sale != null).cast<Sale>().toList();
    } catch (e) {
      print('[StorageService] Error getting sales: $e');
      print('[StorageService] Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Récupérer les ventes par période
  List<Sale> getSalesByDateRange(DateTime startDate, DateTime endDate) {
    try {
      final allSales = getSales();
      return allSales.where((sale) {
        return sale.createdAt.isAfter(startDate) &&
               sale.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('[StorageService] Error getting sales by date range: $e');
      return [];
    }
  }

  /// Supprimer une vente
  Future<void> deleteSale(String saleId) async {
    try {
      await _salesBox?.delete(saleId);
      print('[StorageService] Sale deleted: $saleId');
    } catch (e) {
      print('[StorageService] Error deleting sale: $e');
      rethrow;
    }
  }

  // ==========================
  // CASH MOVEMENTS MANAGEMENT
  // ==========================

  /// Sauvegarder un mouvement de caisse
  Future<void> saveCashMovement(CashMovement movement) async {
    try {
      await _cashMovementsBox?.put(movement.id, movement.toJson());
      print('[StorageService] Cash movement saved: ${movement.id}');
    } catch (e) {
      print('[StorageService] Error saving cash movement: $e');
      rethrow;
    }
  }

  /// Récupérer tous les mouvements de caisse
  List<CashMovement> getCashMovements() {
    try {
      final movementsData = _cashMovementsBox?.values.toList() ?? [];
      return movementsData.map((json) => CashMovement.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      print('[StorageService] Error getting cash movements: $e');
      return [];
    }
  }

  /// Récupérer les mouvements de caisse par caisse
  List<CashMovement> getCashMovementsByRegister(String cashRegisterId) {
    try {
      final allMovements = getCashMovements();
      return allMovements.where((movement) => movement.cashRegisterId == cashRegisterId).toList();
    } catch (e) {
      print('[StorageService] Error getting cash movements by register: $e');
      return [];
    }
  }

  /// Récupérer les mouvements de caisse par type
  List<CashMovement> getCashMovementsByType(String type) {
    try {
      final allMovements = getCashMovements();
      return allMovements.where((movement) => movement.type == type).toList();
    } catch (e) {
      print('[StorageService] Error getting cash movements by type: $e');
      return [];
    }
  }

  // ==========================
  // EMPLOYEES MANAGEMENT
  // ==========================

  /// Sauvegarder un employé
  Future<void> saveEmployee(Employee employee) async {
    try {
      await _employeesBox?.put(employee.id, employee.toJson());
      print('[StorageService] Employee saved: ${employee.id}');
    } catch (e) {
      print('[StorageService] Error saving employee: $e');
      rethrow;
    }
  }

  /// Récupérer tous les employés
  List<Employee> getEmployees() {
    try {
      final employeesData = _employeesBox?.values.toList() ?? [];
      return employeesData.map((json) => Employee.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      print('[StorageService] Error getting employees: $e');
      return [];
    }
  }

  /// Récupérer les employés actifs
  List<Employee> getActiveEmployees() {
    try {
      final allEmployees = getEmployees();
      return allEmployees.where((employee) => employee.isActive).toList();
    } catch (e) {
      print('[StorageService] Error getting active employees: $e');
      return [];
    }
  }

  /// Supprimer un employé
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _employeesBox?.delete(employeeId);
      print('[StorageService] Employee deleted: $employeeId');
    } catch (e) {
      print('[StorageService] Error deleting employee: $e');
      rethrow;
    }
  }
}
