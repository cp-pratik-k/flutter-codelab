import 'dart:math';
import 'package:flutter/material.dart';

/// USAGE
  // PieChart(
          //   items: [
          //     PieChartItem(
          //       name: "Name1",
          //       percentage: 40,
          //       hintText: "This is hint",
          //       color: context.colorScheme.primary,
          //       hintLineColor: context.colorScheme.containerLowOnSurface,
          //     ),
          //     PieChartItem(
          //       name: "Name2",
          //       percentage: 30,
          //       hintText: "This is hint",
          //       color: context.colorScheme.secondary,
          //       hintLineColor: context.colorScheme.containerLowOnSurface,
          //     ),
          //     PieChartItem(
          //       name: "Name3",
          //       percentage: 25,
          //       hintText: "This is hint",
          //       color: context.colorScheme.warning,
          //       hintLineColor: context.colorScheme.containerLowOnSurface,
          //     ),
          //     PieChartItem(
          //       name: "Name4",
          //       percentage: 5,
          //       hintText: "This is hint",
          //       color: context.colorScheme.positive,
          //       hintLineColor: context.colorScheme.containerLowOnSurface,
          //     ),
          //   ],
          //   backgroundColor: context.colorScheme.containerLowOnSurface,
          //  
          //   hintBuilder: (_, item) {
          //     return Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: context.colorScheme.containerLowOnSurface,
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

/// Model for a pie chart slice, including its colors
class PieChartItem {
  final String name;
  final double percentage; // 0.0 - 100.0
  final String hintText;
  final Color color;
  final Color hintLineColor;

  PieChartItem({
    required this.name,
    required this.percentage,
    required this.hintText,
    required this.color,
    this.hintLineColor = Colors.grey,
  }) : assert(percentage >= 0 && percentage <= 100);
}

/// Animated, scalable, and customizable PieChart widget
class PieChart extends StatefulWidget {
  final List<PieChartItem> items;
  final Color backgroundColor;
  final TextStyle? itemTextStyle;
  final TextStyle? hintTextStyle;
  final Widget Function(BuildContext, PieChartItem)? hintBuilder;
  final Widget Function(String)? sliceLabelBuilder;
  final Duration entryDuration;
  final Duration selectDuration;
  final Duration hintDuration;
  final Curve entryCurve;
  final Curve selectCurve;
  final Curve hintCurve;
  final void Function(PieChartItem)? onItemTap;

  const PieChart({
    Key? key,
    required this.items,
    this.backgroundColor = Colors.white,
    this.itemTextStyle,
    this.hintTextStyle,
    this.hintBuilder,
    this.sliceLabelBuilder,
    this.entryDuration = const Duration(milliseconds: 600),
    this.selectDuration = const Duration(milliseconds: 300),
    this.hintDuration = const Duration(milliseconds: 400),
    this.entryCurve = Curves.easeOut,
    this.selectCurve = Curves.easeOut,
    this.hintCurve = Curves.easeOut,
    this.onItemTap,
  }) : super(key: key);

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _selectController;
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
    _selectController = AnimationController(
      vsync: this,
      duration: widget.selectDuration,
    );
    _hintController = AnimationController(
      vsync: this,
      duration: widget.hintDuration,
    );

    _fractions = widget.items.map((e) => e.percentage / 100).toList();
    _cum = [0.0];
    for (var f in _fractions) {
      _cum.add(_cum.last + f);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _selectController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _handleTap(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    if (sqrt(dx * dx + dy * dy) > size.width / 2) return;

    final double angle = (atan2(dy, dx) + 2 * pi) % (2 * pi);
    final double rel = (angle - (-pi / 2) + 2 * pi) % (2 * pi);
    final double pct = rel / (2 * pi);

    for (int i = 0; i < widget.items.length; i++) {
      if (pct >= _cum[i] && pct < _cum[i + 1]) {
        if (_selected == i) {
          _hintController.reverse();
          _selectController.reverse();
          setState(() => _selected = -1);
        } else {
          setState(() => _selected = i);
          _selectController
            ..reset()
            ..forward();
          _hintController
            ..reset()
            ..forward();
        }
        widget.onItemTap?.call(widget.items[i]);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final size = bc.biggest.shortestSide;
        return GestureDetector(
          onTapUp: (e) => _handleTap(e.localPosition, Size(size, size)),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entryController,
              _selectController,
              _hintController,
            ]),
            builder: (_, __) {
              final entryVal =
                  widget.entryCurve.transform(_entryController.value);
              final selectVal =
                  widget.selectCurve.transform(_selectController.value);
              final hintVal = widget.hintCurve.transform(_hintController.value);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _PiePainter(
                      items: widget.items,
                      fractions: _fractions,
                      cum: _cum,
                      entryProgress: entryVal,
                      selectProgress: selectVal,
                      selected: _selected,
                      bgColor: widget.backgroundColor,
                    ),
                  ),
                  // Always show slice labels
                  for (int i = 0; i < widget.items.length; i++)
                    Positioned(
                      left: size / 2 + cos(_midAngle(i)) * size / 4 - 40,
                      top: size / 2 + sin(_midAngle(i)) * size / 4 - 20,
                      width: 80,
                      child: widget.sliceLabelBuilder?.call(
                            '${widget.items[i].name}\n${widget.items[i].percentage.toStringAsFixed(1)}%',
                          ) ??
                          Text(
                            '${widget.items[i].name}\n${widget.items[i].percentage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: widget.itemTextStyle ??
                                const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                          ),
                    ),
                  if (_selected >= 0)
                    CustomPaint(
                      size: Size(size, size),
                      painter: _LinePainter(
                        midAngle: _midAngle(_selected),
                        progress: hintVal,
                        sliceOffset: size / 2 * selectVal * 0.05,
                        radius: size / 2,
                        lineColor: widget.items[_selected].hintLineColor,
                      ),
                    ),
                  if (_selected >= 0 && widget.hintBuilder != null)
                    _buildHintWidget(size, hintVal),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHintWidget(double size, double hintVal) {
    final mid = _midAngle(_selected);
    final r = size / 2 * (1 + _selectCurveValue() * 0.1);
    final hintPos =
        Offset(size / 2 + cos(mid) * (r + 40), size / 2 + sin(mid) * (r + 40));
    return Positioned(
      left: hintPos.dx - 60,
      top: hintPos.dy - 20,
      child: Opacity(
        opacity: hintVal,
        child: widget.hintBuilder!(context, widget.items[_selected]),
      ),
    );
  }

  double _selectCurveValue() => _selectController.value;

  double _midAngle(int index) {
    final start = -pi / 2 + 2 * pi * _cum[index];
    final sweep = 2 * pi * _fractions[index] * _entryController.value;
    return start + sweep / 2;
  }
}

class _PiePainter extends CustomPainter {
  final List<PieChartItem> items;
  final List<double> fractions;
  final List<double> cum;
  final double entryProgress;
  final double selectProgress;
  final int selected;
  final Color bgColor;

  _PiePainter({
    required this.items,
    required this.fractions,
    required this.cum,
    required this.entryProgress,
    required this.selectProgress,
    required this.selected,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()..color = bgColor);

    double start = -pi / 2;
    for (int i = 0; i < items.length; i++) {
      final sweep = 2 * pi * fractions[i] * entryProgress;
      final isSel = i == selected;
      final mid = start + sweep / 2;
      final offsetDist = isSel ? r * 0.05 * selectProgress : 0;
      final offset = Offset(cos(mid), sin(mid)) * offsetDist.toDouble();
      final radius = isSel ? r * (1 + 0.1 * selectProgress) : r;
      canvas.drawArc(
        Rect.fromCircle(center: center + offset, radius: radius),
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

class _LinePainter extends CustomPainter {
  final double midAngle;
  final double progress;
  final double sliceOffset;
  final double radius;
  final Color lineColor;

  _LinePainter({
    required this.midAngle,
    required this.progress,
    required this.sliceOffset,
    required this.radius,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final r = radius * (1 + 0.1 * sliceOffset / (radius * 0.05));
    final sliceCenter =
        center + Offset(cos(midAngle), sin(midAngle)) * (r * 0.6);
    final hintPos = center + Offset(cos(midAngle), sin(midAngle)) * (r + 40);

    final paint = Paint()
      ..color = lineColor.withValues(alpha: progress)
      ..strokeWidth = 2;
    canvas.drawLine(
      sliceCenter,
      Offset.lerp(sliceCenter, hintPos, progress)!,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

