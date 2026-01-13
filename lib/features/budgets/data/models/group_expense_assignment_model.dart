import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/group_expense_assignment_entity.dart';

part 'group_expense_assignment_model.g.dart';

/// Data model for GroupExpenseAssignment with JSON serialization
///
/// This model serves as the data transfer object between:
/// - Supabase backend (via Postgres JSONB)
/// - Local Drift database (via type converters)
/// - Domain layer (converts to/from GroupExpenseAssignmentEntity)
@JsonSerializable()
class GroupExpenseAssignmentModel {
  final String id;
  @JsonKey(name: 'group_id')
  final String groupId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'spending_limit')
  final int spendingLimit;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const GroupExpenseAssignmentModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.spendingLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create model from JSON (from Supabase)
  factory GroupExpenseAssignmentModel.fromJson(Map<String, dynamic> json) =>
      _$GroupExpenseAssignmentModelFromJson(json);

  /// Convert model to JSON (for Supabase)
  Map<String, dynamic> toJson() => _$GroupExpenseAssignmentModelToJson(this);

  /// Convert model to domain entity
  GroupExpenseAssignmentEntity toEntity() {
    return GroupExpenseAssignmentEntity(
      id: id,
      groupId: groupId,
      userId: userId,
      spendingLimit: spendingLimit,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  factory GroupExpenseAssignmentModel.fromEntity(
      GroupExpenseAssignmentEntity entity) {
    return GroupExpenseAssignmentModel(
      id: entity.id,
      groupId: entity.groupId,
      userId: entity.userId,
      spendingLimit: entity.spendingLimit,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  GroupExpenseAssignmentModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    int? spendingLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupExpenseAssignmentModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      spendingLimit: spendingLimit ?? this.spendingLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
