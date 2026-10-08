import 'package:flutter/material.dart';

enum BadgeCategory {
  all('Tất cả'),
  macro('Macro'),
  kitchen('Bếp'),
  streak('Streak');

  final String label;
  const BadgeCategory(this.label);
}

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final BadgeCategory category;
  final bool isUnlocked;
  final int points;
  final IconData icon;
  final int currentProgress;
  final int maxProgress;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isUnlocked,
    this.points = 0,
    required this.icon,
    this.currentProgress = 0,
    this.maxProgress = 100,
  });

  double get progressRatio =>
      maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;
}

enum DateRangeFilter {
  days7('7 Ngày'),
  days30('30 Ngày'),
  allCycle('Toàn chu kỳ');

  final String label;
  const DateRangeFilter(this.label);
}

enum ExportStatus { idle, generating, completed }

class BadgesAndReportModel extends ChangeNotifier {
  // Level & Stats
  final String athleteRank = 'BẬC THẦY DINH DƯỠNG';
  final String rankLevel = 'LV.4';
  final int unlockedBadgesCount = 6;
  final int totalBadgesCount = 8;
  final double rankProgress = 0.75;

  final int streakDays = 28;
  final int macroTargetCount = 45;
  final int reputationPoints = 1420;

  // Filter
  BadgeCategory _selectedCategory = BadgeCategory.all;
  BadgeCategory get selectedCategory => _selectedCategory;

  void setSelectedCategory(BadgeCategory cat) {
    if (_selectedCategory != cat) {
      _selectedCategory = cat;
      notifyListeners();
    }
  }

  // Badges Data
  final List<BadgeItem> _badges = const [
    BadgeItem(
      id: 'b1',
      title: 'Bậc thầy Calo',
      description: 'Giữ thâm hụt 400 kcal suốt 14 ngày',
      category: BadgeCategory.macro,
      isUnlocked: true,
      points: 50,
      icon: Icons.emoji_events,
    ),
    BadgeItem(
      id: 'b2',
      title: 'Chuẩn Macro 7N',
      description: 'P:C:F sai số < 5% trong 7 ngày',
      category: BadgeCategory.macro,
      isUnlocked: true,
      points: 70,
      icon: Icons.bolt,
    ),
    BadgeItem(
      id: 'b3',
      title: 'Bếp Lửa 12 Ngày',
      description: '12 ngày tự nấu liên tiếp',
      category: BadgeCategory.kitchen,
      isUnlocked: true,
      points: 150,
      icon: Icons.outdoor_grill,
    ),
    BadgeItem(
      id: 'b4',
      title: 'Clean Eater Pro',
      description: '0g đường tinh luyện 21 ngày',
      category: BadgeCategory.streak,
      isUnlocked: true,
      points: 100,
      icon: Icons.restaurant,
    ),
    BadgeItem(
      id: 'b5',
      title: 'Chuyên gia Scan AI',
      description: 'Quét nhận diện 100 món ăn bằng AI',
      category: BadgeCategory.kitchen,
      isUnlocked: false,
      icon: Icons.lock,
      currentProgress: 64,
      maxProgress: 100,
    ),
    BadgeItem(
      id: 'b6',
      title: 'Đầu bếp Siêu cơ',
      description: 'Nấu 15 bữa chuẩn tỉ lệ > 40g Protein',
      category: BadgeCategory.macro,
      isUnlocked: false,
      icon: Icons.lock,
      currentProgress: 12,
      maxProgress: 15,
    ),
  ];

  List<BadgeItem> get filteredBadges {
    if (_selectedCategory == BadgeCategory.all) {
      return _badges;
    }
    return _badges.where((b) => b.category == _selectedCategory).toList();
  }

  // Report Export State
  DateRangeFilter _dateRange = DateRangeFilter.days30;
  DateRangeFilter get dateRange => _dateRange;

  void setDateRange(DateRangeFilter range) {
    if (_dateRange != range) {
      _dateRange = range;
      notifyListeners();
    }
  }

  bool _includeBodyChart = true;
  bool get includeBodyChart => _includeBodyChart;
  void toggleBodyChart(bool? val) {
    _includeBodyChart = val ?? !_includeBodyChart;
    notifyListeners();
  }

  bool _includeMicroNutrients = true;
  bool get includeMicroNutrients => _includeMicroNutrients;
  void toggleMicroNutrients(bool? val) {
    _includeMicroNutrients = val ?? !_includeMicroNutrients;
    notifyListeners();
  }

  bool _includeAiReview = true;
  bool get includeAiReview => _includeAiReview;
  void toggleAiReview(bool? val) {
    _includeAiReview = val ?? !_includeAiReview;
    notifyListeners();
  }

  ExportStatus _exportStatus = ExportStatus.idle;
  ExportStatus get exportStatus => _exportStatus;

  Future<void> exportPdf() async {
    if (_exportStatus == ExportStatus.generating) return;

    _exportStatus = ExportStatus.generating;
    notifyListeners();

    // Simulate clinical PDF rendering & export
    await Future.delayed(const Duration(milliseconds: 1600));

    _exportStatus = ExportStatus.completed;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2500));
    _exportStatus = ExportStatus.idle;
    notifyListeners();
  }
}
