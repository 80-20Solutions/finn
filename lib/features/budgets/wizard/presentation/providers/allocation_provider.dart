import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing member allocation percentages with validation.
/// Feature: 001-group-budget-wizard, Task: T031
///
/// Manages:
/// - Member allocation percentages
/// - "Dividi Equamente" (split equally) functionality
/// - Percentage validation (100% ±0.01% tolerance)
class AllocationNotifier extends StateNotifier<AllocationState> {
  AllocationNotifier(List<Map<String, dynamic>> members)
      : super(AllocationState(
          members: members,
          allocations: {},
        ));

  void updateAllocation(String userId, double percentage) {
    final updated = Map<String, double>.from(state.allocations);
    updated[userId] = percentage;
    state = state.copyWith(allocations: updated);
  }

  void splitEqually() {
    final memberCount = state.members.length;
    if (memberCount == 0) return;

    // Calculate equal split with rounding
    final basePercentage = 100.0 / memberCount;
    final allocations = <String, double>{};

    for (int i = 0; i < memberCount; i++) {
      final userId = state.members[i]['user_id'] as String;
      if (i < memberCount - 1) {
        // Regular members get floored percentage
        allocations[userId] = double.parse(basePercentage.toStringAsFixed(2));
      } else {
        // Last member gets remainder to ensure total = 100%
        final sum = allocations.values.fold(0.0, (a, b) => a + b);
        allocations[userId] = double.parse((100.0 - sum).toStringAsFixed(2));
      }
    }

    state = state.copyWith(allocations: allocations);
  }

  void clearAllocations() {
    state = state.copyWith(allocations: {});
  }

  void setAllocations(Map<String, double> allocations) {
    state = state.copyWith(allocations: allocations);
  }

  double get totalPercentage {
    return state.allocations.values.fold(0.0, (sum, val) => sum + val);
  }

  bool get isValid {
    if (state.allocations.isEmpty) return false;
    final total = totalPercentage;
    return (total - 100.0).abs() <= 0.01; // ±0.01% tolerance
  }

  double get remainingPercentage {
    return 100.0 - totalPercentage;
  }

  String get validationMessage {
    if (state.allocations.isEmpty) {
      return 'Assegna le percentuali ai membri';
    }
    if (!isValid) {
      return 'Il totale deve essere 100% (attuale: ${totalPercentage.toStringAsFixed(2)}%)';
    }
    return '';
  }
}

class AllocationState {
  const AllocationState({
    required this.members,
    required this.allocations,
  });

  final List<Map<String, dynamic>> members;
  final Map<String, double> allocations;

  AllocationState copyWith({
    List<Map<String, dynamic>>? members,
    Map<String, double>? allocations,
  }) {
    return AllocationState(
      members: members ?? this.members,
      allocations: allocations ?? this.allocations,
    );
  }
}

// Provider definition
final allocationProvider = StateNotifierProvider.family<AllocationNotifier,
    AllocationState, List<Map<String, dynamic>>>(
  (ref, members) => AllocationNotifier(members),
);
