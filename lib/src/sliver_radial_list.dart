import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';

class SliverRadialList extends SliverMultiBoxAdaptorWidget {
  const SliverRadialList({
    super.key,
    required super.delegate,
    required this.radius,
    required this.anchor,
    this.visibleItemCount,
    this.angularPadding = 0.0,
  });

  final double radius;
  final RadialMenuAnchor anchor;
  final int? visibleItemCount;
  final double angularPadding;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    return RenderSliverRadial(
      childManager: context as SliverMultiBoxAdaptorElement,
      radius: radius,
      anchor: anchor,
      visibleItemCount: visibleItemCount,
      angularPadding: angularPadding,
    );
  }
}

class RenderSliverRadial extends RenderSliverMultiBoxAdaptor {
  RenderSliverRadial({
    required super.childManager,
    required double radius,
    required RadialMenuAnchor anchor,
    required int? visibleItemCount,
    required double angularPadding,
  }) : assert(
         visibleItemCount == null ||
             visibleItemCount <= childManager.childCount,
       ),
       _radius = radius,
       _anchor = anchor,
       _visibleItemCount = anchor == RadialMenuAnchor.center
           ? childManager.childCount
           : visibleItemCount ?? childManager.childCount,
       _angularPadding = angularPadding;

  double _radius;

  double get radius => _radius;

  set radius(double value) {
    if (radius == value) return;
    _radius = value;
    markNeedsLayout();
  }

  RadialMenuAnchor _anchor;

  RadialMenuAnchor get anchor => _anchor;

  set anchor(RadialMenuAnchor value) {
    if (anchor == value) return;
    _anchor = value;
    _visibleItemCount = _anchor == RadialMenuAnchor.center
        ? childManager.childCount
        : visibleItemCount;
    markNeedsLayout();
  }

  int _visibleItemCount;

  int get visibleItemCount => _visibleItemCount;

  set visibleItemCount(int value) {
    if (visibleItemCount == value) return;
    _visibleItemCount = anchor == RadialMenuAnchor.center
        ? childManager.childCount
        : value;
    markNeedsLayout();
  }

  double _angularPadding;

  double get angularPadding => _angularPadding;

  set angularPadding(double value) {
    if (angularPadding == value) return;
    _angularPadding = value;
    markNeedsLayout();
  }

  double _radialToLinear(double radians) {
    return _radius * radians;
  }

  double _linearToRadial(double offset) {
    return offset / _radius;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final length = childManager.childCount;

    final radialAngle = RadialMenuAnchorWrapper.getAngle(_anchor);
    final visibleAngle = radialAngle.visibleArcAngle;

    final angleArcPerChild = (visibleAngle / _visibleItemCount);
    final paintExtent = _radialToLinear(angleArcPerChild) * _visibleItemCount;

    final scrollableAngle = (angleArcPerChild * length);
    final maxScrollExtent = _radialToLinear(scrollableAngle);

    final childDimension = _radialToLinear(angleArcPerChild);
    final childConstraints = BoxConstraints.tight(
      Size(childDimension, childDimension),
    );

    final angularOffset = _linearToRadial(constraints.scrollOffset);
    final startIndex = (angularOffset / angleArcPerChild).floor();
    final endAngularOffset = angularOffset + visibleAngle;

    if (startIndex >= length) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    //Check if we have a valid firstChild
    if (firstChild == null) {
      if (!addInitialChild(index: startIndex)) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? child = firstChild;
    int leadingGarbageChild = 0;

    while (child != null && indexOf(child) < startIndex) {
      leadingGarbageChild += 1;
      child = childAfter(child);
    }
    collectGarbage(leadingGarbageChild, 0);

    if (child == null) {
      if (!addInitialChild(index: startIndex)) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    child = firstChild;

    while (child == null || indexOf(child) > startIndex) {
      child = insertAndLayoutLeadingChild(
        childConstraints,
        parentUsesSize: true,
      );
      if (child == null) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }
    assert(indexOf(child) == startIndex);

    RenderBox currentChild = child;
    double angle = angularOffset;
    int index = startIndex;
    while (angle - (angleArcPerChild / 2) < endAngularOffset &&
        index < length) {
      if (!currentChild.hasSize) {
        currentChild.layout(childConstraints, parentUsesSize: true);
      } else if (child == null) {
        child = insertAndLayoutChild(
          childConstraints,
          after: currentChild,
          parentUsesSize: true,
        );
        if (child == null) {
          geometry = SliverGeometry.zero;
          childManager.didFinishLayout();
          return;
        }
      }

      currentChild = child!;

      final parentData = currentChild.parentData as SliverRadialParentData;
      final childAngle =
          radialAngle.startAngle -
          angularOffset +
          (angleArcPerChild * index) +
          (angleArcPerChild / 2);
      parentData.angle = childAngle;
      parentData.layoutOffset = childAngle;

      angle += _linearToRadial(paintExtentOf(currentChild));

      child = childAfter(currentChild);
      index++;
    }

    int trailingGarbageChild = 0;

    child = childAfter(currentChild);
    while (child != null) {
      trailingGarbageChild += 1;
      child = childAfter(child);
    }
    collectGarbage(0, trailingGarbageChild);

    geometry = SliverGeometry(
      scrollExtent: maxScrollExtent,
      paintExtent: constraints.viewportMainAxisExtent,
      maxPaintExtent: paintExtent,
      crossAxisExtent: constraints.crossAxisExtent,
    );

    childManager.didFinishLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final width = constraints.axis == Axis.vertical
        ? geometry?.crossAxisExtent ?? 0
        : geometry?.paintExtent ?? 0;
    final height = constraints.axis == Axis.vertical
        ? geometry?.paintExtent ?? 0
        : geometry?.crossAxisExtent ?? 0;

    final alignment = RadialMenuAnchorWrapper.getAlignmentFromAnchor(_anchor);
    final center = Offset(
      (alignment.x + 1) / 2 * width,
      (alignment.y + 1) / 2 * height,
    );

    final rect = Rect.fromLTWH(offset.dx, offset.dy, width, height);
    // context.canvas.drawRect(
    //     rect,
    //     Paint()
    //       ..style = PaintingStyle.stroke
    //       ..color = Colors.red);

    // context.canvas.drawArc(
    //     Rect.fromCenter(
    //         center: center, width: _radius * 2, height: _radius * 2),
    //     radialAngle.startAngle,
    //     radialAngle.visibleArcAngle,
    //     false,
    //     Paint()
    //       ..style = PaintingStyle.stroke
    //       ..color = Colors.black);

    context.pushClipRect(needsCompositing, offset, rect, (context, offset) {
      RenderBox? child = firstChild;
      if (child == null) return;

      while (child != null) {
        final childParentData = child.parentData as SliverRadialParentData;
        final angle = childParentData.angle;
        final childSize = child.size.width / 2;

        final dx = center.dx + (_radius * cos(angle)) - childSize;
        final dy = center.dy + (_radius * sin(angle)) - childSize;

        context.paintChild(child, Offset(dx, dy));
        child = childParentData.nextSibling;
      }
    });
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! SliverRadialParentData) {
      child.parentData = SliverRadialParentData();
    }
  }

  @override
  bool hitTestSelf({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) => true;
}

class SliverRadialParentData extends SliverMultiBoxAdaptorParentData {
  double angle = 0.0;
}
