import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymer_app/services/health_service.dart';
import 'package:gymer_app/models/badges_and_report_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HealthService - Smartwatch & Health Connect Tests', () {
    test('HealthService should report correct source label for Android/iOS', () {
      final service = HealthService.instance;
      expect(service.healthSourceLabel.isNotEmpty, true);
    });

    test('updateCustomHealthMetrics should update steps and caloriesBurned', () async {
      final service = HealthService.instance;
      await service.updateCustomHealthMetrics(steps: 8500, caloriesBurned: 450);

      expect(service.todaySteps, 8500);
      expect(service.todayCaloriesBurned, 450);
      expect(service.isAuthorized, true);
      expect(service.lastSyncTime != null, true);
    });

    test('BadgesAndReportModel should update Health Sync badge when metrics are synced', () async {
      final model = BadgesAndReportModel.instance;
      await HealthService.instance.updateCustomHealthMetrics(steps: 7000, caloriesBurned: 380);

      await model.fetchAchievementsData();

      final healthBadge = model.badges.firstWhere((b) => b.id == 'HEALTH_SYNC_ACTIVE');
      expect(healthBadge.isUnlocked, true);
      expect(healthBadge.currentProgress, 1);
    });

    test('BadgesAndReportModel should contain real gymer badges', () {
      final model = BadgesAndReportModel.instance;
      final badgeIds = model.badges.map((b) => b.id).toList();

      expect(badgeIds.contains('HIGH_PROTEIN_HERO'), true);
      expect(badgeIds.contains('MEAL_PREP_MASTER'), true);
      expect(badgeIds.contains('COOKING_STARTER_3'), true);
      expect(badgeIds.contains('COOKING_WEEK_7'), true);
      expect(badgeIds.contains('HEALTH_SYNC_ACTIVE'), true);
    });

    test('HealthService should format today date string and track heart rate', () async {
      final service = HealthService.instance;
      final dateStr = HealthService.getTodayDateString();
      expect(dateStr.length, 10);
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr), true);

      await service.updateCustomHealthMetrics(
        steps: 2656,
        caloriesBurned: 2,
        heartRate: 89,
        source: 'Nothing X',
        syncBackend: false,
      );

      expect(service.todaySteps, 2656);
      expect(service.todayCaloriesBurned, 2);
      expect(service.todayHeartRate, 89);
      expect(service.currentSource, 'Nothing X');
    });

    test('HealthService.init should reset steps and calories to 0 if previous sync was on an older date', () async {
      final service = HealthService.instance;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso = yesterday.toIso8601String();

      SharedPreferences.setMockInitialValues({
        'health_today_steps': 5000,
        'health_today_calories': 250,
        'health_today_heart_rate': 85,
        'health_last_sync': yesterdayIso,
      });

      await service.init();

      expect(service.todaySteps, 0);
      expect(service.todayCaloriesBurned, 0);
      expect(service.todayHeartRate, 0);
    });

    test('HealthService.init should retain steps and calories if synced today', () async {
      final service = HealthService.instance;
      final todayIso = DateTime.now().toIso8601String();

      SharedPreferences.setMockInitialValues({
        'health_today_steps': 3500,
        'health_today_calories': 120,
        'health_today_heart_rate': 78,
        'health_last_sync': todayIso,
      });

      await service.init();

      expect(service.todaySteps, 3500);
      expect(service.todayCaloriesBurned, 120);
      expect(service.todayHeartRate, 78);
    });
  });
}
