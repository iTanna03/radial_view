## 0.1.0+1

Initial release of `radial_view`

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
