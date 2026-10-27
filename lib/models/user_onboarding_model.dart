import 'dart:math' as math;
import 'package:flutter/foundation.dart';

enum Gender { male, female }

enum ActivityLevel {
  low('Ít', '1-2 buổi / tuần'),
  medium('Vừa', '3-5 buổi / tuần'),
  high('Nhiều', '6+ buổi / tuần');

  final String label;
  final String description;
  const ActivityLevel(this.label, this.description);
}

enum NutritionGoal {
  muscleGain('Tăng cơ', '+350 kcal Thặng dư'),
  fatLoss('Giảm mỡ', '-450 kcal Thâm hụt'),
  maintenance('Duy trì', 'Cân bằng TDEE');

  final String title;
  final String badgeText;
  const NutritionGoal(this.title, this.badgeText);
}

class MacroBreakdown {
  final int proteinGrams;
  final int proteinKcal;
  final int proteinPercent;

  final int carbsGrams;
  final int carbsKcal;
  final int carbsPercent;

  final int fatGrams;
  final int fatKcal;
  final int fatPercent;

  const MacroBreakdown({
    required this.proteinGrams,
    required this.proteinKcal,
    required this.proteinPercent,
    required this.carbsGrams,
    required this.carbsKcal,
    required this.carbsPercent,
    required this.fatGrams,
    required this.fatKcal,
    required this.fatPercent,
  });

  factory MacroBreakdown.fromCalories(int calories, NutritionGoal goal) {
    int proteinPct;
    int carbsPct;
    int fatPct;

    switch (goal) {
      case NutritionGoal.fatLoss:
        // Đạm cao bảo toàn khối cơ trong giai đoạn thâm hụt calo
        proteinPct = 35;
        carbsPct = 35;
        fatPct = 30;
        break;
      case NutritionGoal.muscleGain:
        // Tăng carbs cung cấp năng lượng tập nặng và tích lũy glycogen
        proteinPct = 30;
        carbsPct = 45;
        fatPct = 25;
        break;
      case NutritionGoal.maintenance:
        proteinPct = 25;
        carbsPct = 50;
        fatPct = 25;
        break;
    }

    final proteinKcal = (calories * (proteinPct / 100.0)).round();
    final carbsKcal = (calories * (carbsPct / 100.0)).round();
    final fatKcal = (calories * (fatPct / 100.0)).round();

    final proteinGrams = (proteinKcal / 4.0).round();
    final carbsGrams = (carbsKcal / 4.0).round();
    final fatGrams = (fatKcal / 9.0).round();

    return MacroBreakdown(
      proteinGrams: proteinGrams,
      proteinKcal: proteinKcal,
      proteinPercent: proteinPct,
      carbsGrams: carbsGrams,
      carbsKcal: carbsKcal,
      carbsPercent: carbsPct,
      fatGrams: fatGrams,
      fatKcal: fatKcal,
      fatPercent: fatPct,
    );
  }
}

class UserOnboardingModel extends ChangeNotifier {
  static const String noAllergy = 'Không có';

  Gender _gender = Gender.male;
  DateTime _dateOfBirth = DateTime(DateTime.now().year - 24, 1, 1);
  double _heightCm = 175.0;
  double _weightKg = 72.0;
  ActivityLevel _activityLevel = ActivityLevel.medium;

  NutritionGoal _goal = NutritionGoal.fatLoss;
  late int _calories;

  final Set<String> _selectedAllergies = {noAllergy};
  final List<String> _customAllergies = [];
  final Set<String> _selectedPreferences = {};

  UserOnboardingModel() {
    _calories = recommendedCalories;
  }

  // Getters
  Gender get gender => _gender;
  DateTime get dateOfBirth => _dateOfBirth;

  int get age {
    final today = DateTime.now();
    var result = today.year - _dateOfBirth.year;
    if (DateTime(today.year, _dateOfBirth.month, _dateOfBirth.day).isAfter(today)) {
      result--;
    }
    return result.clamp(13, 120);
  }

  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  ActivityLevel get activityLevel => _activityLevel;
  NutritionGoal get goal => _goal;
  int get calories => _calories;

  List<String> get customAllergies => List.unmodifiable(_customAllergies);
  Set<String> get selectedAllergies => Set.unmodifiable(_selectedAllergies);
  Set<String> get selectedPreferences => Set.unmodifiable(_selectedPreferences);

  bool get hasNoAllergy => _selectedAllergies.contains(noAllergy);

  /// Danh sách dị ứng thực phẩm thực tế (không gồm mục 'Không có')
  Set<String> get effectiveAllergies =>
      _selectedAllergies.where((a) => a != noAllergy).toSet();

  /// Tính BMR (Tỷ lệ trao đổi chất cơ bản) theo công thức Mifflin-St Jeor
  double get bmr {
    final s = (_gender == Gender.male) ? 5.0 : -161.0;
    return (10 * _weightKg) + (6.25 * _heightCm) - (5 * age) + s;
  }

  /// Hệ số hoạt động thể chất
  double get activityMultiplier => switch (_activityLevel) {
    ActivityLevel.low => 1.25,     // 1-2 buổi/tuần
    ActivityLevel.medium => 1.45,  // 3-5 buổi/tuần
    ActivityLevel.high => 1.70,    // 6+ buổi/tuần
  };

  /// TDEE: Tổng năng lượng tiêu thụ mỗi ngày dựa trên thể chất và mức độ tập luyện
  int get tdee => (bmr * activityMultiplier).round();

  /// Mức calo nạp vào khuyến nghị theo mục tiêu cá nhân
  int get recommendedCalories => switch (_goal) {
    NutritionGoal.fatLoss => math.max(1200, tdee - 450),       // Thâm hụt để đốt mỡ
    NutritionGoal.maintenance => math.max(1200, tdee),         // Cân bằng giữ cân
    NutritionGoal.muscleGain => math.max(1500, tdee + 350),    // Thặng dư để xây cơ
  };

  MacroBreakdown get macros => MacroBreakdown.fromCalories(_calories, _goal);

  // Setters & Mutators
  void setGender(Gender g) {
    if (_gender != g) {
      _gender = g;
      _recalculateCalories();
    }
  }

  void setAge(int val) {
    _dateOfBirth = DateTime(DateTime.now().year - val.clamp(13, 120).toInt(), 1, 1);
    _recalculateCalories();
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    _recalculateCalories();
  }

  void setHeight(double val) {
    _heightCm = val.clamp(100.0, 240.0);
    _recalculateCalories();
  }

  void setWeight(double val) {
    _weightKg = val.clamp(30.0, 250.0);
    _recalculateCalories();
  }

  void setActivityLevel(ActivityLevel level) {
    if (_activityLevel != level) {
      _activityLevel = level;
      _recalculateCalories();
    }
  }

  void setGoal(NutritionGoal g) {
    _goal = g;
    _recalculateCalories();
  }

  void setCalories(int cal) {
    _calories = cal.clamp(1000, 5000);
    notifyListeners();
  }

  void _recalculateCalories() {
    _calories = recommendedCalories;
    notifyListeners();
  }

  void toggleAllergy(String allergy) {
    if (allergy == noAllergy) {
      if (_selectedAllergies.contains(noAllergy)) {
        _selectedAllergies.remove(noAllergy);
      } else {
        _selectedAllergies.clear();
        _selectedAllergies.add(noAllergy);
      }
    } else {
      _selectedAllergies.remove(noAllergy);
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        _selectedAllergies.add(allergy);
      }
      if (_selectedAllergies.isEmpty) {
        _selectedAllergies.add(noAllergy);
      }
    }
    notifyListeners();
  }

  void addCustomAllergy(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!_customAllergies.any((a) => a.toLowerCase() == trimmed.toLowerCase())) {
      _customAllergies.add(trimmed);
    }
    _selectedAllergies.remove(noAllergy);
    _selectedAllergies.add(trimmed);
    notifyListeners();
  }

  void removeCustomAllergy(String name) {
    _customAllergies.remove(name);
    _selectedAllergies.remove(name);
    if (_selectedAllergies.isEmpty) {
      _selectedAllergies.add(noAllergy);
    }
    notifyListeners();
  }

  void togglePreference(String pref) {
    if (_selectedPreferences.contains(pref)) {
      _selectedPreferences.remove(pref);
    } else {
      _selectedPreferences.add(pref);
    }
    notifyListeners();
  }
}
