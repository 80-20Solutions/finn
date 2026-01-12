/// Member allocation model for JSON serialization.
/// Feature: 001-group-budget-wizard, Task: T010
///
/// Represents a single member's budget percentage allocation.
class MemberAllocationModel {
  const MemberAllocationModel({
    required this.userId,
    required this.displayName,
    required this.percentage,
  });

  /// User ID from profiles table
  final String userId;

  /// User's display name
  final String displayName;

  /// Allocation percentage (0-100, e.g., 33.33)
  final double percentage;

  /// Create from JSON
  factory MemberAllocationModel.fromJson(Map<String, dynamic> json) {
    return MemberAllocationModel(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'percentage': percentage,
    };
  }

  /// Validate percentage is within bounds
  bool get isValid => percentage >= 0 && percentage <= 100;

  @override
  String toString() {
    return 'MemberAllocation($displayName: ${percentage.toStringAsFixed(2)}%)';
  }
}
