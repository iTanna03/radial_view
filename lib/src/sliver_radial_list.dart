import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';
import 'package:radial_view/src/radial_menu_anchor_wrapper.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

// This file implements a custom Sliver that renders its children positioned
// along the circumference of a circle instead of in a straight line.
//
// Key concepts to keep in mind:
//
//   • "Radial" coordinates → angles (in radians).
//   • "Linear" coordinates → pixels, which is what Flutter's scroll engine uses.
//   • The two are related by the arc-length formula:  arc = radius × angle
//     So:  pixels = radius × radians   (see _radialToLinear)
//          radians = pixels / radius   (see _linearToRadial)
//
//   • The [anchor] decides WHERE the center of the circle is placed on screen
//     (e.g. bottom-right corner, dead center, etc.) and HOW MUCH of the arc
//     is visible at once (e.g. a corner anchor → 90° / π/2 visible arc).
//
//   • Scrolling the list rotates items along the arc. Flutter thinks in pixels;
//     we think in angles, so every scroll offset is converted to an angle first.
//
//   • Children are laid out lazily: only the items currently visible (or about
//     to become visible) are kept alive. The rest are garbage-collected.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// SliverRadialList  –  the public-facing Widget
// ---------------------------------------------------------------------------
//
// Use this inside a [CustomScrollView] exactly like [SliverList] or
// [SliverGrid]. It is a thin configuration object; all real work happens in
// the [RenderSliverRadial] render object created below.
/// A sliver that places multiple box children in a radial layout.
class SliverRadialList extends SliverMultiBoxAdaptorWidget {
  /// Creates a [SliverRadialList].
  const SliverRadialList({
    required super.delegate,
    required this.radius,
    required this.anchor,
    required this.maxVisibleItems,
    super.key,
    this.radialExtent,
    this.rotateChildren = true,
    this.angularPadding = 0.0,
  });

  /// The radius of the radial list.
  final double radius;

  /// The anchor point for the radial menu.
  final RadialMenuAnchor anchor;

  /// The maximum number of items visible along the given sweep angle.
  final int maxVisibleItems;

  /// The radial thickness (width) of each child.
  final double? radialExtent;

  /// Whether children should rotate outwards from center.
  final bool rotateChildren;

  /// The angle in radians to pad each item.
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
      maxVisibleItems: maxVisibleItems,
      radialExtent: radialExtent,
      rotateChildren: rotateChildren,
      angularPadding: angularPadding,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverRadial renderObject,
  ) {
    renderObject
      ..radius = radius
      ..anchor = anchor
      ..maxVisibleItems = maxVisibleItems
      ..radialExtent = radialExtent
      ..rotateChildren = rotateChildren
      ..angularPadding = angularPadding;
  }
}

// ---------------------------------------------------------------------------
// RenderSliverRadial  –  the render object that does all the real work
// ---------------------------------------------------------------------------
//
// Extends [RenderSliverMultiBoxAdaptor], which provides:
//   • A [childManager] that lazily builds/destroys child RenderBoxes.
//   • Helper methods: addInitialChild, insertAndLayoutChild,
//     insertAndLayoutLeadingChild, collectGarbage, indexOf, etc.
//   • The linked-list of live children (firstChild, childAfter, …).
/// A render object that lays out its children in a radial layout.
class RenderSliverRadial extends RenderSliverMultiBoxAdaptor {
  /// Creates a [RenderSliverRadial].
  RenderSliverRadial({
    required super.childManager,
    required double radius,
    required RadialMenuAnchor anchor,
    required int maxVisibleItems,
    required double? radialExtent,
    required bool rotateChildren,
    required double angularPadding,
  }) : _radius = radius,
       _anchor = anchor,
       _maxVisibleItems = maxVisibleItems,
       _radialExtent = radialExtent,
       _rotateChildren = rotateChildren,
       _angularPadding = angularPadding;

  double _radius;

  /// The radius of the radial list.
  double get radius => _radius;

  /// Sets the radius of the radial list.
  set radius(double value) {
    if (radius == value) return;
    _radius = value;
    markNeedsLayout();
  }

  // ── anchor ────────────────────────────────────────────────────────────────
  // Changing the anchor also resets _visibleItemCount because a center anchor
  // must always show all items (full 360°), while other anchors can show a
  // subset.
  RadialMenuAnchor _anchor;

  /// The anchor point for the radial menu.
  RadialMenuAnchor get anchor => _anchor;

  /// Sets the anchor point for the radial menu.
  set anchor(RadialMenuAnchor value) {
    if (anchor == value) return;
    _anchor = value;
    markNeedsLayout();
  }

  int _maxVisibleItems;

  /// The maximum number of items visible along the given sweep angle.
  int get maxVisibleItems => _maxVisibleItems;

  /// Sets the maximum number of items visible along the given sweep angle.
  set maxVisibleItems(int value) {
    if (_maxVisibleItems == value) return;
    _maxVisibleItems = value;
    markNeedsLayout();
  }

  double? _radialExtent;

  /// The radial thickness (width) of each child.
  double? get radialExtent => _radialExtent;

  /// Sets the radial thickness (width) of each child.
  set radialExtent(double? value) {
    if (_radialExtent == value) return;
    _radialExtent = value;
    markNeedsLayout();
  }

  bool _rotateChildren;

  /// Whether children should rotate outwards from center.
  bool get rotateChildren => _rotateChildren;

  /// Sets whether children should rotate outwards from center.
  set rotateChildren(bool value) {
    if (_rotateChildren == value) return;
    _rotateChildren = value;
    markNeedsPaint();
  }

  // ── angularPadding ────────────────────────────────────────────────────────
  // Extra radians added to each child's angular slot. Think of it like
  // itemExtent padding on a regular SliverList, but in the angular domain.
  double _angularPadding;

  /// The angle in radians to pad each item.
  double get angularPadding => _angularPadding;

  /// Sets the angle in radians to pad each item.
  set angularPadding(double value) {
    if (angularPadding == value) return;
    _angularPadding = value;
    markNeedsLayout();
  }

  // ── Coordinate conversion helpers ─────────────────────────────────────────
  //
  // Arc-length formula:  s = r × θ
  //
  // _radialToLinear: angle (radians) → pixel length along the arc
  //   Used to express item sizes and scroll extents in pixels so Flutter's
  //   scroll physics can work in its native unit (pixels).
  double _radialToLinear(double radians) {
    return _radius * radians;
  }

  // _linearToRadial: pixel offset → angle (radians)
  //   Used to convert the current scroll offset back into an angle so we know
  //   which part of the circle is currently in view.
  double _linearToRadial(double offset) {
    return offset / _radius;
  }

  // ── performLayout ─────────────────────────────────────────────────────────
  //
  // Called by Flutter whenever the sliver needs to (re)layout its children.
  // Responsibilities:
  //   1. Determine how many pixels the entire list would take if fully unrolled
  //      (maxScrollExtent) so the scroll physics know when to stop.
  //   2. Determine which children are currently visible based on the scroll
  //      offset, and create / destroy children accordingly.
  //   3. Record each visible child's angle in its parentData so paint() knows
  //      where to draw it.
  //   4. Report a SliverGeometry back to the viewport.
  @override
  void performLayout() {
    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    // Total number of items provided by the delegate.
    final length = childManager.childCount;

    // ── Step 1: Angular geometry ────────────────────────────────────────────
    //
    // Ask the anchor helper for:
    //   • startAngle   – where the visible arc begins (in radians, from the
    //                    positive x-axis, consistent with Canvas.drawArc).
    //   • visibleAngle – how wide the visible arc is (in radians).
    //                    e.g. center → 2π, corner → π/2.
    final radialAngle = RadialMenuAnchorWrapper.getAngle(_anchor);
    final visibleAngle = radialAngle.sweepAngle.abs();

    // Choose what bounds the layout spacing across the scroll arc.
    final totalPadding = _maxVisibleItems * angularPadding;
    final anglePerChildContent =
        (visibleAngle - totalPadding) / _maxVisibleItems;

    final angleArcPerChild = anglePerChildContent + angularPadding;

    // ── Step 2: Scroll extents ──────────────────────────────────────────────
    final scrollableAngle = angleArcPerChild * length;
    final maxScrollExtent = _radialToLinear(
      max(0, scrollableAngle - visibleAngle),
    );

    // ── Step 3: Child size ──────────────────────────────────────────────────
    // Use the chord length to determine the exact max dimension along the arc.
    // Chord formula: 2 * R * sin(theta / 2)
    final chordLength = (2 * _radius * sin(anglePerChildContent / 2)).abs();
    final maxThickness = (_radialExtent ?? _radius).clamp(0.0, _radius);

    late final BoxConstraints childConstraints;
    if (_rotateChildren) {
      // When rotated, the child's Y-axis is tangent to the circle (along the chord),
      // and its X-axis points radially outward.
      childConstraints = BoxConstraints(
        minWidth: maxThickness,
        maxWidth: maxThickness,
        minHeight: chordLength,
        maxHeight: chordLength,
      );
    } else {
      // When not rotated, we provide a square box bounded by the chord length.
      final double unrotatedDim = min(chordLength, maxThickness);
      childConstraints = BoxConstraints.tight(Size(unrotatedDim, unrotatedDim));
    }

    // ── Step 4: Determine visible range ────────────────────────────────────
    //
    // constraints.scrollOffset is the current linear scroll position in pixels.
    // Convert it to an angle so we know where the visible window starts on the
    // circle.
    final angularOffset = _linearToRadial(constraints.scrollOffset);

    // Which item index sits at the leading edge of the visible window?
    final startIndex = (angularOffset / angleArcPerChild).floor();

    // The angle at which the visible window ends.
    final endAngularOffset = angularOffset + visibleAngle;

    // If the scroll has gone past all items, report an empty sliver.
    if (startIndex >= length) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    // ── Step 5: Bootstrap the child list ───────────────────────────────────
    //
    // Check if we have a valid firstChild. If the render object has no
    // children at all yet, seed it with the first visible child.
    if (firstChild == null) {
      if (!addInitialChild(index: startIndex)) {
        // The delegate could not build a child at startIndex → empty sliver.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // ── Step 6: Remove leading garbage children ─────────────────────────────
    //
    // Walk forward through the existing child list. Any child whose index is
    // less than startIndex has scrolled out of view from the leading edge and
    // can be destroyed to free memory.
    var child = firstChild;
    var leadingGarbageChild = 0;

    while (child != null && indexOf(child) < startIndex) {
      leadingGarbageChild += 1;
      child = childAfter(child);
    }
    collectGarbage(leadingGarbageChild, 0);

    // After garbage collection the child list might be empty; re-seed it.
    if (child == null) {
      if (!addInitialChild(index: startIndex)) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    child = firstChild;

    // If firstChild's index is greater than startIndex, we need to prepend
    // children before the current leading child until we reach startIndex.
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
    assert(indexOf(child) == startIndex, 'indexOf(child) != startIndex');

    // ── Step 7: Layout visible children & assign angles ────────────────────
    //
    // Iterate forward through items from startIndex until either the trailing
    // edge of the last item passes endAngularOffset or we run out of items.
    // Use a cleaner two-pointer loop:
    //   currentChild → the child being positioned this iteration.
    //   nextChild    → the already-existing sibling after currentChild
    //   (may be null).
    var currentChild = child;
    var nextChild = childAfter(currentChild);
    var angle = angularOffset;
    var index = startIndex;

    while (angle - (angleArcPerChild / 2) < endAngularOffset &&
        index < length) {
      if (index == startIndex) {
        // First iteration – currentChild is already the seeded firstChild.
        // Always re-layout so updated childConstraints (e.g. after angularPadding
        // changes and markNeedsLayout was called) take effect. Flutter skips the
        // actual work when constraints haven't changed, so this is cheap.
        currentChild.layout(childConstraints, parentUsesSize: true);
      } else {
        // Subsequent iterations – advance to the next sibling or insert one.
        if (nextChild != null) {
          // Child already exists from a previous layout pass – re-layout it
          // so any constraint change (e.g. new angularPadding) is applied.
          currentChild = nextChild
            ..layout(childConstraints, parentUsesSize: true);
        } else {
          // No more existing children; append a new one after currentChild.
          final inserted = insertAndLayoutChild(
            childConstraints,
            after: currentChild,
            parentUsesSize: true,
          );
          if (inserted == null) {
            geometry = SliverGeometry.zero;
            childManager.didFinishLayout();
            return;
          }
          currentChild = inserted;
        }
        nextChild = childAfter(currentChild);
      }

      // compute directional multiplier based on sweepAngle
      final sign = radialAngle.sweepAngle < 0 ? -1.0 : 1.0;
      final parentData = currentChild.parentData! as SliverRadialParentData;
      final childAngle =
          radialAngle.startAngle +
          sign *
              ((angleArcPerChild * index) +
                  (angleArcPerChild / 2) -
                  angularOffset);

      // Store the angle so paint() can retrieve it without re-computing.
      parentData
        ..angle = childAngle
        // layoutOffset is required by SliverMultiBoxAdaptorParentData to track
        // each child's position in scroll space (in radians here, not pixels,
        // because paint overrides the pixel-based drawing entirely).
        ..layoutOffset = childAngle;

      // Advance the angle tracker by the FULL slot (content + padding).
      // Using paintExtentOf(currentChild) here would only advance by the
      // content size and would miscount visible children when padding > 0.
      angle += angleArcPerChild;

      index++;
    }

    // ── Step 8: Remove trailing garbage ────────────────────────────────────
    //
    // Any children that were laid out in a previous frame but are now beyond
    // the visible window (trailing edge) should be destroyed.
    var trailingGarbageChild = 0;

    var trailingChild = childAfter(currentChild);
    while (trailingChild != null) {
      trailingGarbageChild += 1;
      trailingChild = childAfter(trailingChild);
    }
    collectGarbage(0, trailingGarbageChild);

    // ── Step 9: Report geometry to the viewport ─────────────────────────────
    //
    // The sliver itself is functionally a fixed-size block that spins
    // internally when scrolled. So we give it a fixed physical "footprint"
    // on the screen equal to the viewport's height (or crossAxisExtent).
    final physicalSize = constraints.viewportMainAxisExtent;

    // The amount of extra internal "travel" the wheel needs to show the
    // last item. We calculated this earlier as `maxScrollExtent`.
    // e.g. if the user needs to scroll 200 pixels to reach the end.
    final internalScroll = maxScrollExtent;

    // The total length of this sliver in scroll space is its physical footprint
    // PLUS the internal scroll travel.
    // Why? Because the Viewport will calculate its `maxScrollExtent` as:
    //   ViewportMaxScroll = sliver.scrollExtent - viewportExtent
    // So:
    //   ViewportMaxScroll = (physicalSize + internalScroll) - physicalSize
    //   ViewportMaxScroll = internalScroll
    // This gives exactly the correct number of scrollable pixels!
    final totalScrollExtent = physicalSize + internalScroll;

    // Calculate how much of the sliver's physical footprint is still
    // overlapping the current viewport. (e.g. if we scroll past internalScroll,
    // the sliver itself starts moving off-screen).
    final layoutExtent = (totalScrollExtent - constraints.scrollOffset).clamp(
      0.0,
      double.infinity,
    );

    // The actual painted pixels, clamped to what space is remaining on screen.
    final paintExtent = layoutExtent.clamp(
      0.0,
      constraints.remainingPaintExtent,
    );

    geometry = SliverGeometry(
      scrollExtent: totalScrollExtent,
      paintExtent: paintExtent,
      maxPaintExtent: physicalSize,
      crossAxisExtent: constraints.crossAxisExtent,
      hasVisualOverflow:
          true, // Content always overflows a spinning wheel visually
    );

    childManager.didFinishLayout();
  }

  // ── paint ─────────────────────────────────────────────────────────────────
  //
  // paint() is called after performLayout() and is responsible for actually
  // drawing each child onto the canvas at its correct circular position.
  //
  // IMPORTANT: unlike a normal list, children are NOT placed at their
  // layoutOffset. Instead we use polar→Cartesian math to map the angle stored
  // in parentData to an (x, y) screen position.
  @override
  void paint(PaintingContext context, Offset offset) {
    // Determine the pixel dimensions of this sliver's painted area.
    // For a vertical scroll axis, crossAxisExtent is the width and
    // paintExtent is the height (and vice versa for horizontal).
    final width = constraints.axis == Axis.vertical
        ? geometry?.crossAxisExtent ?? 0
        : geometry?.paintExtent ?? 0;
    final height = constraints.axis == Axis.vertical
        ? geometry?.paintExtent ?? 0
        : geometry?.crossAxisExtent ?? 0;

    // Map the anchor enum to an Alignment (-1..1 in both axes) and convert
    // that to a pixel coordinate within the sliver's paint area.
    // e.g. Alignment.bottomRight → Offset(width, height)
    //      Alignment.center      → Offset(width/2, height/2)
    final alignment = RadialMenuAnchorWrapper.getAlignmentFromAnchor(_anchor);
    final center = Offset(
      (alignment.x + 1) / 2 * width,
      (alignment.y + 1) / 2 * height,
    );

    // The clip rect prevents children that are partially off-screen (e.g. at
    // the arc boundaries) from bleeding outside the sliver's paint area.
    final rect = Rect.fromLTWH(offset.dx, offset.dy, width, height);

    // ── Debug helpers (uncomment to visualise the layout) ──────────────────
    // Draw the bounding rect of this sliver:
    // context.canvas.drawRect(
    //   rect,
    //   Paint()
    //     ..style = PaintingStyle.stroke
    //     ..color = Colors.red,
    // );
    //
    // //Draw the arc that children are positioned along:
    // final radialAngle = RadialMenuAnchorWrapper.getAngle(_anchor);
    // context.canvas.drawArc(
    //   Rect.fromCenter(center: center, width: _radius * 2, height: _radius * 2),
    //   radialAngle.startAngle,
    //   radialAngle.visibleArcAngle,
    //   false,
    //   Paint()
    //     ..style = PaintingStyle.stroke
    //     ..color = Colors.black,
    // );

    context.pushClipRect(needsCompositing, offset, rect, (context, offset) {
      var child = firstChild;
      if (child == null) return;

      while (child != null) {
        final childParentData = child.parentData! as SliverRadialParentData;

        // Retrieve the angle computed during performLayout().
        final angle = childParentData.angle;

        // Uses either explicitly sized center mapping from native layout size, natively falling back mathematically.
        final offsetX = child.size.width / 2;
        final offsetY = child.size.height / 2;

        // Polar → Cartesian conversion:
        //   x = cx + r·cos(θ)
        //   y = cy + r·sin(θ)
        // Subtract half layout constraint width/height so center sits onto exact curve anchor point natively.
        final dx = center.dx + (_radius * cos(angle)) - offsetX;
        final dy = center.dy + (_radius * sin(angle)) - offsetY;

        if (rotateChildren) {
          final transform = Matrix4.identity()
            ..translateByVector3(Vector3(dx + offsetX, dy + offsetY, 0))
            ..rotateZ(angle)
            ..translateByVector3(Vector3(-offsetX, -offsetY, 0));

          context.pushTransform(needsCompositing, offset, transform, (
            context,
            offset,
          ) {
            context.paintChild(child!, Offset.zero);
          });
        } else {
          context.paintChild(child, Offset(dx, dy));
        }
        // Walk the intrinsic linked list of live children.
        child = childParentData.nextSibling;
      }
    });
  }

  // ── setupParentData ────────────────────────────────────────────────────────
  //
  // Called by Flutter whenever a new child RenderObject is attached. We attach
  // our custom SliverRadialParentData so each child can store its angle.
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! SliverRadialParentData) {
      child.parentData = SliverRadialParentData();
    }
  }

  // ── hitTestSelf ────────────────────────────────────────────────────────────
  //
  // Always returns true so that the sliver itself participates in hit testing.
  // This ensures gestures anywhere within the sliver's painted area are
  // detected, even in the gaps between children.
  @override
  bool hitTestSelf({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) => true;
}

// ---------------------------------------------------------------------------
// SliverRadialParentData
// ---------------------------------------------------------------------------
//
// Flutter's ParentData mechanism lets a parent RenderObject attach private
// layout data to each of its children. This subclass adds a single extra
// field: [angle] (in radians), which is the polar angle at which this child
// should be drawn on the circumference during paint().
//
// [layoutOffset] (inherited from SliverMultiBoxAdaptorParentData) is also
// set in performLayout() – it mirrors the angle so the framework can do basic
// bookkeeping, even though the actual on-screen position is computed from the
// angle during paint().
/// Parent data structure used by [RenderSliverRadial].
class SliverRadialParentData extends SliverMultiBoxAdaptorParentData {
  /// The angle (in radians) at which this child is positioned on the circle.
  /// Measured from the positive x-axis, consistent with [Canvas.drawArc].
  double angle = 0;
}
