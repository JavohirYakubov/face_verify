import 'package:camera/camera.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_oval.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_rectangle.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_shape.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// A custom painter that draws an overlay on the canvas
/// around the detected faces. It adjusts the coordinates based on the camera direction
/// and scales the bounding boxes to fit the canvas size.
class FaceDetectorPainter extends CustomPainter {
  /// A custom painter that draws an overlay on the canvas
  /// around the detected faces. It adjusts the coordinates based on the camera direction
  /// and scales the bounding boxes to fit the canvas size.
  FaceDetectorPainter(
      {required this.absoluteImageSize,
      required this.faces,
      required this.cameraDirection,
      required this.faceOverlayShapeType,
      this.customFaceOverlayShape});

  final Size absoluteImageSize;

  CameraLensDirection cameraDirection;

  final List<Face> faces;

  final FaceOverlayShape? customFaceOverlayShape;
  final FaceOverlayShapeType faceOverlayShapeType;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    for (Face face in faces) {
      // Draw red circles if face not fully inside
      if (face.headEulerAngleY! > 10 || face.headEulerAngleY! < -10) {
        paint.color = Colors.red;
      } else {
        paint.color = Colors.green;
      }

      switch (faceOverlayShapeType) {
        case FaceOverlayShapeType.rectangle:
          drawShape(
              FaceOverlayRectangleShape(), face, scaleX, scaleY, canvas, paint);
        case FaceOverlayShapeType.oval:
          drawShape(
              FaceOverlayOvalShape(), face, scaleX, scaleY, canvas, paint);

        case FaceOverlayShapeType.custom:
          if (customFaceOverlayShape != null) {
            drawShape(
                customFaceOverlayShape!, face, scaleX, scaleY, canvas, paint);
          }
        case FaceOverlayShapeType.none:
          break;
      }
    }
  }

  drawShape(FaceOverlayShape faceOverlayShape, Face face, double scaleX,
      double scaleY, Canvas canvas, Paint paint) {
    // Calculate the adjusted rectangle for the face

    final Rect rect = faceOverlayShape.calculateAdjustedRect(
      face: face,
      absoluteImageSize: absoluteImageSize,
      scaleX: scaleX,
      scaleY: scaleY,
      cameraDirection: cameraDirection,
    );
    // Draw the custom shape

    faceOverlayShape.draw(canvas, paint, rect);
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return true;
  }
}

enum FaceOverlayShapeType { none, rectangle, oval, custom }
