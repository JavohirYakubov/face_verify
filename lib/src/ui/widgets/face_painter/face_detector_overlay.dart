import 'package:camera/camera.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_detector_painter.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_shape.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// [FaceDetectorOverlay] widget is responsible for drawing an overlay around the detected faces.
class FaceDetectorOverlay extends StatelessWidget {
  /// [FaceDetectorOverlay] widget is responsible for drawing an overlay around the detected faces.
  const FaceDetectorOverlay(
      {super.key,
      required this.faces,
      required this.cameraController,
      required this.screenSize,
      required this.faceOverlayShapeType,
      this.customFaceOverlayShape});

  final CameraController cameraController;
  final Size screenSize;
  final List<Face> faces;
  final FaceOverlayShapeType faceOverlayShapeType;
  final FaceOverlayShape? customFaceOverlayShape;

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const SizedBox();
    } else {
      final Size imageSize = Size(
        cameraController.value.previewSize!.height,
        cameraController.value.previewSize!.width,
      );

      return Positioned(
          top: 0.0,
          left: 0.0,
          width: screenSize.width,
          height: screenSize.height,
          child: CustomPaint(
            painter: FaceDetectorPainter(
                absoluteImageSize: imageSize,
                faces: faces,
                cameraDirection: cameraController.description.lensDirection,
                faceOverlayShapeType: faceOverlayShapeType,
                customFaceOverlayShape: customFaceOverlayShape),
          ));
    }
  }
}
