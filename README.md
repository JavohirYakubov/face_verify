A Flutter package for face detection and recognition using Google ML Kit and TensorFlow Lite.

<div align="center"> <img src="doc/cover.jpg" alt="user image example" width="500" height="400" /> </div>

## Features

- **Face Detection**: Detect faces in images using Google ML Kit.
- **Face Recognition**: Recognize faces by comparing embeddings with registered users.
- **Customizable Overlays**: Display custom overlays around detected faces.
- **Performance Optimization**: Customizable resolution of the camera feed and performance mode of the face detector.
- **Offline Capability**: Perform face detection and recognition without an internet connection.

## Getting Started

## Installation

1. Add the package to your project:

```sh
flutter pub add face_verify
```

2. Import the package in your Dart code:

```dart
import 'package:face_verify/face_verify.dart';
```

## Usage

### Initialize Cameras

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  // choose which camera you want to use
  final cameraDescription = cameras.first;
}
```

### Register Users

```dart
  final List<UserModel> users = await registerUsers(
    faceRecognitionInputs: [
      FaceRecognitionInputModel(name: 'User1', imagePath: 'path/to/image1.jpg'),
      FaceRecognitionInputModel(name: 'User2', imagePath: 'path/to/image2.jpg'),
    ],
    cameraDescription: cameraDescription,
  );
```

#### Note

The images provided to register users must be a close-up photo with a white background, similar to a passport or ID image, and should be of high quality. This can significantly affect the model's efficiency and accuracy.

<div align="center"> <img src="doc/user_example.png" alt="user image example" width="300" /> </div>

### Perform Face Recognition

```dart
  Set<UserModel>? recognizedUsers = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetectionView(
                          users: users,
                          cameraDescription: cameraDescription,
                        ),
                      ));
                  if (recognizedUsers != null && recognizedUsers.isNotEmpty) {
                    log('recognized users : $recognizedUsers');
                  }
```

### Parameters

The `DetectionView` widget provides several parameters that can be customized to adjust the behavior and appearance of the face detection and recognition process:

| Parameter                      | Type                   | Default Value                    | Description                                                                                                                                                                                                                |
| ------------------------------ | ---------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cameraDescription` (required) | `CameraDescription`    | -                                | The camera description to be used for the camera feed.                                                                                                                                                                     |
| `users` (required)             | `List<UserModel>`      | -                                | A list of registered `UserModel` objects.                                                                                                                                                                                  |
| `resolutionPreset`             | `ResolutionPreset`     | `ResolutionPreset.high`          | The resolution preset for the camera feed.                                                                                                                                                                                 |
| `frameSkipCount`               | `int`                  | 10                               | The number of frames to be skipped before processing the next frame. This is used to throttle the number of frames processed to help optimize the performance of your application by reducing the computational load.      |
| `threshold`                    | `double`               | 0.8                              | The minimum distance between the face embeddings to be considered as a match. If the distance is less than the threshold, the face is recognized. Decrease the threshold to increase the accuracy of the face recognition. |
| `faceDetectorPerformanceMode`  | `FaceDetectorMode`     | `FaceDetectorMode.accurate`      | The performance mode of the face detector.                                                                                                                                                                                 |
| `faceOverlayShapeType`         | `FaceOverlayShapeType` | `FaceOverlayShapeType.rectangle` | The shape type of the face overlay.                                                                                                                                                                                        |
| `customFaceOverlayShape`       | `FaceOverlayShape?`    | null                             | A custom face overlay shape to be used for the face overlay. `faceOverlayShapeType` must be set to `FaceOverlayShapeType.custom` to use this. Can be customized by extending the `FaceOverlayShape` class.                 |
| `loadingWidget`                | `Widget?`              | null                             | A custom loading widget to be displayed while the camera is initializing.                                                                                                                                                  |

## Authors

- Badieh Nader - [GitHub](https://github.com/Badieh)

## Acknowledgments

This package utilizes a FaceNet model for face recognition, as described in the paper "FaceNet: A Unified Embedding for Face Recognition and Clustering" (Schroff et al., 2015). The model has been converted to TensorFlow Lite format. Model source: Unknown.
