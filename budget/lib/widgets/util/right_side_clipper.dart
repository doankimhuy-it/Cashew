import 'package:flutter/material.dart';

class RightSideClipper extends CustomClipper<RRect> {
  @override
  RRect getClip(Size size) {
    final radius = const Radius.circular(0);
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromPoints(const Offset(0, -1000), Offset(size.width, size.height + 1000)),
      radius,
    );
    return rightRect;
  }

  @override
  bool shouldReclip(CustomClipper<RRect> oldClipper) {
    return false;
  }
}
