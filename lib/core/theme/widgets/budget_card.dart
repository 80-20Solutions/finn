import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import '../app_constants.dart';

/// Budget card component with progress indicator
class BudgetCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final double? progressValue;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.progressValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.largeRadius,
          boxShadow: AppShadows.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              NumberFormat.currency(symbol: '€', decimalDigits: 2).format(amount),
              style: AppTextStyles.display.copyWith(
                color: amount >= 0 ? AppColors.sageGreen : AppColors.terracotta,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildProgressBar(progressValue!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilizzato', style: AppTextStyles.bodySmall),
            Text(
              '${(value * 100).toInt()}%',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.sageGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.bgSecondary,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.sageGreen,
            ),
          ),
        ),
      ],
    );
  }
}
