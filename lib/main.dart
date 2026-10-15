import 'dart:io';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/body_stats_screen.dart';
import 'screens/cooking_timer_screen.dart';
import 'screens/login_screen.dart';
import 'screens/badges_and_report_screen.dart';
import 'models/badges_and_report_model.dart';
import 'screens/recipe_search_screen.dart';
import 'screens/update_body_stats_screen.dart';
import 'screens/nutrition_diary_screen.dart';
import 'services/api_service.dart';
import 'services/ai/ai_service_factory.dart';
import 'services/ai/meal_recommendation_service.dart';
import 'services/ai/providers/themealdb_recipe_service.dart';
import 'models/recipe.dart' as ai_model;
import 'widgets/app_bottom_nav_bar.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool loggedIn = await ApiService.isLoggedIn();
  runApp(NutriGymApp(isLoggedIn: loggedIn));
}

class NutriGymApp extends StatelessWidget {
  final bool isLoggedIn;
  const NutriGymApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriGym AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0; // Mặc định là tab Home

  final List<Widget> _screens = const [
    BadgesAndReportScreen(),
    CameraScanContent(),
    RecipeSearchScreen(),
    BodyStatsScreen(),
    NutritionDiaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER BAR (Giữ cố định)
            const AppHeader(),

            // 2. DYNAMIC BODY (Giữ trạng thái qua IndexedStack)
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: _screens,
              ),
            ),

            // 3. BOTTOM NAVIGATION BAR (Giữ cố định)
            AppBottomNavBar(
              selectedIndex: _currentTab,
              onItemSelected: (index) {
                setState(() {
                  _currentTab = index;
                });
                if (index == 0) {
                  BadgesAndReportModel.instance.fetchAchievementsData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }



}

// Widget Header tách biệt
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NUTRIGYM AI',
                    style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                  ),
                  Text(
                    'Quét Nguyên Liệu',
                    style: AppTypography.headline(color: AppColors.onSurface),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: AppColors.onSurface),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => _buildProfileSheet(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: Icon(Icons.person, size: 40, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('Nguyễn Văn A', style: AppTypography.displayLarge().copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text('0901234567', style: AppTypography.bodyMedium()),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateBodyStatsScreen()));
              },
              child: const Text('CẬP NHẬT CHỈ SỐ CƠ THỂ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fire,
                side: const BorderSide(color: AppColors.fire, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, color: AppColors.fire),
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              label: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.fire)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Nội dung chính của màn hình Quét
class CameraScanContent extends StatefulWidget {
  const CameraScanContent({super.key});

  @override
  State<CameraScanContent> createState() => _CameraScanContentState();
}

class _CameraScanContentState extends State<CameraScanContent> {
  bool _isFlashOn = false;
  List<Map<String, dynamic>> _availableIngredients = [];

  // Lưu trữ nguyên liệu trong phiên làm việc (tồn tại khi chuyển tab, chỉ xóa khi thoát app)
  static List<Map<String, dynamic>> sessionIngredients = [];

  List<Map<String, dynamic>> _ingredients = [];

  void _syncSession() {
    sessionIngredients = List<Map<String, dynamic>>.from(_ingredients);
  }

  @override
  void initState() {
    super.initState();
    _ingredients = List<Map<String, dynamic>>.from(sessionIngredients);
    _loadAvailableIngredients();
  }

  Future<void> _loadAvailableIngredients() async {
    try {
      final list = await ApiService.getIngredients();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _availableIngredients = list;
        });
      }
    } catch (_) {}
  }

  void _showIngredientOptions(int index) {
    final item = _ingredients[index];
    final TextEditingController _weightCtrl = TextEditingController(text: item['weight'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${item['icon']} ${item['name']}', style: AppTypography.titleMedium(color: AppColors.onSurface)),
        content: TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Khối lượng (g)',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
                _syncSession();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.fire),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              setState(() {
                item['weight'] = int.tryParse(_weightCtrl.text) ?? item['weight'];
                _syncSession();
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog() async {
    if (_availableIngredients.isEmpty) {
      try {
        final list = await ApiService.getIngredients();
        if (mounted && list.isNotEmpty) {
          setState(() {
            _availableIngredients = list;
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String filter = '';
        bool isLoadingMore = _availableIngredients.isEmpty;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (isLoadingMore) {
              ApiService.getIngredients().then((list) {
                if (list.isNotEmpty && mounted) {
                  setState(() => _availableIngredients = list);
                  setSheetState(() => isLoadingMore = false);
                }
              });
            }

            final db = _availableIngredients;
            final available = db.where((dbItem) {
              final name = (dbItem['name'] ?? '').toString().toLowerCase();
              final matchesFilter = name.contains(filter.toLowerCase());
              final notYetAdded = !_ingredients.any((i) => i['name'] == dbItem['name']);
              return matchesFilter && notYetAdded;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Thêm nguyên liệu', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) {
                      setSheetState(() {
                        filter = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm trong ${db.length} nguyên liệu...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: available.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy nguyên liệu',
                              style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            itemCount: available.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final item = available[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Text(item['icon']?.toString() ?? '🥗', style: const TextStyle(fontSize: 24)),
                                title: Text(item['name']?.toString() ?? '', style: AppTypography.bodyMedium(color: AppColors.onSurface)),
                                subtitle: Text('${item['kcalPer100g']} kcal / 100g', style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      _ingredients.add({
                                        'name': item['name'],
                                        'icon': item['icon'] ?? '🥗',
                                        'kcalPer100g': item['kcalPer100g'] ?? 100,
                                        'protein': item['protein'] ?? 15,
                                        'carbs': item['carbs'] ?? 5,
                                        'fat': item['fat'] ?? 3,
                                        'weight': 100,
                                      });
                                      _syncSession();
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processImageWithAI(XFile image) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI đang nhận diện nguyên liệu...', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Lọc độ tin cậy > 40% & Công thức < 15p', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final recommendationService = MealRecommendationService(
        foodRecognitionService: AIServiceFactory.createFoodRecognitionService(),
        recipeService: TheMealDBRecipeService(),
      );

      final result = await recommendationService.recommendMeals(
        File(image.path),
        minConfidence: 0.4, // Thuật toán AI: Confidence Score > 40%
        maxDurationMinutes: 15, // Gợi ý công thức dưới 15 phút
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (result.recognizedIngredients.isNotEmpty) {
        setState(() {
          for (final item in result.recognizedIngredients) {
            final name = item.foodName;
            final already = _ingredients.any((i) => i['name'].toString().toLowerCase() == name.toLowerCase());
            if (!already) {
              _ingredients.add({
                'name': name,
                'icon': '🥗',
                'weight': 100,
                'kcalPer100g': 120,
                'protein': 20,
                'carbs': 5,
                'fat': 2,
              });
            }
          }
          _syncSession();
        });

        if (mounted) {
          final summary = result.recognizedIngredients
              .map((r) => '${r.foodName} (${(r.confidence * 100).toStringAsFixed(0)}%)')
              .join(', ');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI nhận diện (Confidence > 40%): $summary'),
              backgroundColor: AppColors.primary,
            ),
          );

          if (result.recipes.isNotEmpty) {
            _showAiQuickRecipesDialog(result.recipes);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy nguyên liệu nào đạt Confidence Score > 40%'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận diện AI: $e'),
            backgroundColor: AppColors.fire,
          ),
        );
      }
    }
  }

  void _showAiQuickRecipesDialog(List<ai_model.Recipe> recipes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('GỢI Ý CÔNG THỨC < 15 PHÚT', style: AppTypography.badge(color: AppColors.primary)),
            const SizedBox(height: 6),
            Text('Từ AI Computer Vision (YOLOv8 Docker > 40%)', style: AppTypography.labelCaption()),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, idx) {
              final r = recipes[idx];
              final duration = r.durationMinutes ?? 12;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.restaurant_menu, color: AppColors.primary),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('⏱ $duration phút • ${r.ingredients.length} nguyên liệu'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CookingTimerScreen(
                        recipe: {
                          'title': r.name,
                          'time': duration,
                          'cooking_time_min': duration,
                          'kcal': 320,
                          'protein': 28,
                          'instructions': r.steps.join('\n'),
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateCapture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _processImageWithAI(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở camera: $e'),
            backgroundColor: AppColors.fire,
          ),
        );
      }
    }
  }

  Future<void> _simulateGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _processImageWithAI(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở thư viện: $e'),
            backgroundColor: AppColors.fire,
          ),
        );
      }
    }
  }

  int get _totalCalories {
    if (_ingredients.isEmpty) return 0;
    double total = 0;
    for (var ing in _ingredients) {
      final kcal = (ing['kcalPer100g'] ?? 100) as num;
      final w = (ing['weight'] ?? 100) as num;
      total += kcal * w / 100;
    }
    return total.round();
  }

  int get _totalProtein {
    if (_ingredients.isEmpty) return 0;
    double total = 0;
    for (var ing in _ingredients) {
      final p = (ing['protein'] ?? (ing['name'].toString().toLowerCase().contains('gà') ? 24 : 12)) as num;
      final w = (ing['weight'] ?? 100) as num;
      total += p * w / 100;
    }
    return total.round();
  }

  int get _totalCarbs {
    if (_ingredients.isEmpty) return 0;
    double total = 0;
    for (var ing in _ingredients) {
      final c = (ing['carbs'] ?? (ing['name'].toString().toLowerCase().contains('cải') ? 7 : 3)) as num;
      final w = (ing['weight'] ?? 100) as num;
      total += c * w / 100;
    }
    return total.round();
  }

  int get _totalFat {
    if (_ingredients.isEmpty) return 0;
    double total = 0;
    for (var ing in _ingredients) {
      final f = (ing['fat'] ?? 3) as num;
      final w = (ing['weight'] ?? 100) as num;
      total += f * w / 100;
    }
    return total.round();
  }

  void _showRecipesDialog() {
    final ingNames = _ingredients.map((i) => i['name'].toString()).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text(
              'CÔNG THỨC GỢI Ý',
              style: AppTypography.badge(color: AppColors.onSurface).copyWith(
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: AppColors.outlineVariant),
          ],
        ),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService.suggestRecipes(ingNames),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final recipes = snapshot.data ?? [];
              if (recipes.isEmpty) {
                return Center(
                  child: Text(
                    'Không tìm thấy công thức phù hợp với nguyên liệu này.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: recipes.length,
                itemBuilder: (context, idx) {
                  final r = recipes[idx];
                  final title = r['title'] ?? 'Món ăn';
                  final kcal = r['kcal'] ?? 0;
                  final time = r['time'] ?? 15;
                  final protein = r['protein'] ?? 0;
                  final matchCount = r['matchingCount'] ?? 0;
                  final tag = matchCount > 0
                      ? 'Khớp $matchCount NVL'
                      : (r['tags'] != null && (r['tags'] as List).isNotEmpty ? (r['tags'] as List).first.toString() : 'Gợi ý');
                  return _buildRecipeItem(
                    title,
                    '$kcal kcal • $time phút • $protein g Pro',
                    tag,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CookingTimerScreen(recipe: r),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ĐÓNG', style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveToInventory() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm nguyên liệu trước khi lưu vào kho!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final List<Map<String, dynamic>> items = _ingredients.map((ing) {
        final weight = (ing['weight'] ?? 100) as num;
        final kcal100 = (ing['kcalPer100g'] ?? 100) as num;
        return {
          'name': ing['name'],
          'quantity': weight,
          'unit': 'g',
          'calories': (kcal100 * weight / 100).toDouble(),
          'protein': ((ing['protein'] ?? 15) as num).toDouble(),
          'carbs': ((ing['carbs'] ?? 5) as num).toDouble(),
          'fat': ((ing['fat'] ?? 3) as num).toDouble(),
          'category': ing['category'] ?? 'other',
          'icon': ing['icon'] ?? '🥗',
        };
      }).toList();
      await ApiService.addInventoryBatch(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu thành công ${items.length} nguyên liệu vào kho!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu vào kho: $e'),
            backgroundColor: AppColors.fire,
          ),
        );
      }
    }
  }

  Widget _buildRecipeItem(String title, String info, String tag, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(info, style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: AppTypography.labelCaption(color: AppColors.onPrimary).copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionDetailDialog(String title, List<Map<String, String>> items) {
    // Logic 4: Popup chi tiết dinh dưỡng
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'CHI TIẾT ${title.toUpperCase()}',
          style: AppTypography.badge(color: AppColors.onSurface).copyWith(
            letterSpacing: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: AppColors.outline, width: 2),
              right: BorderSide(color: AppColors.outline, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name']!, style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  Text(item['value']!, style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('HIỂU RỒI', style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. AI Status Pill Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                      color: _isFlashOn ? AppColors.warning : AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI VISION 4.2 • SẴN SÀNG',
                    style: AppTypography.badge(color: AppColors.onSurface).copyWith(letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  const Icon(Icons.videocam_outlined, color: AppColors.onSurfaceVariant, size: 18),
                  const SizedBox(width: 12),
                  const Icon(Icons.close, color: AppColors.onSurfaceVariant, size: 18),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),

        // 2. Khối Camera có hiệu ứng thu nhỏ mượt mà thành icon bar (như Ảnh 3) khi vuốt lên
        SliverPersistentHeader(
          pinned: true,
          delegate: _CameraScanHeaderDelegate(
            maxHeight: 330.0,
            minHeight: 80.0,
            onCapture: _simulateCapture,
            onGallery: _simulateGallery,
          ),
        ),

        // 3. Khối kết quả với danh sách nguyên liệu hiển thị theo chiều dọc
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 28.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đã nhận diện (${_ingredients.length})',
                        style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showAddIngredientDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 14, color: AppColors.onSurface),
                              const SizedBox(width: 2),
                              Text('THÊM', style: AppTypography.labelCaption(color: AppColors.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DANH SÁCH NGUYÊN LIỆU THEO CHIỀU DỌC
                  if (_ingredients.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Chưa có nguyên liệu nào được nhận diện.\nHãy chụp ảnh hoặc thêm thủ công!',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ing = _ingredients[index];
                        final kcal = ((ing['kcalPer100g'] ?? 100) * (ing['weight'] ?? 100) / 100).round();
                        final weight = ing['weight'] ?? 100;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(ing['icon']?.toString() ?? '🥗', style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ing['name']?.toString() ?? '',
                                      style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$kcal kcal • ${ing['kcalPer100g'] ?? 100} kcal/100g',
                                      style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              // Nút chỉnh sửa khối lượng
                              GestureDetector(
                                onTap: () => _showIngredientOptions(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.outlineVariant),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${weight}g',
                                        style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Nút xóa nguyên liệu
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.fire, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _ingredients.removeAt(index);
                                    _syncSession();
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),
                  // Nút bấm thêm nguyên liệu dạng hàng
                  InkWell(
                    onTap: _showAddIngredientDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Thêm nguyên liệu khác',
                            style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chỉ số dinh dưỡng tổng hợp (Macros)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutritionClickable(
                        label: "NĂNG LƯỢNG", value: "$_totalCalories", unit: "KCAL",
                        onTap: () => _showNutritionDetailDialog("Năng lượng", _ingredients.map((i) => {
                          "name": "${i['name']} (${i['weight']}g)",
                          "value": "${((i['kcalPer100g'] ?? 100) * (i['weight'] ?? 100) / 100).round()} kcal",
                        }).toList()..add({"name": "Tổng cộng", "value": "$_totalCalories kcal"})),
                      ),
                      _buildNutritionClickable(
                        label: "PROTEIN", value: "${_totalProtein}g", unit: "HIGH",
                        onTap: () => _showNutritionDetailDialog("Protein", _ingredients.map((i) => {
                          "name": "${i['name']} (${i['weight']}g)",
                          "value": "${((i['protein'] ?? 15) * (i['weight'] ?? 100) / 100).round()}g",
                        }).toList()..add({"name": "Tổng cộng", "value": "${_totalProtein}g"})),
                      ),
                      _buildNutritionClickable(
                        label: "CARBS", value: "${_totalCarbs}g", unit: "CLEAN",
                        onTap: () => _showNutritionDetailDialog("Carbs", _ingredients.map((i) => {
                          "name": "${i['name']} (${i['weight']}g)",
                          "value": "${((i['carbs'] ?? 5) * (i['weight'] ?? 100) / 100).round()}g",
                        }).toList()..add({"name": "Tổng cộng", "value": "${_totalCarbs}g"})),
                      ),
                      _buildNutritionClickable(
                        label: "CHẤT BÉO", value: "${_totalFat}g", unit: "FIT",
                        onTap: () => _showNutritionDetailDialog("Chất béo", _ingredients.map((i) => {
                          "name": "${i['name']} (${i['weight']}g)",
                          "value": "${((i['fat'] ?? 3) * (i['weight'] ?? 100) / 100).round()}g",
                        }).toList()..add({"name": "Tổng cộng", "value": "${_totalFat}g"})),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu vào kho & Tạo công thức
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      onPressed: _saveToInventory,
                      label: const Text('Lưu vào kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.restaurant_menu),
                      onPressed: _showRecipesDialog,
                      label: const Text('Tạo công thức phù hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionClickable({required String label, required String value, required String unit, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTypography.headline(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w900)),
                Text(unit, style: AppTypography.labelCaption(color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraScanHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  _CameraScanHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bottomPos = 16.0 - 5.0 * progress;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: const Color(0xFFE2E4E8).withValues(alpha: 0.8 + 0.2 * progress),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02 + 0.05 * progress),
              blurRadius: 4.0 + 6.0 * progress,
              offset: Offset(0, 1.0 + 2.0 * progress),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Nền Gradient nhẹ chuẩn như thiết kế gốc
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFECEEF2),
                      Color(0xFFF7F8FA),
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // 2. Watermark Dao & Nĩa (Icons.restaurant - Filled)
              // Đặt ở phần trên-giữa khi chưa vuốt, mờ dần khi cuộn lên
              if (progress < 0.95)
                Opacity(
                  opacity: (1.0 - progress * 2.5).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment(0.0, -0.28 - 0.25 * progress),
                    child: Transform.scale(
                      scale: (1.0 - progress * 0.3).clamp(0.6, 1.0),
                      child: const Icon(
                        Icons.restaurant,
                        size: 82,
                        color: Color(0xFFDCDFE4),
                      ),
                    ),
                  ),
                ),

              // 3. Thanh điều khiển Camera (GALLERY, Nút chụp, AUTO-DETECT 60 FPS)
              // Khi chưa vuốt: nằm gọn ở đáy card (bottom: 16)
              // Khi vuốt lên: trượt đều lên căn giữa thanh 80px (như Ảnh 3)
              Positioned(
                bottom: bottomPos,
                left: 16.0,
                right: 16.0,
                child: Row(
                  children: [
                    // Nút GALLERY
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: onGallery,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.image_outlined, color: AppColors.onSurface, size: 20),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'GALLERY',
                                style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)
                                    .copyWith(fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Nút Chụp ảnh trung tâm (Vòng tròn kép đen viền trắng)
                    GestureDetector(
                      onTap: onCapture,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 22),
                        ),
                      ),
                    ),

                    // Auto-detect & 60 FPS
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.onSurfaceVariant, size: 14),
                            const SizedBox(width: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AUTO-DETECT',
                                  style: AppTypography.labelCaption(color: AppColors.onSurface)
                                      .copyWith(fontWeight: FontWeight.w900, fontSize: 10),
                                ),
                                Text(
                                  '60 FPS',
                                  style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)
                                      .copyWith(fontSize: 9),
                                ),
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
    );
  }

  @override
  bool shouldRebuild(covariant _CameraScanHeaderDelegate oldDelegate) => true;
}
