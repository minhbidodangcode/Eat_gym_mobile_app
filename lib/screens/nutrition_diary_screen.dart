import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

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
    final calCtrl = TextEditingController();
    final servingCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Thêm món vào ${mealType.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: foodCtrl, decoration: const InputDecoration(labelText: 'Tên món ăn')),
            TextField(controller: servingCtrl, decoration: const InputDecoration(labelText: 'Khẩu phần (vd: 1 bát)')),
            TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.addNutritionLog({
                  'logDate': _selectedDate.toIso8601String().split('T')[0],
                  'mealType': mealType,
                  'foodName': foodCtrl.text,
                  'servingSize': 1,
                  'servingUnit': servingCtrl.text.isNotEmpty ? servingCtrl.text : 'phần',
                  'calories': double.tryParse(calCtrl.text) ?? 0,
                  'protein': 0, 'carbs': 0, 'fat': 0,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhật Ký Dinh Dưỡng'),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_diaryData != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildMealSection('Bữa sáng', 'breakfast'),
                    _buildMealSection('Bữa trưa', 'lunch'),
                    _buildMealSection('Bữa tối', 'dinner'),
                    _buildMealSection('Ăn vặt', 'snack'),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Center(child: Text('Không có dữ liệu'))),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
          Text(
            dateStr,
            style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _diaryData!['summary'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Calories', '${summary['totalCalories']}', 'kcal'),
          _buildSummaryItem('Protein', '${summary['totalProtein']}', 'g'),
          _buildSummaryItem('Carbs', '${summary['totalCarbs']}', 'g'),
          _buildSummaryItem('Fat', '${summary['totalFat']}', 'g'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: AppTypography.headline(color: AppColors.onPrimary)),
        Text('$label ($unit)', style: AppTypography.labelCaption(color: AppColors.surface)),
      ],
    );
  }

  Widget _buildMealSection(String title, String mealType) {
    final meals = _diaryData!['meals'][mealType];
    final items = meals['items'] as List;
    final totalCal = meals['totalCalories'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
              Text('$totalCal kcal', style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Chưa có món ăn nào', style: TextStyle(color: AppColors.grey))
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
                        Text(item['foodName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${item['servingSize']} ${item['servingUnit']}', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${item['calories']} kcal'),
                ],
              ),
            )),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showAddFoodDialog(mealType),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Thêm món'),
          )
        ],
      ),
    );
  }
}
