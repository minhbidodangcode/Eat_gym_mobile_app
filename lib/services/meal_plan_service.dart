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
  final String? dayName;
  final String? dateStr;
  final int? kcal;
  final int? protein;
  final int? carbs;
  final int? fat;
  final String? cookType;
  final String? notes;
  final String? workoutType;
  final String? workoutFocus;
  final String? carbLevel;

  const MealPlan({
    required this.id,
    required this.name,
    required this.servings,
    required this.mealType,
    required this.prepDate,
    required this.storedFrozen,
    this.thawAt,
    this.batchId,
    this.dayName,
    this.dateStr,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.cookType,
    this.notes,
    this.workoutType,
    this.workoutFocus,
    this.carbLevel,
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
    'dayName': dayName,
    'dateStr': dateStr,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'cookType': cookType,
    'notes': notes,
    'workoutType': workoutType,
    'workoutFocus': workoutFocus,
    'carbLevel': carbLevel,
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
    dayName: json['dayName']?.toString(),
    dateStr: json['dateStr']?.toString(),
    kcal: (json['kcal'] as num?)?.toInt(),
    protein: (json['protein'] as num?)?.toInt(),
    carbs: (json['carbs'] as num?)?.toInt(),
    fat: (json['fat'] as num?)?.toInt(),
    cookType: json['cookType']?.toString(),
    notes: json['notes']?.toString(),
    workoutType: json['workoutType']?.toString(),
    workoutFocus: json['workoutFocus']?.toString(),
    carbLevel: json['carbLevel']?.toString(),
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

  static Future<void> savePlans(List<MealPlan> newPlans) async {
    final plans = await loadPlans();
    for (final plan in newPlans) {
      plans.removeWhere((item) =>
          item.id == plan.id ||
          (item.prepDate.year == plan.prepDate.year &&
           item.prepDate.month == plan.prepDate.month &&
           item.prepDate.day == plan.prepDate.day &&
           item.mealType.toLowerCase() == plan.mealType.toLowerCase() &&
           item.name.toLowerCase() == plan.name.toLowerCase()));
      plans.add(plan);
      if (plan.storedFrozen && plan.thawAt != null && plan.thawAt!.isAfter(DateTime.now())) {
        await NotificationService().scheduleThawReminder(
          id: plan.id.hashCode & 0x7fffffff,
          thawAt: plan.thawAt!,
          mealName: plan.name,
        );
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plans.map((item) => item.toJson()).toList()));
  }

  static Future<void> deletePlan(MealPlan plan) async {
    final plans = await loadPlans();
    plans.removeWhere((item) => item.id == plan.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plans.map((item) => item.toJson()).toList()));
    await NotificationService().cancelReminder(plan.id.hashCode & 0x7fffffff);
  }

  static Future<void> clearAllPlans() async {
    final plans = await loadPlans();
    for (final plan in plans) {
      await NotificationService().cancelReminder(plan.id.hashCode & 0x7fffffff);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
