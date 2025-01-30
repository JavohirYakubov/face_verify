import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Abstract class for defining custom face overlay shapes.
abstract class FaceOverlayShape {
  /// Draws the custom shape on the canvas.
  ///
  /// - Parameters:
  ///   - canvas: The canvas to draw on.
  ///   - paint: The paint to use for drawing.
  ///   - rect: The rectangle defining the bounds of the shape.
  void draw(Canvas canvas, Paint paint, Rect rect);

  /// Calculates the adjusted coordinates for the face bounding box.
  ///
  /// - Parameters:
  ///   - face: The detected [Face] object.
  ///   - absoluteImageSize: The size of the image from the camera.
  ///   - scaleX: The scale factor for the x-axis.
  ///   - scaleY: The scale factor for the y-axis.
  ///   - cameraDirection: The direction of the camera (front or back).
  /// - Returns: A [Rect] object with the adjusted coordinates.
  Rect calculateAdjustedRect({
    required Face face,
    required Size absoluteImageSize,
    required double scaleX,
    required double scaleY,
    required CameraLensDirection cameraDirection,
  }) {
    final double left = cameraDirection == CameraLensDirection.front
        ? (absoluteImageSize.width - face.boundingBox.right) * scaleX
        : face.boundingBox.left * scaleX;
    final double right = cameraDirection == CameraLensDirection.front
        ? (absoluteImageSize.width - face.boundingBox.left) * scaleX
        : face.boundingBox.right * scaleX;
    final double top = face.boundingBox.top * scaleY;
    final double bottom = face.boundingBox.bottom * scaleY;

    return Rect.fromLTRB(left, top, right, bottom);
  }
}
