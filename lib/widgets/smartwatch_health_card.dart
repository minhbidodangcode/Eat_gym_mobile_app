import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badges_and_report_model.dart';
import '../services/health_service.dart';
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

    // Kích hoạt quét tự động nếu đã có thiết bị kết nối
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.model.isDeviceConnected) {
        _triggerAutoSync();
      }
    });

    // Quét định kỳ mỗi 30 giây khi đang mở ứng dụng và đã kết nối
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.model.isDeviceConnected) {
        _triggerAutoSync();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.model.isDeviceConnected) {
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
    if (_isSyncing || !mounted || !widget.model.isDeviceConnected) return;
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

  void _showConnectDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.watch, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết Nối Thiết Bị Sức Khỏe',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Chọn nguồn đồng bộ bước chân & calo tiêu hao',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Danh sách các nguồn hỗ trợ
                _buildDeviceOption(
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Google Health Connect',
                  subtitle: 'Tự động đọc từ Samsung Health, Garmin, Xiaomi, Pixel Watch',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final granted = await HealthService.instance.requestAuthorization();
                    if (granted) {
                      await widget.model.connectHealthDevice('Google Health Connect');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã kết nối thành công với Google Health Connect!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chưa cấp quyền Health Connect. Vui lòng thử lại.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildDeviceOption(
                  icon: Icons.watch_outlined,
                  iconColor: const Color(0xFF0F172A),
                  title: 'Nothing X (Nothing Watch / CMF)',
                  subtitle: 'Đồng hồ thông minh Nothing Watch Pro, CMF Watch',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.model.connectHealthDevice('Nothing X');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã liên kết với Nothing X thành công!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildDeviceOption(
                  icon: Icons.favorite_outline,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Apple Health / Apple Watch',
                  subtitle: 'Dành cho thiết bị iOS & Apple Watch',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.model.connectHealthDevice('Apple Health');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã kết nối Apple Health thành công!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildDeviceOption(
                  icon: Icons.sports_gymnastics,
                  iconColor: const Color(0xFFD97706),
                  title: 'Garmin / Samsung Health',
                  subtitle: 'Đồng bộ qua nền tảng dữ liệu sức khỏe thể thao',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.model.connectHealthDevice('Garmin Connect');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã liên kết thiết bị thể thao Garmin!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildDeviceOption(
                  icon: Icons.edit_note,
                  iconColor: const Color(0xFF059669),
                  title: 'Nhập giả lập chỉ số (Dùng thử)',
                  subtitle: 'Đặt giá trị calo và bước chân để kiểm tra tính năng',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManualInputDialog(context);
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

  void _showManualInputDialog(BuildContext context) {
    final stepsCtrl = TextEditingController(text: '6500');
    final calCtrl = TextEditingController(text: '420');

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
          'Thiết lập chỉ số kiểm thử',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số bước chân',
                suffixText: 'bước',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calo tiêu hao',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final steps = int.tryParse(stepsCtrl.text) ?? 0;
              final cal = int.tryParse(calCtrl.text) ?? 0;
              Navigator.pop(dlgCtx);
              await widget.model.connectHealthDevice('Smartwatch (Giả lập)');
              await widget.model.updateDailyHealthMetrics(
                steps: steps,
                caloriesBurned: cal,
                heartRate: 75,
                source: 'Smartwatch (Giả lập)',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật chỉ số sức khỏe thử nghiệm!'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              }
            },
            child: const Text('Lưu & Áp Dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final isDark = widget.isDark;
    final isConnected = model.isDeviceConnected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191C1B) : AppColors.surface,
        borderRadius: BorderRadius.circular(isDark ? 28 : 20),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected ? Icons.watch : Icons.watch_off_outlined,
                        size: 22,
                        color: isConnected
                            ? (isDark ? Colors.white : AppColors.primary)
                            : const Color(0xFF94A3B8),
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
                            isConnected
                                ? '${model.healthSourceLabel} • 0h - 24h mỗi ngày'
                                : 'Chưa kết nối thiết bị theo dõi',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: isConnected
                                  ? (isDark ? const Color(0xFFC4C7C5) : AppColors.onSurfaceVariant)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill
              if (isConnected)
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_off, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'CHƯA KẾT NỐI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // 2 Metric Blocks: Calo & Số bước chân
          Row(
            children: [
              // Calo
              Expanded(
                child: _buildMetricBlock(
                  isDark: isDark,
                  icon: Icons.local_fire_department,
                  iconColor: isConnected ? AppColors.fire : const Color(0xFF94A3B8),
                  label: 'Calo tiêu hao',
                  value: isConnected ? '${model.todayCaloriesBurned} kcal' : '0 kcal',
                  subText: isConnected ? null : 'Chưa có dữ liệu',
                ),
              ),
              const SizedBox(width: 12),
              // Số bước chân
              Expanded(
                child: _buildMetricBlock(
                  isDark: isDark,
                  icon: Icons.directions_walk,
                  iconColor: isConnected ? AppColors.green : const Color(0xFF94A3B8),
                  label: 'Số bước chân',
                  value: isConnected ? '${model.todaySteps} bước' : '0 bước',
                  subText: isConnected ? null : 'Chưa có dữ liệu',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Khi chưa kết nối: Nút bấm kết nối thiết bị nổi bật
          if (!isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Đồng bộ dữ liệu sức khỏe',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kết nối Google Health Connect, Apple Health hoặc Smartwatch để hệ thống tự động ghi nhận lượng calo tiêu hao và bước chân mỗi ngày.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showConnectDeviceSheet(context),
                      icon: const Icon(Icons.add_link, size: 18),
                      label: Text(
                        'Kết Nối Thiết Bị Sức Khỏe',
                        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Đã kết nối: Thông tin đồng bộ tự động thời gian thực + Nút ngắt kết nối
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
                Row(
                  children: [
                    Text(
                      _lastSyncTime != null
                          ? '${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}'
                          : 'Vừa xong',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF6E716F) : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Quản lý thiết bị'),
                            content: Text('Bạn có muốn ngắt kết nối với "${model.healthSourceLabel}" không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Ngắt kết nối', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await widget.model.disconnectHealthDevice();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã ngắt kết nối thiết bị sức khỏe.')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Đổi',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
    String? subText,
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
          if (subText != null) ...[
            const SizedBox(height: 2),
            Text(
              subText,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
