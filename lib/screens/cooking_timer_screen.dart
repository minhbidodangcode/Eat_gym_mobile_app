import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CookingTimerScreen extends StatefulWidget {
  const CookingTimerScreen({super.key});

  @override
  State<CookingTimerScreen> createState() => _CookingTimerScreenState();
}

class _CookingTimerScreenState extends State<CookingTimerScreen> {
  /// Total duration for the current step in seconds (e.g. 5 minutes).
  static const int _totalSeconds = 5 * 60;

  /// Remaining seconds on the countdown.
  int _remainingSeconds = 3 * 60 + 43; // starts at 03:43

  /// Whether the timer is actively counting down.
  bool _isRunning = false;

  Timer? _timer;

  // ──────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Timer helpers
  // ──────────────────────────────────────────────

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _pauseTimer();
        return;
      }
      setState(() => _remainingSeconds--);
    });
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

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Title ──────────────────────────────
              Text(
                'Ức gà áp chảo sốt tiêu',
                style: AppTypography.displayLarge(color: AppColors.onSurface).copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),

              // ── Nutrition chips ────────────────────
              _buildNutritionRow(),
              const SizedBox(height: 32),

              // ── Circular timer ─────────────────────
              Center(child: _buildCircularTimer()),
              const SizedBox(height: 32),

              // ── Current step card ──────────────────
              _buildCurrentStepCard(),
              const SizedBox(height: 16),

              // ── Next step card ─────────────────────
              _buildNextStepCard(),
              const SizedBox(height: 28),

              // ── Bottom buttons ─────────────────────
              _buildBottomButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sub-widgets
  // ──────────────────────────────────────────────

  Widget _buildNutritionRow() {
    const chips = ['420 kcal', 'P 46g', 'C 28g', 'F 12g'];
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
    final progress = _remainingSeconds / _totalSeconds;

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
                'Áp chảo mặt 1',
                style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard() {
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
          const SizedBox(height: 10),
          Text(
            'Cho 150g ức gà vào chảo nóng, áp chảo 5 phút. Không lật sớm để thịt chín vàng đều.',
            style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard() {
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
            'TIẾP THEO • 4:00',
            style: AppTypography.labelCaption(color: AppColors.outline).copyWith(
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lật mặt, thêm sốt tiêu và đảo nhẹ.',
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
    return Row(
      children: [
        // ── Tiếp tục / Tạm dừng button ──────────
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

        // ── Bước tiếp button ─────────────────────
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Navigate to next step
            },
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bước tiếp'),
                SizedBox(width: 4),
                Text('→', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════
// Custom painter for the circular progress ring
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

    // Foreground arc (dark)
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start from top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
