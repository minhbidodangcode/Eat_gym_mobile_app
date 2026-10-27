import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/nutrition_advanced_api_service.dart';
import '../theme/app_theme.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Mẻ gà ăn tuần mới');
  final _weightController = TextEditingController(text: '1000');
  final _servingsController = TextEditingController(text: '4');
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _yieldFactors = [];
  Map<String, dynamic>? _selectedFactor;
  String _inputState = 'raw'; // 'raw' or 'cooked'
  bool _isLoading = false;
  bool _isFetching = true;
  List<Map<String, dynamic>> _savedBatches = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isFetching = true);
    try {
      final factorsRes = await NutritionAdvancedApiService.getYieldFactors();
      if (factorsRes.containsKey('yieldFactors') && factorsRes['yieldFactors'] is List) {
        _yieldFactors = List<Map<String, dynamic>>.from(factorsRes['yieldFactors']);
      }
    } catch (_) {}

    // Fallback nếu server chưa có yield factors
    if (_yieldFactors.isEmpty) {
      _yieldFactors = [
        {
          'id': 'c392fdb2-1a41-4c6e-827d-94c3dc09d27f',
          'ingredientName': 'Ức gà phi lê',
          'cookingMethod': 'Luộc / Hấp',
          'rawToCookedFactor': 0.80,
        },
        {
          'id': 'beef-stirfry-1',
          'ingredientName': 'Thịt thăn bò',
          'cookingMethod': 'Áp chảo / Xào',
          'rawToCookedFactor': 0.72,
        },
        {
          'id': 'salmon-bake-1',
          'ingredientName': 'Phi lê cá hồi',
          'cookingMethod': 'Nướng / Áp chảo',
          'rawToCookedFactor': 0.85,
        },
        {
          'id': 'rice-cooked-1',
          'ingredientName': 'Gạo lứt',
          'cookingMethod': 'Nấu cơm',
          'rawToCookedFactor': 2.40,
        },
      ];
    }

    if (_yieldFactors.isNotEmpty) {
      _selectedFactor = _yieldFactors.first;
    }

    // Load các mẻ nấu đã lưu
    try {
      _savedBatches = await NutritionAdvancedApiService.getMealPrepBatches();
    } catch (_) {}

    if (mounted) setState(() => _isFetching = false);
  }

  double get _factor => (_selectedFactor?['rawToCookedFactor'] as num?)?.toDouble() ?? 0.80;

  double get _inputWeight => double.tryParse(_weightController.text) ?? 1000.0;
  int get _servings => int.tryParse(_servingsController.text) ?? 4;

  double get _rawTotal => _inputState == 'raw' ? _inputWeight : _inputWeight / _factor;
  double get _cookedTotal => _inputState == 'raw' ? _inputWeight * _factor : _inputWeight;

  double get _rawPerServing => _servings > 0 ? _rawTotal / _servings : 0;
  double get _cookedPerServing => _servings > 0 ? _cookedTotal / _servings : 0;

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFactor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại nguyên liệu.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await NutritionAdvancedApiService.createMealPrepBatch(
        name: _nameController.text.trim(),
        servings: _servings,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        items: [
          {
            'yieldFactorId': _selectedFactor!['id'],
            'inputWeightG': _inputWeight,
            'inputState': _inputState,
          }
        ],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo mẻ Meal Prep thành công!'),
          backgroundColor: Color(0xFF00E676),
        ),
      );

      // Refresh list
      _savedBatches = await NutritionAdvancedApiService.getMealPrepBatches();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.fire),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Quy Đổi Meal Prep (Sống - Chín)'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.15), Colors.blue.withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chia hộp thông minh cho Gymer',
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Nấu mẻ lớn nguyên liệu sống, tự động chia đều khối lượng chín cho từng hộp ăn.',
                                  style: AppTypography.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tên mẻ nấu
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên mẻ nấu',
                        hintText: 'VD: Ức gà luộc cả tuần',
                        prefixIcon: Icon(Icons.bookmark_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên mẻ' : null,
                    ),
                    const SizedBox(height: 16),

                    // Chọn nguyên liệu
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedFactor,
                      decoration: const InputDecoration(
                        labelText: 'Nguyên liệu & Phương pháp nấu',
                        prefixIcon: Icon(Icons.restaurant),
                        border: OutlineInputBorder(),
                      ),
                      items: _yieldFactors.map((f) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: f,
                          child: Text(
                            '${f['ingredientName']} (${f['cookingMethod']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFactor = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Trạng thái cân: Sống hay Chín
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cân lúc Sống (Raw)')),
                            selected: _inputState == 'raw',
                            onSelected: (sel) {
                              if (sel) setState(() => _inputState = 'raw');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cân lúc Chín (Cooked)')),
                            selected: _inputState == 'cooked',
                            onSelected: (sel) {
                              if (sel) setState(() => _inputState = 'cooked');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Khối lượng & Số khẩu phần
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Khối lượng (gam)',
                              suffixText: 'g',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập gam > 0' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số hộp',
                              suffixText: 'hộp',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bảng tính toán kết quả Live Calculation
                    Container(
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
                              Text('KẾT QUẢ QUY ĐỔI', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                              Text('Hệ số: ${_factor.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng khối lượng SỐNG:'),
                              Text('${_rawTotal.toStringAsFixed(0)} g', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng khối lượng CHÍN:'),
                              Text('${_cookedTotal.toStringAsFixed(0)} g', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MỖI HỘP ĂN CẦN CHIA:', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  '${_cookedPerServing.toStringAsFixed(0)} g chín',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF008947)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '(tương đương ${_rawPerServing.toStringAsFixed(0)}g sống vào nhật ký calo)',
                              style: AppTypography.bodySmall(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _submitBatch,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('LƯU MẺ MEAL PREP NÀY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),

                    if (_savedBatches.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('Các mẻ đã chuẩn bị gần đây', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedBatches.length,
                        itemBuilder: (ctx, idx) {
                          final b = _savedBatches[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: const Icon(Icons.takeout_dining, color: AppColors.primary),
                              ),
                              title: Text(b['name']?.toString() ?? 'Mẻ nấu', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Khẩu phần: ${b['servings']} hộp · ${b['itemCount'] ?? 1} nguyên liệu'),
                              trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF00E676)),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
