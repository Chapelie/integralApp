/// Sync conflict model for managing data synchronization conflicts
///
/// This class handles conflicts that arise when the same data is modified
/// both offline and on the server, providing resolution strategies.
library;

class SyncConflict {
  final String id;
  final String syncQueueId;
  final String entityType;
  final String entityId;
  final String conflictType;
  final Map<String, dynamic> clientData;
  final Map<String, dynamic> serverData;
  final String? resolutionStrategy;
  final String status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;

  SyncConflict({
    required this.id,
    required this.syncQueueId,
    required this.entityType,
    required this.entityId,
    required this.conflictType,
    required this.clientData,
    required this.serverData,
    this.resolutionStrategy,
    this.status = 'pending',
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
  });

  /// Attempts to automatically resolve the conflict by merging data
  ///
  /// Returns a merged Map combining client and server data.
  /// Strategy: Server wins for conflicts, but preserves client-only fields.
  Map<String, dynamic> resolveAutomatically() {
    final merged = <String, dynamic>{};

    // Start with server data as base (server wins)
    merged.addAll(serverData);

    // Add client-only fields that don't exist in server data
    clientData.forEach((key, value) {
      if (!serverData.containsKey(key)) {
        merged[key] = value;
      }
    });

    // Preserve client timestamps if more recent
    if (clientData.containsKey('updatedAt') && serverData.containsKey('updatedAt')) {
      final clientTime = DateTime.parse(clientData['updatedAt'] as String);
      final serverTime = DateTime.parse(serverData['updatedAt'] as String);

      if (clientTime.isAfter(serverTime)) {
        // If client is more recent, use client data for non-critical fields
        merged['updatedAt'] = clientData['updatedAt'];
      }
    }

    return merged;
  }

  /// Converts SyncConflict to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncQueueId': syncQueueId,
      'entityType': entityType,
      'entityId': entityId,
      'conflictType': conflictType,
      'clientData': clientData,
      'serverData': serverData,
      'resolutionStrategy': resolutionStrategy,
      'status': status,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates SyncConflict from JSON map
  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      syncQueueId: json['syncQueueId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      conflictType: json['conflictType'] as String,
      clientData: Map<String, dynamic>.from(json['clientData'] as Map),
      serverData: Map<String, dynamic>.from(json['serverData'] as Map),
      resolutionStrategy: json['resolutionStrategy'] as String?,
      status: json['status'] as String? ?? 'pending',
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Creates a copy of this SyncConflict with updated fields
  SyncConflict copyWith({
    String? id,
    String? syncQueueId,
    String? entityType,
    String? entityId,
    String? conflictType,
    Map<String, dynamic>? clientData,
    Map<String, dynamic>? serverData,
    String? resolutionStrategy,
    String? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
    DateTime? createdAt,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      syncQueueId: syncQueueId ?? this.syncQueueId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      conflictType: conflictType ?? this.conflictType,
      clientData: clientData ?? this.clientData,
      serverData: serverData ?? this.serverData,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SyncConflict(id: $id, entityType: $entityType, conflictType: $conflictType, status: $status)';
  }
}
