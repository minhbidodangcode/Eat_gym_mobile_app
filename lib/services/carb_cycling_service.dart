import 'dart:math';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'meal_plan_service.dart';

enum CarbDayType {
  heavy(
    label: 'Tập nặng (Chân/Lưng)',
    carbLevel: 'High Carb',
    carbBadge: '🔥 High Carb (+Tinh bột)',
    badgeColor: Color(0xFFEF4444),
    kcalMultiplier: 1.10,
    carbPct: 0.50,
    proteinPct: 0.25,
    fatPct: 0.25,
    description: 'Tự động TĂNG lượng tinh bột để nạp đầy glycogen cơ bắp, hỗ trợ sức mạnh tối đa và phục hồi sau buổi tập Chân/Lưng nặng.',
  ),
  light(
    label: 'Tập nhẹ (Ngực/Tay/Vai)',
    carbLevel: 'Moderate Carb',
    carbBadge: '⚡ Moderate Carb (Vừa phải)',
    badgeColor: Color(0xFFF59E0B),
    kcalMultiplier: 1.00,
    carbPct: 0.35,
    proteinPct: 0.30,
    fatPct: 0.35,
    description: 'Duy trì lượng tinh bột ở mức VỪA PHẢI để cung cấp năng lượng vừa đủ cho buổi tập nhẹ, tránh tích mỡ thừa.',
  ),
  rest(
    label: 'Nghỉ ngơi (Đốt mỡ & Hồi phục)',
    carbLevel: 'Low Carb',
    carbBadge: '🌿 Low Carb (Hạ thấp tinh bột)',
    badgeColor: Color(0xFF10B981),
    kcalMultiplier: 0.88,
    carbPct: 0.20,
    proteinPct: 0.35,
    fatPct: 0.45,
    description: 'HẠ THẤP tinh bột vào ngày nghỉ ngơi để giảm insulin máu, kích hoạt cơ chế đốt mỡ tự nhiên và tăng độ nhạy insulin.',
  );

  final String label;
  final String carbLevel;
  final String carbBadge;
  final Color badgeColor;
  final double kcalMultiplier;
  final double carbPct;
  final double proteinPct;
  final double fatPct;
  final String description;

  const CarbDayType({
    required this.label,
    required this.carbLevel,
    required this.carbBadge,
    required this.badgeColor,
    required this.kcalMultiplier,
    required this.carbPct,
    required this.proteinPct,
    required this.fatPct,
    required this.description,
  });
}

class CarbDaySchedule {
  final int dayIndex; // 0: Thứ 2 ... 6: Chủ nhật
  final String dayName;
  final DateTime date;
  CarbDayType dayType;
  String focus;
  int targetKcal;
  int targetProtein;
  int targetCarbs;
  int targetFat;
  List<Map<String, dynamic>> meals;

  CarbDaySchedule({
    required this.dayIndex,
    required this.dayName,
    required this.date,
    required this.dayType,
    required this.focus,
    required this.targetKcal,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.meals,
  });

  CarbDaySchedule copyWith({
    CarbDayType? dayType,
    String? focus,
    int? targetKcal,
    int? targetProtein,
    int? targetCarbs,
    int? targetFat,
    List<Map<String, dynamic>>? meals,
  }) {
    return CarbDaySchedule(
      dayIndex: dayIndex,
      dayName: dayName,
      date: date,
      dayType: dayType ?? this.dayType,
      focus: focus ?? this.focus,
      targetKcal: targetKcal ?? this.targetKcal,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      meals: meals ?? List<Map<String, dynamic>>.from(this.meals),
    );
  }
}

class CarbCyclingPreset {
  final String id;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> days;

  const CarbCyclingPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.days,
  });
}

class CarbCyclingService {
  static final List<CarbCyclingPreset> presets = [
    CarbCyclingPreset(
      id: 'standard_4day',
      title: 'Lịch 4 Buổi (Chuẩn Gymer)',
      subtitle: 'Tập nặng Chân & Lưng (High Carb), 2 buổi nhẹ (Moderate) và 3 ngày nghỉ (Low Carb)',
      days: [
        {'dayIndex': 0, 'dayName': 'Thứ 2', 'type': CarbDayType.heavy, 'focus': 'Chân & Đùi (Tập nặng)'},
        {'dayIndex': 1, 'dayName': 'Thứ 3', 'type': CarbDayType.light, 'focus': 'Ngực & Tay sau (Tập vừa)'},
        {'dayIndex': 2, 'dayName': 'Thứ 4', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi & Phục hồi'},
        {'dayIndex': 3, 'dayName': 'Thứ 5', 'type': CarbDayType.heavy, 'focus': 'Lưng & Xô (Tập nặng)'},
        {'dayIndex': 4, 'dayName': 'Thứ 6', 'type': CarbDayType.light, 'focus': 'Vai & Bụng (Tập vừa)'},
        {'dayIndex': 5, 'dayName': 'Thứ 7', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi & Giãn cơ'},
        {'dayIndex': 6, 'dayName': 'Chủ Nhật', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi nạp năng lượng'},
      ],
    ),
    CarbCyclingPreset(
      id: 'ppl_5day',
      title: 'Push - Pull - Legs (PPL)',
      subtitle: '2 ngày Chân & Lưng tập nặng nạp Carb cao, xen kẽ ngày Đẩy và Nghỉ ngơi',
      days: [
        {'dayIndex': 0, 'dayName': 'Thứ 2', 'type': CarbDayType.heavy, 'focus': 'Legs: Chân & Mông (Tập nặng)'},
        {'dayIndex': 1, 'dayName': 'Thứ 3', 'type': CarbDayType.heavy, 'focus': 'Pull: Lưng & Tay trước (Tập nặng)'},
        {'dayIndex': 2, 'dayName': 'Thứ 4', 'type': CarbDayType.light, 'focus': 'Push: Ngực & Vai (Tập vừa)'},
        {'dayIndex': 3, 'dayName': 'Thứ 5', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi & Phục hồi'},
        {'dayIndex': 4, 'dayName': 'Thứ 6', 'type': CarbDayType.heavy, 'focus': 'Legs & Deadlift (Tập nặng)'},
        {'dayIndex': 5, 'dayName': 'Thứ 7', 'type': CarbDayType.light, 'focus': 'Cardio & Thân trên (Tập nhẹ)'},
        {'dayIndex': 6, 'dayName': 'Chủ Nhật', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi'},
      ],
    ),
    CarbCyclingPreset(
      id: 'upper_lower',
      title: 'Upper - Lower (Thân trên / dưới)',
      subtitle: 'Chia đều chu kỳ thân trên & thân dưới với các ngày High Carb bùng nổ',
      days: [
        {'dayIndex': 0, 'dayName': 'Thứ 2', 'type': CarbDayType.heavy, 'focus': 'Lower: Chân & Đùi (Tập nặng)'},
        {'dayIndex': 1, 'dayName': 'Thứ 3', 'type': CarbDayType.light, 'focus': 'Upper: Ngực & Tay (Tập vừa)'},
        {'dayIndex': 2, 'dayName': 'Thứ 4', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi & Phục hồi'},
        {'dayIndex': 3, 'dayName': 'Thứ 5', 'type': CarbDayType.heavy, 'focus': 'Lower: Lưng & Deadlift (Tập nặng)'},
        {'dayIndex': 4, 'dayName': 'Thứ 6', 'type': CarbDayType.light, 'focus': 'Upper: Vai & Tay (Tập vừa)'},
        {'dayIndex': 5, 'dayName': 'Thứ 7', 'type': CarbDayType.rest, 'focus': 'Cardio nhẹ / Thể thao'},
        {'dayIndex': 6, 'dayName': 'Chủ Nhật', 'type': CarbDayType.rest, 'focus': 'Nghỉ ngơi'},
      ],
    ),
  ];

  /// Kho món ăn phong phú chuẩn bị sẵn theo cấp độ Carb
  static final Map<CarbDayType, Map<String, List<Map<String, dynamic>>>> _curatedRecipes = {
    // 1. NGÀY TẬP NẶNG (HIGH CARB) - Tinh bột cao nạp glycogen
    CarbDayType.heavy: {
      'breakfast': [
        {
          'name': 'Bát Yến mạch cán dẹt ngâm sữa chua Hy Lạp, chuối & mật ong',
          'kcal': 480,
          'protein': 26,
          'carbs': 75,
          'fat': 8,
          'carbBadge': '🌾 [High Carb] +75g Tinh bột nạp năng lượng',
          'ingredients': ['Yến mạch cán dẹt 80g', 'Sữa chua Hy Lạp 120g', 'Chuối tiêu 1 quả', 'Mật ong nguyên chất 1 thìa', 'Hạt chia 10g'],
        },
        {
          'name': 'Bánh mì sandwich nguyên cám kẹp 2 trứng ốp & mứt chuối bơ đậu phộng',
          'kcal': 510,
          'protein': 25,
          'carbs': 68,
          'fat': 16,
          'carbBadge': '🌾 [High Carb] Nạp Carb phức hợp',
          'ingredients': ['Bánh mì nguyên cám 3 lát', 'Trứng gà 2 quả', 'Bơ đậu phộng 15g', 'Chuối 1/2 quả'],
        },
      ],
      'lunch': [
        {
          'name': 'Cơm gạo lứt (200g) + Ức gà áp chảo sốt tiêu đen + Bông cải luộc',
          'kcal': 680,
          'protein': 54,
          'carbs': 85,
          'fat': 12,
          'carbBadge': '🌾 [High Carb] Nạp Glycogen tối đa cho buổi tập Chân/Lưng',
          'ingredients': ['Cơm gạo lứt nấu chín 200g', 'Ức gà phi lê 250g', 'Bông cải xanh 150g', 'Sốt tiêu đen Eat Clean'],
        },
        {
          'name': 'Thịt thăn bò xào măng tây & ớt chuông + 2 bát Cơm gạo lứt thơm',
          'kcal': 720,
          'protein': 56,
          'carbs': 82,
          'fat': 16,
          'carbBadge': '🌾 [High Carb] Giàu Creatine tự nhiên & Tinh bột',
          'ingredients': ['Thịt thăn bò nạc 220g', 'Cơm gạo lứt 200g', 'Măng tây tươi 100g', 'Ớt chuông 80g'],
        },
      ],
      'snack': [
        {
          'name': 'Bữa phụ Pre-workout: 2 củ Khoai lang vàng mật + 1 quả Chuối tiêu',
          'kcal': 360,
          'protein': 8,
          'carbs': 78,
          'fat': 2,
          'carbBadge': '⚡ [High Carb] Tăng áp lực bơm cơ trong set tập nặng',
          'ingredients': ['Khoai lang mật luộc 250g', 'Chuối chín 1 quả'],
        },
        {
          'name': 'Sinh tố Yến mạch chuối tiêu & Bột Whey Protein Isolate',
          'kcal': 410,
          'protein': 34,
          'carbs': 62,
          'fat': 4,
          'carbBadge': '⚡ [High Carb] Hấp thu siêu nhanh trước khi tập',
          'ingredients': ['Yến mạch 50g', 'Whey Isolate 1 muỗng (30g)', 'Chuối tiêu 1 quả', 'Sữa tươi tách béo 200ml'],
        },
      ],
      'dinner': [
        {
          'name': 'Mì gạo lứt Soba xào thịt bò thăn băm & Cà rốt súp lơ',
          'kcal': 620,
          'protein': 48,
          'carbs': 72,
          'fat': 14,
          'carbBadge': '🌾 [High Carb] Phục hồi sợi cơ sau buổi tập nặng',
          'ingredients': ['Mì soba / bún gạo lứt 150g', 'Thịt bò thăn băm 180g', 'Súp lơ xanh 100g', 'Dầu ô liu 1 thìa cafe'],
        },
        {
          'name': 'Cá hồi áp chảo sốt cam mật ong + Cơm gạo lứt & Đậu bắp luộc',
          'kcal': 650,
          'protein': 45,
          'carbs': 68,
          'fat': 20,
          'carbBadge': '🌾 [High Carb] Tinh bột kết hợp Omega-3 chống viêm cơ',
          'ingredients': ['Phi lê cá hồi 200g', 'Cơm gạo lứt 160g', 'Đậu bắp 100g', 'Nước cốt cam tươi'],
        },
      ],
    },

    // 2. NGÀY TẬP NHẸ (MODERATE CARB) - Tinh bột vừa phải
    CarbDayType.light: {
      'breakfast': [
        {
          'name': 'Bánh mì đen nguyên cám kẹp 2 trứng ốp la & bơ lạt + 1/2 quả chuối',
          'kcal': 420,
          'protein': 22,
          'carbs': 42,
          'fat': 18,
          'carbBadge': '⚡ [Moderate Carb] Tinh bột cân bằng cho buổi tập nhẹ',
          'ingredients': ['Bánh mì đen 2 lát (60g)', 'Trứng gà 2 quả', 'Bơ lạt 10g', 'Chuối 50g'],
        },
        {
          'name': 'Cháo yến mạch ức gà xé nấm hương thanh đạm',
          'kcal': 380,
          'protein': 32,
          'carbs': 40,
          'fat': 8,
          'carbBadge': '⚡ [Moderate Carb] Dễ tiêu hóa, vừa vặn năng lượng',
          'ingredients': ['Yến mạch 50g', 'Ức gà xé 150g', 'Nấm hương 50g', 'Hành ngò'],
        },
      ],
      'lunch': [
        {
          'name': 'Cơm gạo lứt (130g) + Tôm sú bóc vỏ xào nấm đùi gà & ớt chuông',
          'kcal': 520,
          'protein': 46,
          'carbs': 48,
          'fat': 9,
          'carbBadge': '⚡ [Moderate Carb] Đạm cao, tinh bột vừa phải',
          'ingredients': ['Cơm gạo lứt 130g', 'Tôm sú tươi 220g', 'Nấm đùi gà 120g', 'Ớt chuông 60g'],
        },
        {
          'name': 'Ức gà phi lê áp chảo sốt chanh leo + Khoai lang luộc (150g) & xà lách',
          'kcal': 510,
          'protein': 50,
          'carbs': 46,
          'fat': 8,
          'carbBadge': '⚡ [Moderate Carb] Giữ dáng và săn chắc cơ',
          'ingredients': ['Ức gà 220g', 'Khoai lang luộc 150g', 'Rau xà lách 100g', 'Sốt chanh leo Eat Clean'],
        },
      ],
      'snack': [
        {
          'name': '1 quả táo xanh thái lát + 1 hộp sữa chua không đường & hạt chia',
          'kcal': 220,
          'protein': 10,
          'carbs': 30,
          'fat': 6,
          'carbBadge': '⚡ [Moderate Carb] Bữa phụ nhẹ nhàng chống đói',
          'ingredients': ['Táo xanh 1 quả (150g)', 'Sữa chua không đường 1 hộp', 'Hạt chia 10g'],
        },
        {
          'name': '1 củ ngô ngọt luộc (bắp ngô) + 1 ly sữa đậu nành không đường',
          'kcal': 250,
          'protein': 12,
          'carbs': 36,
          'fat': 5,
          'carbBadge': '⚡ [Moderate Carb] Nguồn carb từ ngô tự nhiên',
          'ingredients': ['Bắp ngô ngọt luộc 1 bắp', 'Sữa đậu nành nguyên chất 200ml'],
        },
      ],
      'dinner': [
        {
          'name': 'Phi lê cá basa nướng thì là + 1/2 chén cơm lứt & canh rong biển',
          'kcal': 460,
          'protein': 40,
          'carbs': 36,
          'fat': 12,
          'carbBadge': '⚡ [Moderate Carb] Bữa tối nhẹ bụng dễ ngủ',
          'ingredients': ['Cá basa phi lê 220g', 'Cơm gạo lứt 100g', 'Rong biển khô 10g', 'Thì là & gia vị'],
        },
        {
          'name': 'Đậu hũ áp chảo vàng giòn xào nạc vai heo băm + Bông cải trắng hấp',
          'kcal': 490,
          'protein': 42,
          'carbs': 32,
          'fat': 18,
          'carbBadge': '⚡ [Moderate Carb] Cân đối dinh dưỡng',
          'ingredients': ['Đậu phụ trắng 150g', 'Thịt nạc vai băm 120g', 'Bông cải trắng 150g'],
        },
      ],
    },

    // 3. NGÀY NGHỈ NGƠI (LOW CARB) - Cắt giảm Carb, tăng chất béo tốt & đạm
    CarbDayType.rest: {
      'breakfast': [
        {
          'name': 'Trứng cuộn rau củ (nấm rơm, hành tây, ớt chuông) + 1/2 quả bơ lát',
          'kcal': 380,
          'protein': 24,
          'carbs': 10,
          'fat': 26,
          'carbBadge': '🌿 [Low Carb] Chỉ 10g Carb • Tối ưu hóa đốt mỡ',
          'ingredients': ['Trứng gà 3 quả', 'Nấm rơm 50g', 'Ớt chuông 30g', 'Bơ sáp thái lát 70g'],
        },
        {
          'name': 'Salad bơ trứng lòng đào sốt mù tạt mật ong & dầu ô liu',
          'kcal': 360,
          'protein': 20,
          'carbs': 12,
          'fat': 24,
          'carbBadge': '🌿 [Low Carb] Chất béo tốt nuôi dưỡng hormone',
          'ingredients': ['Trứng gà luộc 2 quả', 'Quả bơ chín 80g', 'Rau xà lách romain 100g', 'Dầu ô liu extra virgin 10ml'],
        },
      ],
      'lunch': [
        {
          'name': 'Salad ức gà áp chảo xé sợi sốt dầu ô liu giấm táo & Cà chua bi',
          'kcal': 460,
          'protein': 52,
          'carbs': 14,
          'fat': 18,
          'carbBadge': '🌿 [Low Carb] Đạm khủng 52g • Không tinh bột',
          'ingredients': ['Ức gà áp chảo 260g', 'Xà lách & dưa chuột 150g', 'Cà chua bi 60g', 'Dầu ô liu 1 thìa canh'],
        },
        {
          'name': 'Bò bít tết thăn nạc nướng bơ tỏi + Măng tây xào & Nấm đùi gà',
          'kcal': 520,
          'protein': 50,
          'carbs': 15,
          'fat': 24,
          'carbBadge': '🌿 [Low Carb] Cơ thể chuyển sang dùng mỡ làm năng lượng',
          'ingredients': ['Thịt bò thăn nạc 240g', 'Măng tây 120g', 'Nấm đùi gà 80g', 'Bơ lạt 10g'],
        },
      ],
      'snack': [
        {
          'name': 'Đĩa Hạt hạnh nhân & Hạt óc chó rang mộc (35g) + Trà xanh mát',
          'kcal': 220,
          'protein': 8,
          'carbs': 6,
          'fat': 18,
          'carbBadge': '🌿 [Low Carb] 0 đường, giàu chất béo kháng viêm',
          'ingredients': ['Hạt hạnh nhân rang mộc 20g', 'Hạt óc chó 15g', 'Trà xanh không đường'],
        },
        {
          'name': 'Phô mai tươi Mozzarella hoặc Đậu nành luộc Edamame chấm muối biển',
          'kcal': 200,
          'protein': 18,
          'carbs': 8,
          'fat': 10,
          'carbBadge': '🌿 [Low Carb] Protein nạc cao cấp',
          'ingredients': ['Đậu nành edamame nguyên vỏ 150g', 'Muối biển hạt'],
        },
      ],
      'dinner': [
        {
          'name': 'Phi lê cá hồi tươi áp chảo sốt bơ chanh tỏi + Bông cải xanh luộc',
          'kcal': 510,
          'protein': 46,
          'carbs': 12,
          'fat': 28,
          'carbBadge': '🌿 [Low Carb] Giàu EPA/DHA phục hồi khớp và cơ',
          'ingredients': ['Phi lê cá hồi tươi 220g', 'Bông cải xanh luộc 150g', 'Bơ lạt 10g', 'Tỏi băm & cốt chanh'],
        },
        {
          'name': 'Canh sườn non hầm bí xanh thanh mát (không nêm đường) + Trứng ốp',
          'kcal': 440,
          'protein': 38,
          'carbs': 14,
          'fat': 22,
          'carbBadge': '🌿 [Low Carb] Bữa tối nhẹ nhàng không tích mỡ',
          'ingredients': ['Sườn heo non nạc 200g', 'Bí xanh gọt vỏ 200g', 'Trứng gà 1 quả'],
        },
      ],
    },
  };

  static List<Map<String, dynamic>>? _cachedDbRecipes;
  static List<Map<String, dynamic>>? get cachedDbRecipes => _cachedDbRecipes;

  /// Đồng bộ công thức nấu ăn thực tế từ Database Backend
  static Future<void> syncWithDatabase() async {
    try {
      final recipes = await ApiService.getRecipes();
      if (recipes.isNotEmpty) {
        _cachedDbRecipes = recipes;
        _integrateDbRecipes(recipes);
      }
    } catch (_) {}
  }

  static void _integrateDbRecipes(List<Map<String, dynamic>> recipes) {
    for (final r in recipes) {
      final title = (r['title'] ?? r['name'] ?? '').toString();
      if (title.isEmpty) continue;
      final kcal = (r['kcal'] is num) ? (r['kcal'] as num).round() : ((r['calories'] is num) ? (r['calories'] as num).round() : 400);
      final protein = (r['protein'] is num) ? (r['protein'] as num).round() : 30;
      final carbs = (r['carbs'] is num) ? (r['carbs'] as num).round() : 30;
      final fat = (r['fat'] is num) ? (r['fat'] as num).round() : 10;
      final rawIngredients = r['ingredients'];
      List<String> ings = [];
      if (rawIngredients is List) {
        ings = rawIngredients.map((i) {
          if (i is Map) {
            final n = i['name'] ?? '';
            final a = i['amount'] ?? '';
            final u = i['unit'] ?? 'g';
            return a.toString().isNotEmpty ? '$n $a$u' : n.toString();
          }
          return i.toString();
        }).where((s) => s.isNotEmpty).toList();
      }
      if (ings.isEmpty) {
        ings = [title, 'Gia vị Eat Clean'];
      }

      CarbDayType dayType;
      String carbBadge;
      if (carbs >= 35) {
        dayType = CarbDayType.heavy;
        carbBadge = '🔥 [High Carb] ${carbs}g Carb • Nạp năng lượng tối đa';
      } else if (carbs >= 15) {
        dayType = CarbDayType.light;
        carbBadge = '⚡ [Moderate Carb] ${carbs}g Carb • Cân bằng cơ thể';
      } else {
        dayType = CarbDayType.rest;
        carbBadge = '🌿 [Low Carb] ${carbs}g Carb • Đốt mỡ tự nhiên';
      }

      final lower = title.toLowerCase();
      String slot = 'lunch';
      if (lower.contains('yến mạch') || lower.contains('bánh mì') || lower.contains('trứng ốp') || lower.contains('sáng') || lower.contains('breakfast')) {
        slot = 'breakfast';
      } else if (lower.contains('sinh tố') || lower.contains('hạt') || lower.contains('sữa chua') || lower.contains('phụ') || lower.contains('snack')) {
        slot = 'snack';
      } else if (lower.contains('canh') || lower.contains('súp') || lower.contains('salad') || lower.contains('tối') || lower.contains('dinner')) {
        slot = 'dinner';
      }

      final dishItem = {
        'name': title,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'carbBadge': carbBadge,
        'ingredients': ings,
      };

      final targetList = _curatedRecipes[dayType]?[slot];
      if (targetList != null && !targetList.any((it) => it['name'] == title)) {
        targetList.insert(0, dishItem); // Đưa công thức từ Database lên ưu tiên hàng đầu
      }
    }
  }

  /// Tạo lịch tuần Carb Cycling đầy đủ theo TDEE và mẫu chu kỳ được chọn
  static List<CarbDaySchedule> generateWeeklyPlan({
    required double baselineKcal,
    String presetId = 'standard_4day',
    List<Map<String, dynamic>>? customDays,
    DateTime? startDate,
  }) {
    final start = startDate ?? _getUpcomingMonday();
    final chosenPreset = presets.firstWhere((p) => p.id == presetId, orElse: () => presets[0]);
    final dayConfigs = customDays ?? chosenPreset.days;

    final random = Random();
    final List<CarbDaySchedule> result = [];

    for (int i = 0; i < 7; i++) {
      final config = dayConfigs[i];
      final dayType = config['type'] as CarbDayType? ?? CarbDayType.light;
      final focus = config['focus'] as String? ?? dayType.label;
      final dayName = config['dayName'] as String? ?? 'Thứ ${i + 2}';
      final dayDate = start.add(Duration(days: i));

      // Tính Macros theo công thức Carb Cycling
      final targetKcal = (baselineKcal * dayType.kcalMultiplier).round();
      final targetCarbs = ((targetKcal * dayType.carbPct) / 4.0).round();
      final targetProtein = ((targetKcal * dayType.proteinPct) / 4.0).round();
      final targetFat = ((targetKcal * dayType.fatPct) / 9.0).round();

      // Chọn món ăn tương ứng với CarbDayType
      final typeRecipes = _curatedRecipes[dayType]!;
      final breakfastList = typeRecipes['breakfast']!;
      final lunchList = typeRecipes['lunch']!;
      final snackList = typeRecipes['snack']!;
      final dinnerList = typeRecipes['dinner']!;

      final breakfast = Map<String, dynamic>.from(breakfastList[random.nextInt(breakfastList.length)]);
      final lunch = Map<String, dynamic>.from(lunchList[random.nextInt(lunchList.length)]);
      final snack = Map<String, dynamic>.from(snackList[random.nextInt(snackList.length)]);
      final dinner = Map<String, dynamic>.from(dinnerList[random.nextInt(dinnerList.length)]);

      breakfast['mealType'] = 'Bữa Sáng';
      lunch['mealType'] = 'Bữa Trưa';
      snack['mealType'] = 'Bữa Phụ';
      dinner['mealType'] = 'Bữa Tối';

      result.add(CarbDaySchedule(
        dayIndex: i,
        dayName: dayName,
        date: dayDate,
        dayType: dayType,
        focus: focus,
        targetKcal: targetKcal,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
        meals: [breakfast, lunch, snack, dinner],
      ));
    }

    return result;
  }

  /// Đổi món ngẫu nhiên cho một bữa ăn trong ngày
  static Map<String, dynamic> swapMeal(CarbDayType dayType, String mealTypeKey, String currentMealName) {
    String key = 'lunch';
    final lower = mealTypeKey.toLowerCase();
    if (lower.contains('sáng') || lower.contains('breakfast')) key = 'breakfast';
    if (lower.contains('trưa') || lower.contains('lunch')) key = 'lunch';
    if (lower.contains('phụ') || lower.contains('snack')) key = 'snack';
    if (lower.contains('tối') || lower.contains('dinner')) key = 'dinner';

    final options = _curatedRecipes[dayType]?[key] ?? [];
    if (options.isEmpty) return {};

    final candidates = options.where((m) => m['name'] != currentMealName).toList();
    if (candidates.isEmpty) return Map<String, dynamic>.from(options.first);

    final selected = Map<String, dynamic>.from(candidates[Random().nextInt(candidates.length)]);
    selected['mealType'] = mealTypeKey;
    return selected;
  }

  /// Áp dụng và lưu toàn bộ 7 ngày vào hệ thống MealPlanService
  static Future<void> applyPlanToCalendar(List<CarbDaySchedule> schedule) async {
    final List<MealPlan> plansToSave = [];

    for (final day in schedule) {
      final dateStr = '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}/${day.date.year}';

      for (int mealIdx = 0; mealIdx < day.meals.length; mealIdx++) {
        final meal = day.meals[mealIdx];
        final id = 'carb_cycle_${day.date.millisecondsSinceEpoch}_${day.dayIndex}_$mealIdx';

        plansToSave.add(
          MealPlan(
            id: id,
            name: meal['name']?.toString() ?? 'Món ăn dinh dưỡng',
            servings: 1,
            mealType: meal['mealType']?.toString() ?? 'Bữa trưa',
            prepDate: day.date,
            storedFrozen: false,
            dayName: day.dayName,
            dateStr: dateStr,
            kcal: (meal['kcal'] as num?)?.toInt(),
            protein: (meal['protein'] as num?)?.toInt(),
            carbs: (meal['carbs'] as num?)?.toInt(),
            fat: (meal['fat'] as num?)?.toInt(),
            cookType: 'Nấu tươi theo chu kỳ',
            workoutType: day.dayType.name,
            workoutFocus: day.focus,
            carbLevel: day.dayType.carbLevel,
            notes: '${day.dayType.carbBadge} • ${day.focus}',
          ),
        );
      }
    }

    await MealPlanService.savePlans(plansToSave);
  }

  /// Lấy ngày Thứ 2 gần nhất (hoặc Thứ 2 tuần này/sau)
  static DateTime _getUpcomingMonday() {
    final now = DateTime.now();
    final int weekday = now.weekday; // 1: Thứ 2 ... 7: CN
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
  }
}
