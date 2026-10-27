import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user_onboarding_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/allergy_preference_card.dart';
import '../widgets/custom_header_step.dart';
import '../widgets/nutrition_goal_card.dart';
import '../widgets/physical_info_card.dart';
import '../widgets/primary_button.dart';

/// Chỉ hiện cho tài khoản chưa có hồ sơ thể chất.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _guideController = PageController();
  final _model = UserOnboardingModel();
  int _page = 0;
  bool _showForm = false;
  bool _saving = false;

  static const _guides = [
    _Guide(Icons.document_scanner_outlined, 'Quét thực phẩm thông minh', 'Chụp nguyên liệu để AI nhận diện và ước tính dinh dưỡng nhanh chóng.', Color(0xFF286BFF)),
    _Guide(Icons.restaurant_menu_outlined, 'Ăn đúng theo mục tiêu', 'Nhận gợi ý món ăn, calories và macro được cá nhân hoá cho bạn.', Color(0xFF00A878)),
    _Guide(Icons.local_fire_department_outlined, 'Duy trì thói quen mỗi ngày', 'Theo dõi nhật ký, chuỗi ngày nấu ăn và huy hiệu thành tích.', Color(0xFFFF7A45)),
  ];

  @override
  void dispose() { _guideController.dispose(); _model.dispose(); super.dispose(); }

  String get _activity => switch (_model.activityLevel) {
    ActivityLevel.low => 'light', ActivityLevel.medium => 'moderate', ActivityLevel.high => 'active',
  };
  String get _goal => switch (_model.goal) {
    NutritionGoal.muscleGain => 'bulking', NutritionGoal.fatLoss => 'cutting', NutritionGoal.maintenance => 'maintenance',
  };

  String? _validateProfileForm() {
    if (_model.age < 13 || _model.age > 120) {
      return 'Độ tuổi hợp lệ phải từ 13 đến 120 tuổi. Vui lòng kiểm tra lại ngày sinh.';
    }
    if (_model.heightCm < 50 || _model.heightCm > 250) {
      return 'Vui lòng nhập chiều cao hợp lệ (từ 50cm đến 250cm).';
    }
    if (_model.weightKg < 20 || _model.weightKg > 300) {
      return 'Vui lòng nhập cân nặng hợp lệ (từ 20kg đến 300kg).';
    }
    if (_model.selectedAllergies.isEmpty) {
      return 'Vui lòng chọn thông tin dị ứng hoặc bấm "Không có".';
    }
    if (_model.calories < 1000 || _model.calories > 5000) {
      return 'Mục tiêu calo phải từ 1,000 đến 5,000 kcal/ngày.';
    }
    return null;
  }

  Future<void> _finish() async {
    final validationError = _validateProfileForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(validationError)),
            ],
          ),
          backgroundColor: Colors.redAccent[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final birth = _model.dateOfBirth;
      final birthday = '${birth.year.toString().padLeft(4, '0')}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';
      
      // 1. Lưu cục bộ trước để không bao giờ làm mất dữ liệu của người dùng
      final profilePayload = <String, dynamic>{
        'sex': _model.gender == Gender.male ? 'male' : 'female',
        'dateOfBirth': birthday,
        'heightCm': _model.heightCm,
        'weightKg': _model.weightKg,
        'activityLevel': _activity,
        'fitnessGoal': _goal,
        'allergies': _model.effectiveAllergies.toList(),
        'dietaryPreferences': _model.selectedPreferences.toList(),
        'targetMacros': {
          'calories': _model.calories,
          'protein': _model.macros.proteinGrams,
          'carbs': _model.macros.carbsGrams,
          'fat': _model.macros.fatGrams,
        },
      };
      await ApiService.saveLocalProfile(profilePayload);
      await ApiService.saveOnboardingPreferences(
        allergies: _model.effectiveAllergies,
        preferences: _model.selectedPreferences,
      );

      // 2. Đồng bộ lên Server Backend
      bool syncSuccess = true;
      String? syncErrorMsg;
      try {
        await ApiService.saveProfile(
          sex: _model.gender == Gender.male ? 'male' : 'female',
          dateOfBirth: birthday,
          heightCm: _model.heightCm,
          weightKg: _model.weightKg,
          activityLevel: _activity,
          fitnessGoal: _goal,
          allergies: _model.effectiveAllergies.toList(),
          dietaryPreferences: _model.selectedPreferences.toList(),
          targetMacros: {
            'calories': _model.calories,
            'protein': _model.macros.proteinGrams,
            'carbs': _model.macros.carbsGrams,
            'fat': _model.macros.fatGrams,
          },
        );
      } catch (error) {
        syncSuccess = false;
        syncErrorMsg = error.toString().replaceFirst('Exception: ', '');
      }

      if (!mounted) return;

      if (!syncSuccess && syncErrorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Đã lưu hồ sơ vào máy (Chờ server đồng bộ: $syncErrorMsg)')),
              ],
            ),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    } catch (error) {
      if (mounted) {
        final cleanMsg = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi: $cleanMsg')),
              ],
            ),
            backgroundColor: Colors.redAccent[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _showForm ? _profileForm() : _guideScreen();

  Widget _guideScreen() {
    final last = _page == _guides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => _showForm = true), child: const Text('Bỏ qua hướng dẫn'))),
          Expanded(child: PageView.builder(
            controller: _guideController, itemCount: _guides.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (_, index) => _GuidePage(guide: _guides[index]),
          )),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_guides.length, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8, width: index == _page ? 24 : 8,
            decoration: BoxDecoration(color: index == _page ? AppColors.primary : AppColors.outlineVariant, borderRadius: BorderRadius.circular(99)),
          ))),
          const SizedBox(height: 24),
          PrimaryButton(
            text: last ? 'Thiết lập hồ sơ của tôi' : 'Tiếp tục',
            onPressed: () {
              if (last) {
                setState(() => _showForm = true);
              } else {
                _guideController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ]),
      )),
    );
  }

  Widget _profileForm() => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _model,
        builder: (context, child) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CustomHeaderStep(currentStep: 1, totalSteps: 1, onBack: () => setState(() => _showForm = false)),
          const SizedBox(height: 12),
          Text('Cá nhân hoá kế hoạch của bạn', style: AppTypography.headline(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Thông tin này giúp EatGym tính mục tiêu dinh dưỡng phù hợp.', style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20), PhysicalInfoCard(model: _model), const SizedBox(height: 20),
          NutritionGoalCard(model: _model), const SizedBox(height: 20), AllergyPreferenceCard(model: _model), const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _saving ? null : _finish,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Hoàn tất và bắt đầu'),
          )), const SizedBox(height: 24),
        ]),
      ),
    )),
  );
}

class _Guide {
  final IconData icon; final String title; final String description; final Color color;
  const _Guide(this.icon, this.title, this.description, this.color);
}

class _GuidePage extends StatelessWidget {
  final _Guide guide;
  const _GuidePage({required this.guide});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 150, height: 150, decoration: BoxDecoration(color: guide.color.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(guide.icon, size: 76, color: guide.color)),
    const SizedBox(height: 44), Text(guide.title, textAlign: TextAlign.center, style: AppTypography.displayLarge(color: AppColors.onSurface)),
    const SizedBox(height: 16), Text(guide.description, textAlign: TextAlign.center, style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(height: 1.5)),
  ]);
}
