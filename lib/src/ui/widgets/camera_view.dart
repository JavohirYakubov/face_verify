import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// The [CameraView] widget is responsible for displaying the camera preview
/// using the provided [CameraController] and fitting it to the given [screenSize].
class CameraView extends StatelessWidget {
  ///  [CameraController] used to access the camera and display the camera preview.
  final CameraController cameraController;

  /// [screenSize] is the size of the screen to fit the camera preview to.
  final Size screenSize;

  /// The [CameraView] widget is responsible for displaying the camera preview
  /// using the provided [CameraController] and fitting it to the given [screenSize].
  const CameraView(
      {super.key, required this.cameraController, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0.0,
      left: 0.0,
      width: screenSize.width,
      height: screenSize.height,
      child: AspectRatio(
        aspectRatio: cameraController.value.aspectRatio,
        child: CameraPreview(cameraController),
      ),
    );
  }
}
