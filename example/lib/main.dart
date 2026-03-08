import 'dart:math';

import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const double radius = 180;

    return Scaffold(
      appBar: AppBar(title: const Text('Radial View')),
      body: RadialView.builder(
        anchor: RadialMenuAnchor.bottomCenter,
        radius: radius,
        radialExtent: 90,
        angularPadding: 2,
        itemCount: 100,
        maxVisibleItems: 3,
        itemBuilder: (context, index) {
          final colors = Colors.primaries;

          return CustomPaint(
            painter: SectorPainter(
              radius: radius,
              color: colors[index % colors.length],
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SectorPainter extends CustomPainter {
  final double radius;
  final Color color;

  SectorPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // The child knows its radial thickness (width) and chord length (height)
    final chordLength = size.height;
    final thickness = size.width;

    // The center of the entire radial view in the child's local coordinates.
    // The child's local X-axis points outward radially.
    final center = Offset(thickness / 2 - radius, chordLength / 2);

    // Calculate the sweep angle using the chord length formula
    // chord = 2 * r * sin(theta / 2) -> theta = 2 * asin(chord / (2 * r))
    final theta = 2 * asin(chordLength / (2 * radius));

    // The distance to the inner and outer boundaries from the global center
    final innerRadius = radius - thickness / 2;
    final outerRadius = radius + thickness / 2;

    final path = Path();

    // 1. Draw the inner arc from -theta/2 to +theta/2
    path.addArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -theta / 2,
      theta,
    );

    // 2. Connect to the outer arc and sweep backwards from +theta/2 to -theta/2
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      theta / 2,
      -theta,
      false, // don't start a new subpath, effectively drawing a line to the outer edge
    );

    // 3. Connect the outer edge back to the inner edge forming a closed sector
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant SectorPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}
