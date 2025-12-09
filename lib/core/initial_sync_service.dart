// lib/core/initial_sync_service.dart
// Service pour la synchronisation initiale avec le backend Laravel

// import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/cash_register.dart';

class InitialSyncService {
  static final InitialSyncService _instance = InitialSyncService._internal();
  factory InitialSyncService() => _instance;
  InitialSyncService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();

  /// Effectue la synchronisation initiale avec le backend
  Future<Map<String, dynamic>> performInitialSync() async {
    try {
      print('[InitialSyncService] ========================================');
      print('[InitialSyncService] DÉBUT SYNCHRONISATION INITIALE');
      print('[InitialSyncService] ========================================');
      print('[InitialSyncService] Timestamp: ${DateTime.now().toIso8601String()}');

      final results = <String, dynamic>{
        'success': true,
        'errors': <String>[],
        'synced': <String, int>{},
      };

      // 1. Synchroniser les produits
      print('[InitialSyncService] --- Étape 1/4: Synchronisation des produits ---');
      try {
        final startTime = DateTime.now();
        final products = await _syncProducts();
        final duration = DateTime.now().difference(startTime);
        results['synced']['products'] = products.length;
        print('[InitialSyncService] ✅ Synchronisation produits terminée: ${products.length} produits en ${duration.inMilliseconds}ms');
      } catch (e) {
        results['errors'].add('Products: $e');
        print('[InitialSyncService] ❌ Erreur synchronisation produits: $e');
      }

      // 2. Synchroniser les clients
      print('[InitialSyncService] --- Étape 2/4: Synchronisation des clients ---');
      try {
        final startTime = DateTime.now();
        final customers = await _syncCustomers();
        final duration = DateTime.now().difference(startTime);
        results['synced']['customers'] = customers.length;
        print('[InitialSyncService] ✅ Synchronisation clients terminée: ${customers.length} clients en ${duration.inMilliseconds}ms');
      } catch (e) {
        results['errors'].add('Customers: $e');
        print('[InitialSyncService] ❌ Erreur synchronisation clients: $e');
      }

      // 3. Synchroniser les caisses
      print('[InitialSyncService] --- Étape 3/4: Synchronisation des caisses ---');
      try {
        final startTime = DateTime.now();
        final cashRegisters = await _syncCashRegisters();
        final duration = DateTime.now().difference(startTime);
        results['synced']['cashRegisters'] = cashRegisters.length;
        print('[InitialSyncService] ✅ Synchronisation caisses terminée: ${cashRegisters.length} caisses en ${duration.inMilliseconds}ms');
      } catch (e) {
        results['errors'].add('Cash Registers: $e');
        print('[InitialSyncService] ❌ Erreur synchronisation caisses: $e');
      }

      // 4. Vérifier la connexion utilisateur
      print('[InitialSyncService] --- Étape 4/4: Vérification utilisateur ---');
      try {
        final startTime = DateTime.now();
        await _verifyUserConnection();
        final duration = DateTime.now().difference(startTime);
        print('[InitialSyncService] ✅ Vérification utilisateur terminée en ${duration.inMilliseconds}ms');
      } catch (e) {
        results['errors'].add('User verification: $e');
        print('[InitialSyncService] ❌ Erreur vérification utilisateur: $e');
      }

      results['success'] = results['errors'].isEmpty;

      print('[InitialSyncService] ========================================');
      print('[InitialSyncService] SYNCHRONISATION INITIALE TERMINÉE');
      print('[InitialSyncService] Résultat: ${results['success'] ? "✅ SUCCÈS" : "❌ ÉCHEC"}');
      print('[InitialSyncService] Produits: ${results['synced']['products'] ?? 0}');
      print('[InitialSyncService] Clients: ${results['synced']['customers'] ?? 0}');
      print('[InitialSyncService] Caisses: ${results['synced']['cashRegisters'] ?? 0}');
      print('[InitialSyncService] Erreurs: ${results['errors'].length}');
      if (results['errors'].isNotEmpty) {
        print('[InitialSyncService] Liste des erreurs:');
        for (var error in results['errors']) {
          print('[InitialSyncService]   - $error');
        }
      }
      print('[InitialSyncService] ========================================');

      return results;
    } catch (e) {
      print('[InitialSyncService] ========================================');
      print('[InitialSyncService] ❌ ÉCHEC CRITIQUE DE LA SYNCHRONISATION');
      print('[InitialSyncService] Erreur: $e');
      print('[InitialSyncService] Type: ${e.runtimeType}');
      print('[InitialSyncService] ========================================');
      return {
        'success': false,
        'errors': ['General error: $e'],
        'synced': <String, int>{},
      };
    }
  }

  /// Synchronise les produits depuis le backend
  Future<List<Product>> _syncProducts() async {
    try {
      print('[InitialSyncService] ===== DÉBUT _syncProducts =====');

      // Récupérer les IDs de l'entreprise et de l'entrepôt sélectionnés
      print('[InitialSyncService] Récupération des IDs entreprise/entrepôt...');
      final companyId = await _companyWarehouseService.getSelectedCompanyId();
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();

      print('[InitialSyncService] Company ID: $companyId');
      print('[InitialSyncService] Warehouse ID: $warehouseId');

      if (companyId == null || warehouseId == null) {
        print('[InitialSyncService] ❌ Aucune entreprise ou entrepôt sélectionné');
        throw Exception('Aucune entreprise ou entrepôt sélectionné. Veuillez configurer votre compte.');
      }

      final endpoint = AppConstants.productsEndpoint(companyId, warehouseId);
      print('[InitialSyncService] Endpoint API: $endpoint');
      print('[InitialSyncService] Tentative de récupération des produits depuis l\'API...');

      final response = await _apiService.get(endpoint);

      print('[InitialSyncService] Réponse API reçue - Status: ${response.statusCode}');
      print('[InitialSyncService] Réponse complète: ${response.data}');
      print('[InitialSyncService] Réponse API - Success: ${response.data['success']}');
      print('[InitialSyncService] Type de response.data: ${response.data.runtimeType}');
      print('[InitialSyncService] Type de response.data[\'data\']: ${response.data['data']?.runtimeType}');

      if (response.data['success'] == true) {
        // Vérifier la structure de la réponse
        final dataField = response.data['data'];
        print('[InitialSyncService] Contenu de data field: $dataField');

        List<dynamic> productsData;
        if (dataField is List) {
          // Si data est déjà une liste
          print('[InitialSyncService] data est une liste directe');
          productsData = dataField;
        } else if (dataField is Map) {
          // Si data est un objet avec pagination
          print('[InitialSyncService] data est un objet (probablement paginé)');
          print('[InitialSyncService] Clés disponibles: ${dataField.keys.toList()}');
          productsData = dataField['data'] ?? [];
        } else {
          print('[InitialSyncService] ❌ Structure de data inconnue');
          throw Exception('Structure de réponse inattendue');
        }

        print('[InitialSyncService] Nombre de produits dans la réponse: ${productsData.length}');

        final List<Product> products = productsData.map((json) {
          final product = Product.fromJson(json);
          print('[InitialSyncService] Produit converti: ${product.name} (ID: ${product.id}, Stock: ${product.stock})');
          return product;
        }).toList();

        print('[InitialSyncService] ${products.length} produits convertis avec succès');
        print('[InitialSyncService] Sauvegarde des produits dans le stockage local...');

        // Sauvegarder les produits localement
        int savedCount = 0;
        for (final product in products) {
          await _storageService.saveProduct(product.toJson());
          savedCount++;
          if (savedCount % 10 == 0) {
            print('[InitialSyncService] Sauvegardé $savedCount/${products.length} produits...');
          }
        }

        print('[InitialSyncService] ✅ $savedCount produits sauvegardés localement avec succès');
        print('[InitialSyncService] ===== FIN _syncProducts (Succès) =====');
        return products;
      } else {
        print('[InitialSyncService] ❌ Réponse API indique un échec');
        print('[InitialSyncService] Message: ${response.data['message']}');
        throw Exception('Failed to fetch products: ${response.data['message']}');
      }
    } catch (e) {
      print('[InitialSyncService] ❌ Erreur lors de la récupération des produits: $e');
      print('[InitialSyncService] Type d\'erreur: ${e.runtimeType}');
      print('[InitialSyncService] ===== FIN _syncProducts (Erreur) =====');
      rethrow;
    }
  }

  /// Synchronise les clients depuis le backend
  Future<List<Customer>> _syncCustomers() async {
    try {
      print('[InitialSyncService] ===== DÉBUT _syncCustomers =====');

      final endpoint = AppConstants.customersEndpoint;
      print('[InitialSyncService] Endpoint API: $endpoint');
      print('[InitialSyncService] Tentative de récupération des clients depuis l\'API...');

      final response = await _apiService.get(endpoint);

      print('[InitialSyncService] Réponse API reçue - Status: ${response.statusCode}');
      print('[InitialSyncService] Réponse complète: ${response.data}');
      print('[InitialSyncService] Réponse API - Success: ${response.data['success']}');
      print('[InitialSyncService] Type de response.data[\'data\']: ${response.data['data']?.runtimeType}');

      if (response.data['success'] == true) {
        // Vérifier la structure de la réponse
        final dataField = response.data['data'];
        print('[InitialSyncService] Contenu de data field: $dataField');

        List<dynamic> customersData;
        if (dataField is List) {
          print('[InitialSyncService] data est une liste directe');
          customersData = dataField;
        } else if (dataField is Map) {
          print('[InitialSyncService] data est un objet (probablement paginé)');
          print('[InitialSyncService] Clés disponibles: ${dataField.keys.toList()}');
          customersData = dataField['data'] ?? [];
        } else {
          print('[InitialSyncService] ❌ Structure de data inconnue');
          throw Exception('Structure de réponse inattendue');
        }

        print('[InitialSyncService] Nombre de clients dans la réponse: ${customersData.length}');

        final List<Customer> customers = customersData.map((json) {
          final customer = Customer.fromJson(json);
          print('[InitialSyncService] Client converti: ${customer.name} (ID: ${customer.id})');
          return customer;
        }).toList();

        print('[InitialSyncService] ${customers.length} clients convertis avec succès');
        print('[InitialSyncService] Sauvegarde des clients dans le stockage local...');

        // Sauvegarder les clients localement
        int savedCount = 0;
        for (final customer in customers) {
          await _storageService.saveCustomer(customer.toJson());
          savedCount++;
        }

        print('[InitialSyncService] ✅ $savedCount clients sauvegardés localement avec succès');
        print('[InitialSyncService] ===== FIN _syncCustomers (Succès) =====');
        return customers;
      } else {
        print('[InitialSyncService] ❌ Réponse API indique un échec');
        print('[InitialSyncService] Message: ${response.data['message']}');
        throw Exception('Failed to fetch customers: ${response.data['message']}');
      }
    } catch (e) {
      print('[InitialSyncService] ❌ Erreur lors de la récupération des clients: $e');
      print('[InitialSyncService] Type d\'erreur: ${e.runtimeType}');
      print('[InitialSyncService] ===== FIN _syncCustomers (Erreur) =====');
      rethrow;
    }
  }

  /// Synchronise les caisses depuis le backend
  Future<List<CashRegister>> _syncCashRegisters() async {
    try {
      print('[InitialSyncService] ===== DÉBUT _syncCashRegisters =====');

      // Récupérer l'ID de l'entrepôt (requis pour les caisses)
      print('[InitialSyncService] Récupération du warehouse ID...');
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      print('[InitialSyncService] Warehouse ID: $warehouseId');

      if (warehouseId == null) {
        print('[InitialSyncService] ❌ Aucun entrepôt sélectionné');
        throw Exception('Aucun entrepôt sélectionné. Veuillez configurer votre compte.');
      }

      // Ajouter warehouse_id comme query parameter
      final endpoint = '${AppConstants.cashRegistersEndpoint}?warehouse_id=$warehouseId';
      print('[InitialSyncService] Endpoint API: $endpoint');
      print('[InitialSyncService] Tentative de récupération des caisses depuis l\'API...');

      final response = await _apiService.get(endpoint);

      print('[InitialSyncService] Réponse API reçue - Status: ${response.statusCode}');
      print('[InitialSyncService] Réponse complète: ${response.data}');
      print('[InitialSyncService] Réponse API - Success: ${response.data['success']}');
      print('[InitialSyncService] Type de response.data[\'data\']: ${response.data['data']?.runtimeType}');

      if (response.data['success'] == true) {
        // Vérifier la structure de la réponse
        final dataField = response.data['data'];
        print('[InitialSyncService] Contenu de data field: $dataField');

        List<dynamic> cashRegistersData;
        if (dataField is List) {
          print('[InitialSyncService] data est une liste directe');
          cashRegistersData = dataField;
        } else if (dataField is Map) {
          print('[InitialSyncService] data est un objet (probablement paginé)');
          print('[InitialSyncService] Clés disponibles: ${dataField.keys.toList()}');
          cashRegistersData = dataField['data'] ?? [];
        } else {
          print('[InitialSyncService] ❌ Structure de data inconnue');
          throw Exception('Structure de réponse inattendue');
        }

        print('[InitialSyncService] Nombre de caisses dans la réponse: ${cashRegistersData.length}');

        final List<CashRegister> cashRegisters = cashRegistersData.map((json) {
          final cashRegister = CashRegister.fromJson(json);
          print('[InitialSyncService] Caisse convertie: ${cashRegister.id} (Status: ${cashRegister.status})');
          return cashRegister;
        }).toList();

        print('[InitialSyncService] ${cashRegisters.length} caisses converties avec succès');
        print('[InitialSyncService] Sauvegarde des caisses dans le stockage local...');

        // Sauvegarder les caisses localement
        int savedCount = 0;
        for (final cashRegister in cashRegisters) {
          await _storageService.saveCashRegister(cashRegister.toJson());
          savedCount++;
        }

        print('[InitialSyncService] ✅ $savedCount caisses sauvegardées localement avec succès');
        print('[InitialSyncService] ===== FIN _syncCashRegisters (Succès) =====');
        return cashRegisters;
      } else {
        print('[InitialSyncService] ❌ Réponse API indique un échec');
        print('[InitialSyncService] Message: ${response.data['message']}');
        throw Exception('Failed to fetch cash registers: ${response.data['message']}');
      }
    } catch (e) {
      print('[InitialSyncService] ❌ Erreur lors de la récupération des caisses: $e');
      print('[InitialSyncService] Type d\'erreur: ${e.runtimeType}');
      print('[InitialSyncService] ===== FIN _syncCashRegisters (Erreur) =====');
      rethrow;
    }
  }

  /// Vérifie la connexion utilisateur
  Future<void> _verifyUserConnection() async {
    try {
      final response = await _apiService.get(AppConstants.authMeEndpoint);
      
      if (response.data['success'] != true) {
        throw Exception('User verification failed: ${response.data['message']}');
      }
    } catch (e) {
      print('[InitialSyncService] Error verifying user: $e');
      rethrow;
    }
  }

  /// Vérifie si la synchronisation initiale est nécessaire
  Future<bool> needsInitialSync() async {
    try {
      final products = _storageService.getProducts();
      return products.isEmpty;
    } catch (e) {
      print('[InitialSyncService] Error checking sync status: $e');
      return true;
    }
  }
}

