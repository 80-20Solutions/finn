// Domain Entity: Category Budget for monthly budget allocations
// Feature: Italian Categories and Budget Management (004)
// Task: T014

import 'package:equatable/equatable.dart';

class CategoryBudgetEntity extends Equatable {
  final String id;
  final String categoryId;
  final String groupId;
  final int amount; // Budget amount in cents (EUR)
  final int month; // 1-12
  final int year; // e.g., 2026
  final String createdBy; // Profile ID of creator
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryBudgetEntity({
    required this.id,
    required this.categoryId,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        groupId,
        amount,
        month,
        year,
        createdBy,
        createdAt,
        updatedAt,
      ];

  @override
  bool? get stringify => true;
}
