import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_verify/src/data/models/register_user_input_model.dart';

import 'package:face_verify/src/data/models/recognition_model.dart';
import 'package:face_verify/src/data/models/user_model.dart';
import 'package:face_verify/src/services/face_detector_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:image/image.dart' as img;

/// [registerUsers] function is responsible for registering the users by performing face detection and
/// extracting the embeddings from the images.
///
/// - Parameters:
///   - faceRecognitionInputs: List of FaceRecognitionInputModel objects containing the name and image path of the users.
///   - cameraDescription: The description of the camera used for face detection.
/// - Returns: A list of UserModel objects representing the registered users.
Future<List<UserModel>> registerUsers(
    {required List<RegisterUserInputModel> faceRecognitionInputs,
    required CameraDescription cameraDescription}) async {
  FaceDetectorService faceDetectorService = FaceDetectorService(
    cameraDescription: cameraDescription,
    faceDetectorPerformanceMode: FaceDetectorMode.accurate,
  );
  RecognitionModel recognitionModel = RecognitionModel();

  List<UserModel> users = [];
  for (var i = 0; i < faceRecognitionInputs.length; i++) {
    // face detection
    List<Face> faces = await faceDetectorService.doFaceDetection(
      faceDetectorSource: FaceDetectorSource.localImage,
      localImage: File(faceRecognitionInputs[i].imagePath),
    );

    UserModel user = UserModel(
      id: i,
      name: faceRecognitionInputs[i].name,
      image: faceRecognitionInputs[i].imagePath,
      face: faces[0],
      embeddings: recognitionModel.getEmbeddings(
          image: img.decodeImage(
              await File(faceRecognitionInputs[i].imagePath).readAsBytes())!),
      distance: double.infinity,
      location: faces[0].boundingBox,
    );

    users.add(user);
  }

  log('all users : $users');
  return users;
}
