import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radial_view/src/radial_menu_anchor.dart';
import 'package:radial_view/src/sliver_radial_list.dart';

void main() {
  testWidgets('SliverRadialList debug test', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              SliverRadialList(
                radius: 100,
                anchor: RadialMenuAnchor.bottomCenter,
                // or another anchor
                radialExtent: 50,
                maxVisibleItems: 5,
                angularPadding: 0.1,
                delegate: SliverChildBuilderDelegate((context, index) {
                  return SizedBox(width: 20, height: 20, child: Text('$index'));
                }, childCount: 20),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to the end
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    log('Max scroll extent: ${controller.position.maxScrollExtent}');
  });
}
