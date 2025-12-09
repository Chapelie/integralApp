// lib/core/employee_service.dart
/// Employee service for managing employee operations
///
/// Handles fetching, creating, updating, and deleting employees
/// from the API and local storage.
library;

import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';

class EmployeeService {
  static final EmployeeService _instance = EmployeeService._internal();
  factory EmployeeService() => _instance;
  EmployeeService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  /// Récupérer tous les employés depuis l'API ou le stockage local
  Future<List<Employee>> getEmployees() async {
    try {
      print('[EmployeeService] Getting employees...');
      
      final response = await _apiService.get(AppConstants.employeesEndpoint);
      final List<dynamic> data = response.data['data'];
      final employees = data.map((json) => Employee.fromJson(json)).toList();

      // Sauvegarder localement
      for (final employee in employees) {
        await _storageService.saveEmployee(employee);
      }

      print('[EmployeeService] Found ${employees.length} employees');
      return employees;
    } catch (e) {
      print('[EmployeeService] Error getting employees from API: $e');
      // Fallback vers le stockage local
      return _storageService.getEmployees();
    }
  }

  /// Récupérer un employé par ID
  Future<Employee?> getEmployee(String employeeId) async {
    try {
      print('[EmployeeService] Getting employee: $employeeId');
      
      final response = await _apiService.get(AppConstants.employeeEndpoint(employeeId));
      final employee = Employee.fromJson(response.data['data']);
      
      // Sauvegarder localement
      await _storageService.saveEmployee(employee);
      
      return employee;
    } catch (e) {
      print('[EmployeeService] Error getting employee from API: $e');
      // Fallback vers le stockage local
      final employees = _storageService.getEmployees();
      try {
        return employees.firstWhere((emp) => emp.id == employeeId);
      } catch (_) {
        return null;
      }
    }
  }

  /// Créer un nouvel employé
  Future<Employee> createEmployee(Employee employee) async {
    try {
      print('[EmployeeService] Creating employee: ${employee.name}');
      
      final newEmployee = employee.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _apiService.post(
        AppConstants.employeesEndpoint,
        data: newEmployee.toJson(),
      );
      
      final createdEmployee = Employee.fromJson(response.data['data']);
      
      // Sauvegarder localement
      await _storageService.saveEmployee(createdEmployee);
      
      print('[EmployeeService] Employee created: ${createdEmployee.id}');
      return createdEmployee;
    } catch (e) {
      print('[EmployeeService] Error creating employee: $e');
      rethrow;
    }
  }

  /// Mettre à jour un employé
  Future<Employee> updateEmployee(Employee employee) async {
    try {
      print('[EmployeeService] Updating employee: ${employee.id}');
      
      final updatedEmployee = employee.copyWith(
        updatedAt: DateTime.now(),
      );

      final response = await _apiService.put(
        AppConstants.employeeEndpoint(employee.id),
        data: updatedEmployee.toJson(),
      );
      
      final resultEmployee = Employee.fromJson(response.data['data']);
      
      // Sauvegarder localement
      await _storageService.saveEmployee(resultEmployee);
      
      print('[EmployeeService] Employee updated: ${resultEmployee.id}');
      return resultEmployee;
    } catch (e) {
      print('[EmployeeService] Error updating employee: $e');
      rethrow;
    }
  }

  /// Supprimer un employé
  Future<void> deleteEmployee(String employeeId) async {
    try {
      print('[EmployeeService] Deleting employee: $employeeId');
      
      await _apiService.delete(AppConstants.employeeEndpoint(employeeId));
      
      // Supprimer localement
      await _storageService.deleteEmployee(employeeId);
      
      print('[EmployeeService] Employee deleted: $employeeId');
    } catch (e) {
      print('[EmployeeService] Error deleting employee: $e');
      rethrow;
    }
  }

  /// Récupérer les employés actifs
  Future<List<Employee>> getActiveEmployees() async {
    final employees = await getEmployees();
    return employees.where((emp) => emp.isActive).toList();
  }

  /// Récupérer les employés par rôle
  Future<List<Employee>> getEmployeesByRole(String role) async {
    final employees = await getEmployees();
    return employees.where((emp) => emp.role == role).toList();
  }
}

