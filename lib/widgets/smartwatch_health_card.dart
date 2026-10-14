import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badges_and_report_model.dart';
import '../theme/app_theme.dart';

class SmartwatchHealthCard extends StatefulWidget {
  final BadgesAndReportModel model;
  final bool isDark;

  const SmartwatchHealthCard({
    super.key,
    required this.model,
    this.isDark = false,
  });

  @override
  State<SmartwatchHealthCard> createState() => _SmartwatchHealthCardState();
}

class _SmartwatchHealthCardState extends State<SmartwatchHealthCard> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final result = await widget.model.syncSmartwatchHealthData();
    if (mounted) {
      setState(() => _isSyncing = false);
      final steps = result['steps'] ?? 0;
      final cal = result['caloriesBurned'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Đã đồng bộ $cal kcal và $steps bước từ ${widget.model.healthSourceLabel}!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191C1B) : AppColors.surface,
        borderRadius: BorderRadius.circular(isDark ? 28 : 16),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.watch,
                        size: 22,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐỒNG HỒ SỨC KHỎE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Health Connect / Apple Health',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFFC4C7C5) : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'REAL-TIME',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2 Live Metric Blocks
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181D1B) : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(isDark ? 20 : 14),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 18, color: AppColors.fire),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Calo tiêu hao',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFC4C7C5) : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${model.todayCaloriesBurned} kcal',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181D1B) : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(isDark ? 20 : 14),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, size: 18, color: AppColors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Số bước chân',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFC4C7C5) : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${model.todaySteps}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync Action Button (Nút trắng chữ đen tương tự Image 2)
          GestureDetector(
            onTap: _isSyncing ? null : _handleSync,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: isDark
                    ? null
                    : Border.all(color: AppColors.outlineVariant, width: 1.5),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: _isSyncing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF191C1D)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'ĐANG ĐỒNG BỘ...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                              color: const Color(0xFF191C1D),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sync,
                            size: 20,
                            color: Color(0xFF191C1D),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ĐỒNG BỘ THỜI GIAN THỰC',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                              color: const Color(0xFF191C1D),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
