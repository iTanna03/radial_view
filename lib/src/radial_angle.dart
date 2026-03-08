import 'package:radial_view/src/radial_menu_anchor_wrapper.dart';

/// Represents the angular bounds of a radial view.
class RadialAngle {
  /// Creates a [RadialAngle] with the given [startAngle], [endAngle], and optional [orientation].
  RadialAngle({
    required this.startAngle,
    required this.endAngle,
    this.orientation,
  });

  /// The starting angle of the sweep in radians.
  final double startAngle;

  /// The ending angle of the sweep in radians.
  final double endAngle;

  /// The orientation of the sweep, useful mainly for 180-degree half-circles.
  final RadialSweepOrientation? orientation;

  /// Returns the absolute visible angle of the arc in radians.
  double get visibleArcAngle => sweepAngle.abs();

  /// Returns the signed sweep angle of the arc in radians.
  double get sweepAngle => endAngle - startAngle;

  @override
  String toString() {
    return '$startAngle - $endAngle';
  }
}
