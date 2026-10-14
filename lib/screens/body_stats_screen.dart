import 'package:flutter/material.dart';
import '../models/badges_and_report_model.dart';
import '../theme/app_theme.dart';
import '../widgets/smartwatch_health_card.dart';
import 'update_body_stats_screen.dart';

class BodyStatsScreen extends StatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Cân nặng', '% Mỡ', 'Số đo'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BadgesAndReportModel.instance.fetchAchievementsData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BadgesAndReportModel.instance,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Header
                    Text(
                      'Biểu đồ vóc dáng',
                      style: AppTypography.displayLarge(color: AppColors.onSurface).copyWith(
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Bar
                    _buildTabBar(),
                    const SizedBox(height: 20),

                    // Tab Content - each tab builds its own full content
                    if (_selectedTabIndex == 0) ..._buildWeightTabContent(),
                    if (_selectedTabIndex == 1) ..._buildFatTabContent(),
                    if (_selectedTabIndex == 2) ..._buildMeasurementsTabContent(),
                  ],
                ),
              ),
            ),

            // Bottom Button
            _buildBottomButton(),
          ],
        ),
      ),
    );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab Bar
  // ═══════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: AppTypography.headline(
                    color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  ).copyWith(
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1: Cân nặng
  // ═══════════════════════════════════════════════════

  List<Widget> _buildWeightTabContent() {
    return [
      _buildWeightChart(),
      const SizedBox(height: 16),
      _buildWeightStatsRow(),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildWeightChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight value and target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '72.4',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Mục tiêu: 70 kg',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Change indicator
          Row(
            children: [
              Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                '2.1 kg trong 8 tuần',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _WeightChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStatsRow() {
    return Row(
      children: [
        // Fat percentage card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '17.8%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tỷ lệ mỡ',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Cooking streak card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 6),
                    Text(
                      '${BadgesAndReportModel.instance.streakDays > 0 ? BadgesAndReportModel.instance.streakDays : 12}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày tự nấu',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 2: % Mỡ
  // ═══════════════════════════════════════════════════

  List<Widget> _buildFatTabContent() {
    return [
      _buildFatChart(),
      const SizedBox(height: 16),
      _buildBodyCompositionRow(),
      const SizedBox(height: 16),
      _buildNhanXetCard(),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildFatChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fat value and target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '17.8',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Mục tiêu: 15%',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Change indicator
          Row(
            children: [
              Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                '1.4% trong 8 tuần',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _FatChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionRow() {
    return Row(
      children: [
        // Lean mass card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '59.5 kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khối lượng nạc',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Fat mass card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '12.9 kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khối lượng mỡ',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNhanXetCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhận xét',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tỷ lệ mỡ giảm đều mỗi tuần, đang đúng hướng để đạt mục tiêu 15% trong khoảng 6 tuần tới.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 3: Số đo
  // ═══════════════════════════════════════════════════

  List<Widget> _buildMeasurementsTabContent() {
    return [
      _buildMeasurementsCard(),
      const SizedBox(height: 16),
      _buildLastMeasurementDate(),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildMeasurementsCard() {
    final measurements = [
      _MeasurementData('Vòng ngực', 96, 97, -1),
      _MeasurementData('Vòng eo', 78, 80, -2),
      _MeasurementData('Vòng mông', 94, 94, 0),
      _MeasurementData('Bắp tay', 32, 31, 1),
      _MeasurementData('Đùi', 54, 55, -1),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số đo cơ thể (cm)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...measurements.map((m) => _buildMeasurementRow(m)),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(_MeasurementData data) {
    // Determine change badge color and icon
    Color badgeColor;
    IconData? badgeIcon;

    if (data.change < 0) {
      badgeColor = Colors.blue[600]!;
      badgeIcon = Icons.arrow_downward;
    } else if (data.change > 0) {
      badgeColor = Colors.red[500]!;
      badgeIcon = Icons.arrow_upward;
    } else {
      badgeColor = AppColors.outline!;
      badgeIcon = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Left: label + previous value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lần trước: ${data.previousValue} cm',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),

          // Right: current value + change badge
          Row(
            children: [
              Text(
                '${data.currentValue}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              // Change badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 12, color: badgeColor),
                    ],
                    Text(
                      data.change == 0 ? '—0' : '${data.change.abs()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastMeasurementDate() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ngày đo gần nhất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hôm nay, 26/09 · Đo buổi sáng, chưa ăn sáng',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Shared: Badges Section
  // ═══════════════════════════════════════════════════

  Widget _buildBadgesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Huy hiệu Gynser Chef',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Badge icons row
          Row(
            children: [
              _buildBadge(Icons.emoji_events, true),
              const SizedBox(width: 12),
              _buildBadge(Icons.workspace_premium, true),
              const SizedBox(width: 12),
              _buildBadge(Icons.military_tech, false),
              const SizedBox(width: 12),
              _buildBadge(Icons.star, false),
            ],
          ),
          const SizedBox(height: 16),

          // Unlock text
          Text(
            'Còn 18 ngày nữa để mở khóa huy hiệu Vàng (30 ngày)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, bool earned) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: earned ? AppColors.primary : AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: earned
            ? null
            : Border.all(color: AppColors.outlineVariant!, width: 1.5),
      ),
      child: Icon(
        icon,
        size: 24,
        color: earned ? AppColors.surface : AppColors.outlineVariant,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Bottom Button
  // ═══════════════════════════════════════════════════

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpdateBodyStatsScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            '+ Cập nhật cân nặng / số đo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Data Model
// ══════════════════════════════════════════════════════

class _MeasurementData {
  final String name;
  final int currentValue;
  final int previousValue;
  final int change;

  _MeasurementData(this.name, this.currentValue, this.previousValue, this.change);
}

// ══════════════════════════════════════════════════════
// Weight Chart Painter
// ══════════════════════════════════════════════════════

class _WeightChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['T1', 'T3', 'T5', 'T7', 'T8'];
    final values = [74.5, 74.0, 73.5, 72.8, 72.4];

    _drawChart(canvas, size, labels, values, 71.0, 75.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════
// Fat Chart Painter
// ══════════════════════════════════════════════════════

class _FatChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['T1', 'T3', 'T5', 'T7', 'T8'];
    final values = [19.5, 19.0, 18.6, 18.1, 17.8];

    _drawChart(canvas, size, labels, values, 17.0, 20.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════
// Shared Chart Drawing
// ══════════════════════════════════════════════════════

void _drawChart(
  Canvas canvas,
  Size size,
  List<String> labels,
  List<double> values,
  double minVal,
  double maxVal,
) {
  const double chartLeft = 0;
  final double chartRight = size.width;
  const double chartTop = 0;
  final double chartBottom = size.height - 28;
  final double valRange = maxVal - minVal;

  // Grid lines
  final gridPaint = Paint()
    ..color = AppColors.surfaceContainerHigh
    ..strokeWidth = 1;

  for (int i = 0; i < 4; i++) {
    final y = chartTop + (chartBottom - chartTop) * i / 3;
    canvas.drawLine(
      Offset(chartLeft, y),
      Offset(chartRight, y),
      gridPaint,
    );
  }

  // Calculate points
  final points = <Offset>[];
  for (int i = 0; i < values.length; i++) {
    final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
    final y = chartBottom -
        ((values[i] - minVal) / valRange) * (chartBottom - chartTop);
    points.add(Offset(x, y));
  }

  // Draw line
  final linePaint = Paint()
    ..color = AppColors.primary
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final path = Path();
  path.moveTo(points[0].dx, points[0].dy);

  for (int i = 0; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    final controlX1 = current.dx + (next.dx - current.dx) * 0.4;
    final controlX2 = current.dx + (next.dx - current.dx) * 0.6;
    path.cubicTo(
      controlX1, current.dy,
      controlX2, next.dy,
      next.dx, next.dy,
    );
  }

  canvas.drawPath(path, linePaint);

  // Draw gradient fill below the line
  final fillPath = Path.from(path);
  fillPath.lineTo(points.last.dx, chartBottom);
  fillPath.lineTo(points.first.dx, chartBottom);
  fillPath.close();

  final fillPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.15),
        AppColors.primary.withValues(alpha: 0.02),
      ],
    ).createShader(Rect.fromLTRB(0, chartTop, size.width, chartBottom));

  canvas.drawPath(fillPath, fillPaint);

  // Draw dots
  final dotPaint = Paint()
    ..color = AppColors.primary
    ..style = PaintingStyle.fill;

  final dotBorderPaint = Paint()
    ..color = AppColors.surface
    ..style = PaintingStyle.fill;

  for (int i = 0; i < points.length; i++) {
    if (i == points.length - 1) {
      canvas.drawCircle(points[i], 7, dotBorderPaint);
      canvas.drawCircle(points[i], 5, dotPaint);
    } else {
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }
  }

  // Draw X-axis labels
  final textStyle = TextStyle(
    color: AppColors.outline,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  for (int i = 0; i < labels.length; i++) {
    final textSpan = TextSpan(text: labels[i], style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final x = points[i].dx - textPainter.width / 2;
    final y = chartBottom + 8;
    textPainter.paint(canvas, Offset(x, y));
  }
}
