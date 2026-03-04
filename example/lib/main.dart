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
      body: RadialView(
        anchor: RadialMenuAnchor.bottomCenter,
        radius: 200,
        angularPadding: 10,
        delegate: SliverChildBuilderDelegate(
          (context, index) => CircleAvatar(
            radius: 10,
            backgroundColor: Colors.primaries[index % Colors.primaries.length],
          ),
          childCount: 20,
        ),
        visibleItemCount: 10,
      ),
    );
  }
}
