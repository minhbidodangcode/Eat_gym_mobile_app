import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/meal_plan_service.dart';
import '../services/nutrition_advanced_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Ức gà 4 bữa trưa');
  final _servings = TextEditingController(text: '4');
  final _weight = TextEditingController(text: '1000');

  List<Map<String, dynamic>> _factors = [];
  List<MealPlan> _plans = [];
  String? _factorId;
  String _mealType = 'lunch';
  DateTime _prepDate = DateTime.now();
  DateTime _thawAt = DateTime.now().add(const Duration(days: 1, hours: 20));
  bool _freeze = true;
  bool _saving = false;
  bool _loading = true;
  double? _tdee;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    _weight.dispose();
    super.dispose();
  }

  double get _factor {
    if (_factorId == null || _factors.isEmpty) return 0.8;
    final f = _factors.firstWhere(
      (item) => item['id'].toString() == _factorId,
      orElse: () => _factors.first,
    );
    return (f['rawToCookedFactor'] as num?)?.toDouble() ?? 0.8;
  }

  double get _inputWeightVal => double.tryParse(_weight.text) ?? 1000;
  int get _servingsVal => int.tryParse(_servings.text) ?? 4;
  double get _cookedPerServing => _servingsVal > 0 ? (_inputWeightVal * _factor) / _servingsVal : 0;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await Future.wait<dynamic>([
        NutritionAdvancedApiService.getYieldFactors(),
        MealPlanService.loadPlans(),
        ApiService.getProfile(),
      ]);
      if (!mounted) return;
      List<Map<String, dynamic>> factors = [];
      if (values[0] != null && values[0]['yieldFactors'] is List) {
        factors = List<Map<String, dynamic>>.from(values[0]['yieldFactors']);
      }
      if (factors.isEmpty) {
        factors = [
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
      setState(() {
        _factors = factors;
        _factorId = factors.first['id'].toString();
        _plans = List<MealPlan>.from(values[1]);
        _tdee = (values[2]?['tdeeKcal'] as num?)?.toDouble() ?? 2200;
      });
    } catch (_) {
      if (_factors.isEmpty) {
        _factors = [
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
        _factorId = _factors.first['id'].toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate({required bool thaw}) async {
    final initial = thaw ? _thawAt : _prepDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    if (!thaw) {
      setState(() => _prepDate = DateTime(date.year, date.month, date.day, _prepDate.hour, _prepDate.minute));
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_thawAt),
    );
    if (time != null) {
      setState(() => _thawAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _factorId == null) return;
    setState(() => _saving = true);
    try {
      String? batchId;
      try {
        final result = await NutritionAdvancedApiService.createMealPrepBatch(
          name: _name.text.trim(),
          servings: int.parse(_servings.text),
          notes: 'Kế hoạch ${_mealLabel(_mealType)}${_freeze ? ' • bảo quản đông' : ''}',
          items: [
            {'yieldFactorId': _factorId, 'inputWeightG': double.parse(_weight.text), 'inputState': 'raw'}
          ],
        );
        batchId = result['batch']?['id']?.toString();
      } catch (_) {}

      final plan = MealPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        servings: int.parse(_servings.text),
        mealType: _mealType,
        prepDate: _prepDate,
        storedFrozen: _freeze,
        thawAt: _freeze ? _thawAt : null,
        batchId: batchId,
      );
      await MealPlanService.savePlan(plan);
      if (!mounted) return;
      setState(() {
        _plans = [..._plans, plan]..sort((a, b) => (a.thawAt ?? a.prepDate).compareTo(b.thawAt ?? b.prepDate));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _freeze
                ? '❄️ Đã lập kế hoạch và kích hoạt thông báo nhắc rã đông!'
                : '🍱 Đã lưu kế hoạch Meal Prep thành công!',
          ),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chưa thể lưu kế hoạch: $error'),
            backgroundColor: AppColors.fire,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _date(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} lúc ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _mealLabel(String value) =>
      const {
        'breakfast': 'Bữa sáng',
        'lunch': 'Bữa trưa',
        'dinner': 'Bữa tối',
        'snack': 'Bữa phụ',
      }[value] ?? value;

  Color _mealColor(String value) =>
      const {
        'breakfast': Color(0xFFFFB300),
        'lunch': Color(0xFF00E676),
        'dinner': Color(0xFF2979FF),
        'snack': Color(0xFFAB47BC),
      }[value] ?? const Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = SettingsService.instance.currentColor;
    final cardColor = isDark ? const Color(0xFF151B18) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Kế hoạch Meal Prep & Rã Đông',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textColor,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0B0E0D) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner TDEE & Hướng dẫn
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.15),
                          const Color(0xFF2563EB).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.kitchen_rounded, color: primaryColor, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lập kế hoạch theo nhu cầu cá nhân',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _tdee != null
                                    ? 'Mục tiêu: ${_tdee!.round()} kcal/ngày. Hãy chia mẻ nguyên liệu thành các hộp nhỏ sẵn sàng cho các ngày tới.'
                                    : 'Nấu mẻ lớn, tự động tính khối lượng chín từng hộp và hẹn giờ rã đông tự động.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  color: subTextColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Khối Form Lập kế hoạch
                  Text(
                    'TẠO KẾ HOẠCH NẤU MỚI',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên kế hoạch
                          TextFormField(
                            controller: _name,
                            style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Tên kế hoạch',
                              labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                              hintText: 'Ví dụ: Ức gà 4 bữa trưa',
                              hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6), fontSize: 13),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                              prefixIcon: Icon(Icons.bookmark_border_rounded, color: primaryColor, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên kế hoạch' : null,
                          ),
                          const SizedBox(height: 14),

                          // Số hộp & Bữa dùng
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _servings,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Số hộp (bữa)',
                                    labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                    prefixIcon: Icon(Icons.takeout_dining_rounded, color: primaryColor, size: 20),
                                  ),
                                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Tối thiểu 1' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _mealType,
                                  dropdownColor: isDark ? const Color(0xFF1E2420) : Colors.white,
                                  style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Bữa dùng',
                                    labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'breakfast', child: Text('Sáng')),
                                    DropdownMenuItem(value: 'lunch', child: Text('Trưa')),
                                    DropdownMenuItem(value: 'dinner', child: Text('Tối')),
                                    DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                                  ],
                                  onChanged: (v) => setState(() => _mealType = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Chọn nguyên liệu & cách nấu
                          DropdownButtonFormField<String>(
                            initialValue: _factorId,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E2420) : Colors.white,
                            style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w600, fontSize: 13.5),
                            decoration: InputDecoration(
                              labelText: 'Nguyên liệu & cách nấu',
                              labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                              prefixIcon: Icon(Icons.restaurant_menu_rounded, color: primaryColor, size: 20),
                            ),
                            items: _factors
                                .map((f) => DropdownMenuItem(
                                      value: f['id'].toString(),
                                      child: Text(
                                        '${f['ingredientName']} • ${f['cookingMethod']} (x${(f['rawToCookedFactor'] as num).toStringAsFixed(2)})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _factorId = v),
                          ),
                          const SizedBox(height: 14),

                          // Khối lượng sống cần chuẩn bị
                          TextFormField(
                            controller: _weight,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Khối lượng sống cần chuẩn bị (g)',
                              labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                              prefixIcon: Icon(Icons.scale_rounded, color: primaryColor, size: 20),
                            ),
                            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập khối lượng hợp lệ' : null,
                          ),
                          const SizedBox(height: 12),

                          // Bảng ước tính tự động cho từng hộp
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dự tính: ~${(_inputWeightVal * _factor).round()}g chín tổng mẻ • Cân ~${_cookedPerServing.round()}g thịt chín/hộp',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ngày nấu
                          InkWell(
                            onTap: () => _pickDate(thaw: false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined, color: primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Ngày nấu:', style: TextStyle(color: subTextColor, fontSize: 13)),
                                  const Spacer(),
                                  Text(_date(_prepDate), style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_calendar_outlined, size: 16, color: subTextColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bảo quản ngăn đông switch
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _freeze,
                            activeTrackColor: primaryColor,
                            activeThumbColor: primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                            onChanged: (v) => setState(() => _freeze = v),
                            title: Text('Bảo quản ngăn đông', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor)),
                            subtitle: Text('Tự động lên lịch nhắc bạn chuyển xuống ngăn mát trước khi ăn', style: TextStyle(color: subTextColor, fontSize: 11.5)),
                          ),

                          // Nhắc rã đông (nếu bật ngăn đông)
                          if (_freeze) ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDate(thaw: true),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.ac_unit_rounded, color: primaryColor, size: 20),
                                    const SizedBox(width: 10),
                                    Text('Nhắc rã đông lúc:', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text(_date(_thawAt), style: GoogleFonts.spaceGrotesk(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit_calendar_rounded, size: 16, color: primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Nút Lưu kế hoạch
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _saving || _factorId == null ? null : _save,
                              icon: _saving
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.add_task_rounded, size: 20),
                              label: Text(
                                'LƯU KẾ HOẠCH & ĐẶT LỊCH RÃ ĐÔNG',
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Khối Danh sách kế hoạch sắp tới
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KẾ HOẠCH SẮP TỚI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        '${_plans.length} kế hoạch',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_plans.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_rounded, size: 36, color: subTextColor.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có kế hoạch Meal Prep nào',
                            style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hãy lập mẻ nấu đầu tiên để hệ thống tự động nhắc nhở rã đông chuẩn giờ.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._plans.map((plan) {
                      final mealColor = _mealColor(plan.mealType);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (plan.storedFrozen ? const Color(0xFF00E5FF) : mealColor).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                plan.storedFrozen ? Icons.ac_unit_rounded : Icons.restaurant_rounded,
                                color: plan.storedFrozen ? const Color(0xFF00E5FF) : mealColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          plan.name,
                                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: mealColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _mealLabel(plan.mealType),
                                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: mealColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${plan.servings} hộp • Ngày nấu: ${_date(plan.prepDate)}',
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                  if (plan.storedFrozen && plan.thawAt != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFF00E5FF)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Nhắc rã đông: ${_date(plan.thawAt!)}',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF00E5FF),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              tooltip: 'Xóa kế hoạch',
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await MealPlanService.deletePlan(plan);
                                if (!mounted) return;
                                setState(() => _plans.removeWhere((p) => p.id == plan.id));
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Đã xóa kế hoạch & hủy nhắc nhở.'), behavior: SnackBarBehavior.floating),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
