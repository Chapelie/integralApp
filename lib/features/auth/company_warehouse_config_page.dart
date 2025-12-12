// lib/features/auth/company_warehouse_config_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/company_warehouse_service.dart';
import '../../core/company_warehouse_selection_service.dart';
import '../../core/device_registration_service.dart';
import '../../core/warehouse_type_service.dart';
import '../../models/company.dart';
import '../../models/warehouse.dart';
import '../../providers/cash_register_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';

class CompanyWarehouseConfigPage extends ConsumerStatefulWidget {
  const CompanyWarehouseConfigPage({super.key});

  @override
  ConsumerState<CompanyWarehouseConfigPage> createState() => _CompanyWarehouseConfigPageState();
}

class _CompanyWarehouseConfigPageState extends ConsumerState<CompanyWarehouseConfigPage> {
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();
  
  List<Company> _companies = [];
  List<Warehouse> _warehouses = [];
  String? _selectedCompanyId;
  String? _selectedWarehouseId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('[CompanyWarehouseConfigPage] Loading companies and warehouses...');
      
      // Charger les companies
      _companies = await _companyWarehouseService.getUserCompanies();
      print('[CompanyWarehouseConfigPage] Loaded ${_companies.length} companies');

      if (_companies.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune entreprise trouvée pour cet utilisateur';
          _isLoading = false;
        });
        return;
      }

      // Si une seule company, la sélectionner automatiquement
      if (_companies.length == 1) {
        _selectedCompanyId = _companies.first.id;
        await _loadWarehouses(_companies.first.id);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('[CompanyWarehouseConfigPage] Error loading data: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWarehouses(String companyId) async {
    try {
      print('[CompanyWarehouseConfigPage] Loading warehouses for company: $companyId');
      _warehouses = await _companyWarehouseService.getCompanyWarehouses(companyId);
      print('[CompanyWarehouseConfigPage] Loaded ${_warehouses.length} warehouses');

      // Si un seul warehouse, le sélectionner automatiquement
      if (_warehouses.length == 1) {
        _selectedWarehouseId = _warehouses.first.id;
      }

      setState(() {});
    } catch (e) {
      print('[CompanyWarehouseConfigPage] Error loading warehouses: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des entrepôts: ${e.toString()}';
      });
    }
  }

  Future<void> _onCompanyChanged(String? companyId) async {
    if (companyId == null) return;
    
    setState(() {
      _selectedCompanyId = companyId;
      _selectedWarehouseId = null;
      _warehouses = [];
    });

    await _loadWarehouses(companyId);
  }

  Future<void> _confirmSelection() async {
    if (_selectedCompanyId == null || _selectedWarehouseId == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une entreprise et un entrepôt';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('[CompanyWarehouseConfigPage] Confirming selection...');
      print('[CompanyWarehouseConfigPage] Company ID: $_selectedCompanyId');
      print('[CompanyWarehouseConfigPage] Warehouse ID: $_selectedWarehouseId');

      // Sélectionner la company et le warehouse
      await _companyWarehouseService.selectCompany(_selectedCompanyId!);
      await _companyWarehouseService.selectWarehouse(_selectedWarehouseId!);

      print('[CompanyWarehouseConfigPage] Selection confirmed successfully');

      // Déclencher l'enregistrement du device maintenant qu'on a le warehouse_id
      print('[CompanyWarehouseConfigPage] Triggering device registration...');
      final deviceService = DeviceRegistrationService();
      try {
        await deviceService.registerDeviceToBackend();
        print('[CompanyWarehouseConfigPage] Device registration triggered successfully');
      } catch (e) {
        print('[CompanyWarehouseConfigPage] Device registration failed: $e');
        // On continue même si l'enregistrement échoue, le polling se chargera de réessayer
      }

      // Récupérer le type de warehouse depuis le backend
      print('[CompanyWarehouseConfigPage] Fetching warehouse type...');
      final warehouseTypeService = WarehouseTypeService();
      try {
        await warehouseTypeService.fetchAndStoreWarehouseType();
        print('[CompanyWarehouseConfigPage] Warehouse type fetched successfully');
      } catch (e) {
        print('[CompanyWarehouseConfigPage] Error fetching warehouse type: $e');
        // On continue même si la récupération du type échoue
      }

      // Vérifier l'état de la caisse
      final cashRegisterState = ref.read(cashRegisterProvider);
      
      if (cashRegisterState.currentRegister != null && cashRegisterState.canSell) {
        // Naviguer vers la page POS
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/pos');
        }
      } else {
        // Naviguer vers la page d'ouverture de caisse
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/open-register');
        }
      }
    } catch (e) {
      print('[CompanyWarehouseConfigPage] Error confirming selection: $e');
      setState(() {
        _errorMessage = 'Erreur lors de la confirmation: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
        appBar: UnifiedHeader(
          title: 'Configuration',
          color: theme.colors.primary,
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des données...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colors.destructive,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur',
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FButton(
                          onPress: _loadData,
                          style: FButtonStyle.outline(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre
                        Text(
                          'Configuration de l\'entreprise',
                          style: theme.typography.xl.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sélectionnez votre entreprise et votre entrepôt pour continuer',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Sélection de l'entreprise
                        Text(
                          'Entreprise',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCompanyId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          items: _companies.map((company) {
                            return DropdownMenuItem<String>(
                              value: company.id,
                              child: Text(company.name),
                            );
                          }).toList(),
                          onChanged: _onCompanyChanged,
                        ),
                        const SizedBox(height: 24),

                        // Sélection de l'entrepôt
                        if (_selectedCompanyId != null) ...[
                          Text(
                            'Entrepôt',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWarehouseId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: _warehouses.map((warehouse) {
                              return DropdownMenuItem<String>(
                                value: warehouse.id,
                                child: Text(warehouse.name),
                              );
                            }).toList(),
                            onChanged: (warehouseId) {
                              setState(() {
                                _selectedWarehouseId = warehouseId;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Message d'erreur
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colors.destructive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colors.destructive.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colors.destructive,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.destructive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Bouton de confirmation
                        const Spacer(),
                        FButton(
                          onPress: _isLoading ? null : _confirmSelection,
                          style: FButtonStyle.primary(),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Continuer'),
                        ),
                      ],
                    ),
                  ),
    );
  }
}
