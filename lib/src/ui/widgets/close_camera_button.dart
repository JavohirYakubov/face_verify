import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// [CloseCameraButton] is a widget that displays a close button on the top left corner of the screen.
class CloseCameraButton extends StatelessWidget {
  /// [CloseCameraButton] is a widget that displays a close button on the top left corner of the screen.
  const CloseCameraButton({
    super.key,
    required this.cameraController,
  });

  final CameraController cameraController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 5,
      top: 5,
      child: CloseButton(
        style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.red),
            elevation: WidgetStatePropertyAll(10)),
        color: Colors.white,
        onPressed: () async {
          await cameraController.stopImageStream();
          await cameraController.dispose();

          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
