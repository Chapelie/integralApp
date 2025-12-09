// lib/core/customer_service.dart
/// Customer service for managing customer operations
///
/// Handles fetching, creating, updating, and deleting customers
/// from the API and local storage.

import '../models/customer.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();

  /// Récupérer tous les clients depuis l'API ou le stockage local
  Future<List<Customer>> getCustomers() async {
    try {
      // Récupérer le warehouse_id
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        print('[CustomerService] No warehouse selected, using local storage');
        final customersData = _storageService.getCustomers();
        return customersData.map((data) => Customer.fromJson(data)).toList();
      }

      print('[CustomerService] Getting customers for warehouse: $warehouseId');
      
      final response = await _apiService.get(
        '${AppConstants.customersEndpoint}?warehouse_id=$warehouseId',
      );
      
      List<dynamic> customersData;
      if (response.data['data'] is List) {
        customersData = response.data['data'];
      } else {
        customersData = [];
      }

      final customers = customersData.map((json) => Customer.fromJson(json)).toList();

      // Sauvegarder localement
      for (final customer in customers) {
        await _storageService.saveCustomer(customer.toJson());
      }

      print('[CustomerService] Found ${customers.length} customers');
      return customers;
    } catch (e) {
      print('[CustomerService] Error getting customers from API: $e');
      // Fallback vers le stockage local
      final customersData = _storageService.getCustomers();
      return customersData.map((data) => Customer.fromJson(data)).toList();
    }
  }

  /// Créer un nouveau client
  Future<Customer> createCustomer(Customer customer) async {
    try {
      // Récupérer le warehouse_id
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Aucun entrepôt sélectionné');
      }

      print('[CustomerService] Creating customer: ${customer.name}');
      
      // Préparer les données pour l'API
      final customerData = {
        'firstname': customer.name.split(' ').first,
        'lastname': customer.name.split(' ').skip(1).join(' '),
        'email': customer.email,
        'phone': customer.phone,
        'warehouse_id': warehouseId,
      };

      final response = await _apiService.post(
        AppConstants.customersEndpoint,
        data: customerData,
      );
      
      final createdCustomer = Customer.fromJson(response.data['data']);
      
      // Sauvegarder localement
      await _storageService.saveCustomer(createdCustomer.toJson());
      
      print('[CustomerService] Customer created: ${createdCustomer.id}');
      return createdCustomer;
    } catch (e) {
      print('[CustomerService] Error creating customer: $e');
      
      // Si l'API échoue, sauvegarder localement quand même
      final customerToSave = customer.copyWith(
        id: customer.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _storageService.saveCustomer(customerToSave.toJson());
      
      print('[CustomerService] Customer saved locally: ${customerToSave.id}');
      return customerToSave;
    }
  }

  /// Mettre à jour un client
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      print('[CustomerService] Updating customer: ${customer.id}');
      
      // Récupérer le warehouse_id
      final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
      
      // Préparer les données pour l'API
      final customerData = {
        'firstname': customer.name.split(' ').first,
        'lastname': customer.name.split(' ').skip(1).join(' '),
        'email': customer.email,
        'phone': customer.phone,
        if (warehouseId != null) 'warehouse_id': warehouseId,
      };

      final response = await _apiService.put(
        AppConstants.customerEndpoint(customer.id),
        data: customerData,
      );
      
      final updatedCustomer = Customer.fromJson(response.data['data']);
      
      // Sauvegarder localement
      await _storageService.saveCustomer(updatedCustomer.toJson());
      
      print('[CustomerService] Customer updated: ${updatedCustomer.id}');
      return updatedCustomer;
    } catch (e) {
      print('[CustomerService] Error updating customer: $e');
      rethrow;
    }
  }

  /// Supprimer un client
  Future<void> deleteCustomer(String customerId) async {
    try {
      print('[CustomerService] Deleting customer: $customerId');
      
      await _apiService.delete(AppConstants.customerEndpoint(customerId));
      
      // Supprimer localement
      await _storageService.deleteCustomer(customerId);
      
      print('[CustomerService] Customer deleted: $customerId');
    } catch (e) {
      print('[CustomerService] Error deleting customer: $e');
      rethrow;
    }
  }
}

