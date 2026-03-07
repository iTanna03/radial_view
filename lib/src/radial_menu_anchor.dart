import 'dart:math';

import 'package:flutter/painting.dart';

enum RadialMenuAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class RadialMenuAnchorWrapper {
  static const double _zero = 0.0; // 0 deg
  static const double _halfPi = pi / 2; // 90 deg
  static const double _pi = pi; // 180 deg
  static const double _threeQuarterPi = _pi + _halfPi; // 270 deg
  static const double _full = 2 * _pi; //360 deg

  static const double _minusHalfPi = -_halfPi;

  static final _anchorToAngle = {
    RadialMenuAnchor.topLeft: RadialAngle(startAngle: _zero, endAngle: _halfPi),
    RadialMenuAnchor.topCenter: RadialAngle(
      startAngle: _pi,
      endAngle: _zero,
      orientation: RadialSweepOrientation.horizontal,
    ),
    RadialMenuAnchor.topRight: RadialAngle(startAngle: _pi, endAngle: _halfPi),
    RadialMenuAnchor.centerLeft: RadialAngle(
      startAngle: _minusHalfPi,
      endAngle: _halfPi,
      orientation: RadialSweepOrientation.vertical,
    ),
    RadialMenuAnchor.center: RadialAngle(
      startAngle: _minusHalfPi,
      endAngle: _threeQuarterPi,
    ),
    RadialMenuAnchor.centerRight: RadialAngle(
      startAngle: _threeQuarterPi,
      endAngle: _halfPi,
      orientation: RadialSweepOrientation.vertical,
    ),
    RadialMenuAnchor.bottomLeft: RadialAngle(
      startAngle: _threeQuarterPi,
      endAngle: _full,
    ),
    RadialMenuAnchor.bottomCenter: RadialAngle(
      startAngle: _pi,
      endAngle: _full,
      orientation: RadialSweepOrientation.horizontal,
    ),
    RadialMenuAnchor.bottomRight: RadialAngle(
      startAngle: _threeQuarterPi,
      endAngle: _pi,
    ),
  };

  static Alignment getAlignmentFromAnchor(RadialMenuAnchor anchor) {
    return switch (anchor) {
      RadialMenuAnchor.topLeft => Alignment.topLeft,
      RadialMenuAnchor.topCenter => Alignment.topCenter,
      RadialMenuAnchor.topRight => Alignment.topRight,
      RadialMenuAnchor.centerLeft => Alignment.centerLeft,
      RadialMenuAnchor.center => Alignment.center,
      RadialMenuAnchor.centerRight => Alignment.centerRight,
      RadialMenuAnchor.bottomLeft => Alignment.bottomLeft,
      RadialMenuAnchor.bottomCenter => Alignment.bottomCenter,
      RadialMenuAnchor.bottomRight => Alignment.bottomRight,
    };
  }

  static RadialAngle getAngle(RadialMenuAnchor anchor) =>
      _anchorToAngle[anchor]!;
}

enum RadialSweepOrientation { horizontal, vertical }

class RadialAngle {
  RadialAngle({
    required this.startAngle,
    required this.endAngle,
    this.orientation,
  });

  final double startAngle;
  final double endAngle;
  final RadialSweepOrientation? orientation;

  double get visibleArcAngle => sweepAngle.abs();

  double get sweepAngle => endAngle - startAngle;

  @override
  String toString() {
    return '$startAngle - $endAngle';
  }
}
