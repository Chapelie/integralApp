// cart_provider.dart
// Provider for shopping cart management
// Handles cart items, customer selection, discounts, and total calculations

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/customer.dart';

part 'cart_provider.g.dart';

// Sentinel value for copyWith to distinguish between null and unspecified
const _undefined = Object();

// Cart Item
class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Cart State
class CartState {
  final List<CartItem> items;
  final Customer? selectedCustomer;
  final String? notes;
  final double subtotal;
  final double taxAmount;
  final double total;

  // Restaurant-specific fields
  final String? serviceType; // 'dine_in', 'takeaway', 'delivery'
  final String? tableId;
  final String? tableNumber;
  final String? waiterId;
  final String? waiterName;

  CartState({
    this.items = const [],
    this.selectedCustomer,
    this.notes,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    // Restaurant fields
    this.serviceType,
    this.tableId,
    this.tableNumber,
    this.waiterId,
    this.waiterName,
  });

  CartState copyWith({
    List<CartItem>? items,
    Object? selectedCustomer = _undefined,
    Object? notes = _undefined,
    double? subtotal,
    double? taxAmount,
    double? total,
    Object? serviceType = _undefined,
    Object? tableId = _undefined,
    Object? tableNumber = _undefined,
    Object? waiterId = _undefined,
    Object? waiterName = _undefined,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: selectedCustomer == _undefined
          ? this.selectedCustomer
          : selectedCustomer as Customer?,
      notes: notes == _undefined
          ? this.notes
          : notes as String?,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      serviceType: serviceType == _undefined
          ? this.serviceType
          : serviceType as String?,
      tableId: tableId == _undefined
          ? this.tableId
          : tableId as String?,
      tableNumber: tableNumber == _undefined
          ? this.tableNumber
          : tableNumber as String?,
      waiterId: waiterId == _undefined
          ? this.waiterId
          : waiterId as String?,
      waiterName: waiterName == _undefined
          ? this.waiterName
          : waiterName as String?,
    );
  }
}

// Cart Notifier
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() {
    return CartState();
  }

  // Add item to cart
  void addItem(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
    } else {
      updatedItems = [...state.items, CartItem(product: product, quantity: 1)];
    }

    state = state.copyWith(items: updatedItems);
    Future.microtask(() => _calculateTotals());
  }

  // Remove item from cart
  void removeItem(String productId) {
    final updatedItems = state.items.where(
      (item) => item.product.id != productId,
    ).toList();

    state = state.copyWith(items: updatedItems);
    Future.microtask(() => _calculateTotals());
  }

  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    Future.microtask(() => _calculateTotals());
  }

  // Set customer
  void setCustomer(Customer? customer) {
    state = state.copyWith(selectedCustomer: customer);
  }


  // Set notes
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  // Restaurant-specific methods

  // Set service type
  void setServiceType(String? serviceType) {
    state = state.copyWith(serviceType: serviceType);
  }

  // Set table
  void setTable(String? tableId, String? tableNumber) {
    state = state.copyWith(
      tableId: tableId,
      tableNumber: tableNumber,
    );
  }

  // Set waiter
  void setWaiter(String? waiterId, String? waiterName) {
    state = state.copyWith(
      waiterId: waiterId,
      waiterName: waiterName,
    );
  }

  // Clear cart
  void clearCart() {
    state = CartState();
  }

  // Calculate totals
  Future<void> _calculateTotals() async {
    double subtotal = 0.0;

    for (final item in state.items) {
      subtotal += (item.product.price ?? 0.0) * item.quantity;
    }

    // Vérifier si les taxes sont activées
    final prefs = await SharedPreferences.getInstance();
    final enableTax = prefs.getBool('enableTax') ?? false;
    final defaultTaxRate = prefs.getDouble('defaultTaxRate') ?? 0.0;

    // Calculate tax only if enabled
    double taxAmount = 0.0;
    if (enableTax) {
      for (final item in state.items) {
        final itemSubtotal = (item.product.price ?? 0.0) * item.quantity;
        // Utiliser le taux de taxe du produit s'il existe, sinon le taux par défaut
        final taxRate = item.product.taxRate > 0 ? item.product.taxRate : defaultTaxRate;
        taxAmount += itemSubtotal * (taxRate / 100);
      }
    }

    // Calculate total
    final total = subtotal + taxAmount;

    state = state.copyWith(
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
    );
  }

  // Public method to manually trigger calculation if needed
  Future<void> calculateTotals() async {
    await _calculateTotals();
  }
}
