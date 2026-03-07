import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:radial_view/src/extensions.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';
import 'package:radial_view/src/sliver_radial_list.dart';

class RadialView extends StatelessWidget {
  RadialView({
    required this.anchor,
    required this.radius,
    required List<Widget> children,
    this.itemExtent,
    this.maxVisibleItems,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : assert(
         (itemExtent == null) != (maxVisibleItems == null),
         'Either itemExtent or maxVisibleItems must be provided, but not both.',
       ),
       delegate = SliverChildListDelegate(children),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  RadialView.builder({
    required this.anchor,
    required this.radius,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    this.itemExtent,
    this.maxVisibleItems,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : assert(
         (itemExtent == null) != (maxVisibleItems == null),
         'Either itemExtent or maxVisibleItems must be provided, but not both.',
       ),
       delegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
       ),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  final RadialMenuAnchor anchor;
  final double radius;
  final SliverChildDelegate delegate;

  /// Distance in pixels a child occupies along the circumference
  final double? itemExtent;

  /// The maximum number of items visible along the given sweep angle
  final int? maxVisibleItems;

  /// Whether children should rotate outwards from center
  final bool rotateChildren;

  /// Angle in degrees
  final double angularPadding;
  final RadialAngle _radialAngle;

  Size _getBoundingBoxSize() {
    final angle = _radialAngle.sweepAngle.abs();
    final childSize = itemExtent ?? (this.radius * (angle / maxVisibleItems!));

    final radius = this.radius + childSize / 2;

    if (angle == pi / 2) {
      return Size(radius, radius);
    } else if (angle == pi * 2) {
      return Size(2 * radius, 2 * radius);
    } else if (angle == pi) {
      assert(
        _radialAngle.orientation != null,
        'orientation is required when visibleArcAngle is 180 degree',
      );
      if (_radialAngle.orientation! == RadialSweepOrientation.horizontal) {
        return Size(2 * radius, radius);
      } else {
        return Size(radius, 2 * radius);
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
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: CustomScrollView(
              scrollDirection: _getScrollDirection(),
              slivers: [
                SliverRadialList(
                  delegate: delegate,
                  radius: radius,
                  anchor: anchor,
                  itemExtent: itemExtent,
                  maxVisibleItems: maxVisibleItems,
                  rotateChildren: rotateChildren,
                  angularPadding: angularPadding.toRadians,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
