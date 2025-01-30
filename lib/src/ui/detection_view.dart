import 'dart:io';
import 'package:face_verify/src/data/models/user_model.dart';
import 'package:face_verify/src/ui/widgets/camera_view.dart';
import 'package:face_verify/src/ui/widgets/close_camera_button.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_detector_overlay.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_detector_painter.dart';
import 'package:face_verify/src/ui/widgets/face_painter/face_overlay_shape.dart';
import 'package:face_verify/src/services/face_detector_service.dart';
import 'package:face_verify/src/services/recognition_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// [DetectionView] class is responsible for displaying the camera feed and performing face detection and face recognition.
class DetectionView extends StatefulWidget {
  /// [cameraDescription] Camera description to be used for the camera feed.
  final CameraDescription cameraDescription;

  /// [resolutionPreset] Resolution preset for the camera feed. default is [ResolutionPreset.high].
  final ResolutionPreset resolutionPreset;

  /// [frameSkipCount] The number of frames to be skipped before processing the next frame. This is used to throttle the number of frames processed to help optimize the performance of your application by reducing the computational load. default is 10.
  final int frameSkipCount;

  /// [threshold] The minimum distance between the face embeddings to be considered as a match. Default is 0.8.
  /// if the distance is less than the threshold, the face is recognized.
  /// decrease the threshold to increase the accuracy of the face recognition.
  final double threshold;

  /// [faceDetectorPerformanceMode] The performance mode of the face detector. Default is `FaceDetectorMode.accurate`.
  final FaceDetectorMode faceDetectorPerformanceMode;

  /// [faceOverlayShapeType] The shape type of the face overlay. Default is [FaceOverlayShapeType.rectangle].
  final FaceOverlayShapeType faceOverlayShapeType;

  /// [customFaceOverlayShape] A custom face overlay shape to be used for the face overlay. Default is null.
  /// [faceOverlayShapeType] must be set to [FaceOverlayShapeType.custom] to use this.
  /// can be customized by extending the [FaceOverlayShape] class.
  final FaceOverlayShape? customFaceOverlayShape;

  /// [users] A list of registered [UserModel] objects.
  final List<UserModel> users;

  /// [loadingWidget] A custom loading widget to be displayed while the camera is initializing.
  final Widget? loadingWidget;

  /// [DetectionView] class is responsible for displaying the camera feed and performing face detection and face recognition.
  const DetectionView({
    super.key,
    required this.users,
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
    this.frameSkipCount = 10,
    this.threshold = 0.8,
    this.faceDetectorPerformanceMode = FaceDetectorMode.accurate,
    this.faceOverlayShapeType = FaceOverlayShapeType.rectangle,
    this.customFaceOverlayShape,
    this.loadingWidget,
  });

  @override
  DetectionViewState createState() => DetectionViewState();
}

class DetectionViewState extends State<DetectionView>
    with WidgetsBindingObserver {
  CameraController? cameraController;
  late FaceDetectorService faceDetectorService;
  late RecognitionService recognitionService;

  late List<Face> detectedFaces = [];
  late Set<UserModel> recognitions = {};

  int frameCount = 0;

  /// [isBusy] A boolean value to check if the face recognition is in progress.
  bool isBusy = false;

  @override
  void initState() {
    super.initState();

    //initialize camera footage
    initializeCamera();
  }

  // close all resources
  @override
  Future<void> dispose() async {
    super.dispose();
    await cameraController?.dispose();
    await faceDetectorService.dispose();
    await recognitionService.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (!cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initializeCamera();
    }
  }

  //code to initialize the camera feed
  initializeCamera() async {
    cameraController =
        CameraController(widget.cameraDescription, widget.resolutionPreset,
            imageFormatGroup: Platform.isAndroid
                ? ImageFormatGroup.nv21 // for Android
                : ImageFormatGroup.bgra8888, // for iOS
            enableAudio: false);
    await cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }

      //initialize face detector
      faceDetectorService = FaceDetectorService(
        cameraController: cameraController,
        cameraDescription: widget.cameraDescription,
        faceDetectorPerformanceMode: widget.faceDetectorPerformanceMode,
      );

      // initialize recognition service
      recognitionService = RecognitionService(
        users: widget.users,
        rotationCompensation: faceDetectorService.rotationCompensation!,
        sensorOrientation: widget.cameraDescription.sensorOrientation,
        threshold: widget.threshold,
      );

      cameraController!.startImageStream(
        (image) async {
          frameCount++;
          if (frameCount % widget.frameSkipCount == 0) {
            if (!isBusy) {
              isBusy = true;
              setState(() {});

              //detect faces from the camera frame
              detectedFaces = await faceDetectorService.doFaceDetection(
                  faceDetectorSource: FaceDetectorSource.cameraFrame,
                  cameraFrame: image);

              if (!recognitionService.isRecognized) {
                //perform face recognition on detected faces
                if (recognitionService.performFaceRecognition(
                  recognitions: recognitions,
                  cameraImageFrame: image,
                  faces: detectedFaces,
                )) {
                  if (mounted) {
                    Navigator.of(context).pop(recognitions);
                  }
                } else {
                  isBusy = false;
                  setState(() {});
                }
              }
            }
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          body: (cameraController != null &&
                  cameraController!.value.isInitialized)
              ? Stack(
                  children: [
                    // View for displaying the live camera footage
                    CameraView(
                      cameraController: cameraController!,
                      screenSize: screenSize,
                    ),

                    // View for displaying rectangles around detected faces
                    FaceDetectorOverlay(
                      cameraController: cameraController!,
                      screenSize: screenSize,
                      faces: detectedFaces,
                      customFaceOverlayShape: widget.customFaceOverlayShape,
                      faceOverlayShapeType: widget.faceOverlayShapeType,
                    ),

                    CloseCameraButton(
                      cameraController: cameraController!,
                    )
                  ],
                )
              : widget.loadingWidget ?? Center(child: const Text('Loading')),
        ),
      ),
    );
  }
}
