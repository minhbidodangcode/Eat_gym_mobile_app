import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message.dart';
import '../../models/voice_ingredient_result.dart';
import '../api_service.dart';
import '../carb_cycling_service.dart';
import 'ingredient_normalizer.dart';
import 'voice_ingredient_parser.dart';

class NutriGymChatService {
  /// Xử lý tin nhắn người dùng và trả về phản hồi thông minh từ AI Assistant
  static Future<ChatMessage> processMessage(
    String userText, {
    List<Map<String, dynamic>>? availableIngredients,
    Map<String, dynamic>? customMealPlanOptions,
  }) async {
    final text = userText.trim();
    if (text.isEmpty && customMealPlanOptions == null) {
      return ChatMessage.botText('Xin chào! Tôi có thể giúp gì cho chế độ dinh dưỡng và kho thực phẩm của bạn hôm nay?');
    }

    // Nếu có tùy chọn Meal Prep từ Modal Sheet, ưu tiên trực tiếp tạo kế hoạch
    if (customMealPlanOptions != null) {
      return await generateMealPlan(
        prompt: text.isNotEmpty ? text : 'Lập kế hoạch mealprep',
        forceFromFridge: customMealPlanOptions['forceFromFridge'] == true,
        customOptions: customMealPlanOptions,
      );
    }

    final lower = text.toLowerCase();

    // 1. INTENT: Lời chào hoặc câu hỏi giới thiệu (Greeting)
    if (_isGreeting(lower)) {
      return ChatMessage.botText(
        'Xin chào Gymer! 💪 Tôi là **NutriGym AI Assistant** — Trợ lý ảo dinh dưỡng thể hình của bạn.\n\n'
        'Tôi có thể giúp bạn:\n'
        '• 🎙️ **Thêm nguyên liệu vào tab Nguyên liệu** qua giọng nói hoặc văn bản (VD: *"Hôm nay có 300g ức gà và 3 quả trứng"*)\n'
        '• 🍲 **Gợi ý món ăn dinh dưỡng** từ các nguyên liệu bạn chọn (VD: *"Nấu món gì với ức gà và trứng?"*)\n'
        '• 🥩 **Tư vấn dinh dưỡng tăng cơ/giảm mỡ** (VD: *"Cần nạp bao nhiêu protein để tăng cơ?"*)'
      );
    }

    // 2. INTENT: Kiểm tra danh sách nguyên liệu đã chọn
    if (_isIngredientsListIntent(lower)) {
      return _handleIngredientsListCheck(availableIngredients);
    }

    // 3. INTENT: Tư vấn dinh dưỡng thể hình (Gym Nutrition Q&A)
    // Ưu tiên cao cho các thắc mắc khoa học thể hình (Protein, Pre/Post-workout, Creatine, Bulking, Cutting)
    final nutritionAdvice = _matchNutritionAdvice(lower);
    if (nutritionAdvice != null) {
      return ChatMessage.botText(nutritionAdvice);
    }

    // 4. INTENT: Thêm nguyên liệu bằng giọng nói/văn bản (Ingredient Extraction & Management)
    final parsedIngredients = VoiceIngredientParser.parseSpokenText(
      text,
      availableIngredients: availableIngredients,
    );
    if (parsedIngredients.isNotEmpty && _isIngredientAddIntent(lower, parsedIngredients)) {
      return _handleIngredientAdd(parsedIngredients);
    }

    // INTENT: Lập kế hoạch thực đơn tuần Carb Cycling theo chu kỳ tập luyện
    if (_isCarbCyclingIntent(lower)) {
      return await generateCarbCyclingMealPlan(prompt: text);
    }

    // INTENT: Lập thực đơn thông minh & Kế hoạch Meal Prep (Smart Meal Planning)
    if (_isMealPlanIntent(lower)) {
      return await generateMealPlan(
        prompt: text,
        forceFromFridge: lower.contains('tủ lạnh') || lower.contains('có sẵn') || lower.contains('trong tủ'),
      );
    }

    // 5. INTENT: Gợi ý công thức món ăn (Recipe Suggestions)
    if (_isRecipeIntent(lower)) {
      return await _handleRecipeSuggestion(text, lower, availableIngredients);
    }

    // Fallback: Trả lời tự nhiên và gợi ý hành động
    return ChatMessage.botText(
      'Tôi đã lắng nghe bạn! Với vai trò là Trợ lý AI NutriGym, bạn có thể:\n\n'
      '1. Nói hoặc gõ danh sách nguyên liệu để thêm trực tiếp vào tab Nguyên liệu.\n'
      '2. Hỏi tôi gợi ý món ăn dinh dưỡng từ các nguyên liệu sẵn có.\n'
      '3. Đặt câu hỏi về cách tính Macro, Protein, bữa ăn trước/sau buổi tập gym.\n\n'
      'Bạn muốn thực hiện điều gì tiếp theo?'
    );
  }

  // ---------------------------------------------------------------------------
  // Xử lý các Intent
  // ---------------------------------------------------------------------------

  static bool _isGreeting(String text) {
    return text == 'hi' ||
        text == 'hello' ||
        text.startsWith('chào') ||
        text.startsWith('xin chào') ||
        text.contains('bạn là ai') ||
        text.contains('giúp gì');
  }

  static bool _isIngredientsListIntent(String text) {
    return text.contains('nguyên liệu đã chọn') ||
        text.contains('danh sách nguyên liệu') ||
        text.contains('đã chọn gì') ||
        text.contains('nguyên liệu hiện có') ||
        text.contains('xem nguyên liệu');
  }

  static ChatMessage _handleIngredientsListCheck(List<Map<String, dynamic>>? ingredients) {
    final items = ingredients ?? [];
    if (items.isEmpty) {
      return ChatMessage.botText(
        'Danh sách nguyên liệu của bạn hiện đang trống! 🥗\n\n'
        'Bạn có thể nói hoặc gõ nguyên liệu bạn muốn thêm (ví dụ: *"Thêm 300g ức gà, 4 quả trứng và 2 củ khoai tây"*), tôi sẽ thêm ngay vào tab Nguyên liệu cho bạn.'
      );
    }

    int totalCalories = 0;
    double totalProtein = 0;
    for (final item in items) {
      final kcal = (item['kcalPer100g'] ?? 100) as num;
      final w = (item['weight'] ?? 100) as num;
      totalCalories += (kcal * w / 100).round();
      totalProtein += (((item['protein'] as num?) ?? 10) * w / 100);
    }

    final summary = 'Tab Nguyên liệu của bạn hiện có **${items.length} món**:\n'
        '🔥 Tổng năng lượng: **$totalCalories kcal**\n'
        '💪 Tổng Protein: **${totalProtein.round()}g đạm**\n\n'
        'Dưới đây là các thực phẩm sẵn sàng để bạn chế biến hoặc gợi ý món ăn:';

    return ChatMessage.botIngredients(
      text: summary,
      ingredients: items.map((i) => VoiceIngredientResult(
        name: i['name']?.toString() ?? '',
        rawSpokenText: '',
        icon: i['icon']?.toString() ?? '🥗',
        weight: (i['weight'] as num?)?.toInt() ?? 100,
        kcalPer100g: (i['kcalPer100g'] as num?)?.toInt() ?? 100,
        protein: ((i['protein'] as num?) ?? 10).toDouble(),
        carbs: ((i['carbs'] as num?) ?? 5).toDouble(),
        fat: ((i['fat'] as num?) ?? 3).toDouble(),
      )).toList(),
    );
  }

  static bool _isCarbCyclingIntent(String text) {
    final keywords = [
      'carb cycling',
      'thực đơn tuần',
      'kế hoạch thực đơn tuần',
      'lên kế hoạch thực đơn tuần',
      'lên kế hoạch thực đơn',
      'kế hoạch tuần',
      'lịch ăn tuần',
      'lập lịch ăn',
      'chu kỳ tập',
      'chu kỳ tập luyện',
      'tập nặng chân lưng',
      'tăng tinh bột',
      'hạ thấp carb',
      'xoay vòng carb',
      'chân/lưng',
      'tập nặng',
      'tinh bột',
    ];
    return keywords.any((k) => text.contains(k));
  }

  static bool _isMealPlanIntent(String text) {
    final keywords = [
      'lập thực đơn',
      'lên thực đơn',
      'tạo thực đơn',
      'kế hoạch ăn',
      'lập kế hoạch ăn',
      'lên lịch ăn',
      'tạo lịch',
      'thực đơn tăng cơ',
      'thực đơn giảm mỡ',
      'thực đơn từ tủ lạnh',
      'thực đơn có sẵn',
      'meal prep',
      'meal plan',
      'lập lịch',
      'thực đơn',
    ];
    return keywords.any((k) => text.contains(k));
  }

  static Future<ChatMessage> generateCarbCyclingMealPlan({
    required String prompt,
  }) async {
    double baselineKcal = 2200;
    try {
      final profile = await ApiService.getProfile();
      if (profile != null && profile['tdeeKcal'] != null) {
        baselineKcal = (profile['tdeeKcal'] as num).toDouble();
      }
    } catch (_) {}

    final weeklyPlan = CarbCyclingService.generateWeeklyPlan(
      baselineKcal: baselineKcal,
      presetId: 'standard_4day',
    );

    final List<Map<String, dynamic>> days = [];
    int totalKcalSum = 0;
    int totalProSum = 0;
    int totalCarbsSum = 0;
    int totalFatSum = 0;

    for (final day in weeklyPlan) {
      int dayKcal = 0;
      int dayPro = 0;
      int dayCarbs = 0;
      int dayFat = 0;

      final mealsList = day.meals.map((m) {
        final kcal = (m['kcal'] as num?)?.toInt() ?? 0;
        final pro = (m['protein'] as num?)?.toInt() ?? 0;
        final carbs = (m['carbs'] as num?)?.toInt() ?? 0;
        final fat = (m['fat'] as num?)?.toInt() ?? 0;

        dayKcal += kcal;
        dayPro += pro;
        dayCarbs += carbs;
        dayFat += fat;

        final ings = (m['ingredients'] as List? ?? []).map((i) {
          final s = i.toString();
          return {'name': s, 'amount': 100, 'unit': 'g'};
        }).toList();

        return {
          'type': m['mealType'] ?? 'Bữa ăn',
          'name': m['name'] ?? '',
          'kcal': kcal,
          'protein': pro,
          'carbs': carbs,
          'fat': fat,
          'carbBadge': m['carbBadge'],
          'ingredients': ings,
        };
      }).toList();

      totalKcalSum += dayKcal;
      totalProSum += dayPro;
      totalCarbsSum += dayCarbs;
      totalFatSum += dayFat;

      days.add({
        'dayName': day.dayName,
        'date': '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}',
        'workoutType': day.dayType.name,
        'workoutTypeName': day.dayType.label,
        'workoutFocus': day.focus,
        'carbLevel': day.dayType.carbLevel,
        'carbBadge': day.dayType.carbBadge,
        'targetKcal': day.targetKcal,
        'targetCarbs': day.targetCarbs,
        'targetProtein': day.targetProtein,
        'targetFat': day.targetFat,
        'cookType': day.dayType.carbLevel,
        'notes': '${day.dayType.carbBadge} • ${day.focus}',
        'meals': mealsList,
      });
    }

    final avgDailyKcal = (totalKcalSum / days.length).round();
    final avgDailyPro = (totalProSum / days.length).round();
    final avgDailyCarbs = (totalCarbsSum / days.length).round();
    final avgDailyFat = (totalFatSum / days.length).round();

    final mealPlanData = {
      'planType': 'carb_cycling',
      'planTypeName': 'Kế Hoạch Thực Đơn Tuần (Carb Cycling)',
      'targetGoal': 'Carb Cycling theo Chu kỳ Tập luyện',
      'isCarbCycling': true,
      'targetCalories': baselineKcal.round(),
      'targetProtein': ((baselineKcal * 0.28) / 4).round(),
      'avgDailyKcal': avgDailyKcal,
      'avgDailyPro': avgDailyPro,
      'avgDailyCarbs': avgDailyCarbs,
      'avgDailyFat': avgDailyFat,
      'days': days,
      'isConfirmedAndSaved': false,
    };

    final introText =
        '🤖 **NutriGym AI đã lập xong Kế hoạch Thực Đơn Tuần Carb Cycling cho bạn!**\n\n'
        'Thực đơn 7 ngày bám sát chu kỳ tập luyện với cơ chế khoa học thể hình:\n'
        '• 🔥 **Ngày tập nặng (Chân/Lưng)**: Tự động TĂNG tinh bột (High Carb) để nạp đầy glycogen cơ bắp, hỗ trợ đẩy tạ nặng & phục hồi tối đa.\n'
        '• ⚡ **Ngày tập nhẹ (Ngực/Tay/Vai)**: Giữ mức tinh bột VỪA PHẢI (Moderate Carb) cân bằng năng lượng.\n'
        '• 🌿 **Ngày nghỉ ngơi**: HẠ THẤP tinh bột (Low Carb), tăng chất béo tốt để kích hoạt đốt mỡ tự nhiên và tăng độ nhạy insulin.\n\n'
        'Bạn có thể nhấn **XÁC NHẬN & LƯU VÀO LỊCH** bên dưới để đồng bộ vào Lịch Ăn!';

    return ChatMessage.botMealPlan(
      text: introText,
      mealPlanData: mealPlanData,
    );
  }

  static Future<ChatMessage> generateMealPlan({
    required String prompt,
    bool forceFromFridge = false,
    Map<String, dynamic>? customOptions,
  }) async {
    final profile = await ApiService.getLocalProfile();
    final prefs = await SharedPreferences.getInstance();
    final userId = await ApiService.getUserId() ?? 'guest';
    final fridgeJson = prefs.getString('smart_fridge_items_$userId');
    List<Map<String, dynamic>> fridgeItems = [];
    if (fridgeJson != null && fridgeJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(fridgeJson);
        fridgeItems = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    final lower = prompt.toLowerCase();
    final String sourceMode = customOptions?['sourceMode']?.toString() ??
        (forceFromFridge || customOptions?['forceFromFridge'] == true
            ? (lower.contains('bù đắp') || lower.contains('kết hợp') ? 'hybrid' : 'fridge_only')
            : (lower.contains('tủ lạnh') || lower.contains('có sẵn') ? 'hybrid' : 'market_only'));
    final bool isFromFridge = sourceMode == 'fridge_only';

    // 1. Mục tiêu thể hình
    String goal = customOptions?['goal']?.toString() ??
        (lower.contains('giảm mỡ') || lower.contains('cutting') || lower.contains('siết')
            ? 'Giảm mỡ'
            : (lower.contains('tăng cơ') || lower.contains('bulking') || lower.contains('tăng cân')
                ? 'Tăng cơ'
                : (lower.contains('duy trì')
                    ? 'Duy trì vóc dáng'
                    : (profile?['fitnessGoal']?.toString() ?? prefs.getString('user_custom_goal') ?? 'Tăng cơ'))));

    // 2. Số ngày lên lịch (3, 5, hoặc 7 ngày)
    final int daysCount = (customOptions?['daysCount'] as num?)?.toInt() ??
        (lower.contains('7 ngày') || lower.contains('cả tuần') || lower.contains('1 tuần')
            ? 7
            : (lower.contains('5 ngày') ? 5 : 3));

    // 3. Chế độ chuẩn bị (prepMode)
    final String prepMode = customOptions?['prepMode']?.toString() ??
        (lower.contains('toàn bộ') || lower.contains('100%')
            ? 'full_prep'
            : (lower.contains('nấu tươi')
                ? 'fresh'
                : (lower.contains('carb cycling') ? 'carb_cycling' : 'hybrid')));

    // 4. Dị ứng & Bệnh lý
    final List<String> rawAllergies = customOptions?['allergies'] != null
        ? List<String>.from(customOptions!['allergies'])
        : (prefs.getStringList('food_allergies') ??
            prefs.getStringList('user_allergies') ??
            (profile?['allergies'] != null ? List<String>.from(profile!['allergies']) : <String>[]));

    final List<String> rawMedical = customOptions?['medicalHistory'] != null
        ? List<String>.from(customOptions!['medicalHistory'])
        : (prefs.getStringList('medical_history') ??
            (profile?['medicalHistory'] != null ? List<String>.from(profile!['medicalHistory']) : <String>[]));

    final List<String> activeAllergies = rawAllergies.where((a) => !a.toLowerCase().contains('không có')).toList();
    final List<String> activeMedical = rawMedical.where((m) => !m.toLowerCase().contains('không có')).toList();

    // 5. TDEE & Target Calories
    final double tdee = (profile?['tdeeKcal'] as num?)?.toDouble() ?? 2200;
    int targetCalories = 2200;
    int targetProtein = 140;

    final bool hasKidneyIssue = activeMedical.any((m) => m.toLowerCase().contains('thận'));

    if (goal == 'Tăng cơ') {
      targetCalories = (tdee + 300).round();
      targetProtein = hasKidneyIssue ? 95 : 150;
    } else if (goal == 'Giảm mỡ') {
      targetCalories = (tdee - 400).round();
      targetProtein = hasKidneyIssue ? 90 : 160;
    } else {
      targetCalories = tdee.round();
      targetProtein = hasKidneyIssue ? 85 : 130;
    }

    // 6. Xây dựng danh sách cảnh báo & biện pháp an toàn (Safeguards)
    final List<String> safeguards = [];
    for (final med in activeMedical) {
      final ml = med.toLowerCase();
      if (ml.contains('gout') || ml.contains('purin')) {
        safeguards.add('🩺 Kiêng Gout: Đã loại trừ thịt bò, thịt đỏ đậm, nội tạng và hải sản giàu purin.');
      } else if (ml.contains('tiểu đường')) {
        safeguards.add('🩺 Kiêng Tiểu đường: Loại bỏ đường tinh luyện & carbs nhanh; ưu tiên yến mạch, gạo lứt, khoai lang.');
      } else if (ml.contains('dạ dày') || ml.contains('trào ngược')) {
        safeguards.add('🩺 Kiêng Đau dạ dày: Chế biến hấp luộc thanh đạm, loại bỏ gia vị cay nồng và đồ chiên ngập dầu.');
      } else if (ml.contains('mỡ máu') || ml.contains('huyết áp')) {
        safeguards.add('🩺 Kiêng Mỡ máu & Tim mạch: Hạn chế mỡ động vật & muối natri, bổ sung cá béo Omega-3.');
      } else if (ml.contains('thận')) {
        safeguards.add('🩺 Kiêng Bệnh thận: Kiểm soát lượng đạm tối ưu (dưới 95g/ngày) để giảm tải cho thận.');
      } else {
        safeguards.add('🩺 Chế độ ăn kiêng cho tình trạng: $med.');
      }
    }
    if (activeAllergies.isNotEmpty) {
      safeguards.add('🛡️ Dị ứng thực phẩm: Đã loại bỏ hoàn toàn ${activeAllergies.join(', ')}.');
    }

    // 7. Đồng bộ công thức từ Database Backend & Bộ công thức Gymer chuẩn an toàn
    List<Map<String, dynamic>> dbRecipes = [];
    try {
      dbRecipes = await ApiService.getRecipes();
    } catch (_) {}

    // Lọc công thức database theo dị ứng và bệnh lý
    final List<Map<String, dynamic>> safeDbRecipes = dbRecipes.where((r) {
      return _isRecipeSafeForUser(
        recipe: r,
        activeAllergies: activeAllergies,
        activeMedical: activeMedical,
      );
    }).toList();

    // Lấy pool công thức dự phòng chuẩn Gymer (đã lọc sạch theo dị ứng và bệnh lý)
    final List<Map<String, dynamic>> safeCurated = getSafeCuratedRecipes(
      activeAllergies: activeAllergies,
      activeMedical: activeMedical,
    );

    // Ghép database recipes với curated recipes để đảm bảo đủ món cho cả tuần
    List<Map<String, dynamic>> allCandidateRecipes = [
      ...safeDbRecipes,
      ...safeCurated,
    ];

    // Xử lý nguồn nguyên liệu (sourceMode):
    if (sourceMode == 'fridge_only') {
      // 1. Chỉ dùng nguyên liệu có sẵn trong tủ lạnh
      if (fridgeItems.isNotEmpty) {
        final fridgeNames = fridgeItems.map((f) => f['name']?.toString().toLowerCase() ?? '').toList();
        final matched = allCandidateRecipes.where((r) {
          final rawIngs = r['ingredients'];
          if (rawIngs is List) {
            return rawIngs.any((ing) {
              final ingName = (ing is Map ? ing['name'] : ing?.toString())?.toString().toLowerCase() ?? '';
              return fridgeNames.any((fn) => fn.isNotEmpty && (fn.contains(ingName) || ingName.contains(fn)));
            });
          }
          return false;
        }).toList();
        if (matched.isNotEmpty) {
          allCandidateRecipes = matched;
        }
      }
    } else if (sourceMode == 'hybrid') {
      // 2. Tối ưu tủ lạnh và mua nguyên liệu bù đắp:
      // Ưu tiên các công thức có nguyên liệu trùng với tủ lạnh lên đầu,
      // các món khác bổ sung đầy đủ từ kho công thức Gymer
      if (fridgeItems.isNotEmpty) {
        final fridgeNames = fridgeItems.map((f) => f['name']?.toString().toLowerCase() ?? '').toList();
        allCandidateRecipes.sort((a, b) {
          int countOverlap(Map<String, dynamic> r) {
            final rawIngs = r['ingredients'];
            if (rawIngs is List) {
              return rawIngs.where((ing) {
                final ingName = (ing is Map ? ing['name'] : ing?.toString())?.toString().toLowerCase() ?? '';
                return fridgeNames.any((fn) => fn.isNotEmpty && (fn.contains(ingName) || ingName.contains(fn)));
              }).length;
            }
            return 0;
          }
          return countOverlap(b).compareTo(countOverlap(a));
        });
      }
    }

    // Phân loại món theo khung giờ
    final List<Map<String, dynamic>> breakfastPool = allCandidateRecipes.where((r) {
      final t = (r['mealType'] ?? r['type'] ?? r['tags']?.toString() ?? '').toLowerCase();
      final n = (r['title'] ?? r['name'] ?? '').toLowerCase();
      return t.contains('breakfast') || t.contains('sáng') || n.contains('yến mạch') || n.contains('bánh mì') || n.contains('sinh tố') || n.contains('trứng');
    }).toList();
    if (breakfastPool.isEmpty) breakfastPool.addAll(safeCurated.take(4));

    final List<Map<String, dynamic>> lunchPool = allCandidateRecipes.where((r) {
      final t = (r['mealType'] ?? r['type'] ?? r['tags']?.toString() ?? '').toLowerCase();
      final n = (r['title'] ?? r['name'] ?? '').toLowerCase();
      return t.contains('lunch') || t.contains('trưa') || n.contains('cơm') || n.contains('áp chảo') || n.contains('xào') || n.contains('hấp');
    }).toList();
    if (lunchPool.isEmpty) lunchPool.addAll(safeCurated.skip(2).take(4));

    final List<Map<String, dynamic>> dinnerPool = allCandidateRecipes.where((r) {
      final t = (r['mealType'] ?? r['type'] ?? r['tags']?.toString() ?? '').toLowerCase();
      final n = (r['title'] ?? r['name'] ?? '').toLowerCase();
      return t.contains('dinner') || t.contains('tối') || n.contains('nướng') || n.contains('salad') || n.contains('canh') || n.contains('khoai');
    }).toList();
    if (dinnerPool.isEmpty) dinnerPool.addAll(safeCurated.skip(4).take(4));

    final List<Map<String, dynamic>> snackPool = allCandidateRecipes.where((r) {
      final t = (r['mealType'] ?? r['type'] ?? r['tags']?.toString() ?? '').toLowerCase();
      final n = (r['title'] ?? r['name'] ?? '').toLowerCase();
      return t.contains('snack') || t.contains('phụ') || n.contains('luộc') || n.contains('hạt') || n.contains('whey') || n.contains('sữa chua');
    }).toList();
    if (snackPool.isEmpty) snackPool.addAll(safeCurated.skip(6).take(4));

    // 8. Tạo danh sách các ngày theo daysCount và prepMode
    final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ Nhật'];
    final List<Map<String, dynamic>> days = [];

    for (int dayIdx = 0; dayIdx < daysCount; dayIdx++) {
      final dayName = dayNames[dayIdx % 7];
      final dateStr = dayIdx == 0 ? 'Hôm nay' : (dayIdx == 1 ? 'Ngày mai' : 'Ngày ${dayIdx + 1}');

      bool isMealPrepDay = false;
      String cookType = 'Nấu tươi theo bữa';
      String notes = 'Nấu tươi nhanh gọn 15-20 phút';
      String? defrostAlert;

      if (prepMode == 'full_prep') {
        isMealPrepDay = true;
        cookType = 'Meal Prep cấp đông (Hâm nóng 3p)';
        notes = 'Hộp Meal Prep dinh dưỡng đã nấu sẵn. Tối hôm trước rã đông, hôm sau chỉ cần hâm nóng!';
        defrostAlert = '💡 Tự động nhắc rã đông lúc 20:00 tối trước ngày ăn';
      } else if (prepMode == 'fresh') {
        isMealPrepDay = false;
        cookType = 'Nấu tươi theo bữa';
        notes = 'Nấu tươi từng bữa bảo đảm độ tươi ngon và nhiệt độ lý tưởng.';
      } else if (prepMode == 'carb_cycling') {
        if (dayIdx == 0 || dayIdx == 3) {
          cookType = 'Ngày tập nặng (Chân/Lưng) - Tăng Carb';
          notes = 'Tăng cường 50% Carbs phức để tối đa hóa glycogen và phục hồi sợi cơ lớn.';
        } else if (dayIdx == 2 || dayIdx == 6) {
          cookType = 'Ngày nghỉ (Rest) - Hạ thấp Carb';
          notes = 'Hạ Carb xuống 20%, tăng Protein & Fat tốt để kích hoạt chuyển hóa mỡ.';
        } else {
          cookType = 'Ngày tập vừa (Ngực/Vai/Tay) - Carb vừa phải';
          notes = 'Cân bằng 35% Carbs, 30% Protein và 35% Fat ổn định năng lượng.';
        }
      } else {
        // Hybrid mode (kết hợp)
        if (dayIdx == 0) {
          cookType = 'Nấu tươi theo bữa';
          notes = 'Đầu tuần nấu tươi nhanh 20 phút nạp năng lượng tràn đầy.';
        } else if (dayIdx == 1) {
          isMealPrepDay = true;
          cookType = 'Nấu Meal Prep trước cho hôm sau';
          notes = '💡 Nấu sẵn 2 hộp trưa và tối cho ngày bận. Tự động hẹn rã đông lúc 20:00.';
          defrostAlert = '💡 Tối nay rã đông hộp Meal Prep lúc 20:00';
        } else if (dayIdx == 2) {
          isMealPrepDay = true;
          cookType = 'Hâm nóng Meal Prep đã nấu';
          notes = '✅ Ngày bận rộn: Hâm nóng hộp Meal Prep chỉ 3 phút là có bữa ăn chuẩn Macros.';
        } else if (dayIdx == 3) {
          cookType = 'Nấu tươi theo bữa';
          notes = 'Nấu tươi bữa tối đổi vị thanh mát.';
        } else if (dayIdx == 4) {
          isMealPrepDay = true;
          cookType = 'Nấu Meal Prep trước cho Thứ 6';
          notes = 'Chuẩn bị trước 2 hộp cho ngày làm việc cuối tuần.';
          defrostAlert = '💡 Tối nay rã đông hộp Meal Prep lúc 20:00';
        } else if (dayIdx == 5) {
          isMealPrepDay = true;
          cookType = 'Hâm nóng Meal Prep đã nấu';
          notes = 'Thưởng thức hộp Meal Prep tiện lợi ngày Thứ 6.';
        } else {
          cookType = 'Nấu tươi & Chuẩn bị tuần mới';
          notes = 'Nấu tươi thư thả cuối tuần và sơ chế nguyên liệu tuần kế tiếp.';
        }
      }

      // Chọn món cho từng bữa
      final bRecipe = breakfastPool[dayIdx % breakfastPool.length];
      final lRecipe = lunchPool[dayIdx % lunchPool.length];
      final dRecipe = dinnerPool[dayIdx % dinnerPool.length];
      final sRecipe = snackPool[dayIdx % snackPool.length];

      int getRecipeBaseKcal(Map<String, dynamic> r) {
        return (r['kcal'] is num) ? (r['kcal'] as num).round() : ((r['calories'] is num) ? (r['calories'] as num).round() : 400);
      }

      final int baseDayKcal = getRecipeBaseKcal(bRecipe) +
          getRecipeBaseKcal(lRecipe) +
          getRecipeBaseKcal(dRecipe) +
          getRecipeBaseKcal(sRecipe);

      double scaleFactor = 1.0;
      if (sourceMode == 'hybrid' || sourceMode == 'market_only') {
        // Bắt buộc đạt đủ ngưỡng Calo mục tiêu (Target Calories)
        int dayTargetKcal = targetCalories;
        if (prepMode == 'carb_cycling') {
          if (dayIdx == 0 || dayIdx == 3) {
            dayTargetKcal = (targetCalories * 1.08).round();
          } else if (dayIdx == 2 || dayIdx == 6) {
            dayTargetKcal = (targetCalories * 0.92).round();
          }
        }
        if (baseDayKcal > 0) {
          scaleFactor = dayTargetKcal / baseDayKcal;
        }
      }

      days.add({
        'dayName': dayName,
        'date': dateStr,
        'isMealPrep': isMealPrepDay,
        'cookType': cookType,
        'notes': notes,
        if (defrostAlert != null) 'defrostAlert': defrostAlert,
        'meals': [
          _formatRecipeForMeal(bRecipe, 'Bữa Sáng', scaleFactor: scaleFactor),
          _formatRecipeForMeal(lRecipe, isMealPrepDay ? 'Bữa Trưa (Meal Prep)' : 'Bữa Trưa', scaleFactor: scaleFactor),
          _formatRecipeForMeal(dRecipe, isMealPrepDay ? 'Bữa Tối (Meal Prep)' : 'Bữa Tối', scaleFactor: scaleFactor),
          _formatRecipeForMeal(sRecipe, 'Bữa Phụ', scaleFactor: scaleFactor),
        ],
      });
    }

    // 9. Tính tổng và trung bình Macros
    int totalKcalSum = 0;
    int totalProSum = 0;
    int totalCarbsSum = 0;
    int totalFatSum = 0;

    final Map<String, int> ingredientNeeds = {};
    for (final day in days) {
      for (final meal in day['meals'] as List) {
        totalKcalSum += (meal['kcal'] as num).toInt();
        totalProSum += (meal['protein'] as num).toInt();
        totalCarbsSum += (meal['carbs'] as num).toInt();
        totalFatSum += (meal['fat'] as num).toInt();

        final ings = meal['ingredients'] as List? ?? [];
        for (final ing in ings) {
          final name = ing['name'].toString();
          final amount = (ing['amount'] as num).toInt();
          ingredientNeeds[name] = (ingredientNeeds[name] ?? 0) + amount;
        }
      }
    }

    final avgDailyKcal = (totalKcalSum / days.length).round();
    final avgDailyPro = (totalProSum / days.length).round();
    final avgDailyCarbs = (totalCarbsSum / days.length).round();
    final avgDailyFat = (totalFatSum / days.length).round();

    // 10. Kiểm tra ngưỡng Calo
    final diffKcal = avgDailyKcal - targetCalories;
    final bool hasThresholdWarning = diffKcal.abs() > 250;
    String thresholdWarningText = '';
    if (hasThresholdWarning) {
      if (diffKcal > 0) {
        thresholdWarningText = '⚠️ CẢNH BÁO NGƯỠNG: Calo thực đơn ($avgDailyKcal kcal/ngày) cao hơn $diffKcal kcal so với mục tiêu ($targetCalories kcal). Có thể dư calo nếu đang siết cơ!';
      } else {
        thresholdWarningText = '⚠️ CẢNH BÁO NGƯỠNG: Calo thực đơn ($avgDailyKcal kcal/ngày) thiếu ${diffKcal.abs()} kcal so với mục tiêu ($targetCalories kcal). Thâm hụt quá sâu có thể làm mất cơ!';
      }
    }

    // 11. Tính toán danh sách mua sắm so với Tủ Lạnh
    final List<Map<String, dynamic>> shoppingList = [];
    ingredientNeeds.forEach((name, neededGrams) {
      int inFridgeGrams = 0;
      if (sourceMode != 'market_only') {
        for (final f in fridgeItems) {
          final fName = f['name']?.toString().toLowerCase() ?? '';
          if (fName.contains(name.toLowerCase()) || name.toLowerCase().contains(fName)) {
            inFridgeGrams += ((f['weight'] as num?)?.toInt() ?? 0);
          }
        }
      }

      final int toBuyGrams = neededGrams > inFridgeGrams ? (neededGrams - inFridgeGrams) : 0;
      final details = IngredientNormalizer.getIngredientDetails(name);

      shoppingList.add({
        'name': name,
        'needed': neededGrams,
        'inFridge': inFridgeGrams,
        'toBuy': toBuyGrams,
        'unit': 'g',
        'icon': details['icon'] ?? '🥗',
        'isShortfall': toBuyGrams > 0,
      });
    });

    shoppingList.sort((a, b) {
      if (a['isShortfall'] == true && b['isShortfall'] != true) return -1;
      if (a['isShortfall'] != true && b['isShortfall'] == true) return 1;
      return (b['toBuy'] as num).compareTo(a['toBuy'] as num);
    });

    String planModeTitle = 'Kết hợp Meal Prep & Nấu tươi';
    if (prepMode == 'full_prep') {
      planModeTitle = 'Meal Prep toàn bộ (Cấp đông)';
    } else if (prepMode == 'fresh') {
      planModeTitle = 'Nấu tươi mỗi ngày';
    } else if (prepMode == 'carb_cycling') {
      planModeTitle = 'Carb Cycling chu kỳ tập luyện';
    }

    String planTypeName = 'Kế hoạch Thực Đơn';
    String introText = '';
    if (sourceMode == 'hybrid') {
      planTypeName = 'Tối ưu Tủ Lạnh & Mua Bù Đắp';
      introText = '🤖 **NutriGym AI đã lập Kế Hoạch Kết Hợp Tủ Lạnh & Đi Chợ ($daysCount ngày)!**\n\n'
          'Mục tiêu: **$goal** • Chế độ: **$planModeTitle**\n'
          'Macros TB: **${avgDailyKcal} kcal / ${avgDailyPro}g Protein / ${avgDailyCarbs}g Carbs / ${avgDailyFat}g Fat** (Đã đạt đủ 100% Calo mục tiêu).\n\n'
          'Thực đơn ưu tiên dùng đồ có sẵn trong tủ lạnh và bổ sung nguyên liệu mua bù đắp để đảm bảo năng lượng thể hình.\n'
          '${safeguards.isNotEmpty ? '\n' + safeguards.join('\n') + '\n\n' : ''}'
          'Bạn có thể bấm **Chỉnh sửa thực đơn** để đổi món bất kỳ lúc nào.';
    } else if (sourceMode == 'market_only') {
      planTypeName = 'Đi Chợ Mua Mới Toàn Bộ';
      introText = '🤖 **NutriGym AI đã lập Kế Hoạch Thực Đơn Đi Chợ Toàn Bộ ($daysCount ngày)!**\n\n'
          'Mục tiêu: **$goal** • Chế độ: **$planModeTitle**\n'
          'Macros TB: **${avgDailyKcal} kcal / ${avgDailyPro}g Protein / ${avgDailyCarbs}g Carbs / ${avgDailyFat}g Fat** (Đã đạt đủ 100% Calo mục tiêu).\n\n'
          'Thực đơn sử dụng kho công thức phong phú chuẩn Gymer, toàn bộ nguyên liệu được lên danh sách đi chợ mới.\n'
          '${safeguards.isNotEmpty ? '\n' + safeguards.join('\n') + '\n\n' : ''}'
          'Bạn có thể bấm **Chỉnh sửa thực đơn** để đổi món bất kỳ lúc nào.';
    } else {
      planTypeName = 'Tối ưu từ Tủ Lạnh có sẵn';
      introText = '🤖 **NutriGym AI đã lập xong Thực Đơn Tối Ưu từ Tủ Lạnh ($daysCount ngày)!**\n\n'
          'Thực đơn được thiết kế cho mục tiêu **$goal** (${targetCalories} kcal, ${targetProtein}g đạm/ngày) với chế độ **$planModeTitle**.\n'
          '${safeguards.isNotEmpty ? '\n' + safeguards.join('\n') + '\n\n' : ''}'
          'Bạn có thể bấm **Chỉnh sửa thực đơn** để đổi món hoặc sửa calo trước khi lưu vào Lịch!';
    }

    final mealPlanData = {
      'sourceMode': sourceMode,
      'planType': sourceMode,
      'planTypeName': planTypeName,
      'targetGoal': goal,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'daysCount': daysCount,
      'prepMode': prepMode,
      'avgDailyKcal': avgDailyKcal,
      'avgDailyPro': avgDailyPro,
      'avgDailyCarbs': avgDailyCarbs,
      'avgDailyFat': avgDailyFat,
      'hasThresholdWarning': hasThresholdWarning,
      'thresholdWarning': thresholdWarningText,
      'medicalHistory': activeMedical,
      'allergies': activeAllergies,
      'safeguards': safeguards,
      'allergiesNote': activeAllergies.isNotEmpty ? activeAllergies.join(', ') : 'Không có',
      'medicalNote': activeMedical.isNotEmpty ? activeMedical.join(', ') : 'Bình thường',
      'days': days,
      'shoppingList': shoppingList,
      'isConfirmedAndSaved': false,
      'isCarbCycling': prepMode == 'carb_cycling',
    };

    return ChatMessage.botMealPlan(
      text: introText,
      mealPlanData: mealPlanData,
    );
  }

  // ---------------------------------------------------------------------------
  // Bộ kiểm tra an toàn dinh dưỡng & Danh mục công thức lành mạnh
  // ---------------------------------------------------------------------------

  static bool _isRecipeSafeForUser({
    required Map<String, dynamic> recipe,
    required List<String> activeAllergies,
    required List<String> activeMedical,
  }) {
    final title = (recipe['title'] ?? recipe['name'] ?? '').toString().toLowerCase();
    final ingredients = recipe['ingredients'];
    final List<String> ingNames = [];
    if (ingredients is List) {
      for (final item in ingredients) {
        if (item is Map) {
          ingNames.add((item['name'] ?? '').toString().toLowerCase());
        } else if (item is String) {
          ingNames.add(item.toLowerCase());
        }
      }
    }
    final allText = '$title ${ingNames.join(' ')}';

    // 1. Kiểm tra dị ứng
    for (final alg in activeAllergies) {
      final a = alg.toLowerCase();
      if (a.contains('không có')) continue;

      if (a.contains('hải sản') || a.contains('tôm') || a.contains('cua') || a.contains('mực')) {
        if (allText.contains('hải sản') || allText.contains('tôm') || allText.contains('cua') || 
            allText.contains('mực') || allText.contains('cá hồi') || allText.contains('bạch tuộc') ||
            allText.contains('sò') || allText.contains('nghêu') || allText.contains('cá biển')) {
          return false;
        }
      }
      if (a.contains('đậu phộng') || a.contains('lạc')) {
        if (allText.contains('đậu phộng') || allText.contains('lạc') || allText.contains('bơ đậu phộng')) {
          return false;
        }
      }
      if (a.contains('sữa') || a.contains('lactose')) {
        if (allText.contains('sữa bò') || allText.contains('phô mai') || allText.contains('bơ lạt') || 
            (allText.contains('sữa chua') && !allText.contains('không đường'))) {
          return false;
        }
      }
      if (a.contains('trứng')) {
        if (allText.contains('trứng gà') || allText.contains('trứng vịt') || allText.contains('lòng đỏ') || allText.contains('lòng trắng')) {
          return false;
        }
      }
      if (a.contains('gluten') || a.contains('bột mì')) {
        if (allText.contains('bánh mì') || allText.contains('bột mì') || allText.contains('mì ý') || allText.contains('nui')) {
          return false;
        }
      }
      if (a.contains('đậu nành')) {
        if (allText.contains('đậu nành') || allText.contains('đậu phụ') || allText.contains('đậu hũ')) {
          return false;
        }
      }
    }

    // 2. Kiểm tra bệnh lý
    for (final med in activeMedical) {
      final m = med.toLowerCase();
      if (m.contains('không có')) continue;

      if (m.contains('gout') || m.contains('purin')) {
        if (allText.contains('thịt bò') || allText.contains('thịt thăn bò') || allText.contains('bò nạc') ||
            allText.contains('thịt vịt') || allText.contains('nội tạng') || allText.contains('gan') ||
            allText.contains('tôm') || allText.contains('cua') || allText.contains('mực') || allText.contains('cá hồi')) {
          return false;
        }
      }
      if (m.contains('tiểu đường') || m.contains('đường nhanh')) {
        if (allText.contains('bánh mì trắng') || allText.contains('đường cát') || allText.contains('nước ngọt')) {
          return false;
        }
      }
      if (m.contains('đau dạ dày') || m.contains('trào ngược')) {
        if (allText.contains('tiêu đen') || allText.contains('sốt tiêu') || allText.contains('ớt') || allText.contains('chua cay')) {
          return false;
        }
      }
      if (m.contains('mỡ máu') || m.contains('huyết áp')) {
        if (allText.contains('thịt mỡ') || allText.contains('bơ lạt') || allText.contains('da gà') || allText.contains('thịt ba chỉ')) {
          return false;
        }
      }
    }

    return true;
  }

  static List<Map<String, dynamic>> getSafeCuratedRecipes({
    required List<String> activeAllergies,
    required List<String> activeMedical,
  }) {
    final allCurated = [
      {
        'title': 'Yến mạch ngâm sữa chua Hy Lạp & Chuối tiêu',
        'type': 'Bữa Sáng',
        'kcal': 380,
        'protein': 22,
        'carbs': 55,
        'fat': 6,
        'ingredients': [
          {'name': 'Yến mạch cán dẹt', 'amount': 60, 'unit': 'g'},
          {'name': 'Sữa chua không đường', 'amount': 100, 'unit': 'g'},
          {'name': 'Chuối tiêu chín', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Bánh mì đen nguyên cám nướng trứng ốp & Bơ',
        'type': 'Bữa Sáng',
        'kcal': 410,
        'protein': 20,
        'carbs': 42,
        'fat': 16,
        'ingredients': [
          {'name': 'Bánh mì đen nguyên cám', 'amount': 60, 'unit': 'g'},
          {'name': 'Trứng gà tươi', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Cháo yến mạch thịt ức gà băm rau củ',
        'type': 'Bữa Sáng',
        'kcal': 390,
        'protein': 34,
        'carbs': 46,
        'fat': 7,
        'ingredients': [
          {'name': 'Yến mạch cán dẹt', 'amount': 50, 'unit': 'g'},
          {'name': 'Ức gà phi lê tươi', 'amount': 150, 'unit': 'g'},
          {'name': 'Cà rốt tươi', 'amount': 50, 'unit': 'g'},
        ],
      },
      {
        'title': 'Sinh tố chuối yến mạch đạm đậu nành hạt chia',
        'type': 'Bữa Sáng',
        'kcal': 360,
        'protein': 26,
        'carbs': 52,
        'fat': 5,
        'ingredients': [
          {'name': 'Yến mạch cán dẹt', 'amount': 50, 'unit': 'g'},
          {'name': 'Chuối tiêu chín', 'amount': 100, 'unit': 'g'},
          {'name': 'Hạt chia hữu cơ', 'amount': 15, 'unit': 'g'},
        ],
      },
      {
        'title': 'Ức gà áp chảo sốt mè rang & Cơm gạo lứt',
        'type': 'Bữa Trưa',
        'kcal': 560,
        'protein': 48,
        'carbs': 52,
        'fat': 9,
        'ingredients': [
          {'name': 'Ức gà phi lê tươi', 'amount': 250, 'unit': 'g'},
          {'name': 'Cơm gạo lứt', 'amount': 150, 'unit': 'g'},
          {'name': 'Bông cải xanh', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Thịt thăn bò áp chảo măng tây & Khoai lang luộc',
        'type': 'Bữa Trưa',
        'kcal': 520,
        'protein': 44,
        'carbs': 48,
        'fat': 11,
        'ingredients': [
          {'name': 'Thịt thăn bò nạc', 'amount': 200, 'unit': 'g'},
          {'name': 'Măng tây tươi', 'amount': 100, 'unit': 'g'},
          {'name': 'Khoai lang luộc', 'amount': 150, 'unit': 'g'},
        ],
      },
      {
        'title': 'Phi lê cá hồi áp chảo sốt chanh bơ & Bông cải',
        'type': 'Bữa Trưa',
        'kcal': 540,
        'protein': 40,
        'carbs': 20,
        'fat': 24,
        'ingredients': [
          {'name': 'Phi lê cá hồi tươi', 'amount': 200, 'unit': 'g'},
          {'name': 'Bông cải xanh', 'amount': 150, 'unit': 'g'},
        ],
      },
      {
        'title': 'Tôm sú tươi xào nấm đùi gà & Cơm gạo lứt',
        'type': 'Bữa Trưa',
        'kcal': 490,
        'protein': 42,
        'carbs': 50,
        'fat': 7,
        'ingredients': [
          {'name': 'Tôm sú tươi bóc vỏ', 'amount': 200, 'unit': 'g'},
          {'name': 'Nấm đùi gà', 'amount': 100, 'unit': 'g'},
          {'name': 'Cơm gạo lứt', 'amount': 150, 'unit': 'g'},
        ],
      },
      {
        'title': 'Đậu hũ non áp chảo nấm đông cô & Cơm gạo lứt',
        'type': 'Bữa Trưa',
        'kcal': 460,
        'protein': 32,
        'carbs': 54,
        'fat': 12,
        'ingredients': [
          {'name': 'Đậu hũ trắng tươi', 'amount': 200, 'unit': 'g'},
          {'name': 'Nấm hương tươi', 'amount': 100, 'unit': 'g'},
          {'name': 'Cơm gạo lứt', 'amount': 150, 'unit': 'g'},
        ],
      },
      {
        'title': 'Ức gà cuộn măng tây hấp & Khoai lang luộc',
        'type': 'Bữa Tối',
        'kcal': 510,
        'protein': 46,
        'carbs': 45,
        'fat': 8,
        'ingredients': [
          {'name': 'Ức gà phi lê tươi', 'amount': 250, 'unit': 'g'},
          {'name': 'Măng tây tươi', 'amount': 100, 'unit': 'g'},
          {'name': 'Khoai lang luộc', 'amount': 150, 'unit': 'g'},
        ],
      },
      {
        'title': 'Salad ức gà xé sốt mè rang & Cà chua bi dưa leo',
        'type': 'Bữa Tối',
        'kcal': 420,
        'protein': 42,
        'carbs': 20,
        'fat': 10,
        'ingredients': [
          {'name': 'Ức gà phi lê tươi', 'amount': 200, 'unit': 'g'},
          {'name': 'Dưa leo tươi', 'amount': 100, 'unit': 'g'},
          {'name': 'Cà chua bi', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Canh ức gà hầm củ quả nấm hương thanh đạm',
        'type': 'Bữa Tối',
        'kcal': 450,
        'protein': 38,
        'carbs': 35,
        'fat': 8,
        'ingredients': [
          {'name': 'Ức gà phi lê tươi', 'amount': 200, 'unit': 'g'},
          {'name': 'Cà rốt tươi', 'amount': 80, 'unit': 'g'},
          {'name': 'Bắp ngọt tươi', 'amount': 80, 'unit': 'g'},
        ],
      },
      {
        'title': '2 quả trứng gà luộc lòng đào',
        'type': 'Bữa Phụ',
        'kcal': 150,
        'protein': 14,
        'carbs': 2,
        'fat': 10,
        'ingredients': [
          {'name': 'Trứng gà tươi', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Hạt hạnh nhân rang mộc & Sữa chua không đường',
        'type': 'Bữa Phụ',
        'kcal': 220,
        'protein': 12,
        'carbs': 14,
        'fat': 12,
        'ingredients': [
          {'name': 'Hạt hạnh nhân rang', 'amount': 30, 'unit': 'g'},
          {'name': 'Sữa chua không đường', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Sữa chua Hy Lạp & Chuối tiêu chín',
        'type': 'Bữa Phụ',
        'kcal': 180,
        'protein': 15,
        'carbs': 25,
        'fat': 2,
        'ingredients': [
          {'name': 'Sữa chua không đường', 'amount': 100, 'unit': 'g'},
          {'name': 'Chuối tiêu chín', 'amount': 100, 'unit': 'g'},
        ],
      },
      {
        'title': 'Sinh tố chuối bơ yến mạch hạt chia',
        'type': 'Bữa Phụ',
        'kcal': 240,
        'protein': 10,
        'carbs': 32,
        'fat': 8,
        'ingredients': [
          {'name': 'Chuối tiêu chín', 'amount': 100, 'unit': 'g'},
          {'name': 'Hạt chia hữu cơ', 'amount': 15, 'unit': 'g'},
        ],
      },
    ];

    final filtered = allCurated.where((r) {
      return _isRecipeSafeForUser(
        recipe: r,
        activeAllergies: activeAllergies,
        activeMedical: activeMedical,
      );
    }).toList();

    return filtered.isNotEmpty ? filtered : allCurated;
  }

  static bool _isRecipeIntent(String text) {
    final keywords = [
      'nấu món gì',
      'gợi ý món',
      'công thức',
      'món ngon',
      'ăn gì',
      'chế biến',
      'cách làm',
      'món ăn',
      'nấu gì',
      'làm món gì'
    ];
    return keywords.any((k) => text.contains(k));
  }

  static Future<ChatMessage> _handleRecipeSuggestion(
    String rawText,
    String lower,
    List<Map<String, dynamic>>? availableIngredients,
  ) async {
    List<String> queryIngredients = [];

    // Kiểm tra xem người dùng có nhắc đến nguyên liệu cụ thể trong câu không
    final parsed = VoiceIngredientParser.parseSpokenText(
      rawText,
      availableIngredients: availableIngredients,
    );
    if (parsed.isNotEmpty) {
      queryIngredients = parsed.map((p) => p.name).toList();
    }

    // Nếu không chỉ định nguyên liệu cụ thể, lấy từ danh sách nguyên liệu đã chọn
    if (queryIngredients.isEmpty && availableIngredients != null && availableIngredients.isNotEmpty) {
      queryIngredients = availableIngredients.map((i) => i['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    }

    try {
      var recipes = await ApiService.suggestRecipes(queryIngredients);

      if (recipes.isEmpty) {
        // Fallback: Đồng bộ trực tiếp từ kho Database Recipes
        try {
          final allDb = await ApiService.getRecipes();
          if (allDb.isNotEmpty) {
            if (queryIngredients.isNotEmpty) {
              final queryLower = queryIngredients.map((q) => q.toLowerCase()).toList();
              final matched = allDb.where((r) {
                final t = (r['title'] ?? '').toString().toLowerCase();
                final d = (r['description'] ?? '').toString().toLowerCase();
                final ingList = (r['ingredients'] as List?)?.map((i) => i.toString().toLowerCase()).join(' ') ?? '';
                return queryLower.any((q) => t.contains(q) || d.contains(q) || ingList.contains(q));
              }).toList();
              if (matched.isNotEmpty) {
                recipes = matched;
              }
            }
            if (recipes.isEmpty) {
              recipes = allDb;
            }
          }
        } catch (_) {}
      }

      if (recipes.isEmpty) {
        return ChatMessage.botText(
          'Tôi chưa tìm thấy món ăn phù hợp với danh sách nguyên liệu hiện có. '
          'Bạn thử thêm các nguyên liệu phổ biến như **ức gà, trứng, thịt bò, súp lơ xanh** vào tab Nguyên liệu nhé!'
        );
      }

      final intro = queryIngredients.isNotEmpty
          ? 'Dựa trên nguyên liệu (${queryIngredients.take(4).join(', ')}...), đây là các món ăn giàu dinh dưỡng nhất từ Database gợi ý cho bạn:'
          : 'Dưới đây là các công thức món ăn thể hình chuẩn Macros từ Database gợi ý cho bạn:';

      return ChatMessage.botRecipes(
        text: intro,
        recipes: recipes.take(4).toList(),
      );
    } catch (e) {
      return ChatMessage.botText('Có lỗi khi tìm kiếm công thức gợi ý: $e');
    }
  }

  static bool _isIngredientAddIntent(String text, List<VoiceIngredientResult> ingredients) {
    if (ingredients.isEmpty) return false;

    // Các cụm từ chỉ hành động thêm/khai báo nguyên liệu
    final actionKeywords = [
      'thêm',
      'mua',
      'vừa mua',
      'mới mua',
      'tôi có',
      'mình có',
      'có sẵn',
      'chọn',
      'lấy',
      'nhập',
      'bổ sung',
      'cho vào',
      'cho tôi',
    ];

    if (actionKeywords.any((k) => text.contains(k))) return true;

    // Hoặc câu chứa số lượng đơn vị đo lường/đếm cụ thể (VD: "200g ức gà và 3 quả trứng")
    final hasUnitQuantity = RegExp(
      r'\b\d+(?:[\.,]\d+)?\s*(g|gam|gram|kg|kí|ký|lạng|cân|quả|trái|củ|bắp|hộp|bịch)\b',
      caseSensitive: false,
    ).hasMatch(text);

    final hasWordQuantity = RegExp(
      r'(?:nửa|một|hai|ba|bốn|năm|sáu|bảy|tám|chín|mười|chục|trăm)\s+(?:gam|gram|kg|kí|ký|lạng|cân|quả|trái|củ|bắp|hộp|bịch)',
      caseSensitive: false,
    ).hasMatch(text);

    return hasUnitQuantity || hasWordQuantity;
  }

  static ChatMessage _handleIngredientAdd(List<VoiceIngredientResult> ingredients) {
    int totalKcal = ingredients.fold(0, (sum, i) => sum + i.totalCalories);
    double totalP = ingredients.fold(0.0, (sum, i) => sum + i.totalProtein);

    final summary = 'Tôi đã nhận diện được **${ingredients.length} nguyên liệu** từ yêu cầu của bạn:\n'
        '• Năng lượng: **$totalKcal kcal**\n'
        '• Protein: **${totalP.round()}g đạm**\n\n'
        'Nhấn nút bên dưới để thêm trực tiếp vào tab Nguyên liệu:';

    return ChatMessage.botIngredients(
      text: summary,
      ingredients: ingredients,
    );
  }

  // ---------------------------------------------------------------------------
  // Cơ sở tri thức dinh dưỡng thể hình (Gym Nutrition Knowledge Base)
  // ---------------------------------------------------------------------------

  static String? _matchNutritionAdvice(String text) {
    // 1. Nhu cầu Protein
    if (text.contains('bao nhiêu protein') ||
        text.contains('bao nhiêu đạm') ||
        text.contains('lượng protein') ||
        text.contains('nạp đạm')) {
      return '💪 **Khuyến nghị Protein cho Gymer:**\n\n'
          '• **Tăng cơ (Bulking / Lean Body):** 1.8 – 2.2g protein / kg trọng lượng cơ thể mỗi ngày.\n'
          '  *(Ví dụ: Bạn nặng 70kg thì cần khoảng 130g – 150g protein/ngày)*\n'
          '• **Giảm mỡ giữ cơ (Cutting):** 2.0 – 2.4g protein / kg để chống dị hóa cơ bắp.\n'
          '• **Người tập duy trì sức khỏe:** 1.2 – 1.6g protein / kg.\n\n'
          '💡 *Mẹo:* Hãy chia đều lượng protein thành 4-5 bữa trong ngày (mỗi bữa 25-40g) để cơ thể hấp thu tối đa quá trình tổng hợp protein cơ bắp (MPS).';
    }

    // 2. Bữa ăn trước tập (Pre-workout)
    if (text.contains('trước tập') || text.contains('pre-workout') || text.contains('ăn trước khi tập')) {
      return '⚡ **Bữa ăn lý tưởng trước buổi tập gym:**\n\n'
          '• **Thời điểm:** Ăn trước khi tập từ 1 đến 2 tiếng.\n'
          '• **Nguyên tắc:** Tập trung vào **Carbs phức hợp** (giải phóng năng lượng bền bỉ) + **Protein nạc dễ tiêu** + ít chất béo.\n\n'
          '🥗 **Gợi ý thực đơn nhanh:**\n'
          '1. 1 bát yến mạch nấu sữa chua + 1 quả chuối chín.\n'
          '2. 2 lát bánh mì nguyên cám + 2 quả trứng luộc (hoặc 100g ức gà áp chảo).\n'
          '3. 1 củ khoai lang luộc + 1 muỗng Whey Isolate.\n\n'
          '💧 *Uống đủ 300-500ml nước trước buổi tập 30 phút!*';
    }

    // 3. Bữa ăn sau tập (Post-workout)
    if (text.contains('sau tập') || text.contains('post-workout') || text.contains('ăn sau khi tập')) {
      return '🏆 **Bữa ăn phục hồi sau buổi tập gym:**\n\n'
          '• **Thời điểm vàng:** Trong vòng 30 - 60 phút sau khi kết thúc buổi tập.\n'
          '• **Mục tiêu:** Bù đắp Glycogen cạn kiệt và cung cấp Amino Acids để sửa chữa sợi cơ tổn thương.\n\n'
          '🍗 **Thực đơn vàng:**\n'
          '• **Protein hấp thu nhanh:** 1 muỗng Whey Protein hoặc 150-200g Ức gà / Phi lê cá hồi / Thăn bò.\n'
          '• **Tinh bột hấp thu nhanh:** Cơm trắng, chuối chín, khoai tây nghiền.\n'
          '• **Khoáng chất:** Bổ sung điện giải và nước lọc để chống chuột rút.';
    }

    // 4. Creatine
    if (text.contains('creatine')) {
      return '🧪 **Hướng dẫn sử dụng Creatine Monohydrate chuẩn khoa học:**\n\n'
          '• **Liều lượng:** 3g – 5g mỗi ngày (1 muỗng gạt).\n'
          '• **Thời điểm uống:** Tốt nhất là ngay **sau buổi tập** cùng với bữa ăn có carbs và protein để tăng hấp thu vào cơ bắp.\n'
          '• **Có cần giai đoạn nạp (Loading Phase) không?** Không bắt buộc. Bạn chỉ cần duy trì đều đặn 5g/ngày trong 3-4 tuần là lượng creatine trong cơ sẽ bão hòa.\n'
          '⚠️ *Lưu ý quan trọng:* Creatine hút nước vào tế bào cơ, hãy uống tối thiểu 2.5 - 3 lít nước mỗi ngày!';
    }

    // 5. Tăng cơ (Bulking)
    if (text.contains('tăng cơ') || text.contains('bulk') || text.contains('tăng cân')) {
      return '📈 **Chiến lược Bulking (Tăng cơ nạc) hiệu quả:**\n\n'
          '1. **Thặng dư Calo nhẹ:** Nạp nhiều hơn mức tiêu thụ TDEE khoảng **300 - 500 kcal/ngày** (Clean Bulk) để hạn chế tích mỡ thừa.\n'
          '2. **Tỷ lệ Macro chuẩn:**\n'
          '   • Protein: 2.0g / kg thể trọng.\n'
          '   • Carbs: 4 - 6g / kg thể trọng (Nguồn năng lượng chính để nâng tạ nặng).\n'
          '   • Chất béo tốt: 0.8 - 1g / kg thể trọng (Từ bơ sáp, dầu ô liu, các loại hạt).\n'
          '3. **Ngủ đủ 7-8 tiếng:** Cơ bắp thực sự phát triển trong giấc ngủ sâu!';
    }

    // 6. Giảm mỡ (Cutting)
    if (text.contains('giảm mỡ') || text.contains('cut') || text.contains('giảm cân') || text.contains('siết cơ')) {
      return '🔥 **Chiến lược Cutting (Giảm mỡ giữ cơ) khoa học:**\n\n'
          '1. **Thâm hụt Calo hợp lý:** Giảm **300 - 500 kcal/ngày** so với mức TDEE. Giảm cân bền vững từ 0.5 - 0.7kg/tuần.\n'
          '2. **Tăng cường Protein:** Giữ protein ở mức cao **2.0 - 2.4g / kg** để chống mất cơ khi thâm hụt năng lượng.\n'
          '3. **Chọn thực phẩm thể tích lớn (High Volume):** Tăng cường rau xanh (súp lơ, dưa leo, bắp cải) và trái cây mọng nước để no lâu mà ít calo.\n'
          '4. **Duy trì mức tạ:** Tiếp tục tập tạ nặng để ra tín hiệu cho não bộ giữ lại cơ bắp.';
    }

    // 7. Thực phẩm giàu đạm
    if (text.contains('giàu đạm') ||
        text.contains('nhiều đạm') ||
        text.contains('đạm nhất') ||
        text.contains('thực phẩm giàu đạm') ||
        text.contains('thực phẩm nào giàu đạm') ||
        text.contains('nhiều protein') ||
        text.contains('protein nhất') ||
        text.contains('thức ăn tăng cơ')) {
      return '🥩 **Bảng thực phẩm giàu Protein hàng đầu cho Gymer:**\n\n'
          '• **Ức gà không da:** 31g protein / 100g (165 kcal) — Siêu nạc, tiết kiệm nhất.\n'
          '• **Thăn bò nạc:** 26g protein / 100g (142 kcal) — Giàu sắt, kẽm, creatine tự nhiên.\n'
          '• **Phi lê cá hồi:** 22g protein / 100g (208 kcal) — Giàu Omega-3 kháng viêm.\n'
          '• **Trứng gà:** 6-7g protein / quả (70 kcal) — Giá trị sinh học cao nhất.\n'
          '• **Tôm sú:** 21g protein / 100g (92 kcal) — Cực kỳ ít calo và chất béo.\n'
          '• **Đậu hũ / Đậu nành:** 12-16g protein / 100g — Nguồn đạm thực vật tuyệt vời.\n\n'
          '💡 *Mẹo:* Bạn có thể kết hợp các thực phẩm trên vào thực đơn hàng ngày để đạt mục tiêu nạp 1.8 - 2.2g đạm / kg thể trọng!';
    }

    return null;
  }

  static Map<String, dynamic> _formatRecipeForMeal(Map<String, dynamic> r, String type, {double scaleFactor = 1.0}) {
    final title = (r['title'] ?? r['name'] ?? 'Món ăn').toString();
    final baseKcal = (r['kcal'] is num) ? (r['kcal'] as num).round() : ((r['calories'] is num) ? (r['calories'] as num).round() : 400);
    final basePro = (r['protein'] is num) ? (r['protein'] as num).round() : 30;
    final baseCarb = (r['carbs'] is num) ? (r['carbs'] as num).round() : 30;
    final baseFat = (r['fat'] is num) ? (r['fat'] as num).round() : 10;

    final kcal = (baseKcal * scaleFactor).round();
    final pro = (basePro * scaleFactor).round();
    final carb = (baseCarb * scaleFactor).round();
    final fat = (baseFat * scaleFactor).round();

    final rawIngs = r['ingredients'];
    List<Map<String, dynamic>> parsedIngs = [];
    if (rawIngs is List) {
      for (final item in rawIngs) {
        if (item is Map) {
          final n = (item['name'] ?? '').toString();
          final a = (item['amount'] is num) ? (item['amount'] as num).toInt() : (int.tryParse(item['amount']?.toString() ?? '') ?? 100);
          final u = (item['unit'] ?? 'g').toString();
          if (n.isNotEmpty) {
            final scaledAmount = (a * scaleFactor).round();
            parsedIngs.add({'name': n, 'amount': scaledAmount, 'unit': u});
          }
        } else if (item is String) {
          final scaledAmount = (100 * scaleFactor).round();
          parsedIngs.add({'name': item, 'amount': scaledAmount, 'unit': 'g'});
        }
      }
    }
    if (parsedIngs.isEmpty) {
      final scaledAmount = (150 * scaleFactor).round();
      parsedIngs.add({'name': title, 'amount': scaledAmount, 'unit': 'g'});
    }

    return {
      'type': type,
      'name': title,
      'kcal': kcal,
      'protein': pro,
      'carbs': carb,
      'fat': fat,
      'ingredients': parsedIngs,
    };
  }
}
