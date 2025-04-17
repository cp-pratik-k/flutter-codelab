import 'dart:math';
import 'package:flutter/material.dart';

///USAGE
 // PieChart(
          //   items: [
          //     PieChartItem(
          //       name: "Name1",
          //       percentage: 40,
          //       hintText: "This is hint",
          //       color: context.colorScheme.primary,
          //     ),
          //     PieChartItem(
          //       name: "Name2",
          //       percentage: 30,
          //       hintText: "This is hint",
          //       color: context.colorScheme.secondary,
          //     ),
          //     PieChartItem(
          //       name: "Name3",
          //       percentage: 25,
          //       hintText: "This is hint",
          //       color: context.colorScheme.warning,
          //     ),
          //     PieChartItem(
          //       name: "Name4",
          //       percentage: 5,
          //       hintText: "This is hint",
          //       color: context.colorScheme.positive,
          //     ),
          //   ],
          //   backgroundColor: context.colorScheme.containerLowOnSurface,
          //   hintBuilder: (_, item) {
          //     return Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: context.colorScheme.primary,
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       child: Text(
          //         item.hintText,
          //         style: AppTextStyles.body.copyWith(
          //           color: context.colorScheme.textPrimary,
          //         ),
          //       ),
          //     );
          //   },
          //   onItemTap: (item) {
          //     print("Tapped on ${item.name}");
          //   },
          // ),

/// Model for a pie chart slice, including its color
class PieChartItem {
  final String name;
  final double percentage; // 0.0 - 100.0
  final String hintText;
  final Color color;

  PieChartItem({
    required this.name,
    required this.percentage,
    required this.hintText,
    required this.color,
  }) : assert(percentage >= 0 && percentage <= 100);
}

/// Animated, scalable, and customizable PieChart widget
class PieChart extends StatefulWidget {
  final List<PieChartItem> items;
  final Color backgroundColor;
  final TextStyle? itemTextStyle;
  final TextStyle? hintTextStyle;
  final Widget Function(BuildContext, PieChartItem)? hintBuilder;
  final Duration entryDuration;
  final Duration hintDuration;
  final Curve entryCurve;
  final Curve hintCurve;
  final void Function(PieChartItem)? onItemTap;

  const PieChart({
    Key? key,
    required this.items,
    this.backgroundColor = Colors.white,
    this.itemTextStyle,
    this.hintTextStyle,
    this.hintBuilder,
    this.entryDuration = const Duration(milliseconds: 600),
    this.hintDuration = const Duration(milliseconds: 400),
    this.entryCurve = Curves.easeOut,
    this.hintCurve = Curves.easeOut,
    this.onItemTap,
  }) : super(key: key);

  @override
  _PieChartState createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _hintController;
  int _selected = -1;
  late final List<double> _fractions;
  late final List<double> _cum;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: widget.entryDuration,
    )..forward();
    _hintController = AnimationController(
      vsync: this,
      duration: widget.hintDuration,
    );

    _fractions = widget.items.map((e) => e.percentage / 100).toList();
    _cum = [0.0];
    for (var f in _fractions) _cum.add(_cum.last + f);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _handleTap(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > size.width / 2) return;

    double angle = (atan2(dy, dx) + 2 * pi) % (2 * pi);
    double rel = (angle - (-pi / 2) + 2 * pi) % (2 * pi);
    double pct = rel / (2 * pi);

    for (int i = 0; i < widget.items.length; i++) {
      if (pct >= _cum[i] && pct < _cum[i + 1]) {
        setState(() {
          if (_selected == i) {
            _selected = -1;
            _hintController.reverse();
          } else {
            _selected = i;
            _hintController
              ..reset()
              ..forward();
          }
        });
        widget.onItemTap?.call(widget.items[i]);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      final size = bc.biggest.shortestSide;
      return GestureDetector(
        onTapUp: (e) => _handleTap(e.localPosition, Size(size, size)),
        child: AnimatedBuilder(
          animation: Listenable.merge([_entryController, _hintController]),
          builder: (_, __) {
            final entryVal =
                widget.entryCurve.transform(_entryController.value);
            final hintVal = widget.hintCurve.transform(_hintController.value);

            return Stack(alignment: Alignment.center, children: [
              CustomPaint(
                size: Size(size, size),
                painter: _PiePainter(
                  items: widget.items,
                  fractions: _fractions,
                  cum: _cum,
                  entryProgress: entryVal,
                  selected: _selected,
                  bgColor: widget.backgroundColor,
                ),
              ),
              // item label at slice center
              if (_selected >= 0)
                Positioned(
                  left: size / 2 + cos(_midAngle(_selected)) * size / 4 - 40,
                  top: size / 2 + sin(_midAngle(_selected)) * size / 4 - 20,
                  width: 80,
                  child: Opacity(
                    opacity: hintVal,
                    child: Text(
                      '${widget.items[_selected].name}\n${widget.items[_selected].percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: widget.itemTextStyle ??
                          const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                    ),
                  ),
                ),
              // hint and connector
              if (_selected >= 0)
                CustomPaint(
                  size: Size(size, size),
                  painter: _HintPainter(
                    fractions: _fractions,
                    cum: _cum,
                    items: widget.items,
                    selected: _selected,
                    hintProgress: hintVal,
                    hintTextStyle: widget.hintTextStyle,
                  ),
                ),
            ]);
          },
        ),
      );
    });
  }

  double _midAngle(int index) {
    final start = -pi / 2 + 2 * pi * _cum[index];
    final sweep = 2 * pi * _fractions[index];
    return start + sweep / 2;
  }
}

class _PiePainter extends CustomPainter {
  final List<PieChartItem> items;
  final List<double> fractions;
  final List<double> cum;
  final double entryProgress;
  final int selected;
  final Color bgColor;

  _PiePainter({
    required this.items,
    required this.fractions,
    required this.cum,
    required this.entryProgress,
    required this.selected,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // filled background
    canvas.drawCircle(center, r, Paint()..color = bgColor);

    double start = -pi / 2;
    for (int i = 0; i < items.length; i++) {
      final sweep = 2 * pi * fractions[i] * entryProgress;
      final isSel = i == selected;
      final mid = start + sweep / 2;
      final offset =
          isSel ? Offset(cos(mid), sin(mid)) * (r * 0.05) : Offset.zero;
      canvas.drawArc(
        Rect.fromCircle(center: center + offset, radius: isSel ? r * 1.1 : r),
        start,
        sweep,
        true,
        Paint()..color = items[i].color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HintPainter extends CustomPainter {
  final List<double> fractions;
  final List<double> cum;
  final List<PieChartItem> items;
  final int selected;
  final double hintProgress;
  final TextStyle? hintTextStyle;

  _HintPainter({
    required this.fractions,
    required this.cum,
    required this.items,
    required this.selected,
    required this.hintProgress,
    this.hintTextStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selected < 0 || hintProgress == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 1.1;
    final mid = -pi / 2 + 2 * pi * (cum[selected] + fractions[selected] / 2);
    final sliceCenter = center + Offset(cos(mid), sin(mid)) * (r * 0.6);
    final hintPos = center + Offset(cos(mid), sin(mid)) * (r + 40);

    // draw connector
    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: hintProgress)
      ..strokeWidth = 2;
    canvas.drawLine(sliceCenter,
        Offset.lerp(sliceCenter, hintPos, hintProgress)!, linePaint);

    // fallback: draw text manually
    final hint = items[selected].hintText;
    final tp = TextPainter(
      text: TextSpan(
          text: hint,
          style: hintTextStyle ??
              const TextStyle(fontSize: 12, color: Colors.black87)),
      textDirection: TextDirection.ltr,
    )..layout();
    final boxSize = Size(tp.width + 16, tp.height + 12);
    final boxOffset = Offset.lerp(sliceCenter, hintPos, hintProgress)! -
        Offset(boxSize.width / 2, boxSize.height / 2);

    final boxPaint = Paint()
      ..color = Colors.white.withValues(alpha: hintProgress);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxOffset & boxSize, const Radius.circular(6)),
      boxPaint,
    );
    tp.paint(canvas, boxOffset + const Offset(8, 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
