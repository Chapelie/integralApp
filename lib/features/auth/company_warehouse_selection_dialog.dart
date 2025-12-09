// lib/features/auth/company_warehouse_selection_dialog.dart
// Dialog pour sélectionner company et warehouse

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/company_warehouse_service.dart';
import '../../core/device_registration_service.dart';
import '../../core/warehouse_type_service.dart';
import '../../models/company.dart';
import '../../models/warehouse.dart';

class CompanyWarehouseSelectionDialog extends ConsumerStatefulWidget {
  final List<Company> companies;
  final List<Warehouse>? warehouses;
  final String? selectedCompanyId;
  final String? selectedWarehouseId;

  const CompanyWarehouseSelectionDialog({
    super.key,
    required this.companies,
    this.warehouses,
    this.selectedCompanyId,
    this.selectedWarehouseId,
  });

  @override
  ConsumerState<CompanyWarehouseSelectionDialog> createState() => _CompanyWarehouseSelectionDialogState();
}

class _CompanyWarehouseSelectionDialogState extends ConsumerState<CompanyWarehouseSelectionDialog> {
  String? _selectedCompanyId;
  String? _selectedWarehouseId;
  List<Warehouse> _warehouses = [];
  bool _isLoadingWarehouses = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.selectedCompanyId;
    _selectedWarehouseId = widget.selectedWarehouseId;
    _warehouses = widget.warehouses ?? [];
    
    // Si une company est déjà sélectionnée, charger ses warehouses
    if (_selectedCompanyId != null && _warehouses.isEmpty) {
      _loadWarehouses(_selectedCompanyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return AlertDialog(
      title: const Text('Sélectionner Company et Warehouse'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message d'information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: theme.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez sélectionner une company et un warehouse pour continuer.',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sélection de Company
          Text(
            'Company',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCompanyId,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hint: const Text('Sélectionner une company'),
                items: widget.companies.map((company) {
                  return DropdownMenuItem<String>(
                    value: company.id,
                    child: Text(company.name),
                  );
                }).toList(),
                onChanged: (String? value) {
                  print('[CompanyWarehouseSelectionDialog] Company selection changed to: $value');
                  setState(() {
                    _selectedCompanyId = value;
                    _selectedWarehouseId = null;
                    _warehouses = [];
                  });
                  
                  if (value != null) {
                    print('[CompanyWarehouseSelectionDialog] Loading warehouses for selected company...');
                    _loadWarehouses(value);
                  } else {
                    print('[CompanyWarehouseSelectionDialog] No company selected, clearing warehouses');
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sélection de Warehouse
          Text(
            'Warehouse',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_isLoadingWarehouses) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chargement des warehouses...',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_warehouses.isEmpty && _selectedCompanyId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Aucun warehouse trouvé pour cette company',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWarehouseId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hint: Text(_selectedCompanyId == null 
                      ? 'Sélectionner d\'abord une company'
                      : 'Sélectionner un warehouse'),
                  items: _warehouses.map((warehouse) {
                    return DropdownMenuItem<String>(
                      value: warehouse.id,
                      child: Text(warehouse.name),
                    );
                  }).toList(),
                  onChanged: _selectedCompanyId == null ? null : (String? value) {
                    print('[CompanyWarehouseSelectionDialog] Warehouse selection changed to: $value');
                    setState(() {
                      _selectedWarehouseId = value;
                    });
                    print('[CompanyWarehouseSelectionDialog] Can confirm selection: ${_canConfirm()}');
                  },
                ),
              ),
            ),
          ],
          
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: theme.colors.destructive,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.destructive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        FButton(
          onPress: _canConfirm() ? _handleConfirm : null,
          style: FButtonStyle.primary(),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  bool _canConfirm() {
    return _selectedCompanyId != null && 
           _selectedWarehouseId != null && 
           !_isLoadingWarehouses;
  }

  Future<void> _loadWarehouses(String companyId) async {
    print('[CompanyWarehouseSelectionDialog] Loading warehouses for company: $companyId');
    
    setState(() {
      _isLoadingWarehouses = true;
      _error = null;
    });

    try {
      final service = CompanyWarehouseService();
      print('[CompanyWarehouseSelectionDialog] Calling getCompanyWarehouses...');
      final warehouses = await service.getCompanyWarehouses(companyId);
      print('[CompanyWarehouseSelectionDialog] Retrieved ${warehouses.length} warehouses');
      
      setState(() {
        _warehouses = warehouses;
        _isLoadingWarehouses = false;
      });
      
      print('[CompanyWarehouseSelectionDialog] Warehouses loaded successfully');
    } catch (e) {
      print('[CompanyWarehouseSelectionDialog] Error loading warehouses: $e');
      setState(() {
        _error = 'Erreur lors du chargement des warehouses: ${e.toString()}';
        _isLoadingWarehouses = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_canConfirm()) {
      print('[CompanyWarehouseSelectionDialog] Cannot confirm - missing selections or still loading');
      return;
    }

    print('[CompanyWarehouseSelectionDialog] Confirming selection...');
    print('[CompanyWarehouseSelectionDialog] Selected Company ID: $_selectedCompanyId');
    print('[CompanyWarehouseSelectionDialog] Selected Warehouse ID: $_selectedWarehouseId');

    try {
      final service = CompanyWarehouseService();
      
      print('[CompanyWarehouseSelectionDialog] Saving company selection...');
      await service.selectCompany(_selectedCompanyId!);
      print('[CompanyWarehouseSelectionDialog] Company selection saved successfully');
      
      print('[CompanyWarehouseSelectionDialog] Saving warehouse selection...');
      await service.selectWarehouse(_selectedWarehouseId!);
      print('[CompanyWarehouseSelectionDialog] Warehouse selection saved successfully');

      // Déclencher l'enregistrement du device maintenant qu'on a le warehouse_id
      print('[CompanyWarehouseSelectionDialog] Triggering device registration...');
      final deviceService = DeviceRegistrationService();
      try {
        await deviceService.registerDeviceToBackend();
        print('[CompanyWarehouseSelectionDialog] Device registration triggered successfully');
      } catch (e) {
        print('[CompanyWarehouseSelectionDialog] Device registration failed: $e');
        // On continue même si l'enregistrement échoue, le polling se chargera de réessayer
      }

      // Récupérer le type de warehouse depuis le backend
      print('[CompanyWarehouseSelectionDialog] Fetching warehouse type...');
      final warehouseTypeService = WarehouseTypeService();
      try {
        await warehouseTypeService.fetchAndStoreWarehouseType();
        print('[CompanyWarehouseSelectionDialog] Warehouse type fetched successfully');
      } catch (e) {
        print('[CompanyWarehouseSelectionDialog] Error fetching warehouse type: $e');
        // On continue même si la récupération du type échoue
      }

      if (mounted) {
        print('[CompanyWarehouseSelectionDialog] Closing dialog with success result');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('[CompanyWarehouseSelectionDialog] Error saving selections: $e');
      setState(() {
        _error = 'Erreur lors de la sauvegarde: ${e.toString()}';
      });
    }
  }
}
