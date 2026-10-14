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
  });
}
