import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';

import 'calorie_compensation_screen.dart';
import 'meal_prep_screen.dart';

class NutritionDiaryScreen extends StatefulWidget {
  const NutritionDiaryScreen({super.key});

  @override
  State<NutritionDiaryScreen> createState() => _NutritionDiaryScreenState();
}

class _NutritionDiaryScreenState extends State<NutritionDiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _diaryData;

  @override
  void initState() {
    super.initState();
    _fetchDiary();
  }

  Future<void> _fetchDiary() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final data = await ApiService.getNutritionLogs(dateStr);
      setState(() {
        _diaryData = data;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _diaryData = {
            'summary': {'totalCalories': 0, 'totalProtein': 0, 'totalCarbs': 0, 'totalFat': 0},
            'meals': {
              'breakfast': {'items': [], 'totalCalories': 0},
              'lunch': {'items': [], 'totalCalories': 0},
              'dinner': {'items': [], 'totalCalories': 0},
              'snack': {'items': [], 'totalCalories': 0},
            }
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fetchDiary();
  }

  void _showAddFoodDialog(String mealType) {
    final foodCtrl = TextEditingController();
    final servingCtrl = TextEditingController(text: '1 phần');
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    void updateCaloriesFromMacros() {
      final p = double.tryParse(proCtrl.text) ?? 0.0;
      final c = double.tryParse(carbCtrl.text) ?? 0.0;
      final f = double.tryParse(fatCtrl.text) ?? 0.0;
      if (p > 0 || c > 0 || f > 0) {
        final total = p * 4 + c * 4 + f * 9;
        calCtrl.text = total.toStringAsFixed(0);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2420) : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm món vào ${mealType.toUpperCase()}',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodCtrl,
                style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Tên món ăn (VD: Ức gà áp chảo)',
                  labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: servingCtrl,
                style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Khẩu phần (vd: 1 bát, 200g)',
                  labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Protein (g)',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                        ),
                      ),
                      onChanged: (_) => updateCaloriesFromMacros(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Carbs (g)',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                        ),
                      ),
                      onChanged: (_) => updateCaloriesFromMacros(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Fat (g)',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                        ),
                      ),
                      onChanged: (_) => updateCaloriesFromMacros(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Tổng Calories (kcal)',
                  labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                  helperText: 'Tự tính theo P, C, F hoặc nhập thủ công',
                  helperStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : null),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? primaryAccent : AppColors.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              final name = foodCtrl.text.trim();
              if (name.isEmpty) return;

              final pro = double.tryParse(proCtrl.text) ?? 0.0;
              final carb = double.tryParse(carbCtrl.text) ?? 0.0;
              final fat = double.tryParse(fatCtrl.text) ?? 0.0;
              var cal = double.tryParse(calCtrl.text) ?? 0.0;
              if (cal <= 0 && (pro > 0 || carb > 0 || fat > 0)) {
                cal = pro * 4 + carb * 4 + fat * 9;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.addNutritionLog({
                  'logDate': _selectedDate.toIso8601String().split('T')[0],
                  'mealType': mealType,
                  'foodName': name,
                  'servingSize': 1,
                  'servingUnit': servingCtrl.text.isNotEmpty ? servingCtrl.text.trim() : 'phần',
                  'calories': cal,
                  'protein': pro,
                  'carbs': carb,
                  'fat': fat,
                });
                _fetchDiary();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0D) : AppColors.background,
      appBar: null, // Đã chuyển lên AppHeader chính thống nhất
      body: Column(
        children: [
          _buildDateSelector(isDark),
          // Quick actions bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF151B18) : AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: isDark ? primaryAccent : AppColors.primary,
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.calculate_outlined, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                    label: Text(
                      'Meal Prep',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? primaryAccent : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPrepScreen())),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: isDark ? primaryAccent : AppColors.primary,
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.auto_fix_high_outlined, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                    label: Text(
                      'Bù Trừ Calo',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? primaryAccent : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieCompensationScreen())),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Expanded(child: Center(child: CircularProgressIndicator(color: primaryAccent)))
          else if (_diaryData != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(isDark, primaryAccent),
                    const SizedBox(height: 16),
                    _buildMealSection('Bữa sáng', 'breakfast', isDark, primaryAccent),
                    _buildMealSection('Bữa trưa', 'lunch', isDark, primaryAccent),
                    _buildMealSection('Bữa tối', 'dinner', isDark, primaryAccent),
                    _buildMealSection('Ăn vặt', 'snack', isDark, primaryAccent),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    return Container(
      color: isDark ? const Color(0xFF151B18) : AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : AppColors.onSurface),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            dateStr,
            style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: isDark ? Colors.white : AppColors.onSurface),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, Color primaryAccent) {
    final summary = _diaryData!['summary'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A222D) : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Calories', '${summary['totalCalories']}', 'kcal', isDark),
          _buildSummaryItem('Protein', '${summary['totalProtein']}', 'g', isDark),
          _buildSummaryItem('Carbs', '${summary['totalCarbs']}', 'g', isDark),
          _buildSummaryItem('Fat', '${summary['totalFat']}', 'g', isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headline(color: Colors.white),
        ),
        Text(
          '$label ($unit)',
          style: AppTypography.labelCaption(color: isDark ? const Color(0xFF94A3B8) : AppColors.surface),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, String mealType, bool isDark, Color primaryAccent) {
    final meals = _diaryData!['meals'][mealType];
    final items = meals['items'] as List;
    final totalCal = meals['totalCalories'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.onSurface)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalCal kcal',
                style: AppTypography.bodyMedium(color: isDark ? primaryAccent : AppColors.primary)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Chưa có món ăn nào',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.grey),
            )
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['foodName'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${item['servingSize']} ${item['servingUnit']}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item['calories']} kcal',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE1E3E1) : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? primaryAccent : AppColors.primary,
            ),
            onPressed: () => _showAddFoodDialog(mealType),
            icon: Icon(Icons.add_circle_outline, color: isDark ? primaryAccent : AppColors.primary),
            label: Text(
              'Thêm món',
              style: TextStyle(color: isDark ? primaryAccent : AppColors.primary, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}

