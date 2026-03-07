import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final anchor = RadialMenuAnchor.centerLeft;

    return Scaffold(
      appBar: AppBar(title: Text('Radial View')),
      body: RadialView.builder(
        anchor: anchor,
        radius: 180,
        angularPadding: 10,
        maxVisibleItems: 8,
        itemCount: 100,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: ShapeDecoration(color: Colors.red, shape: StarBorder()),
        ),
      ),
    );
  }
}
