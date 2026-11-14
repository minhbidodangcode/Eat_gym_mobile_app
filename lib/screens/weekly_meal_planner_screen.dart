import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/carb_cycling_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class WeeklyMealPlannerScreen extends StatefulWidget {
  final double? initialTdee;

  const WeeklyMealPlannerScreen({super.key, this.initialTdee});

  @override
  State<WeeklyMealPlannerScreen> createState() => _WeeklyMealPlannerScreenState();
}

class _WeeklyMealPlannerScreenState extends State<WeeklyMealPlannerScreen> {
  double _tdee = 2200;
  bool _loading = true;
  String _selectedPresetId = 'standard_4day';
  int _selectedDayIndex = 0; // 0: Thứ 2 ... 6: Chủ nhật
  List<CarbDaySchedule> _weeklyPlan = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    double baseline = widget.initialTdee ?? 2200;
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        CarbCyclingService.syncWithDatabase(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      if (profile != null && profile['tdeeKcal'] != null) {
        baseline = (profile['tdeeKcal'] as num).toDouble();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _tdee = baseline;
      _weeklyPlan = CarbCyclingService.generateWeeklyPlan(
        baselineKcal: _tdee,
        presetId: _selectedPresetId,
      );
      _loading = false;
    });
  }

  void _changePreset(String presetId) {
    setState(() {
      _selectedPresetId = presetId;
      _weeklyPlan = CarbCyclingService.generateWeeklyPlan(
        baselineKcal: _tdee,
        presetId: presetId,
      );
    });
  }

  void _regeneratePlan() {
    setState(() {
      _weeklyPlan = CarbCyclingService.generateWeeklyPlan(
        baselineKcal: _tdee,
        presetId: _selectedPresetId,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm mới thực đơn tuần theo chu kỳ Carb Cycling!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showChangeWorkoutSheet(int dayIndex) {
    final day = _weeklyPlan[dayIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cấu hình buổi tập: ${day.dayName}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn cường độ tập luyện để hệ thống tự động điều chỉnh lượng tinh bột (Carbs) và Calo tương ứng:',
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),

                // 1. Tập nặng (High Carb)
                _buildWorkoutOptionTile(
                  title: '🔥 Tập Nặng (Chân / Lưng)',
                  subtitle: 'Tăng tinh bột (High Carb • 50% Calo) nạp đầy glycogen',
                  badgeColor: const Color(0xFFEF4444),
                  isSelected: day.dayType == CarbDayType.heavy,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateDayWorkoutType(dayIndex, CarbDayType.heavy, 'Chân & Lưng (Tập nặng)');
                  },
                ),
                const SizedBox(height: 10),

                // 2. Tập nhẹ (Moderate Carb)
                _buildWorkoutOptionTile(
                  title: '⚡ Tập Nhẹ / Vừa (Ngực / Tay / Vai / Cardio)',
                  subtitle: 'Giữ mức vừa phải (Moderate Carb • 35% Calo) cân bằng năng lượng',
                  badgeColor: const Color(0xFFF59E0B),
                  isSelected: day.dayType == CarbDayType.light,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateDayWorkoutType(dayIndex, CarbDayType.light, 'Ngực & Tay (Tập vừa)');
                  },
                ),
                const SizedBox(height: 10),

                // 3. Nghỉ ngơi (Low Carb)
                _buildWorkoutOptionTile(
                  title: '🌿 Nghỉ Ngơi (Hồi Phục / Nghỉ)',
                  subtitle: 'Hạ thấp Carb (Low Carb • 20% Calo) kích hoạt đốt mỡ tự nhiên',
                  badgeColor: const Color(0xFF10B981),
                  isSelected: day.dayType == CarbDayType.rest,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateDayWorkoutType(dayIndex, CarbDayType.rest, 'Nghỉ ngơi & Phục hồi');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutOptionTile({
    required String title,
    required String subtitle,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? badgeColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? badgeColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: badgeColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _updateDayWorkoutType(int dayIndex, CarbDayType newType, String newFocus) {
    final currentDay = _weeklyPlan[dayIndex];
    final targetKcal = (_tdee * newType.kcalMultiplier).round();
    final targetCarbs = ((targetKcal * newType.carbPct) / 4.0).round();
    final targetProtein = ((targetKcal * newType.proteinPct) / 4.0).round();
    final targetFat = ((targetKcal * newType.fatPct) / 9.0).round();

    final regeneratedDays = CarbCyclingService.generateWeeklyPlan(
      baselineKcal: _tdee,
      startDate: currentDay.date.subtract(Duration(days: dayIndex)),
    );

    // Lấy 4 bữa ăn phù hợp với newType
    final matchingDay = regeneratedDays.firstWhere((d) => d.dayType == newType, orElse: () => regeneratedDays[0]);

    setState(() {
      _weeklyPlan[dayIndex] = currentDay.copyWith(
        dayType: newType,
        focus: newFocus,
        targetKcal: targetKcal,
        targetCarbs: targetCarbs,
        targetProtein: targetProtein,
        targetFat: targetFat,
        meals: matchingDay.meals,
      );
    });
  }

  void _swapMeal(int mealIndex) {
    final currentDay = _weeklyPlan[_selectedDayIndex];
    final currentMeal = currentDay.meals[mealIndex];
    final mealName = currentMeal['name']?.toString() ?? '';
    final mealType = currentMeal['mealType']?.toString() ?? 'Bữa trưa';

    final newMeal = CarbCyclingService.swapMeal(currentDay.dayType, mealType, mealName);
    if (newMeal.isNotEmpty) {
      setState(() {
        currentDay.meals[mealIndex] = newMeal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi món mới: ${newMeal['name']}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _applyWeeklyPlan() async {
    setState(() => _loading = true);
    try {
      await CarbCyclingService.applyPlanToCalendar(_weeklyPlan);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã áp dụng thực đơn tuần Carb Cycling vào Lịch Ăn thành công!'),
          backgroundColor: Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi áp dụng thực đơn: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = SettingsService.instance.currentColor;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAFF);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outline;
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textMuted;

    final selectedDay = _weeklyPlan.isNotEmpty ? _weeklyPlan[_selectedDayIndex] : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Thực Đơn Tuần Carb Cycling',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới thực đơn tuần',
            onPressed: _loading ? null : _regeneratePlan,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BANNER GIẢI THÍCH NGUYÊN LÝ CARB CYCLING
                  _buildScientificBanner(isDark, primaryColor, textColor, subTextColor),

                  const SizedBox(height: 16),

                  // 2. CHỌN MẪU CHU KỲ (PRESETS)
                  _buildPresetSelector(isDark, primaryColor, textColor, cardColor, borderColor),

                  const SizedBox(height: 18),

                  // 3. THANH 7 NGÀY TRONG TUẦN (INTERACTIVE 7-DAY BAR)
                  _buildWeeklyDaysRow(isDark, primaryColor, textColor, cardColor, borderColor),

                  const SizedBox(height: 14),

                  // 4. BIỂU ĐỒ SÓNG CARB CYCLING (CARB WAVE VISUALIZER)
                  _buildCarbWaveCard(isDark, primaryColor, cardColor, borderColor, textColor, subTextColor),

                  const SizedBox(height: 18),

                  // 5. CHI TIẾT NGÀY ĐƯỢC CHỌN & DANH SÁCH MÓN ĂN
                  if (selectedDay != null) ...[
                    _buildSelectedDayDetail(selectedDay, isDark, primaryColor, cardColor, borderColor, textColor, subTextColor),
                  ],

                  const SizedBox(height: 80), // khoảng trống cho nút bottom
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _loading ? null : _applyWeeklyPlan,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                'ÁP DỤNG THỰC ĐƠN TUẦN VÀO LỊCH ĂN',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. BANNER NGUYÊN LÝ
  Widget _buildScientificBanner(bool isDark, Color primaryColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.16),
            const Color(0xFF2563EB).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync_alt_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cơ Chế Carb Cycling Khoa Học',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tự động điều tiết Carb theo chu kỳ tập luyện',
                      style: TextStyle(color: subTextColor, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBannerBullet(
            badge: '🔥 Ngày tập nặng (Chân/Lưng)',
            content: 'Tự động TĂNG tinh bột (High Carb) nạp đầy glycogen cơ bắp, hỗ trợ đẩy tạ nặng & phục hồi tối đa.',
            badgeColor: const Color(0xFFEF4444),
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildBannerBullet(
            badge: '⚡ Ngày tập nhẹ (Ngực/Tay/Cardio)',
            content: 'Giữ mức tinh bột VỪA PHẢI (Moderate Carb) cân bằng năng lượng và duy trì sự săn chắc.',
            badgeColor: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildBannerBullet(
            badge: '🌿 Ngày nghỉ ngơi (Hồi phục)',
            content: 'HẠ THẤP tinh bột (Low Carb), tăng chất béo tốt để kích hoạt đốt mỡ tự nhiên và tăng độ nhạy insulin.',
            badgeColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerBullet({
    required String badge,
    required String content,
    required Color badgeColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // 2. CHỌN MẪU CHU KỲ
  Widget _buildPresetSelector(bool isDark, Color primaryColor, Color textColor, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHỌN CHU KỲ TẬP LUYỆN TUẦN',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: CarbCyclingService.presets.map((preset) {
              final isSelected = preset.id == _selectedPresetId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(preset.title),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : textColor,
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: cardColor,
                  side: BorderSide(
                    color: isSelected ? primaryColor : borderColor,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => _changePreset(preset.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 3. THANH 7 NGÀY TUẦN
  Widget _buildWeeklyDaysRow(bool isDark, Color primaryColor, Color textColor, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LỊCH 7 NGÀY TRONG TUẦN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: primaryColor,
              ),
            ),
            Text(
              'Chạm vào ngày để xem món',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final day = _weeklyPlan[index];
            final isSelected = index == _selectedDayIndex;
            final badgeColor = day.dayType.badgeColor;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 5),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? badgeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                        : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? badgeColor : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day.dayName.replaceAll('Thứ ', 'T').replaceAll('Chủ Nhật', 'CN'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? badgeColor : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          day.dayType == CarbDayType.heavy
                              ? 'High'
                              : (day.dayType == CarbDayType.light ? 'Mid' : 'Low'),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.targetCarbs}g C',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? badgeColor : textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 4. BIỂU ĐỒ SÓNG CARB CYCLING (CARB WAVE)
  Widget _buildCarbWaveCard(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_weeklyPlan.isEmpty) return const SizedBox.shrink();

    final maxCarb = _weeklyPlan.map((d) => d.targetCarbs).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Đồ Thị Lượng Carb Chu Kỳ Tuần',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                  ),
                ],
              ),
              Text(
                'Hình sin nạp glycogen',
                style: TextStyle(fontSize: 11, color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final d = _weeklyPlan[i];
                final isSelected = i == _selectedDayIndex;
                final heightFactor = maxCarb > 0 ? (d.targetCarbs / maxCarb) : 0.5;
                final color = d.dayType.badgeColor;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${d.targetCarbs}g',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : subTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 18 : 12,
                        height: 55 * heightFactor,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.dayName.replaceAll('Thứ ', 'T').replaceAll('Chủ Nhật', 'CN'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : subTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 5. CHI TIẾT NGÀY ĐƯỢC CHỌN
  Widget _buildSelectedDayDetail(
    CarbDaySchedule day,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    final badgeColor = day.dayType.badgeColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header ngày
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    day.dayType == CarbDayType.heavy
                        ? Icons.fitness_center_rounded
                        : (day.dayType == CarbDayType.light ? Icons.directions_run_rounded : Icons.bedtime_outlined),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            day.dayName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              day.dayType.carbLevel,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.focus,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Đổi buổi tập', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showChangeWorkoutSheet(_selectedDayIndex),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh tiến trình Macros của ngày
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroStat('Calo mục tiêu', '${day.targetKcal} kcal', AppColors.fire),
                          _buildMacroStat('Tinh bột (Carbs)', '${day.targetCarbs}g', badgeColor),
                          _buildMacroStat('Đạm (Protein)', '${day.targetProtein}g', primaryColor),
                          _buildMacroStat('Chất béo (Fat)', '${day.targetFat}g', const Color(0xFFAB47BC)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        day.dayType.description,
                        style: GoogleFonts.inter(fontSize: 11.5, color: subTextColor, height: 1.35),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'THỰC ĐƠN CHI TIẾT TRONG NGÀY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Danh sách 4 bữa ăn
                ...day.meals.asMap().entries.map((entry) {
                  final mealIdx = entry.key;
                  final meal = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161F2E) : const Color(0xFFFBFDFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                meal['mealType'] ?? 'Bữa ăn',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                              label: const Text('Đổi món', style: TextStyle(fontSize: 11)),
                              onPressed: () => _swapMeal(mealIdx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          meal['name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (meal['carbBadge'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meal['carbBadge'],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '🔥 ${meal['kcal']} kcal   ',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.fire),
                            ),
                            Text(
                              '🌾 ${meal['carbs']}g C   ',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                            Text(
                              '💪 ${meal['protein']}g P   ',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                            Text(
                              '🥑 ${meal['fat']}g F',
                              style: TextStyle(fontSize: 11.5, color: subTextColor),
                            ),
                          ],
                        ),
                        if (meal['ingredients'] != null && (meal['ingredients'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (meal['ingredients'] as List).map<Widget>((ing) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ing.toString(),
                                  style: TextStyle(fontSize: 10.5, color: subTextColor),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
