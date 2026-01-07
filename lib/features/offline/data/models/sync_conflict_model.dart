import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../data/local/offline_database.dart';

/// T094: SyncConflictModel for tracking sync conflicts
///
/// Stores conflicts that occur during sync (server version newer than client)
/// Allows user to review and resolve conflicts manually if needed
class SyncConflictModel {
  final SyncConflict conflict;

  SyncConflictModel(this.conflict);

  /// Convert conflict to map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': conflict.id,
      'user_id': conflict.userId,
      'expense_id': conflict.expenseId,
      'conflict_type': conflict.conflictType,
      'local_version': conflict.localVersion,
      'server_version': conflict.serverVersion,
      'detected_at': conflict.detectedAt.toIso8601String(),
      'resolved_at': conflict.resolvedAt?.toIso8601String(),
      'resolution_strategy': conflict.resolutionStrategy,
      'resolved': conflict.resolved,
    };
  }

  /// Create from JSON
  static SyncConflictModel fromJson(Map<String, dynamic> json) {
    return SyncConflictModel(
      SyncConflict(
        id: json['id'] as int,
        userId: json['user_id'] as String,
        expenseId: json['expense_id'] as String,
        conflictType: json['conflict_type'] as String,
        localVersion: json['local_version'] as String,
        serverVersion: json['server_version'] as String,
        detectedAt: DateTime.parse(json['detected_at'] as String),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
        resolutionStrategy: json['resolution_strategy'] as String?,
        resolved: json['resolved'] as bool,
      ),
    );
  }

  /// Get local version as map
  Map<String, dynamic> getLocalVersion() {
    return jsonDecode(conflict.localVersion) as Map<String, dynamic>;
  }

  /// Get server version as map
  Map<String, dynamic> getServerVersion() {
    return jsonDecode(conflict.serverVersion) as Map<String, dynamic>;
  }

  /// Create Drift companion for insert
  static SyncConflictsCompanion toCompanion({
    required String userId,
    required String expenseId,
    required String conflictType,
    required Map<String, dynamic> localVersion,
    required Map<String, dynamic> serverVersion,
    String resolutionStrategy = 'server_wins',
  }) {
    return SyncConflictsCompanion.insert(
      userId: userId,
      expenseId: expenseId,
      conflictType: conflictType,
      localVersion: jsonEncode(localVersion),
      serverVersion: jsonEncode(serverVersion),
      detectedAt: DateTime.now(),
      resolutionStrategy: drift.Value(resolutionStrategy),
      resolved: const drift.Value(false),
    );
  }

  /// Mark conflict as resolved
  static SyncConflictsCompanion markResolved({
    required int conflictId,
    required String resolutionStrategy,
  }) {
    return SyncConflictsCompanion(
      id: drift.Value(conflictId),
      resolved: const drift.Value(true),
      resolvedAt: drift.Value(DateTime.now()),
      resolutionStrategy: drift.Value(resolutionStrategy),
    );
  }

  /// Get conflict type display string
  String get conflictTypeDisplay {
    switch (conflict.conflictType) {
      case 'update':
        return 'Modifica';
      case 'delete':
        return 'Eliminazione';
      default:
        return 'Sconosciuto';
    }
  }

  /// Get resolution strategy display string
  String get resolutionStrategyDisplay {
    switch (conflict.resolutionStrategy) {
      case 'server_wins':
        return 'Server vince';
      case 'client_wins':
        return 'Client vince';
      case 'manual':
        return 'Manuale';
      default:
        return 'Non risolto';
    }
  }
}
