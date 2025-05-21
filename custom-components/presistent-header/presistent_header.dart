import 'dart:math' show min, max;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/cupertino.dart' show ScrollPosition;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

/// Provides a way to create a sticky header that stays at the top of the viewport
class PersistentHeader extends MultiChildRenderObjectWidget {
   PersistentHeader({
    Key? key,
    required this.header,
    required this.content,
    this.overlapHeaders = false,
    this.controller,
    this.callback,
  }) : super(
          key: key,
          children: [content, header],
        );

  final Widget header;

  final Widget content;

  final bool overlapHeaders;

  final ScrollController? controller;

  final void Function(double stuckAmount)? callback;

  @override
  RenderPersistentHeader createRenderObject(BuildContext context) {
    final scrollPosition =
        controller?.position ?? Scrollable.of(context).position;
    return RenderPersistentHeader(
      scrollPosition: scrollPosition,
      callback: callback,
      overlapHeaders: overlapHeaders,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPersistentHeader renderObject) {
    final scrollPosition = controller?.position ?? Scrollable.of(context).position;
    renderObject
      ..scrollPosition = scrollPosition
      ..callback = callback
      ..overlapHeaders = overlapHeaders;
  }
}

class RenderPersistentHeader extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  void Function(double stuckAmount)? _callback;
  ScrollPosition _scrollPosition;
  bool _overlapHeaders;

  RenderPersistentHeader({
    required ScrollPosition scrollPosition,
    void Function(double stuckAmount)? callback,
    bool overlapHeaders = false,
    RenderBox? header,
    RenderBox? content,
  })  : _scrollPosition = scrollPosition,
        _callback = callback,
        _overlapHeaders = overlapHeaders {
    if (content != null) add(content);
    if (header != null) add(header);
  }

  set scrollPosition(ScrollPosition newValue) {
    if (_scrollPosition == newValue) {
      return;
    }
    final ScrollPosition oldValue = _scrollPosition;
    _scrollPosition = newValue;
    markNeedsLayout();
    if (attached) {
      oldValue.removeListener(markNeedsLayout);
      newValue.addListener(markNeedsLayout);
    }
  }

  set callback(void Function(double stuckAmount)? newValue) {
    if (_callback == newValue) {
      return;
    }
    _callback = newValue;
    markNeedsLayout();
  }

  set overlapHeaders(bool newValue) {
    if (_overlapHeaders == newValue) {
      return;
    }
    _overlapHeaders = newValue;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _scrollPosition.removeListener(markNeedsLayout);
    super.detach();
  }

  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  double get devicePixelRatio =>
      PlatformDispatcher.instance.views.first.devicePixelRatio;

  double roundToNearestPixel(double offset) {
    return (offset * devicePixelRatio).roundToDouble() / devicePixelRatio;
  }

  @override
  void performLayout() {
    final childConstraints = constraints.loosen();
    _headerBox.layout(childConstraints, parentUsesSize: true);
    _contentBox.layout(childConstraints, parentUsesSize: true);

    final headerHeight = roundToNearestPixel(_headerBox.size.height);
    final contentHeight = roundToNearestPixel(_contentBox.size.height);

    final width = constraints.constrainWidth(
      max(constraints.minWidth, _contentBox.size.width),
    );
    final height = constraints.constrainHeight(
      max(constraints.minHeight,
          _overlapHeaders ? contentHeight : headerHeight + contentHeight),
    );
    size = Size(width, height);

    final contentParentData =
        _contentBox.parentData as MultiChildLayoutParentData;
    contentParentData.offset =
        Offset(0.0, _overlapHeaders ? 0.0 : headerHeight);

    final double stuckOffset = roundToNearestPixel(determineStuckOffset());

    final double maxOffset = height - headerHeight;
    final headerParentData =
        _headerBox.parentData as MultiChildLayoutParentData;
    headerParentData.offset =
        Offset(0.0, max(0.0, min(-stuckOffset, maxOffset)));

    if (_callback != null) {
      final stuckAmount =
          max(min(headerHeight, stuckOffset), -headerHeight) / headerHeight;
      _callback!(stuckAmount);
    }
  }

  double determineStuckOffset() {
    final scrollBox =
        _scrollPosition.context.notificationContext!.findRenderObject();
    if (scrollBox?.attached ?? false) {
      try {
        return localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  @override
  void setupParentData(RenderObject child) {
    super.setupParentData(child);
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _contentBox.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _contentBox.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _overlapHeaders
        ? _contentBox.getMinIntrinsicHeight(width)
        : (_headerBox.getMinIntrinsicHeight(width) +
            _contentBox.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _overlapHeaders
        ? _contentBox.getMaxIntrinsicHeight(width)
        : (_headerBox.getMaxIntrinsicHeight(width) +
            _contentBox.getMaxIntrinsicHeight(width));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result as BoxHitTestResult,
        position: position);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}