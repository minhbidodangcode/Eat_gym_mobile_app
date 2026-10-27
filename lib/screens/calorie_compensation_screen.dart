import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/nutrition_advanced_api_service.dart';
import '../theme/app_theme.dart';

class CalorieCompensationScreen extends StatefulWidget {
  const CalorieCompensationScreen({super.key});

  @override
  State<CalorieCompensationScreen> createState() => _CalorieCompensationScreenState();
}

class _CalorieCompensationScreenState extends State<CalorieCompensationScreen> {
  bool _isLoading = false;
  bool _isFetching = true;
  List<Map<String, dynamic>> _deviations = [];
  double _userTargetKcal = 2000.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isFetching = true);
    try {
      final profile = await ApiService.getLocalProfile() ?? await ApiService.getProfile();
      if (profile != null) {
        final target = (profile['targetMacros']?['calories'] as num?)?.toDouble() ??
            (profile['tdeeKcal'] as num?)?.toDouble() ??
            2000.0;
        _userTargetKcal = target;
      }

      _deviations = await NutritionAdvancedApiService.getDeviations();
    } catch (_) {}

    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _triggerCompensation(String deviationId, int days) async {
    setState(() => _isLoading = true);
    try {
      final result = await NutritionAdvancedApiService.allocateCompensation(
        deviationId: deviationId,
        horizonDays: days,
        minKcalPerMeal: 300,
      );

      if (!mounted) return;
      final status = result['compensation']?['status'] ?? 'thành công';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bù trừ Calo hoàn tất ($status)! Đã tự động giảm chỉ tiêu calo của các ngày tới.'),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Tải lại danh sách
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi bù trừ: $e'), backgroundColor: AppColors.fire),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRecordDeviationDialog() async {
    final actualCtrl = TextEditingController(text: (_userTargetKcal + 500).toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: 'Tiệc nướng cùng bạn bè');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Ghi nhận ăn lố Calo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mục tiêu hàng ngày của bạn: ${_userTargetKcal.toStringAsFixed(0)} kcal', style: AppTypography.bodySmall()),
            const SizedBox(height: 12),
            TextField(
              controller: actualCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tổng Calo thực tế đã nạp (kcal)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú lý do (VD: Cheat meal)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final actual = double.tryParse(actualCtrl.text) ?? 0;
              if (actual <= _userTargetKcal) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calo thực tế phải lớn hơn mục tiêu để ghi nhận ăn lố.')),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final todayStr = DateTime.now().toIso8601String().split('T')[0];
                await NutritionAdvancedApiService.recordDeviation(
                  occurredOn: todayStr,
                  targetKcal: _userTargetKcal,
                  actualKcal: actual,
                  note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                );
                await _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Ghi nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Bù Trừ Calo Tự Động'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ghi nhận ăn lố',
            onPressed: _showRecordDeviationDialog,
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card explaining the dynamic feature
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.12), Colors.purple.withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Cơ chế thâm hụt tự động (Dynamic Compensation)',
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Khi bạn lỡ ăn thừa calo trong một bữa tiệc, thuật toán sẽ tự động phân bổ lượng dư này trừ dần vào các bữa ăn của 1-2 ngày tới mà vẫn giữ mức calo tối thiểu 300 kcal/bữa để cơ bắp không bị kiệt sức.',
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lịch sử ăn lệch Calo', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showRecordDeviationDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ghi nhận mới'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_deviations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.celebration_outlined, size: 48, color: Color(0xFF00E676)),
                            const SizedBox(height: 12),
                            Text(
                              'Tuyệt vời! Bạn đang ăn chuẩn kỷ luật!',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chưa có ngày nào ăn vượt mức calo mục tiêu.',
                              style: AppTypography.bodySmall(),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._deviations.map((d) {
                        final id = d['id']?.toString() ?? '';
                        final dateStr = d['occurredOn']?.toString() ?? '';
                        final target = (d['targetKcal'] as num?)?.toDouble() ?? 2000;
                        final actual = (d['actualKcal'] as num?)?.toDouble() ?? 2000;
                        final delta = (d['deltaKcal'] as num?)?.toDouble() ?? (actual - target);
                        final isCompensated = d['isCompensated'] == true;
                        final note = d['note']?.toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: isCompensated ? Colors.grey.shade50 : Colors.red.shade50.withValues(alpha: 0.6),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Text('Ngày: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCompensated ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isCompensated ? 'Đã bù trừ' : 'Chưa bù trừ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isCompensated ? const Color(0xFF008947) : Colors.orange[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Text('Mục tiêu: ${target.toStringAsFixed(0)} kcal · Thực tế nạp: ${actual.toStringAsFixed(0)} kcal'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Vượt mức: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '+${delta.toStringAsFixed(0)} kcal',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (note != null && note.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '($note)',
                                          style: AppTypography.bodySmall(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (!isCompensated && delta > 0) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: _isLoading ? null : () => _triggerCompensation(id, 1),
                                          child: const Text('Trừ vào ngày mai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: _isLoading ? null : () => _triggerCompensation(id, 2),
                                          child: const Text('Chia đều 2 ngày', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
