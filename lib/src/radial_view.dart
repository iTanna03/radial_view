import 'dart:math';

import 'package:flutter/material.dart';
import 'package:radial_view/src/extensions.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';
import 'package:radial_view/src/sliver_radial_list.dart';

class RadialView extends StatelessWidget {
  RadialView({
    required this.anchor,
    required this.radius,
    required List<Widget> children,
    this.childSize,
    this.maxVisibleItems,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : assert(
         (childSize == null) != (maxVisibleItems == null),
         'Either childSize or maxVisibleItems must be provided, but not both.',
       ),
       delegate = SliverChildListDelegate(children),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  RadialView.builder({
    required this.anchor,
    required this.radius,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    this.childSize,
    this.maxVisibleItems,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : assert(
         (childSize == null) != (maxVisibleItems == null),
         'Either childSize or maxVisibleItems must be provided, but not both.',
       ),
       delegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
       ),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  final RadialMenuAnchor anchor;
  final double radius;
  final SliverChildDelegate delegate;

  /// The 2D bounds each child strictly occupies
  final Size? childSize;

  /// The maximum number of items visible along the given sweep angle
  final int? maxVisibleItems;

  /// Whether children should rotate outwards from center
  final bool rotateChildren;

  /// Angle in degrees
  final double angularPadding;
  final RadialAngle _radialAngle;

  Size _getBoundingBoxSize() {
    final angle = _radialAngle.sweepAngle.abs();

    late final double largestChildSpan;
    if (childSize != null) {
      largestChildSpan = max(childSize!.width, childSize!.height);
    } else {
      largestChildSpan = this.radius * (angle / maxVisibleItems!);
    }

    final viewRadius = this.radius + largestChildSpan / 2;

    if (angle == pi / 2) {
      return Size(viewRadius, viewRadius);
    } else if (angle == pi * 2) {
      return Size(2 * viewRadius, 2 * viewRadius);
    } else if (angle == pi) {
      assert(
        _radialAngle.orientation != null,
        'orientation is required when visibleArcAngle is 180 degree',
      );
      if (_radialAngle.orientation! == RadialSweepOrientation.horizontal) {
        return Size(2 * viewRadius, viewRadius);
      } else {
        return Size(viewRadius, 2 * viewRadius);
      }
    } else {
      throw UnsupportedError('Invalid Visible Arc Angle: $angle');
    }
  }

  Axis _getScrollDirection() {
    return switch (_radialAngle.orientation) {
      RadialSweepOrientation.vertical || null => Axis.vertical,
      RadialSweepOrientation.horizontal => Axis.horizontal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = _getBoundingBoxSize();

    return Stack(
      alignment: RadialMenuAnchorWrapper.getAlignmentFromAnchor(anchor),
      fit: StackFit.expand,
      children: [
        Positioned(
          width: size.width,
          height: size.height,
          child: CustomScrollView(
            scrollDirection: _getScrollDirection(),
            slivers: [
              SliverRadialList(
                delegate: delegate,
                radius: radius,
                anchor: anchor,
                childSize: childSize,
                maxVisibleItems: maxVisibleItems,
                rotateChildren: rotateChildren,
                angularPadding: angularPadding.toRadians,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
