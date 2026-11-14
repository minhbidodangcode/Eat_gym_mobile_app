import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/meal_plan_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'nutrigym_chatbot_screen.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  List<MealPlan> _plans = [];
  bool _loading = true;
  double? _tdee;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await Future.wait<dynamic>([
        MealPlanService.loadPlans(),
        ApiService.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = List<MealPlan>.from(values[0]);
        _tdee = (values[1]?['tdeeKcal'] as num?)?.toDouble() ?? 2200;
      });
    } catch (_) {
      final plans = await MealPlanService.loadPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChatbot() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutriGymChatbotScreen()),
    );
    if (mounted) {
      _load();
    }
  }

  Future<void> _deleteMeal(MealPlan plan) async {
    await MealPlanService.deletePlan(plan);
    if (mounted) {
      setState(() => _plans.removeWhere((p) => p.id == plan.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa món "${plan.name}" khỏi lịch.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ thực đơn?'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch ăn và hủy tất cả thông báo nhắc rã đông không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fire),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('XÓA HẾT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MealPlanService.clearAllPlans();
      if (mounted) {
        setState(() => _plans.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã làm trống lịch ăn thành công.'),
            behavior: SnackBarBehavior.floating,
          ),
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

  Map<String, List<MealPlan>> _groupPlansByDay() {
    final Map<String, List<MealPlan>> groups = {};
    for (final plan in _plans) {
      final weekdayStr = _getWeekdayName(plan.prepDate.weekday);
      final dateFormatted = '${plan.prepDate.day.toString().padLeft(2, '0')}/${plan.prepDate.month.toString().padLeft(2, '0')}';
      final key = '$weekdayStr ($dateFormatted)';
      groups.putIfAbsent(key, () => []).add(plan);
    }

    final order = {'breakfast': 0, 'sáng': 0, 'lunch': 1, 'trưa': 1, 'dinner': 2, 'tối': 2, 'snack': 3, 'phụ': 3};
    for (final dayMeals in groups.values) {
      dayMeals.sort((a, b) {
        int orderA = 99;
        int orderB = 99;
        order.forEach((k, v) {
          if (a.mealType.toLowerCase().contains(k)) orderA = v;
          if (b.mealType.toLowerCase().contains(k)) orderB = v;
        });
        return orderA.compareTo(orderB);
      });
    }

    return groups;
  }

  String _formatDateTime(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} lúc ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _mealLabel(String value) {
    final v = value.toLowerCase();
    if (v.contains('sáng') || v == 'breakfast') return 'Bữa sáng';
    if (v.contains('trưa') || v == 'lunch') return 'Bữa trưa';
    if (v.contains('tối') || v == 'dinner') return 'Bữa tối';
    if (v.contains('phụ') || v == 'snack') return 'Bữa phụ';
    return value;
  }

  Color _mealColor(String value) {
    final v = value.toLowerCase();
    if (v.contains('sáng') || v == 'breakfast') return const Color(0xFFFFB300);
    if (v.contains('trưa') || v == 'lunch') return const Color(0xFF00E676);
    if (v.contains('tối') || v == 'dinner') return const Color(0xFF2979FF);
    if (v.contains('phụ') || v == 'snack') return const Color(0xFFAB47BC);
    return const Color(0xFF00E676);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = SettingsService.instance.currentColor;
    final cardColor = isDark ? const Color(0xFF151B18) : AppColors.surface;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outline;
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textMuted;

    final groupedPlans = _groupPlansByDay();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAFF),
        appBar: AppBar(
        title: Text(
          'Lịch Ăn & Meal Prep AI',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textColor,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            tooltip: 'Tải lại lịch',
            onPressed: _load,
          ),
          if (_plans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Xóa toàn bộ lịch',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryColor,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Thông Minh NutriGym AI
                    Container(
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
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lịch Ăn Khoa Học Cùng AI',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _tdee != null
                                          ? 'Mục tiêu: ${_tdee!.round()} kcal/ngày • Tự động tính Macros'
                                          : 'Tự động tính calo, rã đông & đi chợ',
                                      style: TextStyle(color: subTextColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Lịch ăn của bạn được lên kế hoạch và tối ưu trực tiếp cùng Trợ lý Chatbot AI. Bạn không cần phải tính toán thủ công từng món!',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: textColor.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _openChatbot,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: Text(
                                'TRÒ CHUYỆN VỚI AI ĐỂ ĐỔI LỊCH ĂN',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tiêu đề & Tổng kết lịch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KẾ HOẠCH BỮA ĂN CHI TIẾT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_plans.length} món ăn',
                            style: TextStyle(color: primaryColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Trạng thái nếu rỗng
                    if (_plans.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calendar_today_rounded, size: 40, color: primaryColor),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Chưa có thực đơn nào trong lịch',
                              style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hãy mở Chatbot AI để tạo thực đơn theo những nguyên liệu có sẵn trong tủ lạnh hoặc theo mục tiêu tăng cơ giảm mỡ!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: subTextColor, fontSize: 12.5, height: 1.4),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _openChatbot,
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Tạo Thực Đơn Cùng AI Ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      )
                    else
                      // Danh sách các ngày đã lên lịch
                      ...groupedPlans.entries.map((entry) {
                        final dayTitle = entry.key;
                        final dayMeals = entry.value;

                        // Tính tổng Macros của ngày & Thông tin Carb Cycling
                        int dayKcal = 0;
                        int dayProtein = 0;
                        int dayCarbs = 0;
                        String? dayWorkoutFocus;
                        String? dayWorkoutType;
                        String? dayCarbLevel;

                        for (final m in dayMeals) {
                          dayKcal += m.kcal ?? 0;
                          dayProtein += m.protein ?? 0;
                          dayCarbs += m.carbs ?? 0;
                          if (m.workoutFocus != null && m.workoutFocus!.isNotEmpty) {
                            dayWorkoutFocus = m.workoutFocus;
                          }
                          if (m.workoutType != null && m.workoutType!.isNotEmpty) {
                            dayWorkoutType = m.workoutType;
                          }
                          if (m.carbLevel != null && m.carbLevel!.isNotEmpty) {
                            dayCarbLevel = m.carbLevel;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Ngày
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event_note_rounded, size: 18, color: primaryColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            dayTitle,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        if (dayKcal > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E2420) : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: borderColor),
                                            ),
                                            child: Text(
                                              '🔥 $dayKcal kcal • 🌾 ${dayCarbs}g C • 💪 ${dayProtein}g P',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (dayWorkoutFocus != null || dayCarbLevel != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (dayWorkoutType == 'heavy'
                                                      ? const Color(0xFFEF4444)
                                                      : (dayWorkoutType == 'rest'
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFFF59E0B)))
                                                  .withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              dayWorkoutType == 'heavy'
                                                  ? '🔥 High Carb (Tập nặng)'
                                                  : (dayWorkoutType == 'rest'
                                                      ? '🌿 Low Carb (Nghỉ ngơi)'
                                                      : '⚡ Moderate Carb (Tập nhẹ)'),
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: dayWorkoutType == 'heavy'
                                                    ? const Color(0xFFEF4444)
                                                    : (dayWorkoutType == 'rest'
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFF59E0B)),
                                              ),
                                            ),
                                          ),
                                          if (dayWorkoutFocus != null) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                dayWorkoutFocus,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: subTextColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Danh sách món trong ngày
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: dayMeals.map((plan) {
                                    final mealColor = _mealColor(plan.mealType);
                                    final isFrozen = plan.storedFrozen;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1A221E) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: (isFrozen ? const Color(0xFF00E5FF) : mealColor).withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isFrozen ? Icons.ac_unit_rounded : Icons.restaurant_rounded,
                                              color: isFrozen ? const Color(0xFF0097A7) : mealColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: mealColor.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        _mealLabel(plan.mealType),
                                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: mealColor),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isFrozen
                                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                                            : AppColors.green.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        isFrozen ? '❄️ Meal Prep' : '🍳 Nấu tươi',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: isFrozen ? const Color(0xFF0097A7) : AppColors.green,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  plan.name,
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
                                                ),
                                                if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    plan.notes!,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: subTextColor,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    if (plan.kcal != null)
                                                      Text(
                                                        '🔥 ${plan.kcal} kcal',
                                                        style: const TextStyle(fontSize: 11.5, color: AppColors.fire, fontWeight: FontWeight.bold),
                                                      ),
                                                    if (plan.protein != null)
                                                      Text(
                                                        '💪 ${plan.protein}g đạm',
                                                        style: TextStyle(fontSize: 11.5, color: primaryColor, fontWeight: FontWeight.bold),
                                                      ),
                                                    if (plan.carbs != null)
                                                      Text(
                                                        '🌾 ${plan.carbs}g C',
                                                        style: TextStyle(fontSize: 11, color: subTextColor),
                                                      ),
                                                    if (plan.fat != null)
                                                      Text(
                                                        '🥑 ${plan.fat}g F',
                                                        style: TextStyle(fontSize: 11, color: subTextColor),
                                                      ),
                                                  ],
                                                ),
                                                if (isFrozen && plan.thawAt != null) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFF0097A7)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Nhắc rã đông: ${_formatDateTime(plan.thawAt!)}',
                                                        style: GoogleFonts.inter(
                                                          color: const Color(0xFF0097A7),
                                                          fontSize: 11,
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
                                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                            tooltip: 'Xóa món này',
                                            onPressed: () => _deleteMeal(plan),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
