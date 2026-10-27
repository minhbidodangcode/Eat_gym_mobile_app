import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/badges_and_report_model.dart';
import '../theme/app_theme.dart';

class CookingStep {
  final String title;
  final String description;
  final int seconds;

  CookingStep({
    required this.title,
    required this.description,
    required this.seconds,
  });
}

class CookingTimerScreen extends StatefulWidget {
  final Map<String, dynamic>? recipe;

  const CookingTimerScreen({super.key, this.recipe});

  @override
  State<CookingTimerScreen> createState() => _CookingTimerScreenState();
}

class _CookingTimerScreenState extends State<CookingTimerScreen> {
  List<CookingStep> _steps = [];
  int _currentStepIndex = 0;
  int _totalStepSeconds = 300;
  int _remainingSeconds = 300;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initSteps();
    _startTimer();
  }

  void _initSteps() {
    final recipe = widget.recipe ?? {};
    final totalMinutes = (recipe['time'] ?? recipe['cooking_time_min'] ?? 20) as int;
    final instructions = (recipe['instructions'] ?? '') as String;

    final parsedSteps = <CookingStep>[];

    if (instructions.isNotEmpty) {
      // Split by newlines or by step prefixes (e.g. Bước X: or 1.)
      List<String> rawParts = [];
      if (instructions.contains('\n')) {
        rawParts = instructions.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else {
        final stepRegex = RegExp(r'(?:^|\.\s+|\s+)(?=(?:Bước\s*\d+[:\s]|\d+[\.\)]\s+))', caseSensitive: false);
        rawParts = instructions.split(stepRegex).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }

      for (int i = 0; i < rawParts.length; i++) {
        final line = rawParts[i];
        if (line.isEmpty) continue;

        int stepSec = 0;
        final minMatch = RegExp(r'(\d+)\s*(?:phút|p\b)', caseSensitive: false).firstMatch(line);
        final secMatch = RegExp(r'(\d+)\s*(?:giây|s\b)', caseSensitive: false).firstMatch(line);
        if (minMatch != null) {
          stepSec = (int.tryParse(minMatch.group(1)!) ?? 0) * 60;
        } else if (secMatch != null) {
          stepSec = int.tryParse(secMatch.group(1)!) ?? 0;
        }

        String title = 'Bước ${i + 1}';
        String description = line;

        // Split "Bước 1: Sơ chế nguyên liệu tươi (5 phút) - Đậu hũ rửa sạch..."
        final dashIdx = line.indexOf(' - ');
        if (dashIdx != -1) {
          title = line.substring(0, dashIdx).trim();
          description = line.substring(dashIdx + 3).trim();
        } else {
          final colonIdx = line.indexOf(': ');
          if (colonIdx != -1 && colonIdx < 40) {
            title = line.substring(0, colonIdx).trim();
            description = line.substring(colonIdx + 2).trim();
          }
        }

        parsedSteps.add(CookingStep(
          title: title,
          description: description,
          seconds: stepSec,
        ));
      }
    }

    // Fallback if less than 3 steps so no recipe ever appears with only 1 or 2 steps
    if (parsedSteps.length < 3) {
      final dishName = (recipe['title'] ?? 'Món ăn').toString().replaceAll(RegExp(r'^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\s]+', unicode: true), '').trim();
      parsedSteps.clear();
      parsedSteps.addAll([
        CookingStep(
          title: 'Bước 1: Sơ chế nguyên liệu tươi',
          description: 'Rửa sạch toàn bộ các nguyên liệu cho món $dishName. Thái lát hoặc cắt khúc vừa ăn, để ráo nước.',
          seconds: max((totalMinutes * 0.2).round() * 60, 180),
        ),
        CookingStep(
          title: 'Bước 2: Tẩm ướp gia vị thanh đạm',
          description: 'Ướp nguyên liệu với muối hồng, tiêu đen xay, hành tỏi băm nhỏ trong khoảng 5 phút cho ngấm gia vị.',
          seconds: max((totalMinutes * 0.25).round() * 60, 180),
        ),
        CookingStep(
          title: 'Bước 3: Chế biến nhiệt chính',
          description: 'Tiến hành nấu/xào/áp chảo/hấp chín ở nhiệt độ vừa phải để giữ trọn độ mọng nước và dưỡng chất.',
          seconds: max((totalMinutes * 0.35).round() * 60, 300),
        ),
        CookingStep(
          title: 'Bước 4: Nêm nếm & Hoàn thiện hương vị',
          description: 'Nêm nếm lại gia vị thanh đạm, đảo đều tay cho ngấm sâu và hòa quyện các thành phần.',
          seconds: max((totalMinutes * 0.15).round() * 60, 120),
        ),
        CookingStep(
          title: 'Bước 5: Bày biện & Thưởng thức',
          description: 'Bày món $dishName ra đĩa, rắc hành ngò hoặc tiêu xay thơm lừng và thưởng thức ngay khi còn nóng ấm.',
          seconds: 120,
        ),
      ]);
    }

    // Allocate default duration if any step has 0 seconds
    final totalSec = max(totalMinutes * 60, parsedSteps.length * 60);
    final zeroCount = parsedSteps.where((s) => s.seconds <= 0).length;
    final allocatedSec = parsedSteps.fold<int>(0, (sum, s) => sum + s.seconds);
    final remainingForZeros = max(totalSec - allocatedSec, zeroCount * 120);
    final perZeroStepSec = zeroCount > 0 ? (remainingForZeros ~/ zeroCount) : 180;

    _steps = parsedSteps.map((s) {
      final sec = s.seconds > 0 ? s.seconds : perZeroStepSec;
      return CookingStep(
        title: s.title,
        description: s.description,
        seconds: max(sec, 60), // at least 1 minute
      );
    }).toList();

    _currentStepIndex = 0;
    _totalStepSeconds = _steps[0].seconds;
    _remainingSeconds = _totalStepSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _notifyStepFinished();
        _handleStepComplete();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _notifyStepFinished() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
    try {
      await NotificationService().showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Hết giờ ${_steps[_currentStepIndex].title}',
        body: _currentStepIndex == _steps.length - 1 ? 'Món ăn đã hoàn thành.' : 'Sẵn sàng chuyển sang bước tiếp theo.',
      );
    } catch (_) {}
  }

  double _value(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  double get _portionScale {
    final scale = _value((widget.recipe ?? {})['portionScale']);
    return scale <= 0 ? 1 : scale.clamp(.1, 5).toDouble();
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _handleStepComplete() {
    if (_currentStepIndex < _steps.length - 1) {
      _nextStep();
    } else {
      _showCompletionDialog();
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _totalStepSeconds = _steps[_currentStepIndex].seconds;
        _remainingSeconds = _totalStepSeconds;
      });
      _startTimer();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    _pauseTimer();
    final recipe = widget.recipe ?? {};
    final title = recipe['title'] ?? 'Món ăn';
    final kcal = (_value(recipe['kcal']) * _portionScale).round();
    final pro = (_value(recipe['protein']) * _portionScale).round();

    final achievementFuture = _recordCookingAchievement(title);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Chúc mừng!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn đã hoàn thành món', style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: AppTypography.headline(color: AppColors.primary).copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('🔥 $kcal kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('💪 ${pro}g Protein', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: achievementFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        SizedBox(width: 10),
                        Text('Đang cập nhật chuỗi streak...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }
                final res = snapshot.data;
                if (res != null && res.containsKey('streak')) {
                  final streak = res['streak']['consecutiveDays'];
                  final badges = res['newlyAwardedBadges'] as List? ?? [];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 18)),
                            Text('Chuỗi nấu liên tục: $streak ngày!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          ],
                        ),
                        if (badges.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('🏆 Mở khóa: ${badges.map((b) => b['name']).join(', ')}!', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.amber)),
                        ],
                      ],
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('✅ Đã ghi nhận nấu xong vào hồ sơ!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _chooseMealAndLog(ctx),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('ĐÃ ĂN MÓN NÀY - THÊM VÀO NHẬT KÝ'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('HOÀN TẤT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _recordCookingAchievement(String title) async {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final res = await ApiService.recordCookingDay(
        cookedOn: todayStr,
        note: 'Nấu món: $title hoàn thành',
      );
      // Immediately refresh global achievements model
      BadgesAndReportModel.instance.fetchAchievementsData();
      return res;
    } catch (e) {
      debugPrint('Error recording cooking achievement: $e');
      BadgesAndReportModel.instance.fetchAchievementsData();
      return null;
    }
  }

  Future<void> _logMeal(String mealType) async {
    final recipe = widget.recipe ?? {};
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      await ApiService.addNutritionLog({
        'logDate': date, 'mealType': mealType, 'foodName': recipe['title'] ?? 'Món EatGym',
        'servingSize': 1, 'servingUnit': 'phần',
        'calories': _value(recipe['kcal']) * _portionScale,
        'protein': _value(recipe['protein']) * _portionScale,
        'carbs': _value(recipe['carbs']) * _portionScale,
        'fat': _value(recipe['fat']) * _portionScale,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm món vào Nhật ký dinh dưỡng.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa thể ghi nhật ký: $error')));
    }
  }

  void _chooseMealAndLog(BuildContext dialogContext) {
    const meals = {'breakfast': 'Bữa sáng', 'lunch': 'Bữa trưa', 'dinner': 'Bữa tối', 'snack': 'Ăn vặt'};
    showModalBottomSheet(
      context: dialogContext,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Thêm vào bữa nào?', style: TextStyle(fontWeight: FontWeight.bold))),
        for (final item in meals.entries)
          ListTile(title: Text(item.value), onTap: () { Navigator.pop(sheetContext); Navigator.pop(dialogContext); _logMeal(item.key); }),
      ])),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe ?? {};
    final title = recipe['title'] ?? 'Món ăn dinh dưỡng';
    final currentStep = _steps.isNotEmpty ? _steps[_currentStepIndex] : null;
    final nextStep = (_currentStepIndex < _steps.length - 1) ? _steps[_currentStepIndex + 1] : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Bước ${_currentStepIndex + 1} / ${_steps.length}',
          style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant).copyWith(fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Title
              Text(
                title,
                style: AppTypography.displayLarge(color: AppColors.onSurface).copyWith(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),

              // Nutrition Chips
              _buildNutritionRow(),
              const SizedBox(height: 28),

              // Circular Countdown Timer
              Center(child: _buildCircularTimer()),
              const SizedBox(height: 28),

              // Current Step Card
              if (currentStep != null) _buildCurrentStepCard(currentStep),
              const SizedBox(height: 16),

              // Next Step Card
              _buildNextStepCard(nextStep),
              const SizedBox(height: 28),

              // Bottom Buttons
              _buildBottomButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow() {
    final recipe = widget.recipe ?? {};
    final kcal = (_value(recipe['kcal']) * _portionScale).round();
    final pro = (_value(recipe['protein']) * _portionScale).round();
    final carbs = (_value(recipe['carbs']) * _portionScale).round();
    final fat = (_value(recipe['fat']) * _portionScale).round();

    final chips = [
      '$kcal kcal',
      'P ${pro}g',
      'C ${carbs}g',
      'F ${fat}g',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCircularTimer() {
    final progress = _totalStepSeconds > 0 ? (_remainingSeconds / _totalStepSeconds) : 0.0;

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _TimerRingPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: AppTypography.displayLarge(color: AppColors.onSurface).copyWith(
                  fontSize: 48,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bước ${_currentStepIndex + 1} / ${_steps.length}',
                style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard(CookingStep step) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ĐANG LÀM',
                  style: AppTypography.badge(color: AppColors.onPrimary).copyWith(
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(
              fontSize: 20,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildCookingTip(step),
        ],
      ),
    );
  }

  Widget _buildCookingTip(CookingStep step) {
    final text = step.description.toLowerCase();
    final tip = text.contains('gà') || text.contains('áp chảo')
        ? 'Mẹo gymer: áp chảo lửa vừa, chỉ lật 1 lần và để thịt nghỉ 3 phút để ức gà mọng nước.'
        : text.contains('luộc') || text.contains('trứng')
            ? 'Mẹo gymer: cho trứng vào nước sôi 7–8 phút để lòng đào, tránh luộc quá lâu.'
            : 'Mẹo gymer: dùng lửa vừa và nấu vừa chín tới để giữ độ ngọt tự nhiên, hạn chế dầu và sốt nhiều đường.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡 '), Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.35))),
      ]),
    );
  }

  Widget _buildNextStepCard(CookingStep? nextStep) {
    final hasNext = nextStep != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasNext ? 'TIẾP THEO • ${nextStep.title} (${_formatTime(nextStep.seconds)})' : 'BƯỚC CUỐI CÙNG',
            style: AppTypography.labelCaption(color: AppColors.outline).copyWith(
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasNext ? nextStep.description : 'Chuẩn bị hoàn thành và thưởng thức món ăn!',
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastStep = _currentStepIndex >= _steps.length - 1;

    return Row(
      children: [
        // Play / Pause
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleTimer,
            icon: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              size: 20,
            ),
            label: Text(_isRunning ? 'Tạm dừng' : 'Tiếp tục'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outline),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Next Step / Finish
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isLastStep ? 'Hoàn thành' : 'Bước tiếp'),
                const SizedBox(width: 4),
                Text(isLastStep ? '✓' : '→', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════
// Custom painter for the circular countdown ring
// - Bắt đầu từ đỉnh 12h (-pi / 2)
// - Giảm dần theo chiều ngược kim đồng hồ (-2 * pi * progress)
// ════════════════════════════════════════════════

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({required this.progress});

  /// Value between 0.0 (done) and 1.0 (full).
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;
    const strokeWidth = 4.0;

    // Background ring (light gray)
    final bgPaint = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0.0) return;

    // Foreground arc (dark)
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (12 o'clock = -pi / 2), and sweep counter-clockwise (-2 * pi * progress)
    final sweepAngle = -2 * pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 12 o'clock top
      sweepAngle, // counter-clockwise decrease
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

