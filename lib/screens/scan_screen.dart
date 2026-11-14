import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/recipe.dart';
import '../services/ai/ai_service_factory.dart';
import '../services/ai/ingredient_normalizer.dart';
import '../services/ai/meal_recommendation_service.dart';
import '../services/ai/providers/gemini_food_recognition_service.dart';
import '../services/api_service.dart';

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
              return _buildRecipeItem(
                title: recipe.name,
                info: "${recipe.durationMinutes ?? '--'} phút • ${recipe.ingredients.length} nguyên liệu",
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
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "${recipe.durationMinutes ?? '--'} PHÚT",
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
                ...recipe.ingredients.map((ing) => Padding(
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
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

    final hour = DateTime.now().hour;
    String mealType = 'lunch';
    String mealName = 'Bữa trưa';
    if (hour >= 5 && hour < 11) {
      mealType = 'breakfast';
      mealName = 'Bữa sáng';
    } else if (hour >= 11 && hour < 15) {
      mealType = 'lunch';
      mealName = 'Bữa trưa';
    } else if (hour >= 15 && hour < 18) {
      mealType = 'snack';
      mealName = 'Bữa phụ';
    } else {
      mealType = 'dinner';
      mealName = 'Bữa tối';
    }

    try {
      final logData = {
        'logDate': DateTime.now().toIso8601String().split('T')[0],
        'mealType': mealType,
        'foodName': _detectedDishName ?? 'Đĩa thức ăn quét AI',
        'servingSize': 1,
        'servingUnit': _detectedGrams != null ? '${_detectedGrams}g' : '1 đĩa',
        'calories': _totalKcal,
        'protein': _totalProtein,
        'carbs': _totalCarbs,
        'fat': _totalFat,
      };

      try {
        await ApiService.addNutritionLog(logData);
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final dateKey = 'local_diary_${DateTime.now().toIso8601String().split('T')[0]}';
        final existing = prefs.getString(dateKey);
        List<dynamic> logs = [];
        if (existing != null) {
          try {
            logs = jsonDecode(existing);
          } catch (_) {}
        }
        logs.add(logData);
        await prefs.setString(dateKey, jsonEncode(logs));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đã ghi nhận ${_detectedDishName ?? "món ăn"} ($_totalKcal kcal) vào $mealName hôm nay!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi ghi nhật ký: $e')),
        );
      }
    }
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
          'Quét Nguyên Liệu AI',
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
            const SizedBox(height: 8),
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
        const SizedBox(height: 10),

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

        // Khối kết quả
        Expanded(
          flex: 9,
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
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _detectedIngredients.isEmpty
                          ? [const Text("Vui lòng quét để nhận diện", style: TextStyle(color: Colors.grey, fontSize: 13))]
                          : _detectedIngredients.map((ing) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Text("• $ing", style: const TextStyle(fontWeight: FontWeight.w600)),
                            )).toList(),
                      ),
                    ),


                    const SizedBox(height: 20),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? primaryColor : const Color(0xFF0F172A),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.kitchen_rounded),
                        onPressed: _addDetectedIngredientsToFridge,
                        label: const Text('Thêm nguyên liệu vào tủ lạnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
