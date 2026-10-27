import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'segmented_toggle.dart';
import '../models/user_onboarding_model.dart';
import '../theme/app_theme.dart';

class NutritionGoalCard extends StatelessWidget {
  final UserOnboardingModel model;

  const NutritionGoalCard({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final macros = model.macros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2, right: 2),
          child: Text(
            '02 / MỤC TIÊU DINH DƯỠNG',
            style: AppTypography.badge(color: AppColors.outline),
          ),
        ),

        // Outer Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Selector Pills
              SegmentedToggle<NutritionGoal>(
                items: NutritionGoal.values.map((goalItem) {
                  return ToggleItem(
                    value: goalItem,
                    label: goalItem.title,
                  );
                }).toList(),
                selectedValue: model.goal,
                onChanged: (val) => model.setGoal(val),
              ),

              const SizedBox(height: 16),

              // Energy Target Inner Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Energy display & Deficit badge
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CALO NẠP VÀO MỖI NGÀY',
                              style: AppTypography.labelCaption(
                                color: AppColors.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  numberFormat.format(model.calories),
                                  style: AppTypography.displayLarge(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'kcal/ngày',
                                  style: AppTypography.headline(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tiêu hao hàng ngày (TDEE): ${numberFormat.format(model.tdee)} kcal • BMR: ${numberFormat.format(model.bmr.round())} kcal',
                              style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),

                        // Deficit / Surplus Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                color: AppColors.onSurface,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                model.goal.badgeText,
                                style: AppTypography.badge(color: AppColors.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Explanation note for why calorie is higher/lower than TDEE
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              switch (model.goal) {
                                NutritionGoal.fatLoss =>
                                  'Để giảm mỡ, bạn nạp ít hơn mức cơ thể đốt (${numberFormat.format(model.tdee)} kcal) để cơ thể dùng mỡ thừa.',
                                NutritionGoal.maintenance =>
                                  'Nạp bằng mức cơ thể tiêu thụ (${numberFormat.format(model.tdee)} kcal) để duy trì cân nặng ổn định.',
                                NutritionGoal.muscleGain =>
                                  'Nạp nhiều hơn mức cơ thể tiêu thụ (${numberFormat.format(model.tdee)} kcal) để xây dựng cơ bắp.',
                              },
                              style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Calorie Interactive Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceContainerHigh,
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9,
                          elevation: 6,
                          pressedElevation: 8,
                        ),
                        overlayColor: AppColors.primary.withValues(alpha: 0.12),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
                      ),
                      child: Slider(
                        value: model.calories.toDouble().clamp(1000.0, 4500.0),
                        min: 1000,
                        max: 4500,
                        divisions: 70,
                        onChanged: (val) {
                          model.setCalories(val.round());
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 3 Macro distribution cards
                    Row(
                      children: [
                        // Protein
                        Expanded(
                          child: _buildMacroTile(
                            label: 'Protein',
                            grams: '${macros.proteinGrams}g',
                            detail: '${macros.proteinPercent}% · ${macros.proteinKcal} kcal',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Carbs
                        Expanded(
                          child: _buildMacroTile(
                            label: 'Carbs',
                            grams: '${macros.carbsGrams}g',
                            detail: '${macros.carbsPercent}% · ${macros.carbsKcal} kcal',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Fat
                        Expanded(
                          child: _buildMacroTile(
                            label: 'Fat',
                            grams: '${macros.fatGrams}g',
                            detail: '${macros.fatPercent}% · ${macros.fatKcal} kcal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroTile({
    required String label,
    required String grams,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4), // Giảm độ đậm của nền hộp Macro
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant) // Đổi nhãn Protein/Carb/Fat thành màu xám đậm
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            grams,
            style: AppTypography.headline(color: AppColors.onSurface), // Sửa lỗi chữ mất tích: Đổi số g thành màu đen
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}