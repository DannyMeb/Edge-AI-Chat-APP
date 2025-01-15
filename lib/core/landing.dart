// // ignore_for_file: prefer_final_fields, prefer_const_constructors

// import 'dart:io';
// import 'dart:isolate';
// import 'package:falcon_chat/core/system_usage.dart';
// import 'package:flutter/material.dart';

// import 'package:file_picker/file_picker.dart';

// class LandingView extends StatefulWidget {
//   const LandingView({super.key});

//   @override
//   State<LandingView> createState() => _LandingViewState();
// }

// class _LandingViewState extends State<LandingView> {
//   final TextEditingController _promptController = TextEditingController();
//   TextEditingController _responseController = TextEditingController();

//   late ReceivePort _systemUsageReceivePort;
//   late Isolate _systemUsageIsolate;
//   double _ramUsage = 0.0;

//   ReceivePort? _modelReceivePort;
//   Isolate? _modelIsolate;
//   File? modelFile;
//   String? modelName;

//   void _initUsageIsolate() async {
//     _systemUsageReceivePort = ReceivePort();
//     _systemUsageIsolate =
//         await Isolate.spawn(fetchSystemUsage, _systemUsageReceivePort.sendPort);
//     _systemUsageReceivePort.listen((dynamic data) {
//       setState(() {
//         _ramUsage = data['ramUsage'];
//       });
//     });
//   }

//   void _initModelIsolate() async {
//     _modelReceivePort = ReceivePort();
//     _modelIsolate = await Isolate.spawn(fetchModelResponse,
//         [_modelReceivePort!.sendPort, modelFile, _promptController.text]);
//     _modelReceivePort!.listen((dynamic data) {
//       setState(() {
//         _responseController.text += data['token'];
//       });
//     });
//   }

//   void _unLoadModel({bool onlyPort = false}) {
//     if (onlyPort) {
//       _modelReceivePort?.close();
//       return;
//     }
//     modelFile = null;
//     modelName = null;
//     _modelIsolate?.kill();
//     _modelReceivePort?.close();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initUsageIsolate();
//   }

//   @override
//   void dispose() {
//     _systemUsageIsolate.kill();
//     _systemUsageReceivePort.close();
//     _unLoadModel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             _headerSection(),
//             _previousUI(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _headerSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         if (modelName != null)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 modelName!,
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontSize: 20,
//                 ),
//               ),
//               SizedBox(
//                 width: 10,
//               ),
//               Tooltip(
//                 message: modelFile!.path,
//                 child: Icon(
//                   Icons.info,
//                   color: Colors.black45,
//                   size: 19,
//                 ),
//               ),
//               SizedBox(
//                 width: 20,
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _responseController.clear();
//                     _promptController.clear();
//                     _unLoadModel();
//                   });
//                 },
//                 child: Text('Eject Model'),
//               ),
//             ],
//           ),
//         SizedBox(
//           height: 20,
//         ),
//         ElevatedButton(
//           onPressed: () async {
//             FilePickerResult? result = await FilePicker.platform.pickFiles();

//             if (result == null) {
//               return;
//             }

//             final tmpFile = File(result.files.single.path!);
//             modelName = result.files.single.name;
//             setState(() {
//               modelFile = tmpFile;
//             });
//           },
//           child: Text('Select your model'),
//         ),
//         Text(
//           'RAM Usage: ${(_ramUsage * 100).toStringAsFixed(1)}%',
//         ),
//         SizedBox(
//           height: 20,
//         ),
//         ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: Text("Go back"))
//       ],
//     );
//   }

//   Widget _previousUI() {
//     return Row(
//       children: [
//         Expanded(
//           flex: 1,
//           child: Column(
//             children: [
//               ElevatedButton(onPressed: () {}, child: Text("New Page")),
//               SizedBox(
//                 height: 20,
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _responseController.clear();
//                     _promptController.clear();
//                     _unLoadModel(onlyPort: true);
//                   });
//                 },
//                 child: Text('Clear'),
//               ),
//               SizedBox(
//                 height: 20,
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   FilePickerResult? result =
//                       await FilePicker.platform.pickFiles();

//                   if (result == null) {
//                     return;
//                   }

//                   final tmpFile = File(result.files.single.path!);
//                   modelName = result.files.single.name;
//                   setState(() {
//                     modelFile = tmpFile;
//                   });
//                 },
//                 child: Text('Select your model'),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           flex: 3,
//           child: Column(
//             children: [
//               TextField(
//                 controller: _promptController,
//                 decoration: InputDecoration(
//                   labelText: 'Prompt',
//                   hintText: 'Enter your prompt here',
//                 ),
//               ),
//               SizedBox(
//                 height: 20,
//               ),
//               TextField(
//                 controller: _responseController,
//                 maxLines: 6,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(),

//                   // hintText: 'Enter your response here',
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   // _sendPromptToAi();
//                   _initModelIsolate();
//                 },
//                 child: Text('Submit'),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
