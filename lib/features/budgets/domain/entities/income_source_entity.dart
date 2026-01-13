import 'package:equatable/equatable.dart';

/// Income type enumeration
enum IncomeType {
  salary,
  freelance,
  investment,
  other,
  custom,
}

/// Extension for IncomeType enum to string conversion
extension IncomeTypeExtension on IncomeType {
  String toShortString() {
    return toString().split('.').last;
  }

  static IncomeType fromString(String value) {
    return IncomeType.values.firstWhere(
      (e) => e.toShortString() == value,
      orElse: () => IncomeType.other,
    );
  }
}

/// Domain entity representing an income source
///
/// Represents a single source of monthly income for a user.
/// Supports predefined types (salary, freelance, investment, other)
/// and custom types with user-defined names.
class IncomeSourceEntity extends Equatable {
  final String id;
  final String userId;
  final IncomeType type;
  final String? customTypeName;
  final int amount; // Amount in cents
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncomeSourceEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.customTypeName,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validation: Custom type must have a name
  bool get isValid {
    if (type == IncomeType.custom) {
      return customTypeName != null && customTypeName!.trim().isNotEmpty;
    }
    return true;
  }

  /// Get display name for the income type
  String get displayName {
    if (type == IncomeType.custom && customTypeName != null) {
      return customTypeName!;
    }
    return type.toShortString();
  }

  /// Create a copy with updated fields
  IncomeSourceEntity copyWith({
    String? id,
    String? userId,
    IncomeType? type,
    String? customTypeName,
    int? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeSourceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      customTypeName: customTypeName ?? this.customTypeName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        customTypeName,
        amount,
        createdAt,
        updatedAt,
      ];
}
