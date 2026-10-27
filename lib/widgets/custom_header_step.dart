import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomHeaderStep extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const CustomHeaderStep({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 3,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top navigation bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Circular Back Button
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                  border: Border.all(
                    color: AppColors.outlineVariant,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Header Title
            Column(
              children: [
                Text(
                  'Hồ sơ cá nhân',
                  style: AppTypography.headline(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'THIẾT LẬP BAN ĐẦU',
                  style: AppTypography.labelCaption(color: AppColors.outline),
                ),
              ],
            ),

            // Step Indicator Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColors.surfaceContainer,
                border: Border.all(
                  color: AppColors.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: AppColors.dotPulseGlow,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bước $currentStep/$totalSteps',
                    style: AppTypography.badge(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Glowing Linear Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 4,
            width: double.infinity,
            color: AppColors.outlineVariant,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Subheader Banner: Hiệu chỉnh sinh trắc học
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant,
                ),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiệu chỉnh sinh trắc học',
                    style: AppTypography.titleMedium(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dữ liệu giúp tính toán calo & macro phù hợp với bạn',
                    style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
