import 'dart:async';
import 'dart:io';
import 'package:system_info2/system_info2.dart';
import 'dart:isolate';
import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/prompt_template.dart';


void fetchSystemUsage(SendPort sendPort) async {
  Timer.periodic(const Duration(seconds: 1), (_) async {
    int physicalMemory = SysInfo.getTotalPhysicalMemory();
    int freePhysicalMemory = SysInfo.getFreePhysicalMemory();

    sendPort.send({'ramUsage': (physicalMemory - freePhysicalMemory) / physicalMemory});
  });
}

void fetchModelResponse(List<dynamic> args) async {
  // SendPort sendPort, File? modelFile, String prompt
  SendPort sendPort = args[0];
  File? modelFile = args[1];
  String prompt = args[2];

  if (prompt.isEmpty || modelFile == null) {
    return;
  }

  PromptTemplate promptTemplate = PromptTemplate.nothing().copyWith(
    prompt: prompt.trim(),
  );

  await talkAsync(
    filePathToModel: modelFile.path,
    promptTemplate: promptTemplate, 
    onTokenGenerated: (String token) {
        sendPort.send({'token': token});
    }
  );
  sendPort.send({'completed': true});
}