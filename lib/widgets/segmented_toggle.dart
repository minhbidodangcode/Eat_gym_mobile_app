import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToggleItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ToggleItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class SegmentedToggle<T> extends StatelessWidget {
  final List<ToggleItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  const SegmentedToggle({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int selectedIndex = items.indexWhere((item) => item.value == selectedValue);
          final double itemWidth = constraints.maxWidth / items.length;

          return Stack(
            children: [
              // 1. LỚP NỀN ĐEN TRƯỢT (Phải đặt ĐẦU TIÊN để nằm DƯỚI CÙNG)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppColors.activeChipGlow,
                  ),
                ),
              ),

              // 2. LỚP CHỨA NÚT BẤM VÀ CHỮ (Đặt SAU để đè lên trên nền đen)
              Row(
                children: items.map((item) {
                  final isSelected = selectedValue == item.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(item.value),
                      behavior: HitTestBehavior.opaque, // Đảm bảo bắt được sự kiện nhấp chuột
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 18,
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              item.label,
                              style: AppTypography.headline(
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}