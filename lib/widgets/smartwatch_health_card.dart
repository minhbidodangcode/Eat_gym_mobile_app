import 'dart:async';
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

class _SmartwatchHealthCardState extends State<SmartwatchHealthCard>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Kích hoạt quét tự động ngay khi vừa mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoSync();
    });

    // Phương án A: Tự động quét định kỳ mỗi 30 giây khi đang mở ứng dụng
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _triggerAutoSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi người dùng chuyển từ Nothing X hoặc ứng dụng khác quay lại EatGym
    if (state == AppLifecycleState.resumed) {
      _triggerAutoSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerAutoSync() async {
    if (_isSyncing || !mounted) return;
    setState(() => _isSyncing = true);

    try {
      await widget.model.syncSmartwatchHealthData();
      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
          _isSyncing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
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
                            'Nothing X • 0h - 24h mỗi ngày',
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
              // Realtime Auto Polling Pill
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
                      decoration: BoxDecoration(
                        color: _isSyncing ? Colors.amber : AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSyncing ? 'SYNCING...' : 'REAL-TIME',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _isSyncing ? Colors.amber : AppColors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2 Metric Blocks: Calo & Số bước chân
          Row(
            children: [
              // Calo
              Expanded(
                child: _buildMetricBlock(
                  isDark: isDark,
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.fire,
                  label: 'Calo tiêu hao',
                  value: '${model.todayCaloriesBurned} kcal',
                ),
              ),
              const SizedBox(width: 12),
              // Số bước chân
              Expanded(
                child: _buildMetricBlock(
                  isDark: isDark,
                  icon: Icons.directions_walk,
                  iconColor: AppColors.green,
                  label: 'Số bước chân',
                  value: '${model.todaySteps} bước',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Thông tin đồng bộ tự động thời gian thực (Phương án A)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 14,
                    color: isDark ? const Color(0xFF8E918F) : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tự động đồng bộ mỗi 30s',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8E918F) : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                _lastSyncTime != null
                    ? 'Cập nhật: ${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}:${_lastSyncTime!.second.toString().padLeft(2, '0')}'
                    : 'Đang theo dõi...',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6E716F) : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181D1B) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isDark ? 18 : 14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFC4C7C5) : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
