// customer_provider.dart
// Provider for customer management
// Handles customer listing, CRUD operations, and search

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/customer.dart';
import '../core/storage_service.dart';
import '../core/customer_service.dart';

part 'customer_provider.g.dart';

// Customer State
class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Customer Notifier
@riverpod
class CustomerNotifier extends _$CustomerNotifier {
  final CustomerService _customerService = CustomerService();

  @override
  CustomerState build() {
    // Load customers asynchronously
    Future.microtask(() => _loadCustomersAsync());
    return CustomerState();
  }

  // Async method to load customers without modifying state during build
  Future<void> _loadCustomersAsync() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final customers = await _customerService.getCustomers();
      state = state.copyWith(
        customers: customers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }


  // Add customer
  Future<void> addCustomer(Customer customer) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdCustomer = await _customerService.createCustomer(customer);
      
      final updatedCustomers = [...state.customers, createdCustomer];
      state = state.copyWith(
        customers: updatedCustomers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update customer
  Future<void> updateCustomer(Customer customer) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedCustomer = await _customerService.updateCustomer(customer);

      final updatedCustomers = state.customers.map((c) {
        return c.id == updatedCustomer.id ? updatedCustomer : c;
      }).toList();

      state = state.copyWith(
        customers: updatedCustomers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _customerService.deleteCustomer(id);

      final updatedCustomers = state.customers.where((c) => c.id != id).toList();
      state = state.copyWith(
        customers: updatedCustomers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  // Refresh customers from API
  Future<void> refreshCustomers() async {
    await _loadCustomersAsync();
  }

  // Search customers
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) {
      return state.customers;
    }

    final queryLower = query.toLowerCase();
    return state.customers.where((customer) {
      final nameLower = customer.name.toLowerCase();
      final emailLower = customer.email?.toLowerCase() ?? '';
      final phoneLower = customer.phone?.toLowerCase() ?? '';

      return nameLower.contains(queryLower) ||
             emailLower.contains(queryLower) ||
             phoneLower.contains(queryLower);
    }).toList();
  }
}
