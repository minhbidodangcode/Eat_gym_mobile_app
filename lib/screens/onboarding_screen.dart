import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user_onboarding_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_header_step.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_toggle.dart';

/// Màn hình Onboarding 4 Bước chuẩn Figma:
/// - Bước 1: Sinh trắc & Mục tiêu (Biometrics & Mifflin-St Jeor Macro)
/// - Bước 2: Bệnh lý & Khẩu vị (Medical History, Allergies, Favorite Foods, Vegan)
/// - Bước 3: Thói quen & Kết nối (Grocery Habits, Cooking Frequency, Meal Prep)
/// - Bước 4: Thiết lập FoodBlog (Kitchen Name, Handle, Bio, Specialties, Pantry Sync)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _guideController = PageController();
  final _model = UserOnboardingModel();

  int _guidePage = 0;
  bool _showForm = false;
  int _currentStep = 1; // 1, 2, 3, 4
  bool _saving = false;

  // Controllers cho Bước 4 (FoodBlog)
  late final TextEditingController _creatorNameController;
  late final TextEditingController _creatorHandleController;
  late final TextEditingController _creatorBioController;

  static const _guides = [
    _Guide(
      Icons.document_scanner_outlined,
      'Quét thực phẩm thông minh',
      'Chụp nguyên liệu để AI nhận diện và ước tính dinh dưỡng nhanh chóng.',
      Color(0xFF286BFF),
    ),
    _Guide(
      Icons.restaurant_menu_outlined,
      'Ăn đúng theo mục tiêu',
      'Nhận gợi ý món ăn, calories và macro được cá nhân hoá cho bạn.',
      Color(0xFF00A878),
    ),
    _Guide(
      Icons.local_fire_department_outlined,
      'Duy trì thói quen mỗi ngày',
      'Theo dõi nhật ký, chuỗi ngày nấu ăn và huy hiệu thành tích.',
      Color(0xFFFF7A45),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _creatorNameController = TextEditingController(text: _model.creatorName);
    _creatorHandleController = TextEditingController(text: _model.creatorHandle);
    _creatorBioController = TextEditingController(text: _model.creatorBio);

    _loadExistingUser();
  }

  Future<void> _loadExistingUser() async {
    final payload = await ApiService.getJwtPayload();
    if (payload != null && mounted) {
      final name = payload['fullName'] ?? payload['email'] ?? '';
      if (name.isNotEmpty && _creatorNameController.text.isEmpty) {
        setState(() {
          _creatorNameController.text = 'Bếp của $name';
          final cleanHandle = name.toString().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
          _creatorHandleController.text = cleanHandle;
          _model.setCreatorName(_creatorNameController.text);
          _model.setCreatorHandle(_creatorHandleController.text);
        });
      }
    }
  }

  @override
  void dispose() {
    _guideController.dispose();
    _creatorNameController.dispose();
    _creatorHandleController.dispose();
    _creatorBioController.dispose();
    _model.dispose();
    super.dispose();
  }

  String get _activity => switch (_model.activityLevel) {
    ActivityLevel.low => 'light',
    ActivityLevel.medium => 'moderate',
    ActivityLevel.high => 'active',
  };

  String get _goal => switch (_model.goal) {
    NutritionGoal.muscleGain => 'bulking',
    NutritionGoal.fatLoss => 'cutting',
    NutritionGoal.maintenance => 'maintenance',
  };

  String? _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_model.age < 13 || _model.age > 120) {
        return 'Độ tuổi hợp lệ phải từ 13 đến 120 tuổi. Vui lòng kiểm tra lại ngày sinh.';
      }
      if (_model.heightCm < 50 || _model.heightCm > 250) {
        return 'Vui lòng nhập chiều cao hợp lệ (50cm - 250cm).';
      }
      if (_model.weightKg < 20 || _model.weightKg > 300) {
        return 'Vui lòng nhập cân nặng hợp lệ (20kg - 300kg).';
      }
      if (_model.targetWeightKg < 20 || _model.targetWeightKg > 300) {
        return 'Vui lòng nhập cân nặng mục tiêu hợp lệ (20kg - 300kg).';
      }
      if (_model.calories < 1000 || _model.calories > 5000) {
        return 'Mục tiêu calo phải từ 1,000 đến 5,000 kcal/ngày.';
      }
    }
    return null;
  }

  void _nextStep() {
    final err = _validateCurrentStep();
    if (err != null) {
      _showErrorSnackBar(err);
      return;
    }
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      setState(() => _showForm = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _finish() async {
    final validationError = _validateCurrentStep();
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    setState(() => _saving = true);
    try {
      final birth = _model.dateOfBirth;
      final birthday =
          '${birth.year.toString().padLeft(4, '0')}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';

      final creatorName = _creatorNameController.text.trim().isNotEmpty
          ? _creatorNameController.text.trim()
          : 'Bếp Gymer';
      final rawHandle = _creatorHandleController.text.trim();
      final creatorHandle = rawHandle.isNotEmpty
          ? (rawHandle.startsWith('@') ? rawHandle : '@$rawHandle')
          : '@gymer_${math.Random().nextInt(9999)}';
      final creatorBio = _creatorBioController.text.trim().isNotEmpty
          ? _creatorBioController.text.trim()
          : 'Ăn sạch - Tập chuẩn - Tối ưu macro mỗi ngày 💪';

      // 1. Lưu hồ sơ đầy đủ vào SharedPreferences cục bộ
      final profilePayload = <String, dynamic>{
        'sex': _model.gender == Gender.male ? 'male' : 'female',
        'dateOfBirth': birthday,
        'heightCm': _model.heightCm,
        'weightKg': _model.weightKg,
        'targetWeightKg': _model.targetWeightKg,
        'activityLevel': _activity,
        'fitnessGoal': _goal,
        'allergies': _model.effectiveAllergies.toList(),
        'dietaryPreferences': _model.selectedPreferences.toList(),
        'medicalHistory': _model.effectiveMedicalHistory.toList(),
        'favoriteFoods': _model.selectedFavoriteFoods.toList(),
        'isVegan': _model.isVegan,
        'dietLifestyle': _model.selectedDietLifestyle.toList(),
        'cookingFrequency': '${_model.homeCookedMealsCount} bữa/tuần',
        'groceryFrequency': _model.groceryFrequency,
        'onlineShoppingWhenNeeded': _model.onlineShoppingWhenNeeded,
        'linkedShoppingApps': _model.selectedShoppingApps.toList(),
        'mealPrepEnabled': _model.mealPrepAutomation,
        'creatorName': creatorName,
        'creatorHandle': creatorHandle,
        'creatorBio': creatorBio,
        'cookingSpecialties': _model.selectedSpecialties.toList(),
        'kitchenSyncEnabled': _model.kitchenSyncEnabled,
        'avatarUrl': _model.avatarUrl,
        'onboardingCompleted': true,
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

      // 2. Đồng bộ lên Server Backend Postgres
      bool syncSuccess = true;
      String? syncErrorMsg;
      try {
        await ApiService.saveProfile(
          sex: _model.gender == Gender.male ? 'male' : 'female',
          dateOfBirth: birthday,
          heightCm: _model.heightCm,
          weightKg: _model.weightKg,
          targetWeightKg: _model.targetWeightKg,
          activityLevel: _activity,
          fitnessGoal: _goal,
          allergies: _model.effectiveAllergies.toList(),
          dietaryPreferences: _model.selectedPreferences.toList(),
          medicalHistory: _model.effectiveMedicalHistory.toList(),
          favoriteFoods: _model.selectedFavoriteFoods.toList(),
          isVegan: _model.isVegan,
          dietLifestyle: _model.selectedDietLifestyle.toList(),
          cookingFrequency: '${_model.homeCookedMealsCount} bữa/tuần',
          groceryFrequency: _model.groceryFrequency,
          onlineShoppingWhenNeeded: _model.onlineShoppingWhenNeeded,
          linkedShoppingApps: _model.selectedShoppingApps.toList(),
          mealPrepEnabled: _model.mealPrepAutomation,
          creatorName: creatorName,
          creatorHandle: creatorHandle,
          creatorBio: creatorBio,
          cookingSpecialties: _model.selectedSpecialties.toList(),
          kitchenSyncEnabled: _model.kitchenSyncEnabled,
          avatarUrl: _model.avatarUrl,
          onboardingCompleted: true,
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
                Expanded(
                  child: Text('Đã lưu hồ sơ vào máy (Chờ server đồng bộ: $syncErrorMsg)'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        final cleanMsg = error.toString().replaceFirst('Exception: ', '');
        _showErrorSnackBar('Lỗi: $cleanMsg');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showForm ? _buildOnboardingWizard() : _buildIntroGuides();
  }

  // -------------------------------------------------------------
  // GUIDE SLIDES
  // -------------------------------------------------------------
  Widget _buildIntroGuides() {
    final last = _guidePage == _guides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: Text(
                    'Bỏ qua hướng dẫn',
                    style: AppTypography.labelLarge(color: AppColors.textMuted),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _guideController,
                  itemCount: _guides.length,
                  onPageChanged: (value) => setState(() => _guidePage = value),
                  itemBuilder: (_, index) => _GuidePage(guide: _guides[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _guides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: index == _guidePage ? 24 : 6,
                    decoration: BoxDecoration(
                      color: index == _guidePage ? AppColors.primary : AppColors.surfaceContainerAlt,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: last ? 'Thiết lập hồ sơ cá nhân (4 Bước)' : 'Tiếp tục',
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
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4-STEP ONBOARDING WIZARD
  // -------------------------------------------------------------
  Widget _buildOnboardingWizard() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _model,
          builder: (context, _) => Column(
            children: [
              // Header tiến trình 1/4 -> 2/4 -> 3/4 -> 4/4
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CustomHeaderStep(
                  currentStep: _currentStep,
                  totalSteps: 4,
                  onBack: _previousStep,
                ),
              ),

              // Nội dung từng bước
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: switch (_currentStep) {
                        1 => _buildStep1Biometrics(),
                        2 => _buildStep2HealthAndTaste(),
                        3 => _buildStep3HabitsAndKitchen(),
                        4 => _buildStep4FoodBlogSetup(),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ),
              ),

              // Bottom Navigation Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.outline),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _currentStep < 4
                    ? PrimaryButton(
                        text: 'Tiếp tục',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _nextStep,
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Hoàn tất & Khám phá EatGym',
                                      style: AppTypography.titleSmallBold(
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.rocket_launch_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // BƯỚC 1: SINH TRẮC & MỤC TIÊU (Figma Frame 25:2805)
  // =============================================================
  Widget _buildStep1Biometrics() {
    final bmi = _model.bmi;
    String bmiCategory;
    Color bmiColor;
    if (bmi < 18.5) {
      bmiCategory = 'Thiếu cân';
      bmiColor = Colors.orange;
    } else if (bmi < 24.9) {
      bmiCategory = 'Cân đối (Lý tưởng)';
      bmiColor = const Color(0xFF10B981);
    } else if (bmi < 29.9) {
      bmiCategory = 'Thừa cân nhẹ';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = 'Béo phì';
      bmiColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cá nhân hoá kế hoạch',
          style: AppTypography.headlineMedium(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          'Dữ liệu sinh trắc giúp EatGym tính toán Calo & Macro chính xác nhất cho thể trạng của bạn.',
          style: AppTypography.bodyDefault(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),

        // 1. Giới tính & Ngày sinh
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GIỚI TÍNH SINH HỌC & NGÀY SINH', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              SegmentedToggle<Gender>(
                items: const [
                  ToggleItem(value: Gender.male, label: 'Nam', icon: Icons.male_rounded),
                  ToggleItem(value: Gender.female, label: 'Nữ', icon: Icons.female_rounded),
                ],
                selectedValue: _model.gender,
                onChanged: _model.setGender,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _model.dateOfBirth,
                    firstDate: DateTime(now.year - 120, 1, 1),
                    lastDate: DateTime(now.year - 13, now.month, now.day),
                    helpText: 'CHỌN NGÀY SINH',
                  );
                  if (picked != null) _model.setDateOfBirth(picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cake_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            '${_model.dateOfBirth.day.toString().padLeft(2, '0')}/${_model.dateOfBirth.month.toString().padLeft(2, '0')}/${_model.dateOfBirth.year}',
                            style: AppTypography.bodyLarge(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${_model.age} tuổi', style: AppTypography.labelBold(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Chiều cao & Cân nặng & Cân nặng mục tiêu
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CHỈ SỐ THỂ CHẤT & BMI', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${bmi.toStringAsFixed(1)} BMI • $bmiCategory',
                      style: AppTypography.labelBold(color: bmiColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricSlider(
                label: 'Chiều cao hiện tại',
                value: _model.heightCm,
                unit: 'cm',
                min: 120,
                max: 220,
                onChanged: _model.setHeight,
              ),
              const Divider(height: 24, color: AppColors.outline),
              _buildMetricSlider(
                label: 'Cân nặng hiện tại',
                value: _model.weightKg,
                unit: 'kg',
                min: 35,
                max: 160,
                onChanged: _model.setWeight,
              ),
              const Divider(height: 24, color: AppColors.outline),
              _buildMetricSlider(
                label: 'Cân nặng mục tiêu',
                value: _model.targetWeightKg,
                unit: 'kg',
                min: 35,
                max: 160,
                onChanged: _model.setTargetWeight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Mục tiêu thể hình
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MỤC TIÊU THỂ HÌNH', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Column(
                children: NutritionGoal.values.map((goal) {
                  final isSelected = _model.goal == goal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _model.setGoal(goal),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal.title,
                                style: AppTypography.titleSmallBold(
                                  color: isSelected ? Colors.white : AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                goal.badgeText,
                                style: AppTypography.labelBold(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
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
          ),
        ),
        const SizedBox(height: 16),

        // 4. Mức độ vận động
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TẦN SUẤT TẬP LUYỆN / HOẠT ĐỘNG', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              SegmentedToggle<ActivityLevel>(
                items: ActivityLevel.values
                    .map((a) => ToggleItem(value: a, label: a.label))
                    .toList(),
                selectedValue: _model.activityLevel,
                onChanged: _model.setActivityLevel,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _model.activityLevel.description,
                  style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Card Tính toán Calo & Macro theo Mifflin-St Jeor & ACSM
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
            boxShadow: AppColors.buttonGlow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CALO & MACRO KHUYẾN NGHỊ', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  Text('${_model.calories} kcal/ngày', style: AppTypography.titleSmallBold(color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _macroItem('Đạm (Protein)', '${_model.macros.proteinGrams}g', '${_model.macros.proteinPercent}%', const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _macroItem('Tinh bột (Carbs)', '${_model.macros.carbsGrams}g', '${_model.macros.carbsPercent}%', const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _macroItem('Chất béo (Fat)', '${_model.macros.fatGrams}g', '${_model.macros.fatPercent}%', const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chỉ số được tính toán dựa trên chuẩn công thức Mifflin-St Jeor và Viện Thể thao Hoa Kỳ (ACSM). BMR: ${_model.bmr.round()} kcal | TDEE: ${_model.tdee} kcal.',
                      style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =============================================================
  // BƯỚC 2: BỆNH LÝ & KHẨU VỊ (Figma Frame 25:2992)
  // =============================================================
  Widget _buildStep2HealthAndTaste() {
    const medicalOptions = [
      'Không có tiền sử bệnh',
      'Gout',
      'Tiểu đường',
      'Huyết áp cao',
      'Tim mạch',
      'Mỡ máu cao',
      'Đau dạ dày / Tiêu hóa',
      'Thận mạn tính',
      'Gan nhiễm mỡ / Viêm gan',
      'Cường giáp / Suy giáp',
      'Hội chứng ruột kích thích (IBS)',
      'Sỏi thận / Sỏi mật',
      'Loãng xương',
      'Thiếu máu',
      'Viêm khớp / Thoái hóa khớp',
      'Rối loạn tiền đình',
    ];

    const allergyOptions = [
      'Không có',
      'Hải sản (Tôm, Cua, Mực)',
      'Đậu phộng / Lạc',
      'Sữa & Lactose',
      'Trứng gà',
      'Gluten / Bột mì',
      'Đậu nành',
      'Các loại hạt cây (Óc chó, Hạnh nhân)',
      'Cá & Dầu cá',
      'Động vật có vỏ (Nghêu, Sò, Ốc)',
      'Mè / Vừng',
      'Nấm các loại',
      'Thịt đỏ (Bò, Heo)',
      'Chất bảo quản / Bột ngọt',
    ];

    const favoriteOptions = [
      '🍗 Ức gà phi lê',
      '🥩 Thịt bò nạc',
      '🐟 Cá hồi',
      '🐟 Cá ngừ / Cá thu',
      '🥩 Thịt nạc thăn heo',
      '🥚 Trứng gà',
      '🍤 Tôm tươi',
      '🥛 Sữa chua Hy Lạp / Phô mai',
      '🧈 Đậu hũ / Tofu',
      '🍄 Nấm đùi gà / Nấm hương',
      '🫘 Đậu gà / Đậu lăng',
      '🌱 Tempeh / Seitan',
      '🥦 Bông cải xanh / Cải bó xôi',
      '🥛 Sữa hạt (Hạnh nhân, Đậu nành)',
      '🥣 Yến mạch',
      '🥑 Bơ & Các loại hạt',
      '🍚 Gạo lứt & Khoai',
      '🍌 Chuối / Táo / Việt quất',
    ];

    final visibleFavoriteOptions = _model.isVegan
        ? favoriteOptions.where((opt) {
            final cleanLabel = opt.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
            return !UserOnboardingModel.isAnimalFood(cleanLabel);
          }).toList()
        : favoriteOptions;

    const lifestyleOptions = [
      'Eat Clean',
      'Low Carb / Keto',
      'High Protein',
      'Nhịn ăn gián đoạn (IF)',
      'Ăn kiêng linh hoạt (IIFYM)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bệnh lý & Khẩu vị', style: AppTypography.headlineMedium(color: AppColors.onSurface)),
        const SizedBox(height: 6),
        Text(
          'Thiết lập các ràng buộc y tế và khẩu vị yêu thích để EatGym tự động bảo vệ & tối ưu thực đơn an toàn 100%.',
          style: AppTypography.bodyDefault(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),

        // 01 / TIỀN SỬ BỆNH LÝ
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('01 / TIỀN SỬ BỆNH LÝ', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  _countBadge('${_model.selectedMedicalHistory.length} được chọn'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: medicalOptions.map((opt) {
                  final isSelected = _model.selectedMedicalHistory.contains(opt);
                  return _choiceChip(
                    label: opt,
                    isSelected: isSelected,
                    onTap: () => _model.toggleMedicalHistory(opt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hệ thống tự động tinh chỉnh Calo, Đường huyết, Sodium và Purin theo chỉ định bệnh lý.',
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 02 / RÀNG BUỘC DỊ ỨNG THỰC PHẨM
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('02 / RÀNG BUỘC DỊ ỨNG THỰC PHẨM', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  _countBadge('${_model.selectedAllergies.length} được chọn'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergyOptions.map((opt) {
                  final isSelected = _model.selectedAllergies.contains(opt);
                  return _choiceChip(
                    label: opt,
                    isSelected: isSelected,
                    onTap: () => _model.toggleAllergy(opt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 03 / THỰC PHẨM YÊU THÍCH
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('03 / THỰC PHẨM YÊU THÍCH', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  _countBadge('${_model.selectedFavoriteFoods.length} được chọn'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Lựa chọn nguồn đạm & thực phẩm khoái khẩu để ưu tiên trong khẩu phần:',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (_model.isVegan) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_outlined, size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang bật chế độ Ăn thuần chay: các thực phẩm nguồn gốc động vật đã được tự động ẩn.',
                          style: AppTypography.bodySmall(color: const Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleFavoriteOptions.map((opt) {
                  final cleanLabel = opt.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
                  final isSelected = _model.selectedFavoriteFoods.any((f) => f.contains(cleanLabel));
                  return _choiceChip(
                    label: opt,
                    isSelected: isSelected,
                    onTap: () => _model.toggleFavoriteFood(cleanLabel),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'EatGym sẽ ưu tiên phân bổ các nguyên liệu này vào các bữa chính hàng tuần.',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 04 / LỐI SỐNG ẨM THỰC & MỤC TIÊU
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('04 / LỐI SỐNG ẨM THỰC & MỤC TIÊU', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  _countBadge('${_model.selectedDietLifestyle.length + (_model.isVegan ? 1 : 0)} được chọn'),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _model.isVegan,
                onChanged: _model.setVegan,
                activeTrackColor: AppColors.primary,
                title: Text('Ăn thuần chay (Vegan / Plant-based)', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
                subtitle: Text('Loại trừ hoàn toàn thịt động vật và chế phẩm từ sữa.', style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
              ),
              const Divider(height: 20, color: AppColors.outline),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lifestyleOptions.map((opt) {
                  final isSelected = _model.selectedDietLifestyle.contains(opt);
                  return _choiceChip(
                    label: opt,
                    isSelected: isSelected,
                    onTap: () => _model.toggleDietLifestyle(opt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Safety feedback banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dữ liệu y tế và sở thích sẽ cấu hình thuật toán gợi ý món ăn loại trừ tuyệt đối thành phần kích ứng & cá nhân hoá thực đơn an toàn 100%.',
                  style: AppTypography.bodySmall(color: const Color(0xFF15803D)).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =============================================================
  // BƯỚC 3: THÓI QUEN & KẾT NỐI (Figma Frame 25:3300)
  // =============================================================
  Widget _buildStep3HabitsAndKitchen() {
    const groceryFrequencies = [
      'Hàng ngày',
      '2-3 lần / tuần',
      '1 lần / tuần (Cuối tuần)',
    ];

    const shoppingAppOptions = [
      'WinMart / WinMart+',
      'ShopeeFood / Shopee Mart',
      'GrabMart',
      'Bách Hóa Xanh',
      'Co.op Online',
      'Lotte Mart',
      'Go! / Big C',
      'TikiNGON',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thói quen nấu nướng &\nKết nối',
          style: AppTypography.headlineMedium(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          'Tự động hóa chu trình đi chợ, quản lý tủ lạnh và chuẩn bị món ăn (Meal Prep) cho cả tuần.',
          style: AppTypography.bodyDefault(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),

        // 1. Thói quen đi chợ & Liên kết mua sắm online
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THÓI QUEN ĐI CHỢ & MUA SẮM', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Text('Tần suất đi chợ:', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groceryFrequencies.map((f) {
                  final isSelected = _model.groceryFrequency == f;
                  return _choiceChip(
                    label: f,
                    isSelected: isSelected,
                    onTap: () => _model.setGroceryFrequency(f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _model.onlineShoppingWhenNeeded,
                onChanged: _model.setOnlineShoppingWhenNeeded,
                activeTrackColor: AppColors.primary,
                title: Text('Đặt giao online khi cần', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
                subtitle: Text('Có thể chọn song song với lịch đi chợ truyền thống để bổ sung nguyên liệu kịp thời.', style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
              ),
              const Divider(height: 20, color: AppColors.outline),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Liên kết ứng dụng mua sắm thực phẩm:', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
                  ),
                  _countBadge('${_model.selectedShoppingApps.length} đã chọn'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Khi thiếu nguyên liệu trong thực đơn, EatGym sẽ gợi ý mua online và điền sẵn tên nguyên liệu vào thanh tìm kiếm của app bạn chọn.',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shoppingAppOptions.map((app) {
                  final isSelected = _model.selectedShoppingApps.contains(app);
                  return _choiceChip(
                    label: app,
                    isSelected: isSelected,
                    onTap: () => _model.toggleShoppingApp(app),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Thói quen nấu ăn & Meal Prep
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THÓI QUEN NẤU ĂN & MEAL PREP', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số bữa tự nấu trong tuần', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        'Khoảng ${(_model.homeCookedMealsCount / 7.0).toStringAsFixed(1)} bữa / ngày',
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () => _model.setHomeCookedMealsCount(_model.homeCookedMealsCount - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${_model.homeCookedMealsCount}',
                            style: AppTypography.titleSmallBold(color: AppColors.primary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => _model.setHomeCookedMealsCount(_model.homeCookedMealsCount + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.outline),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _model.mealPrepAutomation,
                onChanged: _model.setMealPrepAutomation,
                activeTrackColor: AppColors.primary,
                title: Text('Tự động hóa Meal Prep (Nấu 1 lần ăn nhiều bữa)', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
                subtitle: Text('Tự tính khẩu phần nhân bội số và bù trừ hao hụt khối lượng sống/chín.', style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Micro-delight Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.timer_outlined, size: 22, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tiết kiệm trung bình 4.5 giờ/tuần và đảm bảo 100% Macro mục tiêu khi nấu ăn Meal Prep theo kế hoạch khoa học.',
                  style: AppTypography.bodySmall(color: const Color(0xFFB45309)).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =============================================================
  // BƯỚC 4: THIẾT LẬP FOODBLOG (Figma Frame 25:3442)
  // =============================================================
  Widget _buildStep4FoodBlogSetup() {
    const specialtiesList = [
      'EatClean',
      'HighProtein',
      'MealPrep nhanh',
      'Ăn kiêng Low-Carb',
      'Bữa sáng 10 phút',
      'Món chay Gymer',
      'Sinh tố & Shake',
      'Ăn vặt Healthy',
    ];

    final avatarPresets = [
      {'id': 'gymer_1', 'label': 'Gymer Pro', 'icon': Icons.fitness_center_rounded},
      {'id': 'gymer_2', 'label': 'Clean Chef', 'icon': Icons.restaurant_rounded},
      {'id': 'gymer_3', 'label': 'Fitness Star', 'icon': Icons.sports_gymnastics_rounded},
      {'id': 'gymer_4', 'label': 'Veggie Fit', 'icon': Icons.eco_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thiết lập FoodBlog', style: AppTypography.headlineMedium(color: AppColors.onSurface)),
        const SizedBox(height: 6),
        Text(
          'Tạo thương hiệu bếp cá nhân của bạn để chia sẻ công thức, khoe mâm cơm gymer và kết nối cộng đồng.',
          style: AppTypography.bodyDefault(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),

        // 1. Avatar Studio Card
        _cardWrapper(
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primary,
                      child: CircleAvatar(
                        radius: 43,
                        backgroundColor: AppColors.backgroundLight,
                        child: Icon(
                          avatarPresets.firstWhere(
                            (a) => a['id'] == _model.avatarUrl,
                            orElse: () => avatarPresets.first,
                          )['icon'] as IconData,
                          size: 46,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Chọn phong cách đại diện bếp:', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: avatarPresets.map((preset) {
                  final isSelected = _model.avatarUrl == preset['id'];
                  return InkWell(
                    onTap: () => _model.setAvatarUrl(preset['id'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outline,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            preset['icon'] as IconData,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset['label'] as String,
                            style: AppTypography.labelBold(
                              color: isSelected ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Form thông tin bếp
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THÔNG TIN BẾP CÁ NHÂN', style: AppTypography.labelBold(color: AppColors.textMuted)),
              const SizedBox(height: 14),
              TextField(
                controller: _creatorNameController,
                decoration: InputDecoration(
                  labelText: 'Tên Bếp / Creator Name',
                  hintText: 'VD: Bếp Gymer Khỏe Mạnh',
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _creatorHandleController,
                decoration: InputDecoration(
                  labelText: 'Handle (@)',
                  hintText: 'VD: gymer_fit',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _creatorBioController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Tiểu sử ngắn (Bio)',
                  hintText: 'VD: Ăn sạch - Tập chuẩn - Tối ưu macro mỗi ngày 💪',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Specialties / Thế mạnh ẩm thực
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('THẾ MẠNH ẨM THỰC', style: AppTypography.labelBold(color: AppColors.textMuted)),
                  _countBadge('${_model.selectedSpecialties.length} được chọn'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specialtiesList.map((s) {
                  final isSelected = _model.selectedSpecialties.contains(s);
                  return _choiceChip(
                    label: s,
                    isSelected: isSelected,
                    onTap: () => _model.toggleSpecialty(s),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Kitchen & Pantry Sync Card
        _cardWrapper(
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _model.kitchenSyncEnabled,
            onChanged: _model.setKitchenSyncEnabled,
            activeTrackColor: AppColors.primary,
            title: Text('Đồng bộ bếp & Kho tủ lạnh (Pantry Sync)', style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
            subtitle: Text('Tự động trừ nguyên liệu tồn kho thực tế khi hoàn thành chế biến món ăn.', style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =============================================================
  // REUSABLE UI HELPERS
  // =============================================================
  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.buttonGlow,
      ),
      child: child,
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: AppTypography.labelBold(color: AppColors.primary)),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
          boxShadow: isSelected ? AppColors.activeChipGlow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodySmall(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSlider({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant)),
            Text(
              '${value.round()} $unit',
              style: AppTypography.titleSmallBold(color: AppColors.primary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceContainerAlt,
            thumbColor: AppColors.primary,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: (val) => onChanged(val.roundToDouble()),
          ),
        ),
      ],
    );
  }

  Widget _macroItem(String title, String grams, String percent, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 6),
            Text(title, style: AppTypography.labelBold(color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(grams, style: AppTypography.titleSmallBold(color: AppColors.onSurface)),
            Text(percent, style: AppTypography.labelBold(color: color)),
          ],
        ),
      ),
    );
  }
}

class _Guide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Guide(this.icon, this.title, this.description, this.color);
}

class _GuidePage extends StatelessWidget {
  final _Guide guide;

  const _GuidePage({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: guide.color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(guide.icon, size: 68, color: guide.color),
        ),
        const SizedBox(height: 40),
        Text(
          guide.title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium(color: AppColors.onSurface),
        ),
        const SizedBox(height: 14),
        Text(
          guide.description,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge(color: AppColors.onSurfaceVariant).copyWith(height: 1.5),
        ),
      ],
    );
  }
}
