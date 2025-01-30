import 'dart:io';
import 'dart:math' as math;
import 'dart:developer';

import 'dart:ui';
import 'package:face_verify/src/data/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// [RecognitionModel] class is responsible for loading the face recognition model and
/// performing face recognition by comparing the embeddings of the detected faces with
/// the embeddings of the registered users.
class RecognitionModel {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;

  static const int inputWidth = 160;
  static const int inputHeight = 160;

  /// Creates a [RecognitionModel] with the specified number of threads.
  ///
  /// The [numThreads] parameter specifies the number of threads that the TensorFlow Lite
  /// interpreter should use for inference. This can help optimize the performance of the
  /// model by leveraging multiple CPU cores for parallel processing.
  ///
  /// - Parameter numThreads: The number of threads to use for inference. If not specified,
  ///   the default number of threads will be used.
  RecognitionModel({int? numThreads}) {
    late Delegate delegate;

    if (Platform.isAndroid) {
      delegate = GpuDelegateV2(
        options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
          inferencePreference: TfLiteGpuInferenceUsage
              .TFLITE_GPU_INFERENCE_PREFERENCE_FAST_SINGLE_ANSWER,
          inferencePriority1: TfLiteGpuInferencePriority
              .TFLITE_GPU_INFERENCE_PRIORITY_MAX_PRECISION,
          inferencePriority2:
              TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
          inferencePriority3:
              TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
        ),
      );
    } else if (Platform.isIOS) {
      delegate = GpuDelegate(
        options: GpuDelegateOptions(
            allowPrecisionLoss: true,
            waitType: TFLGpuDelegateWaitType.TFLGpuDelegateWaitTypeActive),
      );
    }

    _interpreterOptions = InterpreterOptions()..addDelegate(delegate);

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    _loadModel();
  }

  /// Loads the face recognition model from the assets folder.
  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
    } catch (e) {
      log('Unable to create interpreter,model not found, Caught Exception: ${e.toString()}');
      throw Exception(
          'Unable to create interpreter, model not found, ${e.toString()}');
    }
  }

  /// [recognize] Performs face recognition on the provided cropped face image.
  ///
  /// This method extracts embeddings from the cropped face image and compares them
  /// with known users to find the nearest match.
  ///
  /// - Parameters:
  ///   - croppedFace: The cropped face image.
  ///   - location: The location of the face in the original image.
  ///   - face: The detected [Face] object.
  /// - Returns: A [UserModel] object representing the recognized user.
  UserModel recognize(
      {required img.Image croppedFace,
      required Rect location,
      required Face face,
      required List<UserModel> users}) {
    // get embeddings from the image
    List<double> embeddings = getEmbeddings(image: croppedFace);

    //looks for the nearest embedding in the database and returns the user
    UserModel user = _findNearest(newEmb: embeddings, users: users);

    log("name= ${user.name} distance= ${user.distance}");

    return user.copyWith(
      location: location,
      face: face,
    );
  }

  /// Converts an [img.Image] to a normalized array suitable for model input.
  ///
  /// This method resizes the image to the required dimensions, flattens the image data,
  /// and normalizes the pixel values to the range [-1, 1].
  ///
  /// - Parameter inputImage: The [img.Image] to be converted.
  /// - Returns: A normalized array suitable for model input.
  List<dynamic> _imageToArray(img.Image inputImage) {
    // Resize the image to the required dimensions
    img.Image resizedImage =
        img.copyResize(inputImage, width: inputWidth, height: inputHeight);

    // Flatten the image data and normalize the pixel values
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();

    // Convert the flattened list to a Float32List
    Float32List float32Array = Float32List.fromList(flattenedList);

    // Normalize the pixel values to the range [-1, 1]
    int channels = 3;

    Float32List reshapedArray =
        Float32List(1 * inputHeight * inputWidth * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < inputHeight; h++) {
        for (int w = 0; w < inputWidth; w++) {
          int index = c * inputHeight * inputWidth + h * inputWidth + w;
          reshapedArray[index] =
              (float32Array[c * inputHeight * inputWidth + h * inputWidth + w] -
                      127.5) /
                  127.5;
        }
      }
    }

    // Reshape the array to the required dimensions
    return reshapedArray.reshape([1, inputWidth, inputHeight, 3]);
  }

  /// Extracts embeddings from the provided image.
  /// - Parameter image: The [img.Image] to be processed.
  List<double> getEmbeddings({
    required img.Image image,
  }) {
    //crop face from image resize it and convert it to float array
    var input = _imageToArray(image);

    //output array
    List output = List.filled(1 * 512, 0).reshape([1, 512]);

    //performs inference
    interpreter.run(input, output);

    //convert dynamic list to double list
    List<double> embeddings = output.first.cast<double>();

    return embeddings;
  }

  /// looks for the user with nearest embedding (face is most similar) in the users list and returns it.
  UserModel _findNearest(
      {required List<double> newEmb, required List<UserModel> users}) {
    UserModel nearestUser = UserModel(
      id: -1,
      name: "Unknown",
      embeddings: [],
      distance: double.infinity,
    );

    for (UserModel user in users) {
      double distance = 0;
      for (int i = 0; i < newEmb.length; i++) {
        double diff = newEmb[i] - user.embeddings[i];
        distance += diff * diff;
      }
      distance = math.sqrt(distance);
      if (distance < nearestUser.distance) {
        nearestUser = user.copyWith(distance: distance);
      }
    }

    return nearestUser;
  }

  void close() {
    interpreter.close();
  }
}
