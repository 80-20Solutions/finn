import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/offline/presentation/providers/offline_providers.dart';
import '../services/connectivity_service.dart';

/// T081: Offline banner showing network status and pending sync count
///
/// Displays when:
/// - Device is offline
/// - There are pending expenses to sync
///
/// Features:
/// - Network status indicator
/// - Pending expense count
/// - Manual retry button
/// - Dismissible
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity status
    final connectivityStatus = ref.watch(connectivityServiceProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return connectivityStatus.when(
      data: (status) {
        // Only show banner if offline or there are pending items
        final isOffline = status == NetworkStatus.offline;
        final hasPending = pendingCount.value ?? 0 > 0;

        if (!isOffline && !hasPending) {
          return const SizedBox.shrink();
        }

        return Material(
          color: isOffline ? Colors.orange.shade700 : Colors.blue.shade700,
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.cloud_queue,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOffline
                            ? 'Modalità offline'
                            : 'Sincronizzazione in corso',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasPending) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${pendingCount.value} ${(pendingCount.value ?? 0) == 1 ? "spesa" : "spese"} da sincronizzare',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // T084: Manual retry button
                if (!isOffline && hasPending) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(syncTriggerProvider.notifier).manualSync();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Riprova',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
