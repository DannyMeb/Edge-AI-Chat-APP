// lib/core/benchmark_service.dart

import 'dart:async';
import 'dart:io';
import 'package:system_info2/system_info2.dart';
import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/prompt_template.dart';

class BenchmarkResult {
  final double modelLoadTime;      // ms
  final double firstTokenLatency;  // ms
  final double averageLatency;     // ms
  final double throughput;         // inferences/second
  final double totalMemoryMB;      // Total memory in MB
  final double usedMemoryMB;       // Used memory in MB
  final double cpuUsageMHz;        // CPU frequency in MHz
  final int totalTokens;           // count
  final double tokensPerSecond;    // tokens/second

  const BenchmarkResult({
    required this.modelLoadTime,
    required this.firstTokenLatency,
    required this.averageLatency,
    required this.throughput,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.cpuUsageMHz,
    required this.totalTokens,
    required this.tokensPerSecond,
  });
}

class BenchmarkService {
  static const int warmupRuns = 0;
  static const int batchSize = 1;
  static const List<String> benchmarkPrompts = [
    "Explain the concept of gravity",
    // "Write a short story about a robot",
    // "What is the capital of France?",
    // "Describe the process of photosynthesis",
    // "Tell me about artificial intelligence",
    // "How does a computer work?",
    // "What are the primary colors?",
    // "Explain quantum physics simply",
  ];

  static Future<BenchmarkResult> runBenchmark(File modelFile) async {
    List<double> latencies = [];
    List<double> memoryUsages = [];
    List<double> cpuFrequencies = [];
    List<double> firstTokenLatencies = [];
    int totalTokens = 0;
    
    // Measure model load time
    print("Measuring model load time...");
    final loadStartTime = DateTime.now();
    await talkAsync(
      filePathToModel: modelFile.path,
      promptTemplate: PromptTemplate.nothing().copyWith(prompt: "Test"),
      onTokenGenerated: (_) {}
    );
    final modelLoadTime = DateTime.now().difference(loadStartTime).inMilliseconds.toDouble();
    print("Model load time: ${modelLoadTime}ms");
    
    // Warm-up phase
    print("Starting warm-up phase...");
    for (int i = 0; i < warmupRuns; i++) {
      await _runSingleInference(modelFile, "This is a warm-up run.");
    }

    // Actual benchmark
    print("Starting benchmark phase...");
    final startTime = DateTime.now();
    
    // Run batch inference
    for (int i = 0; i < batchSize; i++) {
      final promptStartTime = DateTime.now();
      DateTime? firstTokenTime;
      
      final inferenceResult = await _runSingleInferenceWithFirstToken(
        modelFile, 
        benchmarkPrompts[i % benchmarkPrompts.length],
        onFirstToken: (time) {
          firstTokenTime = time;
        }
      );
      
      final promptEndTime = DateTime.now();
      
      // Calculate latency metrics
      latencies.add(promptEndTime.difference(promptStartTime).inMilliseconds.toDouble());
      totalTokens += inferenceResult.tokenCount;
      
      if (firstTokenTime != null) {
        firstTokenLatencies.add(
          firstTokenTime!.difference(promptStartTime).inMilliseconds.toDouble()
        );
      }
      
      // Memory measurements in MB
      final totalMemory = SysInfo.getTotalPhysicalMemory() / (1024 * 1024); // Convert to MB
      final freeMemory = SysInfo.getFreePhysicalMemory() / (1024 * 1024);   // Convert to MB
      final usedMemory = totalMemory - freeMemory;
      memoryUsages.add(usedMemory);

      // CPU measurements
      try {
        double cpuFreq = 0.0;
        if (Platform.isLinux) {
          // Try to read from /proc/cpuinfo on Linux
          final cpuinfo = File('/proc/cpuinfo').readAsStringSync();
          final freqMatch = RegExp(r'cpu MHz\s*:\s*(\d+)').firstMatch(cpuinfo);
          if (freqMatch != null) {
            cpuFreq = double.parse(freqMatch.group(1) ?? '0');
          }
        } else if (Platform.isMacOS) {
          // For macOS, use sysctl (requires sysctl permission)
          final result = Process.runSync('sysctl', ['-n', 'hw.cpufrequency']);
          if (result.exitCode == 0) {
            cpuFreq = double.parse(result.stdout.toString()) / 1000000; // Convert Hz to MHz
          }
        } else if (Platform.isWindows) {
          // For Windows, use WMIC (requires admin privileges)
          final result = Process.runSync('wmic', ['cpu', 'get', 'currentclockspeed']);
          if (result.exitCode == 0) {
            final match = RegExp(r'\d+').firstMatch(result.stdout.toString());
            if (match != null) {
              cpuFreq = double.parse(match.group(0) ?? '0');
            }
          }
        }
        cpuFrequencies.add(cpuFreq);
      } catch (e) {
        print("Error measuring CPU frequency: $e");
        cpuFrequencies.add(2000.0); // Default to 2GHz if measurement fails
      }
      
      print("Completed benchmark run ${i + 1}/$batchSize");
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime).inSeconds;
    final effectiveDuration = totalDuration > 0 ? totalDuration : 1;

    // Calculate final metrics
    final avgMemoryUsage = memoryUsages.reduce((a, b) => a + b) / memoryUsages.length;
    final totalMemory = SysInfo.getTotalPhysicalMemory() / (1024 * 1024); // MB

    return BenchmarkResult(
      modelLoadTime: modelLoadTime,
      firstTokenLatency: firstTokenLatencies.isEmpty ? 0.0 : 
        firstTokenLatencies.reduce((a, b) => a + b) / firstTokenLatencies.length,
      averageLatency: latencies.isEmpty ? 0.0 : 
        latencies.reduce((a, b) => a + b) / latencies.length,
      throughput: batchSize / effectiveDuration,
      totalMemoryMB: totalMemory,
      usedMemoryMB: avgMemoryUsage,
      cpuUsageMHz: cpuFrequencies.isEmpty ? 0.0 : 
        cpuFrequencies.reduce((a, b) => a + b) / cpuFrequencies.length,
      totalTokens: totalTokens,
      tokensPerSecond: totalTokens / effectiveDuration,
    );
  }

  static Future<int> _runSingleInference(File modelFile, String prompt) async {
    int tokenCount = 0;
    
    PromptTemplate promptTemplate = PromptTemplate.nothing().copyWith(
      prompt: prompt.trim(),
    );

    await talkAsync(
      filePathToModel: modelFile.path,
      promptTemplate: promptTemplate,
      onTokenGenerated: (String token) {
        tokenCount++;
      }
    );

    return tokenCount;
  }

  static Future<({int tokenCount, DateTime? firstTokenTime})> _runSingleInferenceWithFirstToken(
    File modelFile, 
    String prompt,
    {required Function(DateTime time) onFirstToken}
  ) async {
    int tokenCount = 0;
    DateTime? firstTokenTime;
    
    PromptTemplate promptTemplate = PromptTemplate.nothing().copyWith(
      prompt: prompt.trim(),
    );

    await talkAsync(
      filePathToModel: modelFile.path,
      promptTemplate: promptTemplate,
      onTokenGenerated: (String token) {
        if (tokenCount == 0) {
          firstTokenTime = DateTime.now();
          onFirstToken(firstTokenTime!);
        }
        tokenCount++;
      }
    );

    return (tokenCount: tokenCount, firstTokenTime: firstTokenTime);
  }
}