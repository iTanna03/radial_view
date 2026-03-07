import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final anchor = RadialMenuAnchor.bottomCenter;

    return Scaffold(
      appBar: AppBar(title: Text('Radial View')),
      body: RadialView.builder(
        anchor: anchor,
        radius: 180,
        angularPadding: 0,
        itemExtent: 60,
        itemCount: 20,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.black,
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }
}
