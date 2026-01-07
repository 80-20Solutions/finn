import 'package:drift/drift.dart' as drift;
import '../local/offline_database.dart';

/// Model for sync queue items
class SyncQueueItemModel {
  final SyncQueueItem driftData;

  SyncQueueItemModel(this.driftData);

  /// Check if this item is ready to retry based on backoff delay
  bool isReadyToRetry() {
    if (driftData.nextRetryAt == null) return true;
    return DateTime.now().isAfter(driftData.nextRetryAt!);
  }

  /// Create companion for inserting a new sync queue item
  static SyncQueueItemsCompanion create({
    required String userId,
    required String operation, // 'create', 'update', 'delete'
    required String entityType, // 'expense', 'expense_image'
    required String entityId,
    required String payload, // JSON string
    int priority = 0,
  }) {
    return SyncQueueItemsCompanion.insert(
      userId: userId,
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      syncStatus: 'pending',
      priority: drift.Value(priority),
      createdAt: DateTime.now(),
    );
  }

  /// Update sync status to syncing
  static SyncQueueItemsCompanion markAsSyncing(SyncQueueItem item) {
    return SyncQueueItemsCompanion(
      id: drift.Value(item.id),
      syncStatus: const drift.Value('syncing'),
      retryCount: drift.Value(item.retryCount + 1),
    );
  }

  /// Mark as failed with next retry time (exponential backoff)
  static SyncQueueItemsCompanion markAsFailed(
    SyncQueueItem item,
    String errorMessage, {
    List<int> retryDelays = const [30, 120, 300], // 30s, 2min, 5min
  }) {
    final retryCount = item.retryCount + 1;
    final shouldGiveUp = retryCount > retryDelays.length;

    DateTime? nextRetry;
    String status;

    if (shouldGiveUp) {
      status = 'failed';
      nextRetry = null;
    } else {
      status = 'pending';
      final delaySeconds = retryDelays[retryCount - 1];
      nextRetry = DateTime.now().add(Duration(seconds: delaySeconds));
    }

    return SyncQueueItemsCompanion(
      id: drift.Value(item.id),
      syncStatus: drift.Value(status),
      retryCount: drift.Value(retryCount),
      nextRetryAt: drift.Value(nextRetry),
      errorMessage: drift.Value(errorMessage),
    );
  }

  /// Mark as completed (will be deleted from queue)
  static SyncQueueItemsCompanion markAsCompleted(SyncQueueItem item) {
    return SyncQueueItemsCompanion(
      id: drift.Value(item.id),
      syncStatus: const drift.Value('completed'),
    );
  }
}
