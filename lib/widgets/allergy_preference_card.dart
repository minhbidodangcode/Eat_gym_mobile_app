import 'package:flutter/material.dart';
import '../models/user_onboarding_model.dart';
import '../theme/app_theme.dart';

class AllergyPreferenceCard extends StatelessWidget {
  final UserOnboardingModel model;

  const AllergyPreferenceCard({
    super.key,
    required this.model,
  });

  static const List<Map<String, String>> allergens = [
    {'name': 'Đậu phộng', 'emoji': '🥜'},
    {'name': 'Hải sản', 'emoji': '🦐'},
    {'name': 'Gluten', 'emoji': '🌾'},
    {'name': 'Sữa bò', 'emoji': '🥛'},
  ];

  static const List<Map<String, String>> preferences = [
    {'name': 'Eat Clean', 'emoji': '🥗'},
    {'name': 'Keto', 'emoji': '🥑'},
    {'name': 'Ăn chay', 'emoji': '🌱'},
    {'name': 'High Protein', 'emoji': '🥩'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2, right: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '03 / DỊ ỨNG & CHẾ ĐỘ ĂN',
                style: AppTypography.badge(color: AppColors.outline),
              ),
              Text(
                'Loại trừ thông minh',
                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
              ),
            ],
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
              // Food Allergy Title
              Text(
                'DỊ ỨNG THỰC PHẨM',
                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),

              // 2x2 Allergen Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allergens.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 46,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final item = allergens[index];
                  final name = item['name']!;
                  final emoji = item['emoji']!;
                  final isSelected = model.selectedAllergies.contains(name);

                  return GestureDetector(
                    onTap: () => model.toggleAllergy(name), // SỬA: Phục hồi lại hàm bấm chọn
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: isSelected ? AppColors.activeChipGlow : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: AppTypography.bodyMedium(
                                  // SỬA: Chọn -> Chữ trắng. Chưa chọn -> Chữ xám
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.onSurfaceVariant,
                                ).copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            // SỬA: Icon tick trắng khi chọn
                            color: isSelected ? AppColors.onPrimary : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Diet Preference Title
              Text(
                'CHẾ ĐỘ ƯU TIÊN',
                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),

              // Wrap of Preference Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preferences.map((pref) {
                  final name = pref['name']!;
                  final emoji = pref['emoji']!;
                  final isSelected = model.selectedPreferences.contains(name);

                  return GestureDetector(
                    onTap: () => model.togglePreference(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // SỬA: Đổi nền nút khi chọn thành primary (đen) thay vì Colors.white
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: isSelected ? AppColors.activeChipGlow : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$emoji $name',
                            style: AppTypography.bodySmall(
                              // SỬA: Đổi màu chữ theo trạng thái (Trắng khi chọn)
                              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            ).copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done,
                              size: 14,
                              // SỬA: Đổi màu dấu tick thành trắng
                              color: AppColors.onPrimary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}