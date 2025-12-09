// lib/core/warehouse_type_service.dart
// Service to fetch and store warehouse type from API

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/warehouse_type.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';
import 'business_config.dart';

class WarehouseTypeService {
  static final WarehouseTypeService _instance = WarehouseTypeService._internal();
  factory WarehouseTypeService() => _instance;
  WarehouseTypeService._internal();

  final _apiService = ApiService();
  final _storageService = StorageService();
  final _companyWarehouseService = CompanyWarehouseService();

  static const String _warehouseTypeKey = 'warehouse_type';

  /// Fetch warehouse type from API and store it locally
  Future<WarehouseType?> fetchAndStoreWarehouseType() async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[WarehouseTypeService] 📦 Récupération du type de warehouse...');

      // Get warehouse ID
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      print('[WarehouseTypeService] 🏪 Warehouse ID: $warehouseId');

      if (warehouseId == null) {
        print('[WarehouseTypeService] ❌ Aucun warehouse sélectionné');
        print('═══════════════════════════════════════════════════════');
        return null;
      }

      final endpoint = AppConstants.warehouseTypeEndpoint(warehouseId);
      print('[WarehouseTypeService] 🌐 URL: $endpoint');
      print('[WarehouseTypeService] 📤 Envoi de la requête GET...');

      final response = await _apiService.get(endpoint);

      print('[WarehouseTypeService] 📥 Response status: ${response.statusCode}');
      print('[WarehouseTypeService] 📥 Response data: ${response.data}');

      if (response.data['success'] == true) {
        // Le backend retourne directement le type dans 'data', pas dans un objet 'type'
        final typeValue = response.data['data'] as String?;
        print('[WarehouseTypeService] 📋 Type reçu: $typeValue');

        final warehouseType = WarehouseType.fromString(typeValue);

        if (warehouseType != null) {
          // Store locally
          print('[WarehouseTypeService] 💾 Sauvegarde locale du type...');
          await _storageService.writeSetting(_warehouseTypeKey, warehouseType.value);
          print('[WarehouseTypeService] ✅ Type sauvegardé: ${warehouseType.displayName}');
          
          // Synchroniser avec BusinessConfig pour mettre à jour les fonctionnalités
          // Cette synchronisation est asynchrone et ne bloque pas
          _syncWithBusinessConfig(warehouseType);
          
          print('═══════════════════════════════════════════════════════');
          return warehouseType;
        } else {
          print('[WarehouseTypeService] ⚠️ Type de warehouse inconnu: $typeValue');
          print('═══════════════════════════════════════════════════════');
          return null;
        }
      } else {
        print('[WarehouseTypeService] ❌ Réponse API invalide');
        print('[WarehouseTypeService] Message: ${response.data['message']}');
        print('═══════════════════════════════════════════════════════');
        return null;
      }
    } catch (e) {
      print('[WarehouseTypeService] ❌ ERREUR récupération type: $e');
      print('[WarehouseTypeService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('═══════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Synchronise le type de warehouse avec BusinessConfig
  void _syncWithBusinessConfig(WarehouseType warehouseType) {
    // Cette méthode doit être appelée de manière asynchrone
    _syncWithBusinessConfigAsync(warehouseType);
  }

  /// Synchronise de manière asynchrone
  Future<void> _syncWithBusinessConfigAsync(WarehouseType warehouseType) async {
    try {
      print('[WarehouseTypeService] 🔄 Synchronisation avec BusinessConfig...');
      
      final businessConfig = BusinessConfig();
      
      // Convertir le WarehouseType en BusinessType
      BusinessType businessType;
      switch (warehouseType) {
        case WarehouseType.restaurant:
          businessType = BusinessType.restaurant;
          break;
        case WarehouseType.supermarket:
        case WarehouseType.pharmacie:
        case WarehouseType.electronique:
          // Tous ces types sont des commerces de détail
          businessType = BusinessType.retail;
          break;
        default:
          businessType = BusinessType.retail;
      }
      
      print('[WarehouseTypeService] 🔄 Configuration du type business: ${businessType.label}');
      await businessConfig.init(businessType);
      print('[WarehouseTypeService] ✅ BusinessConfig mis à jour avec succès');
      
      // Notifier les widgets qui utilisent les fonctionnalités
      print('[WarehouseTypeService] 🔔 Les fonctionnalités ont été mises à jour');
    } catch (e) {
      print('[WarehouseTypeService] ❌ Erreur synchronisation BusinessConfig: $e');
    }
  }

  /// Get stored warehouse type from local storage
  Future<WarehouseType?> getStoredWarehouseType() async {
    try {
      final typeValue = await _storageService.readSetting(_warehouseTypeKey);
      if (typeValue != null && typeValue is String) {
        return WarehouseType.fromString(typeValue);
      }
      return null;
    } catch (e) {
      print('[WarehouseTypeService] Error getting stored type: $e');
      return null;
    }
  }

  /// Check if warehouse type is stored
  Future<bool> hasWarehouseType() async {
    final type = await getStoredWarehouseType();
    return type != null;
  }

  /// Clear stored warehouse type
  Future<void> clearWarehouseType() async {
    try {
      await _storageService.deleteSetting(_warehouseTypeKey);
      print('[WarehouseTypeService] Warehouse type cleared');
    } catch (e) {
      print('[WarehouseTypeService] Error clearing type: $e');
    }
  }
}