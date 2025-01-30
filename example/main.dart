// Copyright (c) 2025 Badieh Nader.

import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_verify/face_verify.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<UserModel> users = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Face Recognition demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () async {
                  // Pick multiple images.
                  final ImagePicker picker = ImagePicker();
                  final List<XFile> images = await picker.pickMultiImage();
                  List<RegisterUserInputModel> selectedImages = images.map(
                    (e) {
                      log(e.name);
                      return RegisterUserInputModel(
                        name: e.name,
                        imagePath: e.path,
                      );
                    },
                  ).toList();

                  users = await registerUsers(
                    faceRecognitionInputs: selectedImages,
                    cameraDescription: cameras[1],
                  );
                  setState(() {});
                },
                child: Text('select images')),
            ElevatedButton(
                onPressed: () async {
                  Set<UserModel>? recognizedUsers = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetectionView(
                          users: users,
                          cameraDescription: cameras[1],
                        ),
                      ));
                  if (recognizedUsers != null && recognizedUsers.isNotEmpty) {
                    log('recognized users : $recognizedUsers');
                  }
                },
                child: Text('check user')),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: SizedBox(
                        child: Text('No users found'),
                      ),
                    )
                  : ListView.builder(
                      itemBuilder: (context, index) => SizedBox(
                          height: 100,
                          child: Card(
                            child: Row(
                              children: [
                                Text(users[index].name),
                                Image.file(File(users[index].image ?? '')),
                              ],
                            ),
                          )),
                      itemCount: users.length,
                    ),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
