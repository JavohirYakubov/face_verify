import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:image/image.dart' as img;

/// [FaceDetectorService] class is responsible for detecting faces from  camera frame or a local image
class FaceDetectorService {
  /// [faceDetector] The face detector object used to detect faces.
  late FaceDetector faceDetector;

  /// [faceDetectorPerformanceMode] The performance mode of the face detector. Default is `FaceDetectorMode.accurate`.
  final FaceDetectorMode faceDetectorPerformanceMode;

  /// [cameraController] The camera controller used to access the camera.
  late CameraController? cameraController;

  /// [cameraDescription] The camera description used to access the camera settings.
  final CameraDescription cameraDescription;

  /// [_orientations] A map of device orientations to their respective rotation values.
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// [rotationCompensation] The rotation compensation value used to adjust the image rotation based on the camera orientation.
  late int? rotationCompensation =
      _orientations[cameraController?.value.deviceOrientation];

  /// [FaceDetectorService] class is responsible for detecting faces from  camera frame or a local image
  FaceDetectorService({
    this.cameraController,
    required this.cameraDescription,
    this.faceDetectorPerformanceMode = FaceDetectorMode.accurate,
  }) {
    FaceDetectorOptions faceDetectorOptions =
        FaceDetectorOptions(performanceMode: faceDetectorPerformanceMode);
    faceDetector = FaceDetector(options: faceDetectorOptions);
    log('FaceDetectorService created');
  }

  /// Performs face detection on the provided image source.
  ///
  /// This function processes the image from the specified source (camera frame or local image)
  /// and detects faces using the face detection library. It converts the image to the required
  /// format and then passes it to the face detection model to detect faces.
  ///
  /// The following steps are performed:
  /// 1. Determines the source of the image (camera frame or local image).
  /// 2. Converts the image to an [InputImage] format required by the face detection library.
  /// 3. Passes the [InputImage] to the face detection model to detect faces.
  /// 4. Returns a list of detected faces.
  ///
  /// Note: If the source is a camera frame, the `cameraController` must not be null.
  ///
  /// - Parameters:
  ///   - faceDetectorSource: The source of the image (camera frame or local image).
  ///   - cameraFrame: The [CameraImage] to be processed (if the source is camera frame).
  ///     Required if `faceDetectorSource` is `FaceDetectorSource.cameraFrame`.
  ///   - localImage: The [File] object representing the local image file (if the source is local image).
  ///     Required if `faceDetectorSource` is `FaceDetectorSource.localImage`.
  /// - Returns: A list of detected [Face] objects.
  /// - Throws: An exception if the required parameters are not provided or if the image conversion fails.
  Future<List<Face>> doFaceDetection({
    required FaceDetectorSource? faceDetectorSource,
    CameraImage? cameraFrame,
    File? localImage,
  }) async {
    InputImage? inputImage;
    if (faceDetectorSource == FaceDetectorSource.cameraFrame &&
        cameraController != null &&
        cameraFrame != null) {
      inputImage = _inputImageFromCameraImage(cameraFrame)!;
    } else if (faceDetectorSource == FaceDetectorSource.localImage &&
        localImage != null) {
      inputImage = await _inputImageFromLocalImage(localImage: localImage);
    } else {
      throw Exception('Invalid face detector source');
    }

    //pass InputImage to face detection model and detect faces
    List<Face> faces = await faceDetector.processImage(inputImage);

    return faces;
  }

  /// Converts a [CameraImage] to an [InputImage] for face detection.
  ///
  /// This function calculates the necessary rotation and format based on the platform
  /// and camera orientation. It is essential for converting the raw camera image data
  /// into a format that the face detection library can process.
  ///
  /// The function ensures that the image format is either NV21 for Android or BGRA8888
  /// for iOS, and only processes images with a single plane. It returns null if the
  /// format or rotation cannot be determined or if the image format is not supported.
  ///
  /// - Parameter image: The [CameraImage] to be converted.
  /// - Returns: An [InputImage] if the conversion is successful, otherwise null.
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation

    final sensorOrientation = cameraDescription.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      rotationCompensation =
          _orientations[cameraController?.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (cameraDescription.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation =
            (sensorOrientation + rotationCompensation!) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation! + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation!);
    }

    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  /// Converts a local image file to an [InputImage] for face detection.
  ///
  /// This function reads the image file from the provided path and converts it into
  /// an [InputImage] format required by the face detection library. It is essential
  /// for converting the local image data into a format that the face detection library
  /// can process.
  ///
  /// - Parameter file: The [File] object representing the local image file.
  /// - Returns: An [InputImage] if the conversion is successful, otherwise null.
  Future<InputImage> _inputImageFromLocalImage(
      {required File localImage}) async {
    File? image;
    // remove rotation of camera images
    image = await _removeRotation(localImage);

    // passing input to face detector and getting detected faces
    InputImage inputImage = InputImage.fromFile(image!);
    return inputImage;
  }

  _removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage.path).readAsBytes());

    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(inputImage.path)
        .writeAsBytes(img.encodeJpg(orientedImage));
  }

  dispose() async {
    await faceDetector.close();
    await cameraController?.dispose();
  }
}

/// [FaceDetectorSource] enum is used to specify the source of the frame to be used for face detection.
/// It can be either a camera frame or a local image.
enum FaceDetectorSource { cameraFrame, localImage }
