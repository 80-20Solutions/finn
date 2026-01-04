// Domain Entity: User Category Usage for virgin category tracking
// Feature: Italian Categories and Budget Management (004)
// Task: T013

import 'package:equatable/equatable.dart';

class UserCategoryUsageEntity extends Equatable {
  final String id;
  final String userId; // Profile ID of user
  final String categoryId; // Category that was used
  final DateTime firstUsedAt; // Timestamp of first expense in category

  const UserCategoryUsageEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.firstUsedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        firstUsedAt,
      ];

  @override
  bool? get stringify => true;
}
