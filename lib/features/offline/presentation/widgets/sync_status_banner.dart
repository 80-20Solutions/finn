import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_providers.dart';

/// Banner widget that displays sync status
///
/// Shows:
/// - Offline indicator when no network with pending syncs
/// - Syncing indicator when online with pending syncs
/// - Nothing when all synced
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (syncStatus) {
        if (syncStatus.isOfflineWithPending) {
          return _buildOfflineBanner(
            context,
            ref,
            syncStatus.pendingCount,
          );
        } else if (syncStatus.isSyncing) {
          return _buildSyncingBanner(
            context,
            ref,
            syncStatus.pendingCount,
          );
        }
        // All synced or idle - show nothing
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOfflineBanner(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) {
    return MaterialBanner(
      backgroundColor: Colors.orange.shade100,
      leading: const Icon(
        Icons.cloud_off,
        color: Colors.orange,
      ),
      content: Text(
        'Offline - $count ${count == 1 ? 'expense' : 'expenses'} pending sync',
        style: TextStyle(
          color: Colors.orange.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildSyncingBanner(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) {
    return MaterialBanner(
      backgroundColor: Colors.blue.shade50,
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      content: Text(
        'Syncing $count ${count == 1 ? 'expense' : 'expenses'}...',
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(syncTriggerProvider.notifier).sync();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

/// Sync status indicator icon for expense list items
class ExpenseSyncStatusIcon extends StatelessWidget {
  final String syncStatus;

  const ExpenseSyncStatusIcon({
    super.key,
    required this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    switch (syncStatus) {
      case 'pending':
        return const Icon(
          Icons.cloud_upload_outlined,
          color: Colors.orange,
          size: 20,
        );
      case 'syncing':
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 'failed':
        return const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        );
      case 'conflict':
        return const Icon(
          Icons.warning_outlined,
          color: Colors.deepOrange,
          size: 20,
        );
      case 'completed':
        return const Icon(
          Icons.cloud_done,
          color: Colors.green,
          size: 20,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
