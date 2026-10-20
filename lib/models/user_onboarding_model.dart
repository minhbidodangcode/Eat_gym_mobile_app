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
  muscleGain('Tăng cơ', 2800, '+350 kcal SURPLUS'),
  fatLoss('Giảm mỡ', 2150, '-400 kcal DEFICIT'),
  maintenance('Duy trì', 2450, 'CÂN BẰNG NĂNG LƯỢNG');

  final String title;
  final int defaultCalories;
  final String badgeText;
  const NutritionGoal(this.title, this.defaultCalories, this.badgeText);
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

  factory MacroBreakdown.fromCalories(int calories) {
    final proteinKcal = (calories * 0.30).round();
    final carbsKcal = (calories * 0.40).round();
    final fatKcal = (calories * 0.30).round();

    final proteinGrams = (proteinKcal / 4).round();
    final carbsGrams = (carbsKcal / 4).round();
    final fatGrams = (fatKcal / 9).round();

    return MacroBreakdown(
      proteinGrams: proteinGrams,
      proteinKcal: proteinKcal,
      proteinPercent: 30,
      carbsGrams: carbsGrams,
      carbsKcal: carbsKcal,
      carbsPercent: 40,
      fatGrams: fatGrams,
      fatKcal: fatKcal,
      fatPercent: 30,
    );
  }
}

class UserOnboardingModel extends ChangeNotifier {
  Gender _gender = Gender.male;
  DateTime _dateOfBirth = DateTime(DateTime.now().year - 26, 1, 1);
  double _heightCm = 175.0;
  double _weightKg = 74.5;
  ActivityLevel _activityLevel = ActivityLevel.medium;

  NutritionGoal _goal = NutritionGoal.fatLoss;
  int _calories = 2150;

  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedPreferences = {};

  // Getters
  Gender get gender => _gender;
  DateTime get dateOfBirth => _dateOfBirth;
  int get age {
    final today = DateTime.now();
    var result = today.year - _dateOfBirth.year;
    if (DateTime(today.year, _dateOfBirth.month, _dateOfBirth.day).isAfter(today)) {
      result--;
    }
    return result;
  }
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  ActivityLevel get activityLevel => _activityLevel;
  NutritionGoal get goal => _goal;
  int get calories => _calories;
  Set<String> get selectedAllergies => Set.unmodifiable(_selectedAllergies);
  Set<String> get selectedPreferences => Set.unmodifiable(_selectedPreferences);

  MacroBreakdown get macros => MacroBreakdown.fromCalories(_calories);

  // Setters & Mutators
  void setGender(Gender g) {
    if (_gender != g) {
      _gender = g;
      notifyListeners();
    }
  }

  void setAge(int val) {
    _dateOfBirth = DateTime(DateTime.now().year - val.clamp(13, 120).toInt(), 1, 1);
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  void setHeight(double val) {
    _heightCm = val.clamp(100.0, 240.0);
    notifyListeners();
  }

  void setWeight(double val) {
    _weightKg = val.clamp(30.0, 250.0);
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel level) {
    _activityLevel = level;
    notifyListeners();
  }

  void setGoal(NutritionGoal g) {
    _goal = g;
    _calories = g.defaultCalories;
    notifyListeners();
  }

  void setCalories(int cal) {
    _calories = cal.clamp(1500, 3500);
    notifyListeners();
  }

  void toggleAllergy(String allergy) {
    if (_selectedAllergies.contains(allergy)) {
      _selectedAllergies.remove(allergy);
    } else {
      _selectedAllergies.add(allergy);
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
