import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  final List<double> dataPoints;
  final Color lineColor;
  final double strokeWidth;

  const SparklineChart({
    super.key,
    this.dataPoints = const [32, 28, 30, 22, 25, 16, 14, 6],
    this.lineColor = Colors.white,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: dataPoints,
          lineColor: lineColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final double strokeWidth;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    // Compute min and max for auto-scaling
    double minY = points.reduce((a, b) => a < b ? a : b);
    double maxY = points.reduce((a, b) => a > b ? a : b);
    final rangeY = (maxY - minY) == 0 ? 1.0 : (maxY - minY);

    Offset? lastPoint;

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y so that lower points (values closer to min) are visually at the top or follow standard plot
      final normalizedY = (points[i] - minY) / rangeY;
      // In Stitch design, point values: 32 -> 6 (higher number is lower on screen)
      final y = normalizedY * (size.height - 12) + 6;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      lastPoint = Offset(x, y);
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw end circle dot with glow
    if (lastPoint != null) {
      final glowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(lastPoint, 6, glowPaint);

      final dotPaint = Paint()..color = lineColor;
      canvas.drawCircle(lastPoint, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
