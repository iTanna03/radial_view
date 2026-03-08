import 'dart:math';

/// Extension methods for converting between degrees and radians.
extension AngleConverter on double {
  /// Converts the angle from degrees to radians.
  double get toRadians => this * (pi / 180);

  /// Converts the angle from radians to degrees.
  double get toDegrees => this * (180 / pi);
}
