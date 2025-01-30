import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_shape.dart';
import 'package:flutter/material.dart';

/// Predefined oval shape.
class FaceOverlayOvalShape extends FaceOverlayShape {
  @override
  void draw(Canvas canvas, Paint paint, Rect rect) {
    canvas.drawOval(rect, paint);
  }
}
