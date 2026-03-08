# Radial View

A Flutter package that provides a customizable radial (circular) layout for your widgets.
`RadialView` arranges a list of widgets in a circular pattern around a specific anchor point and
supports scrolling through them seamlessly using a `CustomScrollView` and a custom
`SliverRadialList`.

## Features

- **Flexible Constructors:** Create a radial view using a static list of `children` or dynamically
  with `.builder` for an infinite or large number of items.
- **Customizable Anchors:** Anchor the radial menu to various positions on the screen (e.g., center,
  top left, bottom right) using `RadialMenuAnchor`.
- **Adjustable Radius & Padding:** Control the radius of the layout and the angular padding between
  items.
- **Radial Extent:** Define the radial thickness (width) of each child.
- **Child Rotation:** Automatically rotate children so they face outwards from the center (
  `rotateChildren`).
- **Scrollable:** Built on top of `CustomScrollView` and slivers, allowing natural scroll
  interactions.

## Getting started

Include the package in your `pubspec.yaml`:

```yaml
dependencies:
  radial_view: ^0.0.1
```

Then, run `flutter pub get` and import it in your Dart code:

```dart
import 'package:radial_view/radial_view.dart';
```

## Usage

### Using Static Children

Use the default constructor when you have a small, predetermined list of children.

```dart
import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

class StaticRadialExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Static Radial View')),
      body: RadialView(
        anchor: RadialMenuAnchor.center,
        radius: 120.0,
        maxVisibleItems: 8,
        rotateChildren: true,
        angularPadding: 5.0,
        // Degrees between items
        children: const [
          Icon(Icons.home, size: 40),
          Icon(Icons.settings, size: 40),
          Icon(Icons.person, size: 40),
          Icon(Icons.favorite, size: 40),
        ],
      ),
    );
  }
}
```

### Using the Builder

Use the `.builder` constructor to create items dynamically. This is useful for building large lists
or infinite scrolling radial views.

```dart
import 'package:flutter/material.dart';
import 'package:radial_view/radial_view.dart';

class BuilderRadialExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Builder Radial View')),
      body: RadialView.builder(
        anchor: RadialMenuAnchor.center,
        radius: 150.0,
        itemCount: 20,
        maxVisibleItems: 10,
        rotateChildren: true,
        angularPadding: 2.0,
        // Padding in degrees
        itemBuilder: (context, index) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
```

## Additional parameters

- `maxVisibleItems`: The maximum number of items visible along the given sweep angle. This helps the
  underlying sliver calculate angular extents.
- `radialExtent`: The radial thickness of each child. If null, it defaults to the `radius`.

## Additional information

For more information and to contribute to the package, please check the GitHub repository or file an
issue. We welcome pull requests!
