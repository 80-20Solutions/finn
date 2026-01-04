// Domain Entity: Category Entity for Italian expense categories
// Feature: Italian Categories and Budget Management (004)
// Task: T012

import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name; // Italian category name (Spesa, Benzina, etc.)
  final String groupId;
  final bool isDefault; // True for system-provided categories
  final String? createdBy; // NULL for default categories
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.groupId,
    required this.isDefault,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        groupId,
        isDefault,
        createdBy,
        createdAt,
        updatedAt,
      ];

  @override
  bool? get stringify => true;
}
