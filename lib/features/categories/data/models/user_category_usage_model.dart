// Data Model: User Category Usage
// Feature: Italian Categories and Budget Management (004)
// Task: T036

import '../../domain/entities/user_category_usage_entity.dart';

/// Data model for user category usage tracking
class UserCategoryUsageModel extends UserCategoryUsageEntity {
  const UserCategoryUsageModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.firstUsedAt,
  });

  /// Create model from JSON
  factory UserCategoryUsageModel.fromJson(Map<String, dynamic> json) {
    return UserCategoryUsageModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      firstUsedAt: DateTime.parse(json['first_used_at'] as String),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'first_used_at': firstUsedAt.toIso8601String(),
    };
  }

  /// Convert entity to model
  factory UserCategoryUsageModel.fromEntity(UserCategoryUsageEntity entity) {
    return UserCategoryUsageModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      firstUsedAt: entity.firstUsedAt,
    );
  }

  /// Convert model to entity
  UserCategoryUsageEntity toEntity() {
    return UserCategoryUsageEntity(
      id: id,
      userId: userId,
      categoryId: categoryId,
      firstUsedAt: firstUsedAt,
    );
  }
}
