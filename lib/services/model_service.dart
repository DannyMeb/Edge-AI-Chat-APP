import 'dart:io';
import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/system_usage.dart';

class ModelService {
  static Future<File?> loadModel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;

      if (filePath != null && filePath.endsWith('.gguf')) {
        return File(filePath);
      }
    }
    return null;
  }

  static void showInvalidModelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Model File'),
          content: Text('Please load a valid .gguf model file.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<({ReceivePort receivePort, Isolate isolate})?> initModelIsolate(
    String userPrompt,
    File modelFile,
  ) async {
    try {
      ReceivePort receivePort = ReceivePort();
      Isolate isolate = await Isolate.spawn(
        fetchModelResponse,
        [receivePort.sendPort, modelFile, userPrompt],
      );
      return (receivePort: receivePort, isolate: isolate);
    } catch (e) {
      print('Error initializing model isolate: $e');
      return null;
    }
  }

  static void unloadModel({
    Isolate? isolate,
    ReceivePort? receivePort,
    bool onlyPort = false,
  }) {
    if (onlyPort) {
      receivePort?.close();
      return;
    }
    isolate?.kill();
    receivePort?.close();
  }
} 