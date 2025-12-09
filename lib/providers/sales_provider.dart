// sales_provider.dart
// Provider for sales management
// Handles sale creation, refunds, listing, and synchronization

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/sale.dart';
import '../core/storage_service.dart';
import '../core/sales_service.dart';
import '../core/sync_service.dart';
import '../core/receipt_service.dart';
import '../models/sale_item.dart';
import 'cart_provider.dart';

part 'sales_provider.g.dart';

// Sales State
class SalesState {
  final List<Sale> sales;
  final List<Sale> pending;
  final bool isLoading;
  final String? error;

  SalesState({
    this.sales = const [],
    this.pending = const [],
    this.isLoading = false,
    this.error,
  });

  SalesState copyWith({
    List<Sale>? sales,
    List<Sale>? pending,
    bool? isLoading,
    String? error,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Sales Notifier
@riverpod
class SalesNotifier extends _$SalesNotifier {
  final StorageService _storageService = StorageService();
  final SalesService _salesService = SalesService();
  final SyncService _syncService = SyncService();
  final ReceiptService _receiptService = ReceiptService();

  @override
  SalesState build() {
    // Don't call loadSales here to avoid circular dependency
    // Instead, load sales when the provider is first accessed
    return SalesState();
  }

  // Load sales from local storage
  Future<void> loadSales() async {
    if (!ref.mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sales = _salesService.getSales();
      final pending = sales.where((sale) => !sale.isSynced).toList();

      if (!ref.mounted) return;

      state = state.copyWith(
        sales: sales,
        pending: pending,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create sale from cart
  Future<Sale?> createSale(CartState cartState, String paymentMethod, String userId, String deviceId, {String? cashRegisterId}) async {
    print('═══════════════════════════════════════════════════════');
    print('[SalesProvider] 🛒 DÉBUT création de vente depuis le panier');
    print('[SalesProvider] 📦 Nombre d\'articles dans le panier: ${cartState.items.length}');
    print('[SalesProvider] 💰 Total du panier: ${cartState.total}');
    print('[SalesProvider] 💳 Méthode de paiement: $paymentMethod');
    print('[SalesProvider] 👤 User ID: $userId');
    print('[SalesProvider] 📱 Device ID: $deviceId');
    print('[SalesProvider] 💵 Cash Register ID: $cashRegisterId');
    
    if (!ref.mounted) {
      print('[SalesProvider] ❌ Widget non monté, abandon');
      return null;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    print('[SalesProvider] ✅ État mis à jour: isLoading=true');

    try {
      // Convert cart items to sale items
      print('[SalesProvider] 🔄 Conversion des articles du panier en sale items...');
      final saleItems = cartState.items.map((item) {
        final price = item.product.price ?? 0.0;
        final lineTotal = price * item.quantity;
        print('[SalesProvider]   - Article: ${item.product.name}, Qty: ${item.quantity}, Prix: $price, Total: $lineTotal');
        return SaleItem(
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: price,
          taxRate: item.product.taxRate,
          lineTotal: lineTotal,
        );
      }).toList();
      print('[SalesProvider] ✅ ${saleItems.length} articles convertis');

      // Create sale using SalesService
      print('[SalesProvider] 📞 Appel de SalesService.createSale()...');
      final sale = await _salesService.createSale(
        items: saleItems,
        total: cartState.total,
        paymentMethod: paymentMethod,
        customerId: cartState.selectedCustomer?.id,
        cashRegisterId: cashRegisterId,
        userId: userId,
        notes: cartState.notes,
        // Restaurant fields
        serviceType: cartState.serviceType,
        tableId: cartState.tableId,
        tableNumber: cartState.tableNumber,
        waiterId: cartState.waiterId,
        waiterName: cartState.waiterName,
      );
      print('[SalesProvider] ✅ Sale créé: ${sale.id}');

      // La vente est créée avec succès, on continue même si le widget n'est plus monté
      // car la vente doit être retournée pour le paiement
      if (!ref.mounted) {
        print('[SalesProvider] ⚠️ Widget non monté après création, mais on retourne la vente quand même');
        return sale; // Retourner la vente même si le widget n'est plus monté
      }

      // Update state (seulement si le widget est encore monté)
      if (ref.mounted) {
        print('[SalesProvider] 🔄 Mise à jour de l\'état avec la nouvelle vente...');
        print('[SalesProvider] Nombre de ventes avant: ${state.sales.length}');
        state = state.copyWith(
          sales: [...state.sales, sale],
          isLoading: false,
          error: null,
        );
        print('[SalesProvider] ✅ État mis à jour: ${state.sales.length} ventes');
        print('[SalesProvider] ✅ Vente ajoutée à l\'état local');
      } else {
        print('[SalesProvider] ⚠️ Widget non monté, pas de mise à jour de l\'état');
      }

      // Print receipt - DÉSACTIVÉ car on utilise maintenant PdfPreviewPage
      // await _receiptService.print(sale);
      print('[SalesProvider] ⚠️ Impression désactivée (gérée dans PaymentModal)');

      print('[SalesProvider] ✅✅✅ VENTE CRÉÉE AVEC SUCCÈS ✅✅✅');
      print('[SalesProvider] 🆔 Sale ID: ${sale.id}');
      print('[SalesProvider] 💰 Total: ${sale.total}');
      print('═══════════════════════════════════════════════════════');
      return sale;
    } catch (e, stackTrace) {
      print('[SalesProvider] ❌❌❌ ERREUR création vente ❌❌❌');
      print('[SalesProvider] Erreur: $e');
      print('[SalesProvider] Type: ${e.runtimeType}');
      print('[SalesProvider] Stack trace: $stackTrace');
      
      if (!ref.mounted) {
        print('[SalesProvider] ❌ Widget non monté, abandon');
        return null;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('[SalesProvider] ❌ État mis à jour avec erreur');
      print('═══════════════════════════════════════════════════════');
      return null;
    }
  }

  // Refund sale
  Future<void> refundSale(String saleId, String pin) async {
    if (!ref.mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement PIN validation
      // await _storageService.validatePin(pin);

      // TODO: Process refund
      // await _storageService.refundSale(saleId);

      // Reload sales
      await loadSales();
    } catch (e) {
      if (!ref.mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get sale by ID
  Sale? getSaleById(String id) {
    try {
      return state.sales.firstWhere((sale) => sale.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sync pending sales
  Future<void> syncPendingSales() async {
    if (!ref.mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement sync pending sales
      // await _syncService.syncPendingSales();

      // Reload sales to update sync status
      await loadSales();
    } catch (e) {
      if (!ref.mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
