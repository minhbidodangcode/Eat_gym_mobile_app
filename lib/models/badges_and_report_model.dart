import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  static final BadgesAndReportModel instance = BadgesAndReportModel._internal();
  factory BadgesAndReportModel() => instance;
  BadgesAndReportModel._internal();

  bool isLoading = false;

  // Level & Stats
  String athleteRank = 'BẬC THẦY DINH DƯỠNG';
  String rankLevel = 'LV.4';
  int unlockedBadgesCount = 3;
  int totalBadgesCount = 6;
  double rankProgress = 0.5;

  int streakDays = 0;
  int macroTargetCount = 14;
  int reputationPoints = 190;

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
  List<BadgeItem> _badges = [
    const BadgeItem(
      id: 'COOKING_STARTER_3',
      title: 'Khởi động bếp núc',
      description: 'Tự nấu liên tục 3 ngày.',
      category: BadgeCategory.streak,
      isUnlocked: false,
      points: 10,
      icon: Icons.local_fire_department,
      maxProgress: 3,
    ),
    const BadgeItem(
      id: 'COOKING_WEEK_7',
      title: 'Bếp trưởng 7 ngày',
      description: 'Tự nấu liên tục 7 ngày.',
      category: BadgeCategory.streak,
      isUnlocked: false,
      points: 30,
      icon: Icons.emoji_events,
      maxProgress: 7,
    ),
    const BadgeItem(
      id: 'COOKING_CHAMPION_30',
      title: 'Chiến binh Meal Prep',
      description: 'Tự nấu liên tục 30 ngày.',
      category: BadgeCategory.kitchen,
      isUnlocked: false,
      points: 150,
      icon: Icons.military_tech,
      maxProgress: 30,
    ),
    const BadgeItem(
      id: 'b1',
      title: 'Bậc thầy Calo',
      description: 'Giữ thâm hụt 400 kcal suốt 14 ngày',
      category: BadgeCategory.macro,
      isUnlocked: true,
      points: 50,
      icon: Icons.bolt,
      currentProgress: 14,
      maxProgress: 14,
    ),
    const BadgeItem(
      id: 'b5',
      title: 'Chuyên gia Scan AI',
      description: 'Quét nhận diện món ăn bằng AI (Confidence > 80%)',
      category: BadgeCategory.kitchen,
      isUnlocked: true,
      points: 100,
      icon: Icons.qr_code_scanner,
      currentProgress: 15,
      maxProgress: 15,
    ),
  ];

  List<BadgeItem> get badges => _badges;

  List<BadgeItem> get filteredBadges {
    if (_selectedCategory == BadgeCategory.all) {
      return _badges;
    }
    return _badges.where((b) => b.category == _selectedCategory).toList();
  }

  /// Tải dữ liệu Streak & Badges từ API Server
  Future<void> fetchAchievementsData() async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Lấy thông tin Streak từ Backend
      try {
        final streakData = await ApiService.getStreak();
        if (streakData.containsKey('streak')) {
          streakDays = (streakData['streak']['consecutiveDays'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      // 2. Lấy danh sách Huy hiệu đã nhận từ Backend
      try {
        final userBadges = await ApiService.getBadges();
        final unlockedCodes = userBadges.map((b) => b['code']?.toString()).toSet();

        _badges = _badges.map((item) {
          final isUnlocked = unlockedCodes.contains(item.id);
          final progress = isUnlocked ? item.maxProgress : (streakDays < item.maxProgress ? streakDays : item.maxProgress);
          return BadgeItem(
            id: item.id,
            title: item.title,
            description: item.description,
            category: item.category,
            isUnlocked: isUnlocked,
            points: item.points,
            icon: item.icon,
            currentProgress: progress,
            maxProgress: item.maxProgress,
          );
        }).toList();

        unlockedBadgesCount = _badges.where((b) => b.isUnlocked).length;
        totalBadgesCount = _badges.length;
        rankProgress = totalBadgesCount > 0 ? unlockedBadgesCount / totalBadgesCount : 0.0;
        reputationPoints = _badges.where((b) => b.isUnlocked).fold(0, (sum, b) => sum + b.points);

        if (streakDays >= 30) {
          athleteRank = 'HUYỀN THOẠI MEAL PREP';
          rankLevel = 'LV.MAX';
        } else if (streakDays >= 7) {
          athleteRank = 'BẾP TRƯỞNG GYMER';
          rankLevel = 'LV.5';
        } else if (streakDays >= 3) {
          athleteRank = 'ĐẦU BẾP NĂNG NỔ';
          rankLevel = 'LV.3';
        } else {
          athleteRank = 'TÂN BINH BẾP NÚC';
          rankLevel = 'LV.1';
        }
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Ghi nhận 1 ngày nấu ăn liên tục và nhận huy hiệu thưởng tự động
  Future<Map<String, dynamic>?> recordCookingDay({String? note, String? mealPrepBatchId}) async {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final result = await ApiService.recordCookingDay(
        cookedOn: todayStr,
        note: note,
        mealPrepBatchId: mealPrepBatchId,
      );

      // Cập nhật lại streak và huy hiệu
      await fetchAchievementsData();
      return result;
    } catch (_) {
      return null;
    }
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
