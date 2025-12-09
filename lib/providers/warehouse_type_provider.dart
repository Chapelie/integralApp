// lib/providers/warehouse_type_provider.dart
// Provider for warehouse type management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/warehouse_type_service.dart';

/// Provider for warehouse type (read-only)
final warehouseTypeProvider = FutureProvider<String?>((ref) async {
  final service = WarehouseTypeService();
  final type = await service.getStoredWarehouseType();
  return type?.value;
});

