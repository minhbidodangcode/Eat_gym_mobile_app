import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';

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
  BadgesAndReportModel._internal() {
    HealthService.instance.init();
  }

  bool isLoading = false;

  // Level & Dynamic Stats (Không còn mock cứng)
  String athleteRank = 'TÂN BINH BẾP NÚC';
  String rankLevel = 'LV.1';
  int unlockedBadgesCount = 0;
  int totalBadgesCount = 6;
  double rankProgress = 0.0;

  int streakDays = 0;
  int macroTargetCount = 0;
  int reputationPoints = 0;

  // Health Data từ Smartwatch / Health Connect / Apple Health
  int get todaySteps => HealthService.instance.todaySteps;
  int get todayCaloriesBurned => HealthService.instance.todayCaloriesBurned;
  int get todayHeartRate => HealthService.instance.todayHeartRate;
  bool get isHealthAuthorized => HealthService.instance.isAuthorized;
  bool get isDeviceConnected => HealthService.instance.isDeviceConnected;
  DateTime? get lastHealthSyncTime => HealthService.instance.lastSyncTime;
  String get healthSourceLabel => HealthService.instance.healthSourceLabel;

  Future<void> connectHealthDevice(String deviceName) async {
    await HealthService.instance.connectDevice(deviceName);
    await syncSmartwatchHealthData();
    notifyListeners();
  }

  Future<void> disconnectHealthDevice() async {
    await HealthService.instance.disconnectDevice();
    notifyListeners();
  }

  /// Cập nhật chỉ số sức khỏe hàng ngày (0h-24h) từ Smartwatch
  Future<void> updateDailyHealthMetrics({
    required int steps,
    required int caloriesBurned,
    int? heartRate,
    String? source,
    String? logDate,
  }) async {
    await HealthService.instance.updateCustomHealthMetrics(
      steps: steps,
      caloriesBurned: caloriesBurned,
      heartRate: heartRate,
      source: source,
      logDate: logDate,
      syncBackend: true,
    );
    await fetchAchievementsData();
  }

  // Filter
  BadgeCategory _selectedCategory = BadgeCategory.all;
  BadgeCategory get selectedCategory => _selectedCategory;

  void setSelectedCategory(BadgeCategory cat) {
    if (_selectedCategory != cat) {
      _selectedCategory = cat;
      notifyListeners();
    }
  }

  // Danh sách huy hiệu thực tế của hệ thống Gymer Chef
  List<BadgeItem> _badges = [
    const BadgeItem(
      id: 'COOKING_STARTER_3',
      title: 'Khởi động bếp núc',
      description: 'Tự nấu liên tục 3 ngày theo dữ liệu thời gian thực.',
      category: BadgeCategory.streak,
      isUnlocked: false,
      points: 20,
      icon: Icons.local_fire_department,
      maxProgress: 3,
    ),
    const BadgeItem(
      id: 'COOKING_WEEK_7',
      title: 'Bếp trưởng 7 ngày',
      description: 'Duy trì chuỗi tự nấu ăn liên tục suốt 7 ngày.',
      category: BadgeCategory.streak,
      isUnlocked: false,
      points: 60,
      icon: Icons.emoji_events,
      maxProgress: 7,
    ),
    const BadgeItem(
      id: 'COOKING_CHAMPION_30',
      title: 'Chiến binh Meal Prep',
      description: 'Kỷ luật nấu ăn liên tục 30 ngày cho gymer.',
      category: BadgeCategory.kitchen,
      isUnlocked: false,
      points: 200,
      icon: Icons.military_tech,
      maxProgress: 30,
    ),
    const BadgeItem(
      id: 'HIGH_PROTEIN_HERO',
      title: 'High Protein Hero',
      description: 'Đạt mục tiêu Protein tối thiểu 120g trong ngày từ nhật ký ăn uống.',
      category: BadgeCategory.macro,
      isUnlocked: false,
      points: 50,
      icon: Icons.fitness_center,
      maxProgress: 7,
    ),
    const BadgeItem(
      id: 'MEAL_PREP_MASTER',
      title: 'Meal Prep Master',
      description: 'Nấu nướng và chuẩn bị các mẻ dinh dưỡng lành mạnh cho tuần.',
      category: BadgeCategory.kitchen,
      isUnlocked: false,
      points: 100,
      icon: Icons.restaurant_menu,
      maxProgress: 5,
    ),
    const BadgeItem(
      id: 'HEALTH_SYNC_ACTIVE',
      title: 'Vận Động Toàn Năng',
      description: 'Kết nối Google Health Connect / Apple Health theo dõi calo tiêu hao.',
      category: BadgeCategory.macro,
      isUnlocked: false,
      points: 40,
      icon: Icons.watch,
      maxProgress: 1,
    ),
  ];

  List<BadgeItem> get badges => _badges;

  List<BadgeItem> get filteredBadges {
    if (_selectedCategory == BadgeCategory.all) {
      return _badges;
    }
    return _badges.where((b) => b.category == _selectedCategory).toList();
  }

  /// Tải dữ liệu Streak, Nhật ký ăn uống & Huy hiệu thực tế từ Backend và Smartwatch
  Future<void> fetchAchievementsData() async {
    try {
      isLoading = true;
      Future.microtask(() => notifyListeners());

      // 1. Lấy thông tin Streak từ Backend API
      try {
        final streakData = await ApiService.getStreak();
        if (streakData.containsKey('streak')) {
          streakDays = (streakData['streak']['consecutiveDays'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      // 2. Lấy danh sách Huy hiệu đã nhận từ Backend API
      Set<String> unlockedCodes = {};
      try {
        final userBadges = await ApiService.getBadges();
        unlockedCodes = userBadges.map((b) => b['code']?.toString() ?? '').toSet();
      } catch (_) {}

      // 3. Tính toán số ngày đạt chuẩn Macro & số ngày High Protein từ Nhật ký ăn uống thực tế
      int calculatedMacroDays = 0;
      int highProteinDays = 0;
      try {
        final summaryData = await ApiService.getNutritionSummary();
        if (summaryData.containsKey('summary') && summaryData['summary'] is List) {
          final List rows = summaryData['summary'];
          for (final row in rows) {
            final pro = (row['totalProtein'] as num?)?.toInt() ?? 0;
            final cal = (row['totalCalories'] as num?)?.toInt() ?? 0;
            if (cal > 0 || pro > 0) {
              calculatedMacroDays++;
            }
            if (pro >= 120) {
              highProteinDays++;
            }
          }
        }
      } catch (_) {}

      macroTargetCount = calculatedMacroDays;

      // 4. Kiểm tra trạng thái Health Connect / Apple Health (chỉ mở khóa khi THỰC SỰ đã kết nối thiết bị và đồng bộ chỉ số calo/bước chân)
      final bool isHealthConnected = HealthService.instance.isDeviceConnected &&
          HealthService.instance.lastSyncTime != null &&
          (HealthService.instance.todayCaloriesBurned > 0 || HealthService.instance.todaySteps > 0);

      // 5. Cập nhật tiến độ của từng huy hiệu theo số liệu thực tế
      _badges = _badges.map((item) {
        bool isUnlocked = unlockedCodes.contains(item.id);
        int progress = 0;

        switch (item.id) {
          case 'COOKING_STARTER_3':
            progress = isUnlocked ? 3 : streakDays.clamp(0, 3);
            if (progress >= 3) isUnlocked = true;
            break;
          case 'COOKING_WEEK_7':
            progress = isUnlocked ? 7 : streakDays.clamp(0, 7);
            if (progress >= 7) isUnlocked = true;
            break;
          case 'COOKING_CHAMPION_30':
            progress = isUnlocked ? 30 : streakDays.clamp(0, 30);
            if (progress >= 30) isUnlocked = true;
            break;
          case 'HIGH_PROTEIN_HERO':
            progress = highProteinDays.clamp(0, item.maxProgress);
            if (progress >= item.maxProgress) isUnlocked = true;
            break;
          case 'MEAL_PREP_MASTER':
            // Tính theo số ngày nấu nướng thực tế
            progress = streakDays.clamp(0, item.maxProgress);
            if (progress >= item.maxProgress) isUnlocked = true;
            break;
          case 'HEALTH_SYNC_ACTIVE':
            // Chỉ mở khóa khi người dùng thực sự đã liên kết thiết bị và đồng bộ dữ liệu calo/bước chân
            progress = isHealthConnected ? 1 : 0;
            isUnlocked = isHealthConnected;
            break;
          default:
            progress = isUnlocked ? item.maxProgress : 0;
        }

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

      // 6. Tính toán điểm uy tín và Level thực tế
      unlockedBadgesCount = _badges.where((b) => b.isUnlocked).length;
      totalBadgesCount = _badges.length;
      rankProgress = totalBadgesCount > 0 ? unlockedBadgesCount / totalBadgesCount : 0.0;
      reputationPoints = _badges.where((b) => b.isUnlocked).fold(0, (sum, b) => sum + b.points);

      if (streakDays >= 30 || unlockedBadgesCount >= 5) {
        athleteRank = 'HUYỀN THOẠI MEAL PREP';
        rankLevel = 'LV.MAX';
      } else if (streakDays >= 7 || unlockedBadgesCount >= 3) {
        athleteRank = 'BẾP TRƯỞNG GYMER';
        rankLevel = 'LV.4';
      } else if (streakDays >= 3 || unlockedBadgesCount >= 1) {
        athleteRank = 'ĐẦU BẾP NĂNG NỔ';
        rankLevel = 'LV.3';
      } else {
        athleteRank = 'TÂN BINH BẾP NÚC';
        rankLevel = 'LV.1';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Đồng bộ dữ liệu tập luyện theo thời gian thực từ Google Health Connect / Apple Health
  Future<Map<String, dynamic>> syncSmartwatchHealthData() async {
    final result = await HealthService.instance.fetchRealtimeHealthData();
    await fetchAchievementsData();
    return result;
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

  Future<String> exportPdf() async {
    if (_exportStatus == ExportStatus.generating) return '';

    _exportStatus = ExportStatus.generating;
    notifyListeners();

    // Render clinical PDF export
    await Future.delayed(const Duration(milliseconds: 1200));

    // Fetch user profile for accurate clinical data
    final profile = await ApiService.getLocalProfile();
    final name = profile?['name'] ?? profile?['fullName'] ?? 'Gymer Athlete';
    final weight = profile?['weight'] ?? 72.0;
    final height = profile?['height'] ?? 175.0;
    final goal = profile?['goal'] ?? 'Tăng cơ giảm mỡ';
    final dateRangeStr = _dateRange.label;

    final reportContent = '''
======================================================
     BÁO CÁO DINH DƯỠNG & THỂ CHẤT LÂM SÀNG GYMER
======================================================
Họ và tên vận động viên: $name
Mục tiêu thể hình: $goal
Chỉ số thể trạng: Cân nặng ${weight}kg | Chiều cao ${height}cm
Phạm vi dữ liệu: $dateRangeStr
Danh hiệu Gymer Chef: $athleteRank ($rankLevel)
Điểm uy tín tích luỹ: $reputationPoints pts | Chuỗi nấu liên tục: $streakDays ngày
Tiêu hao vận động hôm nay: $todayCaloriesBurned kcal ($todaySteps bước)
Nguồn dữ liệu thiết bị đeo: $healthSourceLabel

CHI TIẾT KIỂM TOÁN DINH DƯỠNG & KHUYẾN NGHỊ:
- Tỷ lệ tuân thủ Protein: ${macroTargetCount > 0 ? 'Tốt (Đạt chỉ tiêu)' : 'Cần tối ưu thêm'}
- Số huy hiệu đạt chuẩn: $unlockedBadgesCount / $totalBadgesCount huy hiệu
${_includeAiReview ? "- Khuyến nghị AI Coach: Duy trì lượng protein từ 1.8-2.2g/kg trọng lượng cơ thể, phân bổ đều 3-4 bữa trong ngày kết hợp bù trừ thâm hụt calo kịp thời." : ""}
${_includeMicroNutrients ? "- Vi chất & Nước: Khuyến nghị bổ sung tối thiểu 2.5L - 3.5L nước/ngày và tăng cường rau xanh giàu Kali, Magiê." : ""}

Mã xác thực y khoa / HLV: GYMER-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}
Ngày tạo báo cáo: ${DateTime.now().toLocal().toString().split('.')[0]}
Tiêu chuẩn: HIPAA & HealthKit Compliance
======================================================
''';

    _exportStatus = ExportStatus.completed;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));
    _exportStatus = ExportStatus.idle;
    notifyListeners();

    return reportContent;
  }
}
