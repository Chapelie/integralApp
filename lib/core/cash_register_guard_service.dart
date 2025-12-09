// lib/core/cash_register_guard_service.dart
// Service pour vérifier et forcer l'ouverture de caisse

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cash_register_api_service.dart';
import 'cash_register_service.dart';
import 'sync_service.dart';
import '../features/cash_register/force_open_register_dialog.dart';
import '../providers/cash_register_provider.dart';

class CashRegisterGuardService {
  static final CashRegisterGuardService _instance = CashRegisterGuardService._internal();
  factory CashRegisterGuardService() => _instance;
  CashRegisterGuardService._internal();

  final _apiService = CashRegisterApiService();
  final _syncService = SyncService();
  final _cashRegisterService = CashRegisterService();

  /// Vérifier si une caisse est ouverte et afficher un dialog si nécessaire
  Future<bool> checkAndForceOpenRegister(BuildContext context, WidgetRef ref) async {
    try {
      print('[CashRegisterGuardService] 🔍 Checking register status...');
      
      // D'abord, vérifier dans le cache local
      final localRegister = _cashRegisterService.getCurrentRegister();
      if (localRegister != null && localRegister.status == 'open') {
        print('[CashRegisterGuardService] ✅ Register found in local cache: ${localRegister.id}');
        
        // Mettre à jour le provider avec le registre local
        ref.read(cashRegisterProvider.notifier).state = CashRegisterState(
          currentRegister: localRegister,
          canSell: true,
          isLoading: false,
        );
        return true;
      }
      
      // Si pas de cache local, rafraîchir depuis le backend
      await ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
      
      // Vérifier l'état de la caisse dans le provider
      final cashRegisterState = ref.read(cashRegisterProvider);
      print('[CashRegisterGuardService] 📊 Register state: ${cashRegisterState.currentRegister?.id}, canSell: ${cashRegisterState.canSell}');
      
      if (cashRegisterState.currentRegister != null && cashRegisterState.canSell) {
        print('[CashRegisterGuardService] ✅ Register is open');
        return true;
      }

      print('[CashRegisterGuardService] ❌ No register open, showing dialog');
      // Aucune caisse ouverte, afficher le dialog pour ouvrir
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ForceOpenRegisterDialog(),
      );

      return result ?? false;
    } catch (e) {
      print('[CashRegisterGuardService] ❌ Error checking register: $e');
      
      // En cas d'erreur, afficher le dialog d'ouverture
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ForceOpenRegisterDialog(),
      );

      return result ?? false;
    }
  }

  /// Vérifier si une caisse est ouverte (sans dialog)
  Future<bool> isRegisterOpen() async {
    try {
      return await _apiService.isRegisterOpen();
    } catch (e) {
      print('[CashRegisterGuardService] Error checking register status: $e');
      return false;
    }
  }
}
