import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// for preview only
import 'package:flutter/widget_previews.dart';
import 'package:flutter/material.dart' show Colors, Ink, InkWell, Material;

class GravitationalLayout extends MultiChildRenderObjectWidget {
  final double orbitSpacing;
  final Paint? orbitPaint;
  final double initialAngle;
  final Widget body;
  final List<Widget> orbiting;

  GravitationalLayout({
    super.key,
    this.orbitSpacing = 1.0,
    this.orbitPaint,
    this.initialAngle = 0.0,
    required this.body,
    required this.orbiting,
  }) : super(children: [body, ...orbiting]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      GravitationalRenderObject(
        orbitSpacing: orbitSpacing,
        orbitPaint: orbitPaint,
        initialAngle: initialAngle,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant GravitationalRenderObject renderObject,
  ) {
    renderObject.orbitSpacing = orbitSpacing;
    renderObject.orbitPaint = orbitPaint;
    renderObject.initialAngle = initialAngle;
  }

  static Offset getWidgetPosition(BuildContext context) {
    final layoutedObject =
        context.findRenderObject()!.parentData as _GravitationalParentData;
    return layoutedObject.relativeOffset!;
  }
}

class _GravitationalParentData extends ContainerBoxParentData<RenderBox> {
  double? angle;
  Offset? relativeOffset;
}

class GravitationalRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GravitationalParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GravitationalParentData> {
  double _orbitSpacing;
  double get orbitSpacing => _orbitSpacing;
  set orbitSpacing(double value) {
    if (_orbitSpacing == value) {
      return;
    }
    _orbitSpacing = value;
    markNeedsLayout();
  }

  Paint? _orbitPaint;
  Paint? get orbitPaint => _orbitPaint;
  set orbitPaint(Paint? value) {
    if (_orbitPaint == value) {
      return;
    }
    _orbitPaint = value;
    markNeedsPaint();
  }

  double _initialAngle;
  double get initialAngle => _initialAngle;
  set initialAngle(double value) {
    if (_initialAngle == value) {
      return;
    }
    _initialAngle = value;
    _computeChildrenOffsets();
    markNeedsPaint();
  }

  double? _orbitDistance;

  GravitationalRenderObject({
    required double orbitSpacing,
    required Paint? orbitPaint,
    required double initialAngle,
  }) : _orbitSpacing = orbitSpacing,
       _orbitPaint = orbitPaint,
       _initialAngle = initialAngle;

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _GravitationalParentData();
  }

  @override
  void performLayout() {
    RenderBox body = firstChild!;
    final bodyData = body.parentData as _GravitationalParentData;
    body.layout(BoxConstraints.tightFor(), parentUsesSize: true);
    double bodyRadius = body.size.longestSide / 2;

    double maxRadius = 0.0;
    RenderBox? child = bodyData.nextSibling;
    while (child != null) {
      final childParentData = child.parentData as _GravitationalParentData;

      child.layout(BoxConstraints.tightFor(), parentUsesSize: true);
      maxRadius = max(maxRadius, child.size.longestSide / 2.0);

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    _orbitDistance = bodyRadius + maxRadius + orbitSpacing;

    double angle = 0;
    double angleDelta = 2 * pi / (childCount - 1);

    child = bodyData.nextSibling;
    while (child != null) {
      final childParentData = child.parentData as _GravitationalParentData;

      childParentData.angle = angle;
      angle += angleDelta;

      child = childParentData.nextSibling;
    }

    size = Size.square(2 * (_orbitDistance! + maxRadius));
    _computeChildrenOffsets();
  }

  void _computeChildrenOffsets() {
    final systemCenter = size.center(Offset.zero);

    RenderBox body = firstChild!;
    final bodyData = body.parentData as _GravitationalParentData;
    bodyData.offset = body.size.uncenter(systemCenter);
    bodyData.relativeOffset = Offset.zero;

    RenderBox? child = bodyData.nextSibling;
    while (child != null) {
      final childParentData = child.parentData as _GravitationalParentData;

      childParentData.relativeOffset = Offset.fromDirection(
        _initialAngle + childParentData.angle!,
        _orbitDistance!,
      );
      childParentData.offset =
          systemCenter + child.size.uncenter(childParentData.relativeOffset!);

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final systemCenter = size.center(offset);

    if (_orbitPaint != null) {
      context.canvas.drawCircle(systemCenter, _orbitDistance!, _orbitPaint!);
    }

    super.defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return super.defaultHitTestChildren(result, position: position);
  }
}

extension OrbitalsExtension on Size {
  Offset uncenter(Offset center) =>
      Offset(center.dx - width / 2.0, center.dy - height / 2.0);
}

Widget _getCircle(double radius, Color color) {
  return Material(
    child: InkWell(
      // ignore: avoid_print
      onTap: () => print("You clicked on $color"),
      customBorder: CircleBorder(),
      child: Ink(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}

@Preview(name: "Static Gravitational layout")
Widget sampleGravitationalBLayout() {
  return Center(
    child: GravitationalLayout(
      orbitSpacing: 15,
      orbitPaint: Paint()
        ..color = Colors.purple
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      initialAngle: pi / 4,
      body: _getCircle(30, Colors.yellow),
      orbiting: [
        _getCircle(20, Colors.red),
        _getCircle(10, Colors.blue),
        _getCircle(15, Colors.green),
      ],
    ),
  );
}
