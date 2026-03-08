import 'package:flutter/material.dart';
import 'package:radial_view/src/extensions.dart';
import 'package:radial_view/src/radial_angle.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';
import 'package:radial_view/src/radial_menu_anchor_wrapper.dart';
import 'package:radial_view/src/sliver_radial_list.dart';

/// A widget that displays its children in a radial layout.
class RadialView extends StatelessWidget {
  /// Creates a [RadialView] with a predetermined list of static children.
  RadialView({
    required this.anchor,
    required this.radius,
    required List<Widget> children,
    required this.maxVisibleItems,
    this.controller,
    this.radialExtent,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : delegate = SliverChildListDelegate(children),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  /// Creates a [RadialView] whose children are built on demand.
  RadialView.builder({
    required this.anchor,
    required this.radius,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    required this.maxVisibleItems,
    this.controller,
    this.radialExtent,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
    super.key,
  }) : delegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
       ),
       _radialAngle = RadialMenuAnchorWrapper.getAngle(anchor);

  /// Scroll Controller
  final ScrollController? controller;

  /// The anchor point for the radial menu.
  final RadialMenuAnchor anchor;

  /// The radius of the radial menu.
  final double radius;

  /// A delegate that provides the children for the [RadialView].
  final SliverChildDelegate delegate;

  /// The maximum number of items visible along the given sweep angle.
  final int maxVisibleItems;

  /// The radial thickness (width) of each child. If null, defaults to [radius].
  final double? radialExtent;

  /// Whether children should rotate outwards from center
  final bool rotateChildren;

  /// Angle in degrees
  final double angularPadding;
  final RadialAngle _radialAngle;

  Axis _getScrollDirection() {
    return switch (_radialAngle.orientation) {
      RadialSweepOrientation.vertical || null => Axis.vertical,
      RadialSweepOrientation.horizontal => Axis.horizontal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      scrollDirection: _getScrollDirection(),
      slivers: [
        SliverRadialList(
          delegate: delegate,
          radius: radius,
          anchor: anchor,
          maxVisibleItems: maxVisibleItems,
          radialExtent: radialExtent,
          rotateChildren: rotateChildren,
          angularPadding: angularPadding.toRadians,
        ),
      ],
    );
  }
}
