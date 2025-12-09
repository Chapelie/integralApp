/// Sync queue entry model for managing offline-first data synchronization
///
/// This class manages the queue of operations that need to be synchronized
/// with the server, including retry logic and conflict detection.
library;

class SyncQueueEntry {
  final String id;
  final String deviceId;
  final String? warehouseId;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> data;
  final DateTime clientTimestamp;
  final String status;
  final int retryCount;
  final String checksum;
  final String? error;

  SyncQueueEntry({
    required this.id,
    required this.deviceId,
    this.warehouseId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.clientTimestamp,
    this.status = 'pending',
    this.retryCount = 0,
    required this.checksum,
    this.error,
  });

  /// Converts SyncQueueEntry to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'warehouseId': warehouseId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'data': data,
      'clientTimestamp': clientTimestamp.toIso8601String(),
      'status': status,
      'retryCount': retryCount,
      'checksum': checksum,
      'error': error,
    };
  }

  /// Creates SyncQueueEntry from JSON map
  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      warehouseId: json['warehouseId'] as String?,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      clientTimestamp: DateTime.parse(json['clientTimestamp'] as String),
      status: json['status'] as String? ?? 'pending',
      retryCount: json['retryCount'] as int? ?? 0,
      checksum: json['checksum'] as String,
      error: json['error'] as String?,
    );
  }

  /// Creates a copy of this SyncQueueEntry with updated fields
  SyncQueueEntry copyWith({
    String? id,
    String? deviceId,
    String? warehouseId,
    String? entityType,
    String? entityId,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? clientTimestamp,
    String? status,
    int? retryCount,
    String? checksum,
    String? error,
  }) {
    return SyncQueueEntry(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      warehouseId: warehouseId ?? this.warehouseId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      checksum: checksum ?? this.checksum,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'SyncQueueEntry(id: $id, entityType: $entityType, operation: $operation, status: $status, retryCount: $retryCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SyncQueueEntry &&
        other.id == id &&
        other.deviceId == deviceId &&
        other.warehouseId == warehouseId &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.operation == operation &&
        other.status == status &&
        other.retryCount == retryCount &&
        other.checksum == checksum;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deviceId.hashCode ^
        warehouseId.hashCode ^
        entityType.hashCode ^
        entityId.hashCode ^
        operation.hashCode ^
        status.hashCode ^
        retryCount.hashCode ^
        checksum.hashCode;
  }
}
