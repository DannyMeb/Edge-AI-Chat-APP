// lib/widgets/compact_benchmark_widget.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../core/benchmark_service.dart';

class CompactBenchmarkWidget extends StatefulWidget {
  final File modelFile;
  final bool isSidebar;

  const CompactBenchmarkWidget({
    Key? key,
    required this.modelFile,
    this.isSidebar = false,
  }) : super(key: key);

  @override
  State<CompactBenchmarkWidget> createState() => _CompactBenchmarkWidgetState();
}

class _CompactBenchmarkWidgetState extends State<CompactBenchmarkWidget> {
  bool _isRunning = false;
  BenchmarkResult? _result;

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final result = await BenchmarkService.runBenchmark(widget.modelFile);
      if (mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Benchmark failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSidebar ? Colors.white : Colors.deepPurple;
    
    return Card(
      color: widget.isSidebar ? Colors.deepPurple.withOpacity(0.2) : null,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRunning) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: color),
                    const SizedBox(height: 8),
                    Text(
                      'Running benchmark...',
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
            ] else if (_result != null) ...[
              _buildCompactMetrics(color),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runBenchmark,
              icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.speed),
              label: Text(_isRunning ? 'Running...' : 'Run Benchmark'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isSidebar ? Colors.white24 : Colors.deepPurple,
                foregroundColor: widget.isSidebar ? Colors.white : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetrics(Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetricChip(
          'Latency', 
          '${_result!.averageLatency.toStringAsFixed(1)}ms', 
          color
        ),
        _buildMetricChip(
          'Tokens/s', 
          _result!.tokensPerSecond.toStringAsFixed(1), 
          color
        ),
        _buildMetricChip(
          'Memory', 
          '${_result!.usedMemoryMB.toStringAsFixed(0)}MB', 
          color
        ),
        _buildMetricChip(
          'CPU', 
          '${(_result!.cpuUsageMHz).toStringAsFixed(0)}MHz', 
          color
        ),
        if (_result!.modelLoadTime > 0) _buildMetricChip(
          'Load Time', 
          '${_result!.modelLoadTime.toStringAsFixed(0)}ms', 
          color
        ),
        if (_result!.firstTokenLatency > 0) _buildMetricChip(
          '1st Token', 
          '${_result!.firstTokenLatency.toStringAsFixed(0)}ms', 
          color
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}