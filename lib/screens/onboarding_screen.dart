import 'package:flutter/material.dart';
import '../models/user_onboarding_model.dart';
import '../theme/app_theme.dart';
import '../widgets/allergy_preference_card.dart';
import '../widgets/custom_header_step.dart';
import '../widgets/nutrition_goal_card.dart';
import '../widgets/physical_info_card.dart';
import '../widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final UserOnboardingModel _model;

  @override
  void initState() {
    super.initState();
    _model = UserOnboardingModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _onContinue() {
    final m = _model;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Đã lưu thông tin hồ sơ',
                  style: AppTypography.headline(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '• Giới tính: ${m.gender == Gender.male ? "Nam" : "Nữ"}\n'
              '• Tuổi: ${m.age} | Cao: ${m.heightCm.toInt()}cm | Nặng: ${m.weightKg}kg\n'
              '• Tần suất: ${m.activityLevel.label} (${m.activityLevel.description})\n'
              '• Mục tiêu: ${m.goal.title} (${m.calories} kcal/ngày)\n'
              '• Macro: Protein ${m.macros.proteinGrams}g, Carbs ${m.macros.carbsGrams}g, Fat ${m.macros.fatGrams}g\n'
              '• Dị ứng: ${m.selectedAllergies.isEmpty ? "Không có" : m.selectedAllergies.join(", ")}\n'
              '• Ưu tiên: ${m.selectedPreferences.isEmpty ? "Không có" : m.selectedPreferences.join(", ")}',
              style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tiếp tục sang Bước 2 (Quét AI)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _model,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Progress & Title
                  CustomHeaderStep(
                    currentStep: 1,
                    totalSteps: 3,
                    onBack: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quay lại màn hình trước'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Section 01: Thông tin thể chất
                  PhysicalInfoCard(model: _model),

                  const SizedBox(height: 20),

                  // Section 02: Mục tiêu dinh dưỡng & Bộ tính Macro tự động
                  NutritionGoalCard(model: _model),

                  const SizedBox(height: 20),

                  // Section 03: Dị ứng thực phẩm & Chế độ ăn ưu tiên
                  AllergyPreferenceCard(model: _model),

                  const SizedBox(height: 28),

                  // Submit Action Button
                  PrimaryButton(
                    text: 'Tiếp tục',
                    onPressed: _onContinue,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
