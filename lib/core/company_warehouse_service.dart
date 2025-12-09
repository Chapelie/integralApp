// lib/core/company_warehouse_service.dart
// Service pour gérer les companies et warehouses

import 'package:dio/dio.dart';
import 'constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/company.dart';
import '../models/warehouse.dart';

class CompanyWarehouseService {
  static final CompanyWarehouseService _instance = CompanyWarehouseService._internal();
  factory CompanyWarehouseService() => _instance;
  CompanyWarehouseService._internal();

  final _apiService = ApiService();
  final _storageService = StorageService();

  // Storage keys
  static const String _selectedCompanyKey = 'selected_company_id';
  static const String _selectedWarehouseKey = 'selected_warehouse_id';
  static const String _companiesKey = 'companies';
  static const String _warehousesKey = 'warehouses';

  /// Obtenir les companies de l'utilisateur
  Future<List<Company>> getUserCompanies() async {
    try {
      print('[CompanyWarehouseService] Getting user companies...');
      print('[CompanyWarehouseService] API Endpoint: ${AppConstants.companiesEndpoint}');
      
      final response = await _apiService.get(AppConstants.companiesEndpoint);
      
      print('[CompanyWarehouseService] API Response Status: ${response.statusCode}');
      print('[CompanyWarehouseService] API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[CompanyWarehouseService] Response success field: ${data['success']}');
        print('[CompanyWarehouseService] Response data field exists: ${data['data'] != null}');
        
        if (data['success'] == true && data['data'] != null) {
          final companiesData = data['data'] as List;
          print('[CompanyWarehouseService] Raw companies data: $companiesData');
          print('[CompanyWarehouseService] Number of companies in response: ${companiesData.length}');
          
          final companies = companiesData
              .map((json) {
                print('[CompanyWarehouseService] Processing company: $json');
                return Company.fromJson(json as Map<String, dynamic>);
              })
              .toList();
          
          print('[CompanyWarehouseService] Successfully parsed ${companies.length} companies');
          for (int i = 0; i < companies.length; i++) {
            final company = companies[i];
            print('[CompanyWarehouseService] Company $i: ID=${company.id}, Name=${company.name}');
          }
          
          // Sauvegarder localement
          try {
            await _storageService.writeSetting(
              _companiesKey,
              companies.map((c) => c.toJson()).toList(),
            );
            print('[CompanyWarehouseService] Companies saved to local storage successfully');
          } catch (storageError) {
            print('[CompanyWarehouseService] Error saving companies to storage: $storageError');
          }
          
          print('[CompanyWarehouseService] Found ${companies.length} companies');
          return companies;
        } else {
          print('[CompanyWarehouseService] API response indicates failure or no data');
          print('[CompanyWarehouseService] Success field: ${data['success']}');
          print('[CompanyWarehouseService] Data field: ${data['data']}');
        }
      } else {
        print('[CompanyWarehouseService] API returned non-200 status: ${response.statusCode}');
      }
      
      throw Exception('Erreur lors de la récupération des companies');
    } catch (e) {
      print('[CompanyWarehouseService] Error getting companies: $e');
      
      // Essayer de récupérer depuis le stockage local
      try {
        final companiesData = await _storageService.readSetting(_companiesKey);
        if (companiesData != null) {
          final companies = (companiesData as List)
              .map((json) => Company.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList();
          print('[CompanyWarehouseService] Loaded ${companies.length} companies from storage');
          return companies;
        }
      } catch (storageError) {
        print('[CompanyWarehouseService] Error loading from storage: $storageError');
      }
      
      rethrow;
    }
  }

  /// Obtenir les warehouses d'une company
  Future<List<Warehouse>> getCompanyWarehouses(String companyId) async {
    try {
      print('[CompanyWarehouseService] Getting warehouses for company: $companyId');
      final endpoint = AppConstants.warehousesEndpoint(companyId);
      print('[CompanyWarehouseService] API Endpoint: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      print('[CompanyWarehouseService] API Response Status: ${response.statusCode}');
      print('[CompanyWarehouseService] API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[CompanyWarehouseService] Response success field: ${data['success']}');
        print('[CompanyWarehouseService] Response data field exists: ${data['data'] != null}');
        
        if (data['success'] == true && data['data'] != null) {
          final warehousesData = data['data'] as List;
          print('[CompanyWarehouseService] Raw warehouses data: $warehousesData');
          print('[CompanyWarehouseService] Number of warehouses in response: ${warehousesData.length}');
          
          final warehouses = warehousesData
              .map((json) {
                print('[CompanyWarehouseService] Processing warehouse: $json');
                return Warehouse.fromJson(json as Map<String, dynamic>);
              })
              .toList();
          
          print('[CompanyWarehouseService] Successfully parsed ${warehouses.length} warehouses');
          for (int i = 0; i < warehouses.length; i++) {
            final warehouse = warehouses[i];
            print('[CompanyWarehouseService] Warehouse $i: ID=${warehouse.id}, Name=${warehouse.name}');
          }
          
          // Sauvegarder localement
          try {
            await _storageService.writeSetting(
              '${_warehousesKey}_$companyId',
              warehouses.map((w) => w.toJson()).toList(),
            );
            print('[CompanyWarehouseService] Warehouses saved to local storage successfully');
          } catch (storageError) {
            print('[CompanyWarehouseService] Error saving warehouses to storage: $storageError');
          }
          
          print('[CompanyWarehouseService] Found ${warehouses.length} warehouses for company $companyId');
          return warehouses;
        } else {
          print('[CompanyWarehouseService] API response indicates failure or no data');
          print('[CompanyWarehouseService] Success field: ${data['success']}');
          print('[CompanyWarehouseService] Data field: ${data['data']}');
        }
      } else {
        print('[CompanyWarehouseService] API returned non-200 status: ${response.statusCode}');
      }
      
      throw Exception('Erreur lors de la récupération des warehouses');
    } catch (e) {
      print('[CompanyWarehouseService] Error getting warehouses: $e');
      
      // Essayer de récupérer depuis le stockage local
      try {
        final warehousesData = await _storageService.readSetting('${_warehousesKey}_$companyId');
        if (warehousesData != null) {
          final warehouses = (warehousesData as List)
              .map((json) => Warehouse.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList();
          print('[CompanyWarehouseService] Loaded ${warehouses.length} warehouses from storage');
          return warehouses;
        }
      } catch (storageError) {
        print('[CompanyWarehouseService] Error loading warehouses from storage: $storageError');
      }
      
      rethrow;
    }
  }

  /// Sélectionner une company
  Future<void> selectCompany(String companyId) async {
    try {
      await _storageService.writeSetting(_selectedCompanyKey, companyId);
      print('[CompanyWarehouseService] Selected company: $companyId');
    } catch (e) {
      print('[CompanyWarehouseService] Error selecting company: $e');
      rethrow;
    }
  }

  /// Sélectionner un warehouse
  Future<void> selectWarehouse(String warehouseId) async {
    try {
      await _storageService.writeSetting(_selectedWarehouseKey, warehouseId);
      print('[CompanyWarehouseService] Selected warehouse: $warehouseId');
    } catch (e) {
      print('[CompanyWarehouseService] Error selecting warehouse: $e');
      rethrow;
    }
  }

  /// Obtenir la company sélectionnée
  Future<Company?> getSelectedCompany() async {
    try {
      final companyId = await _storageService.readSetting(_selectedCompanyKey);
      if (companyId == null) return null;

      final companies = await getUserCompanies();
      return companies.firstWhere(
        (c) => c.id == companyId,
        orElse: () => throw Exception('Company not found'),
      );
    } catch (e) {
      print('[CompanyWarehouseService] Error getting selected company: $e');
      return null;
    }
  }

  /// Obtenir le warehouse sélectionné
  Future<Warehouse?> getSelectedWarehouse() async {
    try {
      final warehouseId = await _storageService.readSetting(_selectedWarehouseKey);
      if (warehouseId == null) return null;

      final company = await getSelectedCompany();
      if (company == null) return null;

      final warehouses = await getCompanyWarehouses(company.id);
      return warehouses.firstWhere(
        (w) => w.id == warehouseId,
        orElse: () => throw Exception('Warehouse not found'),
      );
    } catch (e) {
      print('[CompanyWarehouseService] Error getting selected warehouse: $e');
      return null;
    }
  }

  /// Obtenir l'ID de la company sélectionnée
  Future<String?> getSelectedCompanyId() async {
    try {
      return await _storageService.readSetting(_selectedCompanyKey);
    } catch (e) {
      print('[CompanyWarehouseService] Error getting selected company ID: $e');
      return null;
    }
  }

  /// Obtenir l'ID du warehouse sélectionné
  Future<String?> getSelectedWarehouseId() async {
    try {
      return await _storageService.readSetting(_selectedWarehouseKey);
    } catch (e) {
      print('[CompanyWarehouseService] Error getting selected warehouse ID: $e');
      return null;
    }
  }

  /// Vérifier si une company et un warehouse sont sélectionnés
  Future<bool> hasSelection() async {
    final companyId = await getSelectedCompanyId();
    final warehouseId = await getSelectedWarehouseId();
    return companyId != null && warehouseId != null;
  }

  /// Effacer la sélection
  Future<void> clearSelection() async {
    try {
      await _storageService.writeSetting(_selectedCompanyKey, '');
      await _storageService.writeSetting(_selectedWarehouseKey, '');
      print('[CompanyWarehouseService] Selection cleared');
    } catch (e) {
      print('[CompanyWarehouseService] Error clearing selection: $e');
      rethrow;
    }
  }
}


