import 'dart:math';

extension AngleConverter on double {
  double get toRadians => this * (pi / 180);

  double get toDegrees => this * (180 / pi);
}
