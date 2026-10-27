import 'package:flutter/material.dart';
import '../models/user_onboarding_model.dart';
import '../theme/app_theme.dart';

class AllergyPreferenceCard extends StatefulWidget {
  final UserOnboardingModel model;

  const AllergyPreferenceCard({
    super.key,
    required this.model,
  });

  @override
  State<AllergyPreferenceCard> createState() => _AllergyPreferenceCardState();
}

class _AllergyPreferenceCardState extends State<AllergyPreferenceCard> {
  final TextEditingController _customAllergyController = TextEditingController();

  static const List<Map<String, String>> commonAllergens = [
    {'name': 'Đậu phộng', 'emoji': '🥜'},
    {'name': 'Hải sản', 'emoji': '🦐'},
    {'name': 'Gluten / Lúa mì', 'emoji': '🌾'},
    {'name': 'Sữa bò / Lactose', 'emoji': '🥛'},
    {'name': 'Trứng gà', 'emoji': '🥚'},
    {'name': 'Đậu nành', 'emoji': '🫘'},
    {'name': 'Hạt hạnh nhân / Óc chó', 'emoji': '🌰'},
    {'name': 'Cá biển', 'emoji': '🐟'},
  ];

  static const List<Map<String, String>> preferences = [
    {'name': 'Eat Clean', 'emoji': '🥗'},
    {'name': 'Keto', 'emoji': '🥑'},
    {'name': 'Ăn chay', 'emoji': '🌱'},
    {'name': 'High Protein', 'emoji': '🥩'},
  ];

  @override
  void dispose() {
    _customAllergyController.dispose();
    super.dispose();
  }

  void _handleAddCustomAllergy() {
    final text = _customAllergyController.text.trim();
    if (text.isNotEmpty) {
      widget.model.addCustomAllergy(text);
      _customAllergyController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final isNoAllergy = model.hasNoAllergy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2, right: 2),
          child: Text(
            '03 / DỊ ỨNG & CHẾ ĐỘ ĂN',
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
              // Food Allergy Title
              Text(
                'DỊ ỨNG THỰC PHẨM',
                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),

              // 1. Nút "Không có dị ứng"
              GestureDetector(
                onTap: () => model.toggleAllergy(UserOnboardingModel.noAllergy),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isNoAllergy ? AppColors.primary : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNoAllergy
                          ? AppColors.primary
                          : AppColors.outlineVariant.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: isNoAllergy ? AppColors.activeChipGlow : null,
                  ),
                  child: Row(
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Không có (Không bị dị ứng)',
                          style: AppTypography.bodyMedium(
                            color: isNoAllergy
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ).copyWith(
                            fontWeight: isNoAllergy ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: isNoAllergy ? AppColors.onPrimary : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'HOẶC CHỌN CÁC LOẠI DỊ ỨNG NẾU CÓ:',
                style: AppTypography.labelCaption(color: AppColors.outline),
              ),
              const SizedBox(height: 8),

              // 2. Danh sách dị ứng phổ biến (Wrap chips)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonAllergens.map((item) {
                  final name = item['name']!;
                  final emoji = item['emoji']!;
                  final isSelected = model.selectedAllergies.contains(name);

                  return GestureDetector(
                    onTap: () => model.toggleAllergy(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: AppTypography.bodySmall(
                              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            ).copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check, size: 14, color: AppColors.onPrimary),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // 3. Hiển thị các dị ứng tự thêm nếu có
              if (model.customAllergies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: model.customAllergies.map((customName) {
                    final isSelected = model.selectedAllergies.contains(customName);
                    return Container(
                      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => model.toggleAllergy(customName),
                            child: Text(
                              '⚠️ $customName',
                              style: AppTypography.bodySmall(
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                              ).copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => model.removeCustomAllergy(customName),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isSelected ? AppColors.onPrimary : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // 4. Ô tìm kiếm & thêm dị ứng khác
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _customAllergyController,
                        style: AppTypography.bodyMedium(color: AppColors.onSurface),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Nhập hoặc tìm dị ứng khác (VD: Mè, Thịt bò...)',
                          hintStyle: AppTypography.bodySmall(color: AppColors.outline),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleAddCustomAllergy(),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleAddCustomAllergy,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        '+ Thêm',
                        style: AppTypography.bodyMedium(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
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