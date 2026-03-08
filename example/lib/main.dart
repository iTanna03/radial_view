import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Radial View')),
      body: RadialView.builder(
        anchor: RadialMenuAnchor.centerLeft,
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
