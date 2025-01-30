import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_shape.dart';
import 'package:flutter/material.dart';

/// Predefined rectangle shape.
class FaceOverlayRectangleShape extends FaceOverlayShape {
  @override
  void draw(Canvas canvas, Paint paint, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );
  }
}
