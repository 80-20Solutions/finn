import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/income_source_entity.dart';

part 'income_source_model.g.dart';

/// Data model for IncomeSource with JSON serialization
///
/// This model serves as the data transfer object between:
/// - Supabase backend (via Postgres JSONB)
/// - Local Drift database (via type converters)
/// - Domain layer (converts to/from IncomeSourceEntity)
@JsonSerializable()
class IncomeSourceModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String type;
  @JsonKey(name: 'custom_type_name')
  final String? customTypeName;
  final int amount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const IncomeSourceModel({
    required this.id,
    required this.userId,
    required this.type,
    this.customTypeName,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create model from JSON (from Supabase)
  factory IncomeSourceModel.fromJson(Map<String, dynamic> json) =>
      _$IncomeSourceModelFromJson(json);

  /// Convert model to JSON (for Supabase)
  Map<String, dynamic> toJson() => _$IncomeSourceModelToJson(this);

  /// Convert model to domain entity
  IncomeSourceEntity toEntity() {
    return IncomeSourceEntity(
      id: id,
      userId: userId,
      type: IncomeTypeExtension.fromString(type),
      customTypeName: customTypeName,
      amount: amount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  factory IncomeSourceModel.fromEntity(IncomeSourceEntity entity) {
    return IncomeSourceModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type.toShortString(),
      customTypeName: entity.customTypeName,
      amount: entity.amount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  IncomeSourceModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? customTypeName,
    int? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeSourceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      customTypeName: customTypeName ?? this.customTypeName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
