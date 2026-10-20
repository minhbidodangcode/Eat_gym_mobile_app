import 'package:flutter/material.dart';
import '../models/user_onboarding_model.dart';
import '../theme/app_theme.dart';
import 'segmented_toggle.dart'; // File widget mới bạn sẽ tạo ở Bước 2

class PhysicalInfoCard extends StatelessWidget {
  final UserOnboardingModel model;

  const PhysicalInfoCard({
    super.key,
    required this.model,
  });

  void _showNumberEditDialog(
      BuildContext context, {
        required String title,
        required String unit,
        required num initialValue,
        required ValueChanged<double> onSubmitted,
      }) {
    final controller = TextEditingController(text: initialValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text(
          'Chỉnh sửa $title',
          style: AppTypography.titleMedium(color: AppColors.onSurface),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTypography.headline(color: AppColors.onSurface),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                onSubmitted(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: model.dateOfBirth,
      firstDate: DateTime(DateTime.now().year - 120),
      lastDate: DateTime(DateTime.now().year - 13),
      helpText: 'CHỌN NGÀY SINH',
    );
    if (selected != null) model.setDateOfBirth(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2, right: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '01 / THÔNG TIN THỂ CHẤT',
                style: AppTypography.badge(color: AppColors.outline),
              ),
              Text(
                'Độ chính xác: 98%',
                style: AppTypography.labelCaption(color: AppColors.onSurface),
              ),
            ],
          ),
        ),
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
              Text(
                'GIỚI TÍNH SINH HỌC',
                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),

              // SỬA: Thay thế bằng Widget SegmentedToggle cho Giới tính
              SegmentedToggle<Gender>(
                items: const [
                  ToggleItem(value: Gender.male, label: 'Nam', icon: Icons.male),
                  ToggleItem(value: Gender.female, label: 'Nữ', icon: Icons.female),
                ],
                selectedValue: model.gender,
                onChanged: (val) => model.setGender(val),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'NGÀY SINH',
                      value: '${model.dateOfBirth.day.toString().padLeft(2, '0')}/${model.dateOfBirth.month.toString().padLeft(2, '0')}',
                      unit: '${model.age} tuổi',
                      onTap: () => _pickDateOfBirth(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'CHIỀU CAO',
                      value: model.heightCm.toInt().toString(),
                      unit: 'cm',
                      onTap: () {
                        _showNumberEditDialog(
                          context,
                          title: 'Chiều cao',
                          unit: 'cm',
                          initialValue: model.heightCm,
                          onSubmitted: (v) => model.setHeight(v),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'CÂN NẶNG',
                      value: model.weightKg.toStringAsFixed(1),
                      unit: 'kg',
                      onTap: () {
                        _showNumberEditDialog(
                          context,
                          title: 'Cân nặng',
                          unit: 'kg',
                          initialValue: model.weightKg,
                          onSubmitted: (v) => model.setWeight(v),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TẦN SUẤT VẬN ĐỘNG',
                    style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                  ),
                  Text(
                    model.activityLevel.description,
                    style: AppTypography.badge(color: AppColors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // SỬA: Thay thế bằng Widget SegmentedToggle cho Vận động
              SegmentedToggle<ActivityLevel>(
                items: ActivityLevel.values.map((lvl) {
                  return ToggleItem(value: lvl, label: lvl.label);
                }).toList(),
                selectedValue: model.activityLevel,
                onChanged: (val) => model.setActivityLevel(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
      BuildContext context, {
        required String label,
        required String value,
        required String unit,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.labelCaption(color: AppColors.outline),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.metricValue(color: AppColors.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
