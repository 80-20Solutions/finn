import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App design constants - spacing, radius, shadows
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);

  static RoundedRectangleBorder get smallShape => RoundedRectangleBorder(
        borderRadius: smallRadius,
      );
  static RoundedRectangleBorder get mediumShape => RoundedRectangleBorder(
        borderRadius: mediumRadius,
      );
  static RoundedRectangleBorder get largeShape => RoundedRectangleBorder(
        borderRadius: largeRadius,
      );
  static RoundedRectangleBorder get extraLargeShape => RoundedRectangleBorder(
        borderRadius: extraLargeRadius,
      );
}

/// Organic, soft shadows
class AppShadows {
  static List<BoxShadow> get small => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: AppColors.shadowDark,
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];
}
