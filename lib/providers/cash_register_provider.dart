// cash_register_provider.dart
// Provider for cash register management
// Handles register opening/closing, validation, and sale recording

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cash_register.dart';
import '../models/sale.dart';
import '../core/cash_register_service.dart';
import '../core/cash_register_api_service.dart';
import '../core/company_warehouse_service.dart';
import '../core/device_service.dart';
import '../core/storage_service.dart';
import '../core/constants.dart';

part 'cash_register_provider.g.dart';

// Cash Register State
class CashRegisterState {
  final CashRegister? currentRegister;
  final List<CashRegister> history;
  final bool isLoading;
  final String? error;
  final bool canSell;

  CashRegisterState({
    this.currentRegister,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.canSell = false,
  });

  CashRegisterState copyWith({
    CashRegister? currentRegister,
    List<CashRegister>? history,
    bool? isLoading,
    String? error,
    bool? canSell,
  }) {
    return CashRegisterState(
      currentRegister: currentRegister ?? this.currentRegister,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      canSell: canSell ?? this.canSell,
    );
  }
}

// Cash Register Notifier
@riverpod
class CashRegisterNotifier extends _$CashRegisterNotifier {
  // API-backed service for opening/closing registers on the backend
  final CashRegisterApiService _apiRegisterService = CashRegisterApiService();
  // Local service for client-side updates like recording sales, caching, etc.
  final CashRegisterService _localRegisterService = CashRegisterService();
  // Storage service for saving data locally
  final StorageService _storageService = StorageService();

  @override
  CashRegisterState build() {
    // Don't call _loadCurrentAsync here to avoid circular dependency
    // Instead, load current register when the provider is first accessed
    return CashRegisterState();
  }

  // Public method to load current register (can be called from UI)
  Future<void> loadCurrentRegister() async {
    if (!ref.mounted) {
      print('[CashRegisterProvider] ⚠️ Provider not mounted, skipping load');
      return;
    }

    print('[CashRegisterProvider] ==========================================');
    print('[CashRegisterProvider] 🔍 DÉBUT loadCurrentRegister()');
    print('[CashRegisterProvider] État actuel: canSell=${state.canSell}, register=${state.currentRegister?.id}');

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[CashRegisterProvider] 🌐 Chargement de la caisse depuis le backend...');
      
      // Récupérer les IDs nécessaires
      final companyWarehouseService = CompanyWarehouseService();
      final deviceService = DeviceService();
      
      print('[CashRegisterProvider] 📍 Récupération warehouseId...');
      final warehouseId = await companyWarehouseService.getSelectedWarehouseId();
      print('[CashRegisterProvider] 📦 Warehouse ID: $warehouseId');
      
      print('[CashRegisterProvider] 📱 Récupération deviceId...');
      // Utiliser le backend_device_id si disponible, sinon le deviceId local
      final deviceId = await deviceService.getDeviceIdForApi();
      print('[CashRegisterProvider] 📱 Device ID: $deviceId');
      
      CashRegister? register;
      
      // Essayer de récupérer depuis le backend d'abord
      if (warehouseId != null && deviceId != null) {
        try {
          print('[CashRegisterProvider] 🌐 Fetching from backend API...');
          register = await _apiRegisterService.getActiveRegister(
            warehouseId: warehouseId,
            deviceId: deviceId,
          );
          
          if (register != null) {
            print('[CashRegisterProvider] ✅ Active register found on backend: ${register.id}');
            print('[CashRegisterProvider] 📊 Register status: ${register.status}');
            
            // Sauvegarder localement pour le cache (se fait toujours)
            await _storageService.saveCashRegister(register.toJson());
            await _storageService.writeSetting(
              AppConstants.currentCashRegisterKey,
              register.id,
            );
            
            // Vérifier si le provider est toujours monté AVANT de mettre à jour le state
            if (!ref.mounted) {
              print('[CashRegisterProvider] ⚠️ Provider disposed before state update');
              print('[CashRegisterProvider] ℹ️ Register saved locally: ${register.id}');
              return;
            }
            
            // Mettre à jour l'état maintenant qu'on est sûr que le provider est monté
            final canSell = register.status == 'open';
            print('[CashRegisterProvider] 📊 Register status: ${register.status}, canSell: $canSell');
            
            state = state.copyWith(
              currentRegister: register,
              canSell: canSell,
              isLoading: false,
            );
            print('[CashRegisterProvider] ✅ État mis à jour: register=${register.id}, canSell=$canSell');
            print('[CashRegisterProvider] ==========================================');
            return; // Sortir ici car on a trouvé une caisse active
          } else {
            print('[CashRegisterProvider] ⚠️ No active register found on backend');
            
            // Pas de caisse active, nettoyer le state
            register = null;
          }
        } catch (e) {
          print('[CashRegisterProvider] ❌ Backend fetch failed: $e');
          
          // Vérifier si le provider est toujours monté
          if (!ref.mounted) {
            print('[CashRegisterProvider] ⚠️ Provider disposed during backend fetch');
            return;
          }
          
          // En cas d'erreur backend, utiliser le fallback local uniquement
          register = _localRegisterService.getCurrentRegister();
          if (register != null) {
            print('[CashRegisterProvider] 📱 Using local register: ${register.id}');
            
          // Mettre à jour le state avec le registre local
          final canSell = register.status == 'open';
          print('[CashRegisterProvider] 📊 Local register status: ${register.status}, canSell: $canSell');
          
          state = state.copyWith(
            currentRegister: register,
            canSell: canSell,
            isLoading: false,
          );
          print('[CashRegisterProvider] ✅ État mis à jour avec registre local: register=${register.id}, canSell=$canSell');
          print('[CashRegisterProvider] ==========================================');
          return;
          }
        }
      } else {
        print('[CashRegisterProvider] ⚠️ Missing warehouse_id or device_id, using local storage');
        register = _localRegisterService.getCurrentRegister();
        if (register != null) {
          print('[CashRegisterProvider] 📱 Using local register: ${register.id}');
          
          // Mettre à jour le state avec le registre local
          if (!ref.mounted) {
            print('[CashRegisterProvider] ⚠️ Provider disposed before state update');
            return;
          }
          
          final canSell = register.status == 'open';
          print('[CashRegisterProvider] 📊 Local register status: ${register.status}, canSell: $canSell');
          
          state = state.copyWith(
            currentRegister: register,
            canSell: canSell,
            isLoading: false,
          );
          print('[CashRegisterProvider] ✅ État mis à jour avec registre local: register=${register.id}, canSell=$canSell');
          print('[CashRegisterProvider] ==========================================');
          return;
        }
      }
      
      // Aucune caisse trouvée, nettoyer le state
      print('[CashRegisterProvider] ⚠️ Aucune caisse active trouvée (ni backend ni local)');
      final history = _localRegisterService.getRegisterHistory();

      if (!ref.mounted) {
        print('[CashRegisterProvider] ⚠️ Provider disposed before final state update');
        return;
      }

      print('[CashRegisterProvider] 🎯 Mise à jour état final: Register=null, CanSell=false');

      state = state.copyWith(
        currentRegister: null,
        history: history,
        isLoading: false,
        canSell: false,
        error: null,
      );
      
      print('[CashRegisterProvider] ✅ État final mis à jour: canSell=${state.canSell}');
      print('[CashRegisterProvider] ==========================================');
    } catch (e) {
      print('[CashRegisterProvider] ❌ Error loading register: $e');
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Open register
  Future<void> openRegister(double openingBalance, String userId, String deviceId, String warehouseId, {String? notes}) async {
    if (!ref.mounted) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final register = await _apiRegisterService.openRegister(
        openingBalance: openingBalance,
        userId: userId,
        deviceId: deviceId,
        warehouseId: warehouseId,
        notes: notes,
      );

      if (!ref.mounted) return;

      state = state.copyWith(
        currentRegister: register,
        isLoading: false,
        canSell: true,
      );
    } catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Close register
  Future<void> closeRegister(double closingBalance, String? notes) async {
    if (!ref.mounted) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final current = state.currentRegister;
      if (current == null) {
        state = state.copyWith(isLoading: false, error: 'Aucune caisse ouverte');
        return;
      }

      final closedRegister = await _apiRegisterService.closeRegister(
        registerId: current.id,
        closingBalance: closingBalance,
        notes: notes,
      );

      if (!ref.mounted) return;

      final updatedHistory = [...state.history, closedRegister];

      state = state.copyWith(
        currentRegister: null,
        history: updatedHistory,
        isLoading: false,
        canSell: false,
      );
    } catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh register state from backend
  Future<void> refreshRegisterState() async {
    print('[CashRegisterProvider] 🔄 Refreshing register state from backend...');
    await loadCurrentRegister();
  }

  // Validate if can sell
  bool validateCanSell() {
    final canSell = state.currentRegister != null &&
                    state.currentRegister!.closedAt == null;

    state = state.copyWith(canSell: canSell);
    return canSell;
  }

  // Record sale
  Future<void> recordSale(Sale sale) async {
    if (!ref.mounted) return;
    
    if (!state.canSell) {
      if (!ref.mounted) return;
      state = state.copyWith(error: 'No register open');
      return;
    }

    try {
      await _localRegisterService.recordSale(
        sale.total,
        saleId: sale.id,
        userId: sale.userId,
      );

      if (!ref.mounted) return;

      // Update current register with new sale
      final currentSalesCount = state.currentRegister!.salesCount ?? 0;
      final currentTotalSales = state.currentRegister!.totalSales ?? 0.0;
      final currentExpectedCash = state.currentRegister!.expectedCash ?? state.currentRegister!.openingBalance;

      final updatedRegister = state.currentRegister!.copyWith(
        salesCount: currentSalesCount + 1,
        totalSales: currentTotalSales + sale.total,
        expectedCash: currentExpectedCash + sale.total,
      );

      state = state.copyWith(
        currentRegister: updatedRegister,
        error: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  // Reset all registers (for testing)
  Future<void> resetAllRegisters() async {
    try {
      await _localRegisterService.resetAllRegisters();
      state = CashRegisterState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
