import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class MealPlan {
  final String id;
  final String name;
  final int servings;
  final String mealType;
  final DateTime prepDate;
  final DateTime? thawAt;
  final bool storedFrozen;
  final String? batchId;

  const MealPlan({
    required this.id,
    required this.name,
    required this.servings,
    required this.mealType,
    required this.prepDate,
    required this.storedFrozen,
    this.thawAt,
    this.batchId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servings': servings,
    'mealType': mealType,
    'prepDate': prepDate.toIso8601String(),
    'thawAt': thawAt?.toIso8601String(),
    'storedFrozen': storedFrozen,
    'batchId': batchId,
  };

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
    id: json['id'].toString(),
    name: json['name'].toString(),
    servings: (json['servings'] as num?)?.toInt() ?? 1,
    mealType: json['mealType']?.toString() ?? 'lunch',
    prepDate: DateTime.parse(json['prepDate'].toString()),
    thawAt: json['thawAt'] == null ? null : DateTime.tryParse(json['thawAt'].toString()),
    storedFrozen: json['storedFrozen'] == true,
    batchId: json['batchId']?.toString(),
  );
}

class MealPlanService {
  static const _storageKey = 'meal_prep_plans_v1';

  static Future<List<MealPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_storageKey);
    if (source == null) return [];
    try {
      final decoded = jsonDecode(source) as List;
      final plans = decoded.map((item) => MealPlan.fromJson(Map<String, dynamic>.from(item))).toList();
      plans.sort((a, b) => (a.thawAt ?? a.prepDate).compareTo(b.thawAt ?? b.prepDate));
      return plans;
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlan(MealPlan plan) async {
    final plans = await loadPlans();
    plans.removeWhere((item) => item.id == plan.id);
    plans.add(plan);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plans.map((item) => item.toJson()).toList()));
    if (plan.storedFrozen && plan.thawAt != null && plan.thawAt!.isAfter(DateTime.now())) {
      await NotificationService().scheduleThawReminder(
        id: plan.id.hashCode & 0x7fffffff,
        thawAt: plan.thawAt!,
        mealName: plan.name,
      );
    }
  }

  static Future<void> deletePlan(MealPlan plan) async {
    final plans = await loadPlans();
    plans.removeWhere((item) => item.id == plan.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plans.map((item) => item.toJson()).toList()));
    await NotificationService().cancelReminder(plan.id.hashCode & 0x7fffffff);
  }
}
