/// Cash register model for managing cash drawer sessions
///
/// This class tracks cash register sessions including opening/closing balances,
/// sales totals, and reconciliation for the IntegralPOS system.
library;

class CashRegister {
  final String id;
  final String userId;
  final String deviceId;
  final String? warehouseId;
  final double openingBalance;
  final double? closingBalance;
  final double? expectedCash;
  final double? actualCash;
  final double? difference;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;
  final int? salesCount;
  final double? totalSales;
  final bool isSynced;

  CashRegister({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.warehouseId,
    required this.openingBalance,
    this.closingBalance,
    this.expectedCash,
    this.actualCash,
    this.difference,
    this.status = 'open',
    required this.openedAt,
    this.closedAt,
    this.notes,
    this.salesCount,
    this.totalSales,
    this.isSynced = false,
  });

  /// Calculates the difference between expected and actual cash
  ///
  /// Returns the difference (can be positive or negative)
  double calculateDifference() {
    if (expectedCash == null || actualCash == null) {
      return 0.0;
    }
    return actualCash! - expectedCash!;
  }

  /// Converts CashRegister to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'warehouseId': warehouseId,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'difference': difference,
      'status': status,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'notes': notes,
      'salesCount': salesCount,
      'totalSales': totalSales,
      'isSynced': isSynced,
    };
  }

  /// Creates CashRegister from JSON map
  factory CashRegister.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return CashRegister(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      deviceId: json['device_id'] as String? ?? json['deviceId'] as String,
      warehouseId: json['warehouse_id'] as String? ?? json['warehouseId'] as String?,
      openingBalance: safeToDouble(json['opening_balance'] ?? json['openingBalance']),
      closingBalance: json['closing_balance'] != null || json['closingBalance'] != null
          ? safeToDouble(json['closing_balance'] ?? json['closingBalance'])
          : null,
      expectedCash: json['expected_balance'] != null || json['expectedCash'] != null
          ? safeToDouble(json['expected_balance'] ?? json['expectedCash'])
          : null,
      actualCash: json['actualCash'] != null
          ? safeToDouble(json['actualCash'])
          : null,
      difference: json['cash_difference'] != null || json['difference'] != null
          ? safeToDouble(json['cash_difference'] ?? json['difference'])
          : null,
      status: json['status'] as String? ?? 'open',
      openedAt: DateTime.parse(json['opened_at'] ?? json['openedAt'] as String),
      closedAt: json['closed_at'] != null || json['closedAt'] != null
          ? DateTime.parse((json['closed_at'] ?? json['closedAt']) as String)
          : null,
      notes: json['notes'] as String?,
      salesCount: json['salesCount'] as int?,
      totalSales: json['totalSales'] != null
          ? safeToDouble(json['totalSales'])
          : null,
      isSynced: json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? false,
    );
  }

  /// Creates a copy of this CashRegister with updated fields
  CashRegister copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? warehouseId,
    double? openingBalance,
    double? closingBalance,
    double? expectedCash,
    double? actualCash,
    double? difference,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    String? notes,
    int? salesCount,
    double? totalSales,
    bool? isSynced,
  }) {
    return CashRegister(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      warehouseId: warehouseId ?? this.warehouseId,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      salesCount: salesCount ?? this.salesCount,
      totalSales: totalSales ?? this.totalSales,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'CashRegister(id: $id, status: $status, openingBalance: $openingBalance, totalSales: $totalSales)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CashRegister &&
        other.id == id &&
        other.userId == userId &&
        other.deviceId == deviceId &&
        other.warehouseId == warehouseId &&
        other.openingBalance == openingBalance &&
        other.status == status &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        deviceId.hashCode ^
        warehouseId.hashCode ^
        openingBalance.hashCode ^
        status.hashCode ^
        isSynced.hashCode;
  }
}
