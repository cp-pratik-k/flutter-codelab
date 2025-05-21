import 'package:flutter/material.dart';

class RoundGradientProgressBar extends StatelessWidget {
  final double size;
  final Gradient gradient;

  /// provide 0 - 100 value for percentage
  final double percentage;
  final double backgroundStrokeWidth;
  final Color backgroundStrokeColor;
  final double progressStrokeWidth;
  final StrokeCap maxStrokeCap;
  final StrokeCap strokeCap;

  const RoundGradientProgressBar({
    super.key,
    this.size = 100,
    required this.gradient,
    required this.percentage,
    this.backgroundStrokeColor = Colors.transparent,
    this.backgroundStrokeWidth = 12,
    this.progressStrokeWidth = 12,
    this.maxStrokeCap = StrokeCap.square,
    this.strokeCap = StrokeCap.round,
  });

  @override
  Widget build(BuildContext context) {
    final insideStrokePadding = (progressStrokeWidth > backgroundStrokeWidth
            ? progressStrokeWidth
            : backgroundStrokeWidth) /
        2;
    return Padding(
      padding: EdgeInsets.all(insideStrokePadding),
      child: CustomPaint(
        size: Size(
          size - insideStrokePadding,
          size - insideStrokePadding,
        ),
        painter: RoundGradientProgressBarPainter(
          backgroundStrokeColor: backgroundStrokeColor,
          backgroundStrokeWidth: backgroundStrokeWidth,
          progressStrokeWidth: progressStrokeWidth,
          maxStrokeCap: maxStrokeCap,
          strokeCap: strokeCap,
          gradient: gradient,
          percentage: percentage,
        ),
      ),
    );
  }
}

class RoundGradientProgressBarPainter extends CustomPainter {
  final Gradient gradient;
  final double backgroundStrokeWidth;
  final Color backgroundStrokeColor;
  final double progressStrokeWidth;
  final double percentage;
  final StrokeCap maxStrokeCap;
  final StrokeCap strokeCap;

  RoundGradientProgressBarPainter({
    required this.gradient,
    required this.percentage,
    this.backgroundStrokeColor = Colors.transparent,
    this.backgroundStrokeWidth = 12,
    this.progressStrokeWidth = 12,
    this.maxStrokeCap = StrokeCap.square,
    this.strokeCap = StrokeCap.round,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = backgroundStrokeColor
      ..strokeWidth = backgroundStrokeWidth;

    canvas.drawCircle(center, radius, paint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..shader = gradient.createShader(rect)
      ..strokeWidth = progressStrokeWidth
      ..strokeCap = percentage == 100 ? maxStrokeCap : strokeCap;

    const startAngle = -3.14 / 2;
    final sweepAngle = 2 * 3.14 * (percentage / 100);

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}