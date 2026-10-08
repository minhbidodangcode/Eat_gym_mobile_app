import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/body_stats_screen.dart';
import 'screens/cooking_timer_screen.dart';
import 'screens/login_screen.dart';
import 'screens/badges_and_report_screen.dart';
import 'screens/recipe_search_screen.dart';
import 'screens/update_body_stats_screen.dart';
import 'screens/nutrition_diary_screen.dart';
import 'screens/timer_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tạm tắt NotificationService vì chưa có file google-services.json
  // await NotificationService().initialize();
  
  runApp(const NutriGymApp());
}

class NutriGymApp extends StatelessWidget {
  const NutriGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriGym AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
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

  // Hàm chuyển đổi nội dung body dựa trên tab
  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return const BadgesAndReportScreen();
      case 1:
        return const CameraScanContent();
      case 2:
        return const RecipeSearchScreen();
      case 3:
        return const BodyStatsScreen();
      case 4:
        return const NutritionDiaryScreen();
      default:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Tính năng đang phát triển',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text('Vui lòng quay lại sau!', style: TextStyle(color: AppColors.grey)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER BAR (Giữ cố định)
            const AppHeader(),

            // 2. DYNAMIC BODY (Thay đổi theo tab)
            Expanded(child: _buildBody()),

            // 3. BOTTOM NAVIGATION BAR (Giữ cố định)
            AppBottomNavBar(
              selectedIndex: _currentTab,
              onItemSelected: (index) {
                setState(() {
                  _currentTab = index;
                });
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

  List<Map<String, dynamic>> _ingredients = [
    {"name": "Ức gà", "weight": 200, "icon": "🍗", "kcalPer100g": 135},
    {"name": "Bông cải xanh", "weight": 100, "icon": "🥦", "kcalPer100g": 50},
  ];

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
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog() {
    final List<Map<String, dynamic>> db = [
      {"name": "Thịt bò", "icon": "🥩", "kcalPer100g": 250},
      {"name": "Trứng gà", "icon": "🥚", "kcalPer100g": 155},
      {"name": "Cà chua", "icon": "🍅", "kcalPer100g": 18},
      {"name": "Cơm trắng", "icon": "🍚", "kcalPer100g": 130},
      {"name": "Khoai lang", "icon": "🍠", "kcalPer100g": 86},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Thêm nguyên liệu', style: AppTypography.titleMedium(color: AppColors.onSurface)),
              const SizedBox(height: 16),
              ...db.where((dbItem) => !_ingredients.any((i) => i['name'] == dbItem['name'])).map((dbItem) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(dbItem['icon'], style: const TextStyle(fontSize: 24)),
                  title: Text(dbItem['name'], style: AppTypography.bodyMedium(color: AppColors.onSurface)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () {
                      setState(() {
                        _ingredients.add({...dbItem, "weight": 100});
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _simulateCapture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        // Giả lập quét thành công và thêm nguyên liệu
        setState(() {
          _ingredients.add({"name": "Thịt gà", "icon": "🍗", "weight": 200});
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận diện: Thịt gà'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở camera: $e'),
          backgroundColor: AppColors.fire,
        ),
      );
    }
  }

  void _showRecipesDialog() {
    // Logic 3: Popup danh sách công thức
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: AppColors.outline, width: 2),
              right: BorderSide(color: AppColors.outline, width: 2),
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildRecipeItem("🍗 Ức gà áp chảo sốt cam", "450 kcal • 20 phút", "Cao Protein"),
              _buildRecipeItem("🥗 Salad gà & bông cải xanh", "320 kcal • 15 phút", "Ít Carbs"),
              _buildRecipeItem("🍲 Soup gà rau củ giải nhiệt", "280 kcal • 30 phút", "Dễ tiêu hóa"),
              _buildRecipeItem("🌯 Wrap gà ngũ cốc", "380 kcal • 10 phút", "Năng lượng nhanh"),
            ],
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
    try {
      final List<Map<String, dynamic>> items = _ingredients.map((ing) {
        return {
          'name': ing['name'],
          'quantity': ing['weight'],
          'unit': 'g',
          'calories': (ing['kcalPer100g'] * ing['weight'] / 100).toDouble(),
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'category': 'other',
        };
      }).toList();
      await ApiService.addInventoryBatch(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu nguyên liệu vào kho!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    }
  }

  Widget _buildRecipeItem(String title, String info, String tag) {
    return Container(
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
    return Column(
      children: [
        // AI Status Pill Bar
        Padding(
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
        const SizedBox(height: 10),

        // Khối Camera
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                          colors: [AppColors.outlineVariant, AppColors.surfaceContainerLow, AppColors.surfaceContainer],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant_outlined, size: 80, color: AppColors.outlineVariant),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                                    child: const Icon(Icons.image_outlined, color: AppColors.onSurface, size: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('GALLERY', style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _simulateCapture,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                              ),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 20),
                              ),
                            ),
                          ),
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
                                      Text('AUTO-DETECT', style: AppTypography.labelCaption(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w900)),
                                      Text('60 FPS', style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Đã nhận diện', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                          child: Text('CHỈNH SỬA', style: AppTypography.labelCaption(color: AppColors.onSurface)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...List.generate(_ingredients.length, (index) {
                            final ing = _ingredients[index];
                            return GestureDetector(
                              onTap: () => _showIngredientOptions(index),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  border: Border.all(color: AppColors.outlineVariant),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${ing['icon']} ${ing['name']} (${ing['weight']}g)",
                                  style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _showAddIngredientDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: AppColors.onPrimary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutritionClickable(
                          label: "NĂNG LƯỢNG", value: "320", unit: "KCAL",
                          onTap: () => _showNutritionDetailDialog("Năng lượng", [
                            {"name": "Ức gà (200g)", "value": "270 kcal"},
                            {"name": "Bông cải xanh", "value": "50 kcal"},
                            {"name": "Tổng cộng", "value": "320 kcal"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "PROTEIN", value: "48g", unit: "HIGH",
                          onTap: () => _showNutritionDetailDialog("Protein", [
                            {"name": "Ức gà (200g)", "value": "46g"},
                            {"name": "Bông cải xanh", "value": "2g"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "CARBS", value: "14g", unit: "CLEAN",
                          onTap: () => _showNutritionDetailDialog("Carbs", [
                            {"name": "Ức gà (200g)", "value": "0g"},
                            {"name": "Bông cải xanh", "value": "14g"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "CHẤT BÉO", value: "9g", unit: "FIT",
                          onTap: () => _showNutritionDetailDialog("Chất béo", [
                            {"name": "Ức gà (200g)", "value": "8g"},
                            {"name": "Bông cải xanh", "value": "1g"},
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveToInventory,
                        child: const Text('Lưu vào kho', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _showRecipesDialog,
                        child: const Text('Tạo công thức phù hợp', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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
