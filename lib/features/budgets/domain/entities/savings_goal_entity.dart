import 'package:equatable/equatable.dart';

/// Domain entity representing a user's monthly savings goal
///
/// Each user has at most one savings goal at a time (1:1 relationship).
/// The goal can be automatically adjusted when group expenses exceed available budget.
/// Tracks the original amount and adjustment timestamp for transparency.
class SavingsGoalEntity extends Equatable {
  final String id;
  final String userId;
  final int amount; // Current savings goal amount in cents
  final int? originalAmount; // Original amount before auto-adjustment (in cents)
  final DateTime? adjustedAt; // When the goal was last auto-adjusted
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoalEntity({
    required this.id,
    required this.userId,
    required this.amount,
    this.originalAmount,
    this.adjustedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if the savings goal has been automatically adjusted
  bool get wasAutoAdjusted => originalAmount != null && adjustedAt != null;

  /// Calculate how much the goal was reduced (returns 0 if not adjusted or increased)
  int get adjustmentAmount {
    if (originalAmount == null) return 0;
    return originalAmount! - amount;
  }

  /// Validation: Amount must be non-negative
  bool get isValid => amount >= 0;

  /// Create a copy with updated fields
  SavingsGoalEntity copyWith({
    String? id,
    String? userId,
    int? amount,
    int? originalAmount,
    DateTime? adjustedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      adjustedAt: adjustedAt ?? this.adjustedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        originalAmount,
        adjustedAt,
        createdAt,
        updatedAt,
      ];
}
