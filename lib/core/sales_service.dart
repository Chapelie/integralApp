// lib/core/sales_service.dart
/// Sales service for managing sales operations
///
/// Handles creating, saving, and syncing sales with both local storage
/// and the backend API.
library;

import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/cash_movement.dart';
import '../models/table.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'constants.dart';
import 'business_config.dart';
import 'kitchen_service.dart';
import 'table_service.dart';
import 'company_warehouse_service.dart';
import 'device_service.dart';
import 'cash_movement_service.dart';

class SalesService {
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();
  final Uuid _uuid = const Uuid();

  /// Créer et enregistrer une vente
  Future<Sale> createSale({
    required List<SaleItem> items,
    required double total,
    required String paymentMethod,
    String? customerId,
    String? cashRegisterId,
    String? userId,
    String? notes,
    // Restaurant-specific parameters
    String? serviceType,
    String? tableId,
    String? tableNumber,
    String? waiterId,
    String? waiterName,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[SalesService] 🛒 Création d\'une nouvelle vente...');
      print('[SalesService] 📦 Nombre d\'articles: ${items.length}');
      print('[SalesService] 💰 Total: $total FCFA');
      print('[SalesService] 💳 Méthode de paiement: $paymentMethod');
      if (cashRegisterId != null) print('[SalesService] 💵 Cash Register ID: $cashRegisterId');
      if (userId != null) print('[SalesService] 👤 User ID: $userId');
      if (serviceType != null) print('[SalesService] 🍽️ Type de service: $serviceType');
      if (tableNumber != null) print('[SalesService] 🪑 Table: $tableNumber');

      // Récupérer le warehouse_id
      print('[SalesService] 🔍 Récupération du warehouse_id...');
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      print('[SalesService] 🏪 Warehouse ID: $warehouseId');

      if (warehouseId == null) {
        print('[SalesService] ❌ Aucun entrepôt sélectionné');
        print('═══════════════════════════════════════════════════════');
        throw Exception('Aucun entrepôt sélectionné. Veuillez configurer votre compte.');
      }

      final saleId = _uuid.v4();
      final now = DateTime.now();

      // Calculate subtotal and tax
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.quantity * item.price - (item.discount ?? 0.0)),
      );
      
      // Vérifier si les taxes sont activées
      final prefs = await SharedPreferences.getInstance();
      final enableTax = prefs.getBool('enableTax') ?? false;
      final defaultTaxRate = prefs.getDouble('defaultTaxRate') ?? 0.0;
      
      final taxAmount = enableTax
          ? items.fold<double>(
              0.0,
              (sum, item) {
                final itemSubtotal = item.quantity * item.price - (item.discount ?? 0.0);
                // Utiliser le taux de taxe du produit s'il existe, sinon le taux par défaut
                final taxRate = item.taxRate > 0 ? item.taxRate : defaultTaxRate;
                return sum + (itemSubtotal * (taxRate / 100));
              },
            )
          : 0.0;

      // Récupérer le device_id pour l'API (backend_device_id si disponible)
      print('[SalesService] 📱 Récupération du device_id...');
      final deviceService = DeviceService();
      final actualDeviceId = await deviceService.getDeviceIdForApi();
      print('[SalesService] 📱 Device ID: $actualDeviceId');

      // Créer la vente
      final sale = Sale(
        id: saleId,
        warehouseId: warehouseId,
        items: items,
        subtotal: subtotal,
        taxAmount: taxAmount,
        total: total,
        paymentMethod: paymentMethod,
        paymentStatus: 'completed',
        customerId: customerId,
        cashRegisterId: cashRegisterId,
        userId: userId ?? 'unknown',
        deviceId: actualDeviceId,
        notes: notes,
        createdAt: now,
        // Restaurant fields
        serviceType: serviceType,
        tableId: tableId,
        tableNumber: tableNumber,
        waiterId: waiterId,
        waiterName: waiterName,
      );

      // Enregistrer localement dans Hive
      print('[SalesService] 💾 Sauvegarde locale de la vente...');
      await _storageService.saveSale(sale);
      print('[SalesService] ✅ Vente sauvegardée localement: $saleId');

      // Create kitchen order if in restaurant mode with dine-in service
      final businessConfig = BusinessConfig();
      if (businessConfig.isFeatureEnabled('enableKitchen') &&
          serviceType == 'dine_in') {
        try {
          print('[SalesService] 🍳 Création d\'une commande cuisine...');
          final kitchenService = KitchenService();
          final kitchenOrder = await kitchenService.createOrder(
            saleId: saleId,
            items: items,
            tableNumber: tableNumber,
            waiterName: waiterName,
            notes: notes,
          );
          print('[SalesService] ✅ Commande cuisine créée: ${kitchenOrder.id}');
        } catch (e) {
          print('[SalesService] ⚠️ Erreur création commande cuisine: $e');
          // Continue with sale creation even if kitchen order fails
        }
      }

      // Update table status to occupied if table was selected
      if (tableId != null && serviceType == 'dine_in') {
        try {
          print('[SalesService] 🪑 Mise à jour du statut de la table...');
          final tableService = TableService();
          await tableService.updateTableStatus(
            tableId,
            TableStatus.occupied,
            currentOrderId: saleId,
          );
          print('[SalesService] ✅ Statut de la table mis à jour: $tableId');
        } catch (e) {
          print('[SalesService] ⚠️ Erreur mise à jour table: $e');
        }
      }

      // Créer le mouvement de caisse associé
      if (cashRegisterId != null) {
        print('[SalesService] 💵 Création du mouvement de caisse...');
        final cashMovementService = CashMovementService();
        await cashMovementService.createMovement(
          cashRegisterId: cashRegisterId,
          type: 'sale',
          amount: total,
          description: 'Vente - ${items.length} article(s)',
          saleId: saleId,
          userId: userId,
        );
        print('[SalesService] ✅ Mouvement de caisse créé');
      }

      // Synchroniser avec l'API en arrière-plan
      print('[SalesService] 🌐 Synchronisation avec l\'API en arrière-plan...');
      _syncSaleToAPI(sale);

      print('[SalesService] ✅ Vente créée avec succès!');
      print('[SalesService] 🆔 Sale ID: $saleId');
      print('[SalesService] 💰 Total: $total FCFA');
      print('═══════════════════════════════════════════════════════');

      return sale;
    } catch (e) {
      print('[SalesService] ❌ ERREUR création vente: $e');
      print('[SalesService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Synchroniser une vente avec l'API
  Future<void> _syncSaleToAPI(Sale sale) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('[SalesService] 🔄 Synchronisation de la vente...');
      print('[SalesService] 🆔 Sale ID: ${sale.id}');
      print('[SalesService] 💰 Total: ${sale.total} FCFA');
      print('[SalesService] 📦 Nombre d\'articles: ${sale.items.length}');
      print('[SalesService] 💳 Méthode de paiement: ${sale.paymentMethod}');
      if (sale.warehouseId != null) print('[SalesService] 🏪 Warehouse ID: ${sale.warehouseId}');
      print('[SalesService] 👤 User ID: ${sale.userId}');

      final saleJson = sale.toApiJson();
      print('[SalesService] 🌐 URL: ${AppConstants.salesEndpoint}');
      print('[SalesService] 📄 JSON envoyé (API format - snake_case): $saleJson');
      
      // Log items details for debugging
      print('[SalesService] 📦 Items envoyés:');
      for (int i = 0; i < sale.items.length; i++) {
        final item = sale.items[i];
        final itemJson = item.toApiJson(deviceId: sale.deviceId);
        print('[SalesService]   Item $i: ${itemJson}');
      }
      
      print('[SalesService] 📤 Envoi de la requête POST...');

      final response = await _apiService.post(
        AppConstants.salesEndpoint,
        data: saleJson,
      );

      print('[SalesService] 📥 Response status: ${response.statusCode}');
      print('[SalesService] 📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[SalesService] ✅ Vente synchronisée avec succès!');
        print('[SalesService] 🆔 Sale ID: ${sale.id}');
        print('═══════════════════════════════════════════════════════');
      } else {
        print('[SalesService] ❌ Échec de la synchronisation');
        print('[SalesService] Status: ${response.statusCode}');
        print('[SalesService] ⚠️ La vente reste en local, sera synchronisée plus tard');
        print('═══════════════════════════════════════════════════════');
      }
    } catch (e) {
      print('[SalesService] ❌ ERREUR synchronisation vente: $e');
      print('[SalesService] 📋 Type d\'erreur: ${e.runtimeType}');
      print('[SalesService] ⚠️ La vente reste en local, sera synchronisée plus tard');
      print('═══════════════════════════════════════════════════════');
      // La vente reste en local, sera synchronisée plus tard
    }
  }

  /// Récupérer toutes les ventes
  List<Sale> getSales() {
    return _storageService.getSales();
  }

  /// Récupérer les ventes par période
  List<Sale> getSalesByDateRange(DateTime startDate, DateTime endDate) {
    return _storageService.getSalesByDateRange(startDate, endDate);
  }

  /// Récupérer les ventes d'une caisse
  List<Sale> getSalesByCashRegister(String cashRegisterId) {
    final allSales = getSales();
    return allSales.where((sale) => sale.cashRegisterId == cashRegisterId).toList();
  }

  /// Récupérer les ventes d'un client
  List<Sale> getSalesByCustomer(String customerId) {
    final allSales = getSales();
    return allSales.where((sale) => sale.customerId == customerId).toList();
  }

  /// Calculer le total des ventes par période
  double getTotalSalesByDateRange(DateTime startDate, DateTime endDate) {
    final sales = getSalesByDateRange(startDate, endDate);
    return sales.fold(0.0, (sum, sale) => sum + sale.total);
  }

  /// Calculer le nombre de ventes par période
  int getSalesCountByDateRange(DateTime startDate, DateTime endDate) {
    return getSalesByDateRange(startDate, endDate).length;
  }

  /// Obtenir les statistiques de ventes
  Map<String, dynamic> getSalesStats(DateTime startDate, DateTime endDate) {
    final sales = getSalesByDateRange(startDate, endDate);
    
    if (sales.isEmpty) {
      return {
        'totalSales': 0.0,
        'salesCount': 0,
        'averageSale': 0.0,
        'paymentMethods': <String, int>{},
        'topProducts': <Map<String, dynamic>>[],
      };
    }

    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.total);
    final salesCount = sales.length;
    final averageSale = totalSales / salesCount;

    // Compter les méthodes de paiement
    final paymentMethods = <String, int>{};
    for (final sale in sales) {
      paymentMethods[sale.paymentMethod] = (paymentMethods[sale.paymentMethod] ?? 0) + 1;
    }

    // Top produits
    final productCounts = <String, int>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
      }
    }

    final topProducts = productCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);

    return {
      'totalSales': totalSales,
      'salesCount': salesCount,
      'averageSale': averageSale,
      'paymentMethods': paymentMethods,
      'topProducts': topProducts.map((e) => {
        'productName': e.key,
        'quantity': e.value,
      }).toList(),
    };
  }

  /// Récupérer les ventes récentes
  List<Sale> getRecentSales(int limit) {
    final allSales = getSales();
    // Trier par date de création (plus récentes en premier)
    final sortedSales = allSales.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Retourner les N plus récentes
    return sortedSales.take(limit).toList();
  }
}

