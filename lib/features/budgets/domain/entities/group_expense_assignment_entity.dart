import 'package:equatable/equatable.dart';

/// Domain entity representing a user's spending limit assignment in a group
///
/// When a user joins or is added to a family group, group admins assign them
/// a monthly spending limit for group expenses. This entity tracks that assignment.
/// A user can have multiple assignments (one per group they're a member of).
class GroupExpenseAssignmentEntity extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final int spendingLimit; // Monthly spending limit in cents
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupExpenseAssignmentEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.spendingLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validation: Spending limit must be non-negative
  bool get isValid => spendingLimit >= 0;

  /// Create a copy with updated fields
  GroupExpenseAssignmentEntity copyWith({
    String? id,
    String? groupId,
    String? userId,
    int? spendingLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupExpenseAssignmentEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      spendingLimit: spendingLimit ?? this.spendingLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        spendingLimit,
        createdAt,
        updatedAt,
      ];
}
