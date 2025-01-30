import 'package:camera/camera.dart';
import 'package:face_verify/src/data/models/recognition_model.dart';
import 'package:face_verify/src/data/models/user_model.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:developer';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// [RecognitionService] class is responsible for performing face recognition on the detected faces.
class RecognitionService {
  /// [threshold] The minimum distance between the face embeddings to be considered as a match. Default is 0.8.
  /// if the distance is less than the threshold, the face is recognized.
  /// decrease the threshold to increase the accuracy of the face recognition.
  final double threshold;

  /// [sensorOrientation] The orientation of the camera sensor.
  final int sensorOrientation;

  /// [users] A list of registered [UserModel] objects.
  final List<UserModel> users;

  /// [RecognitionService] class is responsible for performing face recognition on the detected faces.
  RecognitionService(
      {required this.rotationCompensation,
      required this.sensorOrientation,
      required this.users,
      this.threshold = 0.8}) {
    log('recognition service created');
  }

  /// [rotationCompensation] The rotation compensation to be applied to the image.
  int rotationCompensation;

  /// [isRecognized] A boolean value to check if the face is recognized.
  bool isRecognized = false;

  /// [recognitionModel] An instance of the [RecognitionModel] class.
  RecognitionModel recognitionModel = RecognitionModel();

  /// [recognizedUser] The user that is recognized.
  UserModel? recognizedUser;

  /// Performs face recognition on the provided image frames and detected faces.
  ///
  /// This method processes the provided image frames (either from the camera or a local image) and
  /// detected faces then performs face recognition to identify known users. It updates the
  /// `recognitions` set with the recognized users.
  ///
  /// - Parameters:
  ///   - cameraImageFrame: The [CameraImage] to be processed (if provided).
  ///   - localImageFrame: The [img.Image] to be processed (if provided).
  ///   - faces: A list of detected [Face] objects.
  ///   - recognitions: A set of [UserModel] objects to be updated with recognized users.
  /// - Returns: A boolean value indicating whether any faces were recognized.
  bool performFaceRecognition({
    CameraImage? cameraImageFrame,
    img.Image? localImageFrame,
    required List<Face> faces,
    required Set<UserModel> recognitions,
  }) {
    recognitions.clear();
    img.Image? image;
    if (cameraImageFrame != null) {
      //convert CameraImage to Image and rotate it so that our frame will be in a portrait
      image = Platform.isIOS
          ? _convertBGRA8888ToImage(cameraImageFrame) as img.Image?
          : _convertNV21(cameraImageFrame);

      if (Platform.isIOS) {
        image = img.copyRotate(image!, angle: sensorOrientation);
      } else if (Platform.isAndroid) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;

        image = img.copyRotate(image!, angle: rotationCompensation);
      }
    } else if (localImageFrame != null) {
      image = localImageFrame;
    }

    img.Image? croppedFace;

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      //crop face
      croppedFace = _cropFaces(image: image!, faceRect: faceRect);

      //pass cropped face to face recognition model
      recognizedUser = recognitionModel.recognize(
          users: users,
          croppedFace: croppedFace,
          location: faceRect,
          face: face);

      if (recognizedUser!.distance < threshold &&
          recognizedUser!.distance >= 0) {
        recognitions.add(recognizedUser!);
        log('Face Recognized !');
        isRecognized = true;
      }
    }

    return isRecognized;
  }

  img.Image _cropFaces({required img.Image image, required Rect faceRect}) {
    return img.copyCrop(image,
        x: faceRect.left.toInt(),
        y: faceRect.top.toInt(),
        width: faceRect.width.toInt(),
        height: faceRect.height.toInt());
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];
    var iosBytesOffset = 28;
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      rowStride: plane.bytesPerRow,
      bytesOffset: iosBytesOffset,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertNV21(CameraImage image) {
    final width = image.width.toInt();
    final height = image.height.toInt();

    Uint8List yuv420sp = image.planes[0].bytes;

    final outImg = img.Image(height: height, width: width);
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0) {
          r = 0;
        } else if (r > 262143) {
          r = 262143;
        }

        if (g < 0) {
          g = 0;
        } else if (g > 262143) {
          g = 262143;
        }
        if (b < 0) {
          b = 0;
        } else if (b > 262143) {
          b = 262143;
        }

        outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
      }
    }
    return outImg;
  }

  dispose() {
    recognitionModel.close();
  }
}
