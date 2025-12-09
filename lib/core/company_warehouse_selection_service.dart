// lib/core/company_warehouse_selection_service.dart
// Service pour gérer la sélection de company/warehouse après login

import 'package:flutter/material.dart';
import 'company_warehouse_service.dart';
import 'storage_service.dart';
import '../models/company.dart';
import '../models/warehouse.dart';
import '../features/auth/company_warehouse_selection_dialog.dart';

class CompanyWarehouseSelectionService {
  static final CompanyWarehouseSelectionService _instance = CompanyWarehouseSelectionService._internal();
  factory CompanyWarehouseSelectionService() => _instance;
  CompanyWarehouseSelectionService._internal();

  final _companyWarehouseService = CompanyWarehouseService();
  final _storageService = StorageService();

  /// Vérifier si l'utilisateur a déjà une sélection
  Future<bool> hasExistingSelection() async {
    try {
      print('[CompanyWarehouseSelectionService] Checking for existing selection...');
      
      // Vérifier si l'utilisateur a déjà une company et warehouse sélectionnées
      final selectedCompanyId = await _storageService.readSetting('selected_company_id');
      final selectedWarehouseId = await _storageService.readSetting('selected_warehouse_id');
      
      print('[CompanyWarehouseSelectionService] Selected company ID: $selectedCompanyId');
      print('[CompanyWarehouseSelectionService] Selected warehouse ID: $selectedWarehouseId');
      
      if (selectedCompanyId != null && selectedWarehouseId != null) {
        print('[CompanyWarehouseSelectionService] User has existing selection');
        return true;
      } else {
        print('[CompanyWarehouseSelectionService] No existing selection found');
        return false;
      }
    } catch (e) {
      print('[CompanyWarehouseSelectionService] Error checking existing selection: $e');
      return false;
    }
  }

  /// Vérifier et afficher le dialog de sélection si nécessaire
  Future<bool> checkAndShowSelectionDialog(BuildContext context) async {
    try {
      print('[CompanyWarehouseSelectionService] Starting selection check workflow...');
      
      // Vérifier si une sélection existe déjà
      print('[CompanyWarehouseSelectionService] Checking if selection already exists...');
      final hasSelection = await _companyWarehouseService.hasSelection();
      print('[CompanyWarehouseSelectionService] Has existing selection: $hasSelection');
      
      if (hasSelection) {
        print('[CompanyWarehouseSelectionService] Selection already exists, skipping dialog');
        return true;
      }

      // Obtenir les companies de l'utilisateur
      print('[CompanyWarehouseSelectionService] Fetching user companies...');
      final companies = await _companyWarehouseService.getUserCompanies();
      print('[CompanyWarehouseSelectionService] Retrieved ${companies.length} companies');
      
      if (companies.isEmpty) {
        print('[CompanyWarehouseSelectionService] No companies found, cannot proceed');
        return false;
      }

      // Si une seule company, la sélectionner automatiquement
      if (companies.length == 1) {
        final company = companies.first;
        print('[CompanyWarehouseSelectionService] Only one company found, auto-selecting: ${company.name} (${company.id})');
        
        await _companyWarehouseService.selectCompany(company.id);
        print('[CompanyWarehouseSelectionService] Company selected successfully');
        
        // Obtenir les warehouses de cette company
        print('[CompanyWarehouseSelectionService] Fetching warehouses for company: ${company.id}');
        final warehouses = await _companyWarehouseService.getCompanyWarehouses(company.id);
        print('[CompanyWarehouseSelectionService] Retrieved ${warehouses.length} warehouses');
        
        if (warehouses.isNotEmpty) {
          // Si un seul warehouse, le sélectionner automatiquement
          if (warehouses.length == 1) {
            final warehouse = warehouses.first;
            print('[CompanyWarehouseSelectionService] Only one warehouse found, auto-selecting: ${warehouse.name} (${warehouse.id})');
            await _companyWarehouseService.selectWarehouse(warehouse.id);
            print('[CompanyWarehouseSelectionService] Auto-selected company and warehouse successfully');
            return true;
          } else {
            // Plusieurs warehouses, afficher le dialog
            print('[CompanyWarehouseSelectionService] Multiple warehouses found, showing selection dialog');
            return await _showSelectionDialog(context, companies, warehouses, company.id);
          }
        } else {
          print('[CompanyWarehouseSelectionService] No warehouses found for company ${company.id}');
          return false;
        }
      } else {
        // Plusieurs companies, afficher le dialog
        print('[CompanyWarehouseSelectionService] Multiple companies found (${companies.length}), showing selection dialog');
        return await _showSelectionDialog(context, companies, null, null);
      }
    } catch (e) {
      print('[CompanyWarehouseSelectionService] Error checking selection: $e');
      return false;
    }
  }

  /// Afficher le dialog de sélection
  Future<bool> _showSelectionDialog(
    BuildContext context,
    List<Company> companies,
    List<Warehouse>? warehouses,
    String? selectedCompanyId,
  ) async {
    try {
      print('[CompanyWarehouseSelectionService] Showing selection dialog...');
      print('[CompanyWarehouseSelectionService] Companies count: ${companies.length}');
      print('[CompanyWarehouseSelectionService] Warehouses count: ${warehouses?.length ?? 0}');
      print('[CompanyWarehouseSelectionService] Pre-selected company ID: $selectedCompanyId');
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CompanyWarehouseSelectionDialog(
          companies: companies,
          warehouses: warehouses,
          selectedCompanyId: selectedCompanyId,
        ),
      );

      print('[CompanyWarehouseSelectionService] Dialog result: $result');
      return result ?? false;
    } catch (e) {
      print('[CompanyWarehouseSelectionService] Error showing dialog: $e');
      return false;
    }
  }

  /// Forcer l'affichage du dialog de sélection
  Future<bool> showSelectionDialog(BuildContext context) async {
    try {
      final companies = await _companyWarehouseService.getUserCompanies();
      
      if (companies.isEmpty) {
        print('[CompanyWarehouseSelectionService] No companies available');
        return false;
      }

      return await _showSelectionDialog(context, companies, null, null);
    } catch (e) {
      print('[CompanyWarehouseSelectionService] Error showing forced dialog: $e');
      return false;
    }
  }
}
