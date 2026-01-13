import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/savings_goal_entity.dart';

part 'savings_goal_model.g.dart';

/// Data model for SavingsGoal with JSON serialization
///
/// This model serves as the data transfer object between:
/// - Supabase backend (via Postgres JSONB)
/// - Local Drift database (via type converters)
/// - Domain layer (converts to/from SavingsGoalEntity)
@JsonSerializable()
class SavingsGoalModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final int amount;
  @JsonKey(name: 'original_amount')
  final int? originalAmount;
  @JsonKey(name: 'adjusted_at')
  final DateTime? adjustedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.originalAmount,
    this.adjustedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create model from JSON (from Supabase)
  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      _$SavingsGoalModelFromJson(json);

  /// Convert model to JSON (for Supabase)
  Map<String, dynamic> toJson() => _$SavingsGoalModelToJson(this);

  /// Convert model to domain entity
  SavingsGoalEntity toEntity() {
    return SavingsGoalEntity(
      id: id,
      userId: userId,
      amount: amount,
      originalAmount: originalAmount,
      adjustedAt: adjustedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  factory SavingsGoalModel.fromEntity(SavingsGoalEntity entity) {
    return SavingsGoalModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      originalAmount: entity.originalAmount,
      adjustedAt: entity.adjustedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    int? amount,
    int? originalAmount,
    DateTime? adjustedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      adjustedAt: adjustedAt ?? this.adjustedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
