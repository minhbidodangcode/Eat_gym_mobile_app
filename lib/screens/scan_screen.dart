import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/recipe.dart';
import '../services/ai/ai_service_factory.dart';
import '../services/ai/food_recognition_service.dart';
import '../services/ai/ingredient_normalizer.dart';
import '../services/ai/meal_recommendation_service.dart';
import '../services/ai/providers/gemini_food_recognition_service.dart';
import '../services/api_service.dart';
import '../services/meal_plan_service.dart';
import '../theme/app_theme.dart';
import 'cooking_timer_screen.dart';
import 'meal_prep_screen.dart';

// Nội dung chính của màn hình Quét
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isFlashOn = false;
  bool _isLoading = false;
  bool _isDishMode = false; // Chế độ quét: false = Quét nguyên liệu, true = Quét đĩa món ăn
  double _confidenceThreshold = 0.4;
  File? _selectedImage;
  List<Recipe> _recommendedRecipes = [];
  List<String> _detectedIngredients = [];

  // Thông tin phân tích đĩa thức ăn
  String? _detectedDishName;
  int? _detectedGrams;
  String? _dishSuggestion;
  int _userMealLimitKcal = 750; // Hạn mức 1 bữa ăn mặc định (~35% TDEE)
  String _userGoal = 'Tăng cơ';

  int _totalKcal = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  // Khởi tạo AI Services
  late final FoodRecognitionService _foodRecognitionService;
  late final MealRecommendationService _recommendationService;

  @override
  void initState() {
    super.initState();
    _foodRecognitionService = AIServiceFactory.createFoodRecognitionService();
    _recommendationService = MealRecommendationService(
      foodRecognitionService: _foodRecognitionService,
      recipeService: AIServiceFactory.createRecipeService(),
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.getProfile() ?? await ApiService.getLocalProfile();
      if (profile != null) {
        final double tdee = (profile['tdeeKcal'] as num?)?.toDouble() ?? 2200;
        final goal = profile['fitnessGoal']?.toString() ?? 'Tăng cơ';
        double target = tdee;
        if (goal.contains('Tăng')) {
          target = tdee + 300;
        } else if (goal.contains('Giảm')) {
          target = tdee - 400;
        }
        if (mounted) {
          setState(() {
            _userGoal = goal;
            // Một bữa ăn chính thường chiếm khoảng 30% - 35% tổng calo trong ngày
            _userMealLimitKcal = (target * 0.35).round();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
        _recommendedRecipes = [];
        _detectedIngredients = [];
        _detectedDishName = null;
        _detectedGrams = null;
        _dishSuggestion = null;
        _totalKcal = 0;
        _totalProtein = 0;
        _totalCarbs = 0;
        _totalFat = 0;
      });

      try {
        if (_isDishMode) {
          // 🍽️ CHẾ ĐỘ QUÉT ĐĨA MÓN ĂN ĐÃ NẤU CHÍN
          final dishData = await _foodRecognitionService.recognizeCookedDish(_selectedImage!);
          if (!mounted) return;

          final dishName = dishData['dishName']?.toString() ?? 'Đĩa thức ăn Gymer';
          final grams = (dishData['estimatedGrams'] as num?)?.toInt() ?? 420;
          final kcal = (dishData['calories'] as num?)?.toInt() ?? 550;
          final pro = (dishData['protein'] as num?)?.toDouble() ?? 40.0;
          final carb = (dishData['carbs'] as num?)?.toDouble() ?? 50.0;
          final fat = (dishData['fat'] as num?)?.toDouble() ?? 12.0;
          final ingList = dishData['ingredients'] is List
              ? (dishData['ingredients'] as List).map((e) => e.toString()).toList()
              : <String>[];
          final suggestion = dishData['suggestion']?.toString() ?? 'Bữa ăn cân đối chuẩn macro Gymer.';

          setState(() {
            _detectedDishName = dishName;
            _detectedGrams = grams;
            _totalKcal = kcal;
            _totalProtein = pro;
            _totalCarbs = carb;
            _totalFat = fat;
            _detectedIngredients = ingList;
            _dishSuggestion = suggestion;
            _isLoading = false;
          });
        } else {
          // 🥦 CHẾ ĐỘ QUÉT NGUYÊN LIỆU TƯƠI SỐNG
          final result = await _recommendationService.recommendMeals(
            _selectedImage!,
            minConfidence: _confidenceThreshold,
          );

          if (!mounted) return;

          int kcal = 0;
          double pro = 0;
          double carbs = 0;
          double fat = 0;

          for (final item in result.recognizedIngredients) {
            final details = IngredientNormalizer.getIngredientDetails(item.foodName);
            final k = (details['kcal'] as num?)?.toInt() ?? 120;
            final p = (details['protein'] as num?)?.toDouble() ?? 10.0;
            final c = (details['carbs'] as num?)?.toDouble() ?? 5.0;
            final f = (details['fat'] as num?)?.toDouble() ?? 3.0;

            kcal += k;
            pro += p;
            carbs += c;
            fat += f;
          }

          setState(() {
            _recommendedRecipes = result.recipes;
            _detectedIngredients = result.recognizedIngredients
                .map((r) => r.foodName)
                .toList();
            _totalKcal = kcal;
            _totalProtein = pro;
            _totalCarbs = carbs;
            _totalFat = fat;
            _isLoading = false;
          });

          if (_recommendedRecipes.isNotEmpty) {
            _showRecipesDialog();
          } else if (_detectedIngredients.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy nguyên liệu hoặc công thức phù hợp')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }


  void _showUpdateApiKeyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString('gemini_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Cập nhật API Key AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dán Gemini API Key mới vào đây. Hệ thống sẽ ngay lập tức sử dụng Key này để nhận diện nguyên liệu:',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Dán API Key (AQ... hoặc AIzaSy...)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await GeminiFoodRecognitionService.saveApiKey(newKey);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Đã lưu và kích hoạt Gemini API Key mới thành công!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              if (mounted) Navigator.pop(dCtx);
            },
            child: const Text('Lưu & Kích hoạt'),
          ),
        ],
      ),
    );
  }

  void _simulateCapture() {
    _pickImage(ImageSource.camera);
  }

  void _pickFromGallery() {
    _pickImage(ImageSource.gallery);
  }

  void _showRecipesDialog() {
    if (_recommendedRecipes.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            const Text(
              'CÔNG THỨC GỢI Ý',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: const Color(0xFFE5E7EB)),
          ],
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recommendedRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _recommendedRecipes[index];
              final duration = recipe.durationMinutes ?? 10;
              final infoText = recipe.ingredients.isNotEmpty
                  ? "$duration phút • ${recipe.ingredients.length} nguyên liệu"
                  : "$duration phút";

              return _buildRecipeItem(
                title: recipe.name,
                info: infoText,
                tag: index == 0 ? "Phù hợp nhất" : "Gợi ý",
                onTap: () => _showRecipeDetailDialog(recipe),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetailDialog(Recipe recipe) {
    // Thu thập danh sách nguyên liệu đầy đủ
    final List<String> displayIngredients = List<String>.from(recipe.ingredients);
    if (displayIngredients.isEmpty) {
      for (final det in _detectedIngredients) {
        if (!displayIngredients.contains(det)) {
          displayIngredients.add('$det (khẩu phần gymer)');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            Text(
              recipe.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontSize: 15,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "${recipe.durationMinutes ?? 10} PHÚT",
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: const Color(0xFFE5E7EB)),
          ],
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NGUYÊN LIỆU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                ...displayIngredients.map((ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("• $ing", style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'CÁCH LÀM',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                ...recipe.steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text("${entry.key + 1}. ${entry.value}", style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // Đóng popup chi tiết
                  Navigator.pop(context); // Đóng popup danh sách công thức
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CookingTimerScreen(
                        recipe: {
                          'title': recipe.name,
                          'name': recipe.name,
                          'time': recipe.durationMinutes ?? 10,
                          'cooking_time_min': recipe.durationMinutes ?? 10,
                          'instructions': recipe.steps.join('\n'),
                          'steps': recipe.steps,
                          'ingredients': displayIngredients,
                          'kcal': _totalKcal > 0 ? _totalKcal : 380,
                          'protein': _totalProtein > 0 ? _totalProtein.round() : 35,
                          'carbs': _totalCarbs > 0 ? _totalCarbs.round() : 35,
                          'fat': _totalFat > 0 ? _totalFat.round() : 10,
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                label: const Text('CHỌN CÔNG THỨC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem({required String title, required String info, required String tag, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // Nền item màu trắng để nổi bật trên nền xám sáng của popup
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(info, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionDetailDialog(String title) {
    // Logic 4: Popup chi tiết dinh dưỡng (Placeholder)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'CHI TIẾT ${title.toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Chưa có dữ liệu dinh dưỡng',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addDetectedIngredientsToFridge() async {
    if (_detectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ảnh hoặc chọn ảnh quét nguyên liệu trước!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await ApiService.getUserId() ?? 'guest';
      final userKey = 'smart_fridge_items_$userId';
      final jsonStr = prefs.getString(userKey);
      List<Map<String, dynamic>> fridgeItems = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        fridgeItems = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      int addedCount = 0;
      for (int i = 0; i < _detectedIngredients.length; i++) {
        final rawName = _detectedIngredients[i];
        final details = IngredientNormalizer.getIngredientDetails(rawName);
        final itemMap = {
          'id': 'scan_${DateTime.now().millisecondsSinceEpoch}_$i',
          'name': details['vi'] ?? rawName,
          'icon': details['icon'] ?? '🥗',
          'weight': 200,
          'unit': 'g',
          'compartment': details['cat'] == 'protein' ? 'freezer' : 'cool',
          'kcalPer100g': (details['kcal'] as num?)?.toInt() ?? 100,
          'protein': (details['protein'] as num?)?.toInt() ?? 15,
          'carbs': (details['carbs'] as num?)?.toInt() ?? 5,
          'fat': (details['fat'] as num?)?.toInt() ?? 3,
          'addedAt': DateTime.now().toIso8601String(),
        };

        final existingIdx = fridgeItems.indexWhere((it) => it['name'] == itemMap['name']);
        if (existingIdx != -1) {
          fridgeItems[existingIdx]['weight'] = ((fridgeItems[existingIdx]['weight'] as num?)?.toInt() ?? 0) + 200;
        } else {
          fridgeItems.add(itemMap);
        }
        addedCount++;
      }

      await prefs.setString(userKey, jsonEncode(fridgeItems));
      CameraScanContent.sessionIngredients = List<Map<String, dynamic>>.from(fridgeItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đã thêm $addedCount nguyên liệu quét được vào Tủ Lạnh Thông Minh!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu vào tủ lạnh: $e')),
        );
      }
    }
  }

  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ nhật';
      default: return 'Thứ $weekday';
    }
  }

  String _mealLabel(String value) {
    final v = value.toLowerCase();
    if (v.contains('sáng') || v == 'breakfast') return 'Bữa sáng';
    if (v.contains('trưa') || v == 'lunch') return 'Bữa trưa';
    if (v.contains('tối') || v == 'dinner') return 'Bữa tối';
    if (v.contains('phụ') || v == 'snack') return 'Bữa phụ';
    return value;
  }

  Future<void> _logDishToNutritionDiary() async {
    if (_detectedDishName == null && _totalKcal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ảnh hoặc chọn ảnh đĩa món ăn để phân tích trước!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final allPlans = await MealPlanService.loadPlans();
    final now = DateTime.now();
    final weekdayStr = _getWeekdayName(now.weekday);
    final dateFormatted = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
    final todayLabel = '$weekdayStr ($dateFormatted)';

    // Tìm các món ăn của ngày hôm nay trong lịch đã lên
    List<MealPlan> todayMeals = allPlans.where((p) =>
      (p.prepDate.year == now.year && p.prepDate.month == now.month && p.prepDate.day == now.day) ||
      p.dateStr == dateFormatted
    ).toList();

    // Nếu không tìm thấy theo ngày cụ thể nhưng có lịch, tìm theo thứ hoặc lấy ngày đầu tiên
    if (todayMeals.isEmpty && allPlans.isNotEmpty) {
      final byDay = allPlans.where((p) => p.dayName?.toLowerCase() == weekdayStr.toLowerCase()).toList();
      if (byDay.isNotEmpty) {
        todayMeals = byDay;
      } else {
        final firstDate = allPlans.first.prepDate;
        todayMeals = allPlans.where((p) =>
          p.prepDate.year == firstDate.year &&
          p.prepDate.month == firstDate.month &&
          p.prepDate.day == firstDate.day
        ).toList();
      }
    }

    MealPlan? getExistingMeal(String mealKey) {
      for (final p in todayMeals) {
        final t = p.mealType.toLowerCase();
        if (mealKey == 'breakfast' && (t.contains('sáng') || t == 'breakfast')) return p;
        if (mealKey == 'lunch' && (t.contains('trưa') || t == 'lunch')) return p;
        if (mealKey == 'dinner' && (t.contains('tối') || t == 'dinner')) return p;
        if (mealKey == 'snack' && (t.contains('phụ') || t == 'snack')) return p;
      }
      return null;
    }

    if (!mounted) return;

    // Hiển thị BottomSheet chọn bữa ăn để thay thế
    final selectedMealType = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildMealSelectionSheet(
          context: ctx,
          todayLabel: todayLabel,
          dishName: _detectedDishName ?? 'Đĩa thức ăn quét AI',
          dishKcal: _totalKcal,
          dishProtein: _totalProtein.round(),
          dishCarbs: _totalCarbs.round(),
          dishFat: _totalFat.round(),
          breakfastMeal: getExistingMeal('breakfast'),
          lunchMeal: getExistingMeal('lunch'),
          dinnerMeal: getExistingMeal('dinner'),
          snackMeal: getExistingMeal('snack'),
        );
      },
    );

    if (selectedMealType == null) return; // Người dùng đóng bảng chọn

    // Tiến hành thay thế món ăn và tự động cân đối lại calo các bữa sau
    await _applyMealReplacement(
      selectedMealType: selectedMealType,
      allPlans: allPlans,
      todayMeals: todayMeals,
      now: now,
      weekdayStr: weekdayStr,
      dateFormatted: dateFormatted,
    );
  }

  Widget _buildMealSelectionSheet({
    required BuildContext context,
    required String todayLabel,
    required String dishName,
    required int dishKcal,
    required int dishProtein,
    required int dishCarbs,
    required int dishFat,
    required MealPlan? breakfastMeal,
    required MealPlan? lunchMeal,
    required MealPlan? dinnerMeal,
    required MealPlan? snackMeal,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final mealOptions = [
      {
        'type': 'breakfast',
        'name': 'Bữa sáng',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFFFB300),
        'existing': breakfastMeal,
      },
      {
        'type': 'lunch',
        'name': 'Bữa trưa',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFF2563EB),
        'existing': lunchMeal,
      },
      {
        'type': 'snack',
        'name': 'Bữa phụ',
        'icon': Icons.local_cafe_rounded,
        'color': const Color(0xFF8B5CF6),
        'existing': snackMeal,
      },
      {
        'type': 'dinner',
        'name': 'Bữa tối',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF10B981),
        'existing': dinnerMeal,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghi Nhận Vào Lịch Ăn',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.green),
                          const SizedBox(width: 5),
                          Text(
                            'Hôm nay: $todayLabel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: subColor,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Card món ăn vừa quét
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fastfood_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dishName,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dishKcal kcal • ${dishProtein}g Protein • ${dishCarbs}g C • ${dishFat}g F',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Chọn bữa ăn bạn muốn thay thế:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
            const SizedBox(height: 10),

            // 4 lựa chọn bữa ăn
            ...mealOptions.map((opt) {
              final type = opt['type'] as String;
              final name = opt['name'] as String;
              final icon = opt['icon'] as IconData;
              final color = opt['color'] as Color;
              final existing = opt['existing'] as MealPlan?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.pop(context, type),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: existing != null ? color.withValues(alpha: 0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: existing != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                existing != null
                                    ? 'Hiện tại: ${existing.name} (${existing.kcal ?? 0} kcal)'
                                    : 'Chưa có món trong lịch • Bấm để thêm mới',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: existing != null ? subColor : const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _applyMealReplacement({
    required String selectedMealType,
    required List<MealPlan> allPlans,
    required List<MealPlan> todayMeals,
    required DateTime now,
    required String weekdayStr,
    required String dateFormatted,
  }) async {
    final scannedKcal = _totalKcal;
    final scannedName = _detectedDishName ?? 'Đĩa món ăn quét AI';

    // 1. Tìm món hiện tại đang có ở bữa này (nếu có)
    MealPlan? targetOldPlan;
    for (final p in todayMeals) {
      final t = p.mealType.toLowerCase();
      if (selectedMealType == 'breakfast' && (t.contains('sáng') || t == 'breakfast')) {
        targetOldPlan = p;
        break;
      }
      if (selectedMealType == 'lunch' && (t.contains('trưa') || t == 'lunch')) {
        targetOldPlan = p;
        break;
      }
      if (selectedMealType == 'dinner' && (t.contains('tối') || t == 'dinner')) {
        targetOldPlan = p;
        break;
      }
      if (selectedMealType == 'snack' && (t.contains('phụ') || t == 'snack')) {
        targetOldPlan = p;
        break;
      }
    }

    final oldMealKcal = targetOldPlan?.kcal ?? 0;

    // 2. Tính tổng calo mục tiêu của ngày hôm nay (tổng kế hoạch ban đầu)
    int targetDayKcal = todayMeals.fold(0, (sum, p) => sum + (p.kcal ?? 0));
    if (targetDayKcal < 500) {
      targetDayKcal = _userMealLimitKcal * 3;
    }

    // 3. Tạo MealPlan mới cho bữa được chọn
    final newMeal = MealPlan(
      id: targetOldPlan?.id ?? 'scan_${DateTime.now().millisecondsSinceEpoch}',
      name: '$scannedName (Quét AI)',
      servings: 1,
      mealType: selectedMealType,
      prepDate: targetOldPlan?.prepDate ?? now,
      storedFrozen: false,
      dayName: targetOldPlan?.dayName ?? weekdayStr,
      dateStr: targetOldPlan?.dateStr ?? dateFormatted,
      kcal: scannedKcal,
      protein: _totalProtein.round(),
      carbs: _totalCarbs.round(),
      fat: _totalFat.round(),
      cookType: 'Nấu tươi (Quét AI)',
      notes: '📸 Món ăn thực tế nhận diện từ AI Vision',
    );

    // 4. Thứ tự các bữa ăn trong ngày: sáng (0) -> trưa (1) -> phụ (2) -> tối (3)
    int getMealOrder(String mealType) {
      final t = mealType.toLowerCase();
      if (t.contains('sáng') || t == 'breakfast') return 0;
      if (t.contains('trưa') || t == 'lunch') return 1;
      if (t.contains('phụ') || t == 'snack') return 2;
      if (t.contains('tối') || t == 'dinner') return 3;
      return 99;
    }

    final selectedOrder = getMealOrder(selectedMealType);

    // Các bữa ăn diễn ra SAU bữa này trong ngày
    final subsequentMeals = todayMeals.where((p) =>
      p.id != targetOldPlan?.id &&
      getMealOrder(p.mealType) > selectedOrder
    ).toList();

    // 5. Tính toán xem tổng calo ngày có bị VƯỢT MỤC TIÊU không
    // unadjustedDayKcal là tổng nếu thay thế mà không chỉnh sửa các bữa sau
    int unadjustedDayKcal = 0;
    for (final m in todayMeals) {
      if (m.id == targetOldPlan?.id) {
        unadjustedDayKcal += scannedKcal;
      } else {
        unadjustedDayKcal += (m.kcal ?? 0);
      }
    }
    if (targetOldPlan == null) {
      unadjustedDayKcal += scannedKcal;
    }

    bool exceedsTarget = unadjustedDayKcal > targetDayKcal;
    int excessKcal = unadjustedDayKcal - targetDayKcal;

    List<MealPlan> adjustedSubsequentMeals = [];
    int totalReducedKcal = 0;

    // 6. Nếu VƯỢT MỤC TIÊU và có các bữa sau: Tự động điều chỉnh giảm calo các bữa sau để không vượt mục tiêu
    if (exceedsTarget && subsequentMeals.isNotEmpty) {
      final sumSubsequent = subsequentMeals.fold(0, (sum, m) => sum + (m.kcal ?? 0));
      if (sumSubsequent > 0) {
        // Ngân sách calo còn lại cho các bữa sau
        int targetSubsequentBudget = sumSubsequent - excessKcal;
        // Đảm bảo mỗi bữa tối thiểu 100 kcal
        if (targetSubsequentBudget < 100 * subsequentMeals.length) {
          targetSubsequentBudget = 100 * subsequentMeals.length;
        }

        final double scaleRatio = targetSubsequentBudget / sumSubsequent;

        for (final m in subsequentMeals) {
          final origKcal = m.kcal ?? 0;
          final newKcal = (origKcal * scaleRatio).round();
          final diff = origKcal - newKcal;
          totalReducedKcal += diff;

          final origP = m.protein ?? 0;
          final origC = m.carbs ?? 0;
          final origF = m.fat ?? 0;

          adjustedSubsequentMeals.add(
            m.copyWith(
              kcal: newKcal,
              protein: (origP * scaleRatio).round(),
              carbs: (origC * scaleRatio).round(),
              fat: (origF * scaleRatio).round(),
              notes: '⚡ Tự động giảm -$diff kcal (còn $newKcal kcal) để cân đối calo với $scannedName ở ${_mealLabel(selectedMealType)}',
            ),
          );
        }
      }
    }

    // 7. Cập nhật danh sách toàn bộ kế hoạch (allPlans)
    final updatedPlans = List<MealPlan>.from(allPlans);

    // Thay thế hoặc thêm bữa ăn mới
    if (targetOldPlan != null) {
      final idx = updatedPlans.indexWhere((p) => p.id == targetOldPlan!.id);
      if (idx != -1) {
        updatedPlans[idx] = newMeal;
      } else {
        updatedPlans.add(newMeal);
      }
    } else {
      updatedPlans.add(newMeal);
    }

    // Thay thế các bữa sau đã điều chỉnh giảm calo
    for (final adj in adjustedSubsequentMeals) {
      final idx = updatedPlans.indexWhere((p) => p.id == adj.id);
      if (idx != -1) {
        updatedPlans[idx] = adj;
      }
    }

    // Lưu lại toàn bộ kế hoạch đã cập nhật
    await MealPlanService.overwriteAllPlans(updatedPlans);

    // 8. Đồng bộ vào Nhật ký dinh dưỡng cá nhân
    try {
      final logData = {
        'logDate': now.toIso8601String().split('T')[0],
        'mealType': selectedMealType,
        'foodName': scannedName,
        'servingSize': 1,
        'servingUnit': _detectedGrams != null ? '${_detectedGrams}g' : '1 đĩa',
        'calories': scannedKcal,
        'protein': _totalProtein,
        'carbs': _totalCarbs,
        'fat': _totalFat,
      };
      try {
        await ApiService.addNutritionLog(logData);
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final dateKey = 'local_diary_${now.toIso8601String().split('T')[0]}';
        final existing = prefs.getString(dateKey);
        List<dynamic> logs = [];
        if (existing != null) {
          try { logs = jsonDecode(existing); } catch (_) {}
        }
        logs.add(logData);
        await prefs.setString(dateKey, jsonEncode(logs));
      }
    } catch (_) {}

    // 9. Hiển thị Dialog báo kết quả chi tiết kèm nút Mở Trang Lịch
    if (mounted) {
      _showReplacementResultDialog(
        selectedMealName: _mealLabel(selectedMealType),
        scannedName: scannedName,
        scannedKcal: scannedKcal,
        oldMealKcal: oldMealKcal,
        targetDayKcal: targetDayKcal,
        exceedsTarget: exceedsTarget,
        adjustedMeals: adjustedSubsequentMeals,
        totalReducedKcal: totalReducedKcal,
      );
    }
  }

  void _showReplacementResultDialog({
    required String selectedMealName,
    required String scannedName,
    required int scannedKcal,
    required int oldMealKcal,
    required int targetDayKcal,
    required bool exceedsTarget,
    required List<MealPlan> adjustedMeals,
    required int totalReducedKcal,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đã Cập Nhật Kế Hoạch!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🍽️ Đã thay thế $selectedMealName bằng món:',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '$scannedName ($scannedKcal kcal)',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                if (exceedsTarget && adjustedMeals.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFEA580C), size: 18),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'TỰ ĐỘNG CÂN BẰNG CALO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-$totalReducedKcal kcal',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Món ăn mới nạp nhiều hơn (${scannedKcal - oldMealKcal} kcal). AI đã tự động cắt giảm khẩu phần các bữa sau để tổng calo ngày đạt đúng hạn mức $targetDayKcal kcal (không vượt mục tiêu):',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF7C2D12), height: 1.35),
                        ),
                        const SizedBox(height: 8),
                        ...adjustedMeals.map((adj) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right_rounded, size: 18, color: Color(0xFFEA580C)),
                              Expanded(
                                child: Text(
                                  '${_mealLabel(adj.mealType)}: còn ${adj.kcal} kcal',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tổng calo hôm nay không vượt mục tiêu ($targetDayKcal kcal). Các bữa ăn tiếp theo được giữ nguyên!',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ĐÓNG', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealPrepScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('XEM TRANG LỊCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isDishMode ? 'Quét Đĩa Món Ăn AI' : 'Quét Nguyên Liệu AI',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E9F2),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Mode Switcher (Segmented Tab: 🥦 Quét nguyên liệu vs 🍽️ Quét đĩa món ăn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isDishMode) {
                            setState(() {
                              _isDishMode = false;
                              _detectedDishName = null;
                              _detectedGrams = null;
                              _dishSuggestion = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isDishMode
                                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isDishMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🥦', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'Quét nguyên liệu',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: !_isDishMode ? FontWeight.bold : FontWeight.w600,
                                  color: !_isDishMode
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isDishMode) {
                            setState(() {
                              _isDishMode = true;
                              _recommendedRecipes = [];
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isDishMode
                                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isDishMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🍽️', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'Quét đĩa món ăn',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _isDishMode ? FontWeight.bold : FontWeight.w600,
                                  color: _isDishMode
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AI Status Pill Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _showUpdateApiKeyDialog,
                      onLongPress: _showUpdateApiKeyDialog,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI VISION 4.2 • ${_isLoading ? "PROCESSING" : "READY"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.videocam_outlined, color: Color(0xFF6B7280), size: 18),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

        // Khối Camera
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE5E7EB), Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                        ),
                      ),
                      child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.restaurant_outlined, size: 80, color: Color(0xFFD1D5DB)),
                          ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: _pickFromGallery,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.image_outlined, color: Color(0xFF111827), size: 20),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('GALLERY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: _simulateCapture,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF111827), width: 3),
                              ),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(color: Color(0xFF111827), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFF4B5563), size: 14),
                                  const SizedBox(width: 4),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('AI ANALYSIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                                      Text(_isLoading ? 'PROCESSING' : 'READY', style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Khối kết quả phân tích & cảnh báo
        Expanded(
          flex: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header kết quả
                    if (_isDishMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _detectedDishName ?? 'Đĩa món ăn đã nấu',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                if (_detectedGrams != null)
                                  Text(
                                    'Khẩu phần ước tính: ~$_detectedGrams g • Mục tiêu: $_userGoal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant, size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  'Đĩa đã nấu',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Text('Đã nhận diện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                          const Spacer(),
                          if (_recommendedRecipes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                              child: const Text('CHỈNH SỬA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Danh sách thành phần / nguyên liệu
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _detectedIngredients.isEmpty
                          ? [
                              Text(
                                _isDishMode ? "Vui lòng chụp hoặc chọn ảnh đĩa thức ăn để phân tích" : "Vui lòng quét để nhận diện nguyên liệu",
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              )
                            ]
                          : _detectedIngredients.map((ing) => Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Text(
                                  ing,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151)),
                                ),
                              ),
                            )).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // 4 chỉ số Macro tròn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutritionClickable(
                          label: "NĂNG LƯỢNG",
                          value: _totalKcal > 0 ? '$_totalKcal' : '--',
                          unit: "KCAL",
                          onTap: () => _showNutritionDetailDialog("Năng lượng"),
                        ),
                        _buildNutritionClickable(
                          label: "PROTEIN",
                          value: _totalProtein > 0 ? '${_totalProtein.round()}' : '--',
                          unit: _totalProtein > 0 ? 'G' : '--',
                          onTap: () => _showNutritionDetailDialog("Protein"),
                        ),
                        _buildNutritionClickable(
                          label: "CARBS",
                          value: _totalCarbs > 0 ? '${_totalCarbs.round()}' : '--',
                          unit: _totalCarbs > 0 ? 'G' : '--',
                          onTap: () => _showNutritionDetailDialog("Carbs"),
                        ),
                        _buildNutritionClickable(
                          label: "CHẤT BÉO",
                          value: _totalFat > 0 ? '${_totalFat.round()}' : '--',
                          unit: _totalFat > 0 ? 'G' : '--',
                          onTap: () => _showNutritionDetailDialog("Chất béo"),
                        ),
                      ],
                    ),

                    // THẺ KIỂM TRA & CẢNH BÁO VƯỢT NGƯỠNG BỮA ĂN (Dành riêng cho Chế độ Đĩa Món Ăn)
                    if (_isDishMode && _totalKcal > 0) ...[
                      const SizedBox(height: 14),
                      if (_totalKcal > _userMealLimitKcal) ...[
                        // 🔴 VƯỢT NGƯỠNG BỮA ĂN
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFDBA74)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 18),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'CẢNH BÁO VƯỢT NGƯỠNG BỮA ĂN',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC2410C),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${_totalKcal - _userMealLimitKcal} kcal',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Món ăn này chứa $_totalKcal kcal (vượt ${_totalKcal - _userMealLimitKcal} kcal so với hạn mức bữa ăn của bạn: $_userMealLimitKcal kcal). Lượng Chất béo: ${_totalFat.round()}g Fat.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12), height: 1.35),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '💡 Gợi ý: ${_dishSuggestion ?? "Hãy giảm 1/2 lượng sốt hoặc chia bớt khẩu phần tinh bột để không phá vỡ Macro ngày."}',
                                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF9A3412)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // 🟢 ĐẠT CHUẨN MACROS BỮA ĂN
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'ĐẠT CHUẨN MACROS BỮA ĂN',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bữa ăn đạt $_totalKcal kcal / ${_totalProtein.round()}g Protein — rất phù hợp cho mục tiêu $_userGoal của bạn (Hạn mức: $_userMealLimitKcal kcal)!',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.35),
                              ),
                              if (_dishSuggestion != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '💡 $_dishSuggestion',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 18),
                    // Nút hành động thích ứng theo chế độ quét
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? primaryColor : const Color(0xFF0F172A),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: Icon(_isDishMode ? Icons.bookmark_add_rounded : Icons.kitchen_rounded),
                        onPressed: _isDishMode ? _logDishToNutritionDiary : _addDetectedIngredientsToFridge,
                        label: Text(
                          _isDishMode ? 'Ghi nhận vào Nhật ký ăn uống hôm nay' : 'Thêm nguyên liệu vào tủ lạnh',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildNutritionClickable({required String label, required String value, required String unit, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                Text(unit, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
