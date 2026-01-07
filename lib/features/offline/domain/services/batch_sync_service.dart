import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/offline_database.dart';

/// Result of syncing a single item
class SyncItemResult {
  final String id;
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? serverVersion; // For conflicts
  final DateTime? serverUpdatedAt;

  SyncItemResult({
    required this.id,
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.serverVersion,
    this.serverUpdatedAt,
  });

  factory SyncItemResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;

    return SyncItemResult(
      id: json['id'] as String,
      success: status == 'success',
      errorMessage: json['error_message'] as String?,
      errorCode: json['error_code'] as String?,
      serverVersion: status == 'conflict'
          ? json['server_version'] as Map<String, dynamic>?
          : null,
      serverUpdatedAt: json['server_updated_at'] != null
          ? DateTime.parse(json['server_updated_at'] as String)
          : null,
    );
  }

  bool get isConflict => errorCode == null && serverVersion != null;
}

/// Result of syncing a batch of items
class BatchSyncResult {
  final Map<String, SyncItemResult> results;

  BatchSyncResult(this.results);

  int get successCount => results.values.where((r) => r.success).length;
  int get failureCount => results.values.where((r) => !r.success).length;
  int get conflictCount => results.values.where((r) => r.isConflict).length;

  bool get hasConflicts => conflictCount > 0;
  bool get allSuccess => failureCount == 0 && conflictCount == 0;
}

/// Service for batch sync operations with Supabase RPC functions
///
/// Handles:
/// - Batch create expenses
/// - Batch update expenses (with conflict detection)
/// - Batch delete expenses
class BatchSyncService {
  final SupabaseClient _supabase;

  BatchSyncService({required SupabaseClient supabase}) : _supabase = supabase;

  /// Batch create expenses via RPC
  Future<Map<String, SyncItemResult>> batchCreateExpenses(
    List<SyncQueueItem> items,
  ) async {
    if (items.isEmpty) return {};

    try {
      // Parse payloads
      final expenses = items.map((item) {
        final payload = jsonDecode(item.payload);
        return payload;
      }).toList();

      // Call Supabase RPC
      final response = await _supabase.rpc(
        'batch_create_expenses',
        params: {'p_expenses': expenses},
      ) as List;

      // Convert to results map
      final results = <String, SyncItemResult>{};
      for (final result in response) {
        final syncResult = SyncItemResult.fromJson(
          Map<String, dynamic>.from(result as Map),
        );
        results[syncResult.id] = syncResult;
      }

      return results;
    } on PostgrestException catch (e) {
      // Server error - mark all as failed
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        final payload = jsonDecode(item.payload);
        results[payload['id'] as String] = SyncItemResult(
          id: payload['id'] as String,
          success: false,
          errorMessage: e.message,
          errorCode: e.code,
        );
      }
      return results;
    } catch (e) {
      // Network or other error
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        final payload = jsonDecode(item.payload);
        results[payload['id'] as String] = SyncItemResult(
          id: payload['id'] as String,
          success: false,
          errorMessage: 'Network error: ${e.toString()}',
        );
      }
      return results;
    }
  }

  /// Batch update expenses via RPC (with conflict detection)
  Future<Map<String, SyncItemResult>> batchUpdateExpenses(
    List<SyncQueueItem> items,
  ) async {
    if (items.isEmpty) return {};

    try {
      // Build update payloads
      final updates = items.map((item) {
        final payload = jsonDecode(item.payload);
        return {
          'id': item.entityId,
          'client_updated_at': payload['local_updated_at'],
          'fields': payload,
        };
      }).toList();

      // Call Supabase RPC
      final response = await _supabase.rpc(
        'batch_update_expenses',
        params: {'p_updates': updates},
      ) as List;

      // Convert to results map
      final results = <String, SyncItemResult>{};
      for (final result in response) {
        final syncResult = SyncItemResult.fromJson(
          Map<String, dynamic>.from(result as Map),
        );
        results[syncResult.id] = syncResult;
      }

      return results;
    } on PostgrestException catch (e) {
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        results[item.entityId] = SyncItemResult(
          id: item.entityId,
          success: false,
          errorMessage: e.message,
          errorCode: e.code,
        );
      }
      return results;
    } catch (e) {
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        results[item.entityId] = SyncItemResult(
          id: item.entityId,
          success: false,
          errorMessage: 'Network error: ${e.toString()}',
        );
      }
      return results;
    }
  }

  /// Batch delete expenses via RPC
  Future<Map<String, SyncItemResult>> batchDeleteExpenses(
    List<SyncQueueItem> items,
  ) async {
    if (items.isEmpty) return {};

    try {
      // Extract expense IDs
      final expenseIds = items.map((item) => item.entityId).toList();

      // Call Supabase RPC
      final response = await _supabase.rpc(
        'batch_delete_expenses',
        params: {'p_expense_ids': expenseIds},
      ) as List;

      // Convert to results map
      final results = <String, SyncItemResult>{};
      for (final result in response) {
        final syncResult = SyncItemResult.fromJson(
          Map<String, dynamic>.from(result as Map),
        );
        results[syncResult.id] = syncResult;
      }

      return results;
    } on PostgrestException catch (e) {
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        results[item.entityId] = SyncItemResult(
          id: item.entityId,
          success: false,
          errorMessage: e.message,
          errorCode: e.code,
        );
      }
      return results;
    } catch (e) {
      final results = <String, SyncItemResult>{};
      for (final item in items) {
        results[item.entityId] = SyncItemResult(
          id: item.entityId,
          success: false,
          errorMessage: 'Network error: ${e.toString()}',
        );
      }
      return results;
    }
  }

  /// Get expenses by IDs (for conflict resolution)
  Future<List<Map<String, dynamic>>> getExpensesByIds(
    List<String> expenseIds,
  ) async {
    if (expenseIds.isEmpty) return [];

    try {
      final response = await _supabase.rpc(
        'get_expenses_by_ids',
        params: {'p_expense_ids': expenseIds},
      ) as List;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}
