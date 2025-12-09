// lib/providers/employee_provider.dart
/// Riverpod provider for managing employees
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/employee.dart';
import '../core/employee_service.dart';

part 'employee_provider.g.dart';

// Employee State
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;

  EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeeState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Employee Notifier
@riverpod
class EmployeeNotifier extends _$EmployeeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  @override
  EmployeeState build() {
    // Don't call loadEmployees here to avoid circular dependency
    // Instead, load employees when the provider is first accessed
    return EmployeeState();
  }

  /// Loads all employees from the API or local storage
  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await _employeeService.getEmployees();
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Adds a new employee
  Future<void> addEmployee(Employee employee) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newEmployee = await _employeeService.createEmployee(employee);
      state = state.copyWith(
        employees: [...state.employees, newEmployee],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates an existing employee
  Future<void> updateEmployee(Employee employee) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedEmployee = await _employeeService.updateEmployee(employee);
      state = state.copyWith(
        employees: state.employees.map((e) => e.id == updatedEmployee.id ? updatedEmployee : e).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Deletes an employee
  Future<void> deleteEmployee(String employeeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _employeeService.deleteEmployee(employeeId);
      state = state.copyWith(
        employees: state.employees.where((e) => e.id != employeeId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Gets active employees
  List<Employee> getActiveEmployees() {
    return state.employees.where((e) => e.isActive).toList();
  }

  /// Gets employees by role
  List<Employee> getEmployeesByRole(String role) {
    return state.employees.where((e) => e.role == role).toList();
  }
}
