// lib/core/cash_register_service.dart
// Cash register management service for opening, closing, and tracking cash flow
// Handles register sessions and validates sales permissions
// Offline-first: local storage is primary, API sync in background

import 'package:uuid/uuid.dart';
import '../models/cash_register.dart';
import 'storage_service.dart';
import 'sync_service.dart';
import 'api_service.dart';
import 'cash_movement_service.dart';
import 'constants.dart';

/// Cash register service
class CashRegisterService {
  static final CashRegisterService _instance = CashRegisterService._internal();
  factory CashRegisterService() => _instance;
  CashRegisterService._internal();

  final _storageService = StorageService();
  final _syncService = SyncService();
  final _apiService = ApiService();
  final _uuid = const Uuid();

  /// Open a new cash register session
  Future<CashRegister> openRegister({
    required double openingBalance,
    required String userId,
    required String deviceId,
    String? notes,
  }) async {
    try {
      print('[CashRegisterService] Opening cash register...');

      // Check if there's already an open register
      final currentRegister = getCurrentRegister();
      if (currentRegister != null) {
        print('[CashRegisterService] Closing existing register before opening new one...');
        // For testing purposes, close the existing register automatically
        await closeRegister(currentRegister.openingBalance, 'Fermeture automatique pour nouveau registre');
      }

      final registerId = _uuid.v4();
      final now = DateTime.now();

      final cashRegisterData = {
        'id': registerId,
        'deviceId': deviceId,
        'userId': userId,
        'status': 'open',
        'openingBalance': openingBalance,
        'expectedCash': openingBalance,
        'openedAt': now.toIso8601String(),
        'closedAt': null,
        'closingBalance': null,
        'actualCash': null,
        'difference': null,
        'notes': notes,
        'salesCount': 0,
        'totalSales': 0.0,
        'isSynced': false,
      };

      // Save to storage
      await _storageService.saveCashRegister(cashRegisterData);

      // Store as current register
      await _storageService.writeSetting(
        AppConstants.currentCashRegisterKey,
        registerId,
      );

      // Add to sync queue (for offline sync)
      await _storageService.addToSyncQueue({
        'entityType': 'cash_register',
        'entityId': registerId,
        'operation': 'create',
        'data': cashRegisterData,
      });

      print('[CashRegisterService] Cash register opened locally: $registerId');
      print('[CashRegisterService] Opening balance: $openingBalance ${AppConstants.currencySymbol}');

      // Sync to API in background (non-blocking)
      _openRegisterInAPI(cashRegisterData).catchError((e) {
        print('[CashRegisterService] API sync error (register will sync later): $e');
        // Register is already saved locally, will sync later
      });

      return CashRegister.fromJson(cashRegisterData);
    } catch (e) {
      print('[CashRegisterService] Error opening register: $e');
      rethrow;
    }
  }

  /// Close the current cash register session
  Future<CashRegister> closeRegister(double actualCash, String? notes) async {
    try {
      print('[CashRegisterService] Closing cash register...');

      final currentRegisterData = getCurrentRegisterData();
      if (currentRegisterData == null) {
        throw Exception('Aucun registre ouvert à fermer.');
      }

      final now = DateTime.now();
      final expectedBalance = currentRegisterData['expectedCash'] as double;
      final difference = actualCash - expectedBalance;

      // Update register
      final closedRegisterData = Map<String, dynamic>.from(currentRegisterData);
      closedRegisterData['status'] = 'closed';
      closedRegisterData['closedAt'] = now.toIso8601String();
      closedRegisterData['closingBalance'] = actualCash;
      closedRegisterData['actualCash'] = actualCash;
      closedRegisterData['difference'] = difference;

      if (notes != null) {
        closedRegisterData['notes'] = '${currentRegisterData['notes'] ?? ''}\nClosure: $notes';
      }

      // Save to storage
      await _storageService.saveCashRegister(closedRegisterData);

      // Clear current register
      await _storageService.writeSetting(
        AppConstants.currentCashRegisterKey,
        '',
      );

      // Enqueue for sync
      await _storageService.addToSyncQueue({
        'entityType': 'cash_register',
        'entityId': closedRegisterData['id'],
        'operation': 'update',
        'data': closedRegisterData,
      });

      print('[CashRegisterService] Cash register closed locally: ${closedRegisterData['id']}');
      print('[CashRegisterService] Expected: $expectedBalance ${AppConstants.currencySymbol}');
      print('[CashRegisterService] Actual: $actualCash ${AppConstants.currencySymbol}');
      print('[CashRegisterService] Difference: $difference ${AppConstants.currencySymbol}');

      // Sync to API in background (non-blocking)
      _closeRegisterInAPI(closedRegisterData['id'] as String, actualCash, notes).catchError((e) {
        print('[CashRegisterService] API sync error (register will sync later): $e');
        // Register is already saved locally, will sync later
      });

      return CashRegister.fromJson(closedRegisterData);
    } catch (e) {
      print('[CashRegisterService] Error closing register: $e');
      rethrow;
    }
  }

  /// Get current open cash register
  CashRegister? getCurrentRegister() {
    try {
      final data = _storageService.getCurrentCashRegister();
      if (data == null) return null;
      return CashRegister.fromJson(data);
    } catch (e) {
      print('[CashRegisterService] Error getting current register: $e');
      return null;
    }
  }

  /// Get current open cash register data (raw Map)
  Map<String, dynamic>? getCurrentRegisterData() {
    try {
      return _storageService.getCurrentCashRegister();
    } catch (e) {
      print('[CashRegisterService] Error getting current register data: $e');
      return null;
    }
  }

  /// Get cash register history
  List<CashRegister> getRegisterHistory({int? limit}) {
    try {
      var registersData = _storageService.getCashRegisters();

      // Sort by openedAt descending
      registersData.sort((a, b) {
        final aDate = DateTime.parse(a['openedAt']);
        final bDate = DateTime.parse(b['openedAt']);
        return bDate.compareTo(aDate);
      });

      if (limit != null && limit > 0) {
        registersData = registersData.take(limit).toList();
      }

      return registersData.map((data) => CashRegister.fromJson(data)).toList();
    } catch (e) {
      print('[CashRegisterService] Error getting register history: $e');
      return [];
    }
  }

  /// Validate that a cash register is open before allowing sales
  bool validateCanSell() {
    try {
      final currentRegister = getCurrentRegister();

      if (currentRegister == null) {
        print('[CashRegisterService] Cannot sell: No open register');
        return false;
      }

      if (currentRegister.status != 'open') {
        print('[CashRegisterService] Cannot sell: Register not open');
        return false;
      }

      return true;
    } catch (e) {
      print('[CashRegisterService] Error validating can sell: $e');
      return false;
    }
  }

  /// Record a sale in the current register
  Future<void> recordSale(double amount, {String? saleId, String? userId}) async {
    try {
      final currentRegisterData = getCurrentRegisterData();
      if (currentRegisterData == null) {
        throw Exception('No open register');
      }

      final registerId = currentRegisterData['id'] as String;

      // Update register balances
      final updatedRegisterData = Map<String, dynamic>.from(currentRegisterData);
      updatedRegisterData['expectedCash'] = (currentRegisterData['expectedCash'] as double) + amount;
      updatedRegisterData['salesCount'] = (currentRegisterData['salesCount'] as int) + 1;
      updatedRegisterData['totalSales'] = (currentRegisterData['totalSales'] as double) + amount;

      // Save updated register
      await _storageService.saveCashRegister(updatedRegisterData);

      // Create cash movement via CashMovementService
      final cashMovementService = CashMovementService();
      cashMovementService.createMovement(
        cashRegisterId: registerId,
        type: 'sale',
        amount: amount,
        description: 'Vente enregistrée',
        saleId: saleId,
        userId: userId,
      ).catchError((e) {
        print('[CashRegisterService] Error creating cash movement: $e');
        // Continue even if movement creation fails
      });

      print('[CashRegisterService] Sale recorded: $amount ${AppConstants.currencySymbol}');
      print('[CashRegisterService] New expected cash: ${updatedRegisterData['expectedCash']} ${AppConstants.currencySymbol}');
    } catch (e) {
      print('[CashRegisterService] Error recording sale: $e');
      rethrow;
    }
  }

  /// Record a refund in the current register
  Future<void> recordRefund(double amount, {String? refundId, String? saleId, String? userId}) async {
    try {
      final currentRegisterData = getCurrentRegisterData();
      if (currentRegisterData == null) {
        throw Exception('No open register');
      }

      final registerId = currentRegisterData['id'] as String;

      // Update register balances
      final updatedRegisterData = Map<String, dynamic>.from(currentRegisterData);
      updatedRegisterData['expectedCash'] = (currentRegisterData['expectedCash'] as double) - amount;

      // Save updated register
      await _storageService.saveCashRegister(updatedRegisterData);

      // Create cash movement via CashMovementService
      final cashMovementService = CashMovementService();
      cashMovementService.createMovement(
        cashRegisterId: registerId,
        type: 'refund',
        amount: amount,
        description: 'Remboursement enregistré',
        saleId: saleId,
        userId: userId,
      ).catchError((e) {
        print('[CashRegisterService] Error creating cash movement: $e');
        // Continue even if movement creation fails
      });

      print('[CashRegisterService] Refund recorded: $amount ${AppConstants.currencySymbol}');
      print('[CashRegisterService] New expected cash: ${updatedRegisterData['expectedCash']} ${AppConstants.currencySymbol}');
    } catch (e) {
      print('[CashRegisterService] Error recording refund: $e');
      rethrow;
    }
  }

  /// Get register summary for current session
  Map<String, dynamic>? getCurrentSummary() {
    try {
      final currentRegister = getCurrentRegister();
      if (currentRegister == null) return null;

      final duration = DateTime.now().difference(currentRegister.openedAt);

      return {
        'register_id': currentRegister.id,
        'status': currentRegister.status,
        'opening_balance': currentRegister.openingBalance,
        'expected_cash': currentRegister.expectedCash,
        'sales_count': currentRegister.salesCount,
        'total_sales': currentRegister.totalSales,
        'opened_at': currentRegister.openedAt.toIso8601String(),
        'duration_hours': duration.inHours,
        'duration_minutes': duration.inMinutes,
      };
    } catch (e) {
      print('[CashRegisterService] Error getting summary: $e');
      return null;
    }
  }

  /// Get register by ID
  CashRegister? getRegisterById(String id) {
    try {
      final registersData = _storageService.getCashRegisters();
      final registerData = registersData.firstWhere(
        (r) => r['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (registerData.isEmpty) return null;
      return CashRegister.fromJson(registerData);
    } catch (e) {
      print('[CashRegisterService] Error getting register by ID: $e');
      return null;
    }
  }

  /// Calculate session statistics
  Map<String, dynamic> calculateSessionStats(CashRegister register) {
    try {
      final openingBalance = register.openingBalance;
      final closingBalance = register.closingBalance ?? register.actualCash ?? 0.0;
      final totalSales = register.totalSales ?? 0.0;
      final salesCount = register.salesCount ?? 0;

      final expectedCash = register.expectedCash ?? openingBalance;
      final difference = closingBalance - expectedCash;

      return {
        'opening_balance': openingBalance,
        'closing_balance': closingBalance,
        'total_sales': totalSales,
        'sales_count': salesCount,
        'expected_cash': expectedCash,
        'difference': difference,
        'difference_percentage': expectedCash > 0 ? (difference / expectedCash) * 100 : 0,
      };
    } catch (e) {
      print('[CashRegisterService] Error calculating stats: $e');
      return {};
    }
  }

  /// Reset all cash registers (for testing)
  Future<void> resetAllRegisters() async {
    try {
      print('[CashRegisterService] Resetting all registers...');
      await _storageService.clearAll();
      print('[CashRegisterService] All registers reset');
    } catch (e) {
      print('[CashRegisterService] Error resetting registers: $e');
      rethrow;
    }
  }

  /// Open register in API
  Future<void> _openRegisterInAPI(Map<String, dynamic> registerData) async {
    try {
      final endpoint = AppConstants.openCashRegisterEndpoint;
      final response = await _apiService.post(
        endpoint,
        data: {
          'opening_balance': registerData['openingBalance'],
          'notes': registerData['notes'],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[CashRegisterService] Register synced to API: ${registerData['id']}');
        // Update local register with API response if needed
        if (response.data['data'] != null) {
          final apiRegister = response.data['data'];
          registerData['id'] = apiRegister['id'] ?? registerData['id'];
          await _storageService.saveCashRegister(registerData);
        }
      }
    } catch (e) {
      print('[CashRegisterService] Error opening register in API: $e');
      rethrow;
    }
  }

  /// Close register in API
  Future<void> _closeRegisterInAPI(String registerId, double actualCash, String? notes) async {
    try {
      final endpoint = AppConstants.closeCashRegisterEndpoint(registerId);
      final response = await _apiService.post(
        endpoint,
        data: {
          'actual_cash': actualCash,
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        print('[CashRegisterService] Register closed in API: $registerId');
      }
    } catch (e) {
      print('[CashRegisterService] Error closing register in API: $e');
      rethrow;
    }
  }

  /// Get active register from API (with fallback to local)
  Future<CashRegister?> getActiveRegisterFromAPI() async {
    try {
      final endpoint = AppConstants.activeCashRegisterEndpoint;
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final registerData = response.data['data'];
        if (registerData != null) {
          final register = CashRegister.fromJson(registerData);
          // Save to local storage
          await _storageService.saveCashRegister(registerData);
          await _storageService.writeSetting(
            AppConstants.currentCashRegisterKey,
            register.id,
          );
          return register;
        }
      }
      return null;
    } catch (e) {
      print('[CashRegisterService] Error getting active register from API: $e');
      // Fallback to local
      return getCurrentRegister();
    }
  }
}
