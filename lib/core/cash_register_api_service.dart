// lib/core/cash_register_api_service.dart
// Service pour gérer les caisses avec l'API backend

import 'package:dio/dio.dart';
import 'constants.dart';
import 'api_service.dart';
import 'sync_service.dart';
import 'storage_service.dart';
import '../models/cash_register.dart';

class CashRegisterApiService {
  static final CashRegisterApiService _instance = CashRegisterApiService._internal();
  factory CashRegisterApiService() => _instance;
  CashRegisterApiService._internal();

  final _apiService = ApiService();
  final _syncService = SyncService();
  final _storageService = StorageService();

  /// Vérifier si une caisse est ouverte
  Future<bool> isRegisterOpen({String? warehouseId, String? deviceId}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CashRegisterApiService] 🔍 Checking if register is open...');
      print('[CashRegisterApiService] 📦 Params: warehouseId=$warehouseId, deviceId=$deviceId');

      // Construire l'URL avec les query params
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (deviceId != null) queryParams['device_id'] = deviceId;

      final uri = Uri.parse(AppConstants.activeCashRegisterEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('[CashRegisterApiService] 🌐 URL: ${uri.toString()}');
      print('[CashRegisterApiService] 📤 Sending GET request...');

      final response = await _apiService.get(uri.toString());

      print('[CashRegisterApiService] 📥 Response status: ${response.statusCode}');
      print('[CashRegisterApiService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final registerData = data['data'];
          final status = registerData['status'] as String?;
          final isOpen = status == 'open';

          print('[CashRegisterApiService] ✅ Register status: $status, isOpen: $isOpen');
          print('═══════════════════════════════════════════════════════');
          return isOpen;
        }
      }

      print('[CashRegisterApiService] ⚠️ No active register found');
      print('═══════════════════════════════════════════════════════');
      return false;
    } catch (e) {
      print('[CashRegisterApiService] ❌ Error checking register status: $e');
      print('[CashRegisterApiService] ❌ Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Obtenir la caisse active
  Future<CashRegister?> getActiveRegister({String? warehouseId, String? deviceId}) async {
    try {
      print('[CashRegisterApiService] Getting active register...');

      // Construire l'URL avec les query params
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (deviceId != null) queryParams['device_id'] = deviceId;

      final uri = Uri.parse(AppConstants.activeCashRegisterEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await _apiService.get(uri.toString());

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final registerData = data['data'];
          print('[CashRegisterApiService] Active register found: ${registerData['id']}');
          return CashRegister.fromJson(registerData);
        }
      }

      print('[CashRegisterApiService] No active register found');
      return null;
    } catch (e) {
      print('[CashRegisterApiService] Error getting active register: $e');
      return null;
    }
  }

  /// Ouvrir une caisse
  Future<CashRegister> openRegister({
    required double openingBalance,
    required String userId,
    required String deviceId,
    required String warehouseId,
    String? notes,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CashRegisterApiService] 🔓 Opening register...');
      print('[CashRegisterApiService] 📦 Request data:');
      print('  - opening_balance: $openingBalance');
      print('  - user_id: $userId');
      print('  - device_id: $deviceId');
      print('  - warehouse_id: $warehouseId');
      print('  - notes: $notes');

      final requestData = {
        'opening_balance': openingBalance,
        'user_id': userId,
        'device_id': deviceId,
        'warehouse_id': warehouseId,
        'notes': notes,
      };

      print('[CashRegisterApiService] 🌐 URL: ${AppConstants.openCashRegisterEndpoint}');
      print('[CashRegisterApiService] 📤 Sending POST request...');

      final response = await _apiService.post(
        AppConstants.openCashRegisterEndpoint,
        data: requestData,
      );

      print('[CashRegisterApiService] 📥 Response status: ${response.statusCode}');
      print('[CashRegisterApiService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final registerData = data['data'];
          final cashRegister = CashRegister.fromJson(registerData);

          print('[CashRegisterApiService] 💾 Saving register locally...');
          // Sauvegarder localement
          await _storageService.saveCashRegister(registerData);

          // Marquer comme synchronisé
          await _storageService.writeSetting(
            AppConstants.currentCashRegisterKey,
            cashRegister.id,
          );

          print('[CashRegisterApiService] ✅ Register opened successfully!');
          print('[CashRegisterApiService] 🆔 Register ID: ${cashRegister.id}');
          print('[CashRegisterApiService] 💰 Opening balance: ${cashRegister.openingBalance}');
          print('═══════════════════════════════════════════════════════');
          return cashRegister;
        }
      }

      print('[CashRegisterApiService] ❌ Unexpected response format');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Erreur lors de l\'ouverture de la caisse');
    } catch (e) {
      print('[CashRegisterApiService] ❌ Error opening register: $e');
      print('[CashRegisterApiService] ❌ Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Fermer une caisse
  Future<CashRegister> closeRegister({
    required String registerId,
    required double closingBalance,
    String? notes,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[CashRegisterApiService] 🔒 Closing register...');
      print('[CashRegisterApiService] 🆔 Register ID: $registerId');
      print('[CashRegisterApiService] 📦 Request data:');
      print('  - closing_balance: $closingBalance');
      print('  - notes: $notes');

      final requestData = {
        'closing_balance': closingBalance,
        'notes': notes,
      };

      print('[CashRegisterApiService] 🌐 URL: ${AppConstants.closeCashRegisterEndpoint(registerId)}');
      print('[CashRegisterApiService] 📤 Sending POST request...');

      final response = await _apiService.post(
        AppConstants.closeCashRegisterEndpoint(registerId),
        data: requestData,
      );

      print('[CashRegisterApiService] 📥 Response status: ${response.statusCode}');
      print('[CashRegisterApiService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final registerData = data['data'];
          final cashRegister = CashRegister.fromJson(registerData);

          print('[CashRegisterApiService] 💾 Saving closed register locally...');
          // Sauvegarder localement
          await _storageService.saveCashRegister(registerData);

          // Effacer la caisse courante
          await _storageService.writeSetting(
            AppConstants.currentCashRegisterKey,
            '',
          );

          print('[CashRegisterApiService] ✅ Register closed successfully!');
          print('[CashRegisterApiService] 💰 Closing balance: ${cashRegister.closingBalance}');
          print('[CashRegisterApiService] 📊 Difference: ${cashRegister.difference ?? 0}');
          print('═══════════════════════════════════════════════════════');
          return cashRegister;
        }
      }

      print('[CashRegisterApiService] ❌ Unexpected response format');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Erreur lors de la fermeture de la caisse');
    } catch (e) {
      print('[CashRegisterApiService] ❌ Error closing register: $e');
      print('[CashRegisterApiService] ❌ Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }
}
