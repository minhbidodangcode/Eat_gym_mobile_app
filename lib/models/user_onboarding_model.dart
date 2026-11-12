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
  static const String noMedical = 'Không có tiền sử bệnh';

  Gender _gender = Gender.male;
  DateTime _dateOfBirth = DateTime(DateTime.now().year - 24, 1, 1);
  double _heightCm = 175.0;
  double _weightKg = 72.0;
  double _targetWeightKg = 70.0;
  ActivityLevel _activityLevel = ActivityLevel.medium;

  NutritionGoal _goal = NutritionGoal.fatLoss;
  late int _calories;

  final Set<String> _selectedAllergies = {noAllergy};
  final List<String> _customAllergies = [];
  final Set<String> _selectedPreferences = {};

  // Bước 2: Bệnh lý, Thực phẩm yêu thích & Lối sống
  final Set<String> _selectedMedicalHistory = {noMedical};
  final Set<String> _selectedFavoriteFoods = {
    'Ức gà phi lê',
    'Thịt bò nạc',
    'Trứng gà',
    'Cá hồi'
  };
  bool _isVegan = false;
  final Set<String> _selectedDietLifestyle = {'Eat Clean', 'High Protein'};

  // Bước 3: Thói quen đi chợ & Nấu ăn
  String _groceryFrequency = '2-3 lần / tuần';
  bool _onlineShoppingWhenNeeded = true;
  final Set<String> _selectedShoppingApps = {
    'WinMart / WinMart+',
    'ShopeeFood / Shopee Mart',
  };
  int _homeCookedMealsCount = 7;
  bool _mealPrepAutomation = true;

  static const List<String> _animalFoodKeywords = [
    'ức gà',
    'thịt bò',
    'cá hồi',
    'trứng',
    'tôm',
    'cá ngừ',
    'cá thu',
    'cá basa',
    'thịt nạc',
    'thịt heo',
    'sữa chua hy lạp',
    'phô mai',
  ];

  static bool isAnimalFood(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('nấm đùi gà') ||
        lower.contains('sữa hạt') ||
        lower.contains('đậu hũ') ||
        lower.contains('tempeh') ||
        lower.contains('seitan')) {
      return false;
    }
    return _animalFoodKeywords.any((kw) => lower.contains(kw));
  }

  // Bước 4: Thiết lập FoodBlog
  String _creatorName = '';
  String _creatorHandle = '';
  String _creatorBio = '';
  final Set<String> _selectedSpecialties = {
    'EatClean',
    'HighProtein',
    'MealPrep nhanh'
  };
  bool _kitchenSyncEnabled = true;
  bool _isFoodBlogPrivate = false;
  String _avatarUrl = 'gymer_1';

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
  double get targetWeightKg => _targetWeightKg;
  double get bmi => _weightKg / math.pow(_heightCm / 100.0, 2);
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

  Set<String> get selectedMedicalHistory => Set.unmodifiable(_selectedMedicalHistory);
  Set<String> get effectiveMedicalHistory =>
      _selectedMedicalHistory.where((m) => m != noMedical).toSet();
  bool get hasNoMedical => _selectedMedicalHistory.contains(noMedical);

  Set<String> get selectedFavoriteFoods => Set.unmodifiable(_selectedFavoriteFoods);
  bool get isVegan => _isVegan;
  Set<String> get selectedDietLifestyle => Set.unmodifiable(_selectedDietLifestyle);

  String get groceryFrequency => _groceryFrequency;
  bool get onlineShoppingWhenNeeded => _onlineShoppingWhenNeeded;
  Set<String> get selectedShoppingApps => Set.unmodifiable(_selectedShoppingApps);
  int get homeCookedMealsCount => _homeCookedMealsCount;
  bool get mealPrepAutomation => _mealPrepAutomation;

  String get creatorName => _creatorName;
  String get creatorHandle => _creatorHandle;
  String get creatorBio => _creatorBio;
  Set<String> get selectedSpecialties => Set.unmodifiable(_selectedSpecialties);
  bool get kitchenSyncEnabled => _kitchenSyncEnabled;
  bool get isFoodBlogPrivate => _isFoodBlogPrivate;
  String get avatarUrl => _avatarUrl;

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

  void setTargetWeight(double val) {
    _targetWeightKg = val.clamp(30.0, 250.0);
    notifyListeners();
  }

  void toggleMedicalHistory(String item) {
    if (item == noMedical) {
      if (_selectedMedicalHistory.contains(noMedical)) {
        _selectedMedicalHistory.remove(noMedical);
      } else {
        _selectedMedicalHistory.clear();
        _selectedMedicalHistory.add(noMedical);
      }
    } else {
      _selectedMedicalHistory.remove(noMedical);
      if (_selectedMedicalHistory.contains(item)) {
        _selectedMedicalHistory.remove(item);
      } else {
        _selectedMedicalHistory.add(item);
      }
      if (_selectedMedicalHistory.isEmpty) {
        _selectedMedicalHistory.add(noMedical);
      }
    }
    notifyListeners();
  }

  void toggleFavoriteFood(String item) {
    if (_isVegan && isAnimalFood(item)) return;
    if (_selectedFavoriteFoods.contains(item)) {
      _selectedFavoriteFoods.remove(item);
    } else {
      _selectedFavoriteFoods.add(item);
    }
    notifyListeners();
  }

  void setVegan(bool val) {
    _isVegan = val;
    if (_isVegan) {
      _selectedFavoriteFoods.removeWhere(isAnimalFood);
      if (_selectedFavoriteFoods.isEmpty) {
        _selectedFavoriteFoods.addAll([
          'Đậu hũ / Tofu',
          'Nấm đùi gà / Nấm hương',
          'Yến mạch',
        ]);
      }
    }
    notifyListeners();
  }

  void toggleDietLifestyle(String item) {
    if (_selectedDietLifestyle.contains(item)) {
      _selectedDietLifestyle.remove(item);
    } else {
      _selectedDietLifestyle.add(item);
    }
    notifyListeners();
  }

  void setGroceryFrequency(String val) {
    _groceryFrequency = val;
    notifyListeners();
  }

  void setOnlineShoppingWhenNeeded(bool val) {
    _onlineShoppingWhenNeeded = val;
    notifyListeners();
  }

  bool isShoppingAppConnected(String app) => _selectedShoppingApps.contains(app);

  void connectShoppingApp(String app) {
    if (_selectedShoppingApps.add(app)) {
      notifyListeners();
    }
  }

  void disconnectShoppingApp(String app) {
    if (_selectedShoppingApps.remove(app)) {
      notifyListeners();
    }
  }

  void toggleShoppingApp(String app) {
    if (_selectedShoppingApps.contains(app)) {
      _selectedShoppingApps.remove(app);
    } else {
      _selectedShoppingApps.add(app);
    }
    notifyListeners();
  }

  void setHomeCookedMealsCount(int val) {
    _homeCookedMealsCount = val.clamp(1, 21);
    notifyListeners();
  }

  void setMealPrepAutomation(bool val) {
    _mealPrepAutomation = val;
    notifyListeners();
  }

  void setCreatorName(String val) {
    _creatorName = val;
    notifyListeners();
  }

  void setCreatorHandle(String val) {
    _creatorHandle = val;
    notifyListeners();
  }

  void setCreatorBio(String val) {
    _creatorBio = val;
    notifyListeners();
  }

  void toggleSpecialty(String item) {
    if (_selectedSpecialties.contains(item)) {
      _selectedSpecialties.remove(item);
    } else {
      _selectedSpecialties.add(item);
    }
    notifyListeners();
  }

  void setKitchenSyncEnabled(bool val) {
    _kitchenSyncEnabled = val;
    notifyListeners();
  }

  void setFoodBlogPrivate(bool val) {
    _isFoodBlogPrivate = val;
    notifyListeners();
  }

  void setAvatarUrl(String val) {
    _avatarUrl = val;
    notifyListeners();
  }
}
