import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance Monitoring Utility for SABOHUB
/// Tracks key metrics like navigation time, load time, memory usage
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _measurements = {};
  final List<PerformanceMetric> _metrics = [];

  /// Start measuring an operation
  void startMeasuring(String operationName) {
    _startTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      debugPrint('🚀 Performance: Started measuring $operationName');
    }
  }

  /// Stop measuring and record the duration
  Duration? stopMeasuring(String operationName) {
    final endTime = DateTime.now();
    final startTime = _startTimes[operationName];

    if (startTime == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Performance: No start time found for $operationName');
      }
      return null;
    }

    final duration = endTime.difference(startTime);
    _measurements[operationName] = duration;
    _startTimes.remove(operationName);

    // Record metric
    _metrics.add(PerformanceMetric(
      name: operationName,
      duration: duration,
      timestamp: endTime,
    ));

    if (kDebugMode) {
      debugPrint(
          '✅ Performance: $operationName took ${duration.inMilliseconds}ms');
    }

    // Alert if operation takes too long
    _checkPerformanceThresholds(operationName, duration);

    return duration;
  }

  /// Measure a function execution time
  Future<T> measureAsync<T>(
      String operationName, Future<T> Function() operation) async {
    startMeasuring(operationName);
    try {
      final result = await operation();
      stopMeasuring(operationName);
      return result;
    } catch (e) {
      stopMeasuring(operationName);
      rethrow;
    }
  }

  /// Measure a synchronous function execution time
  T measureSync<T>(String operationName, T Function() operation) {
    startMeasuring(operationName);
    try {
      final result = operation();
      stopMeasuring(operationName);
      return result;
    } catch (e) {
      stopMeasuring(operationName);
      rethrow;
    }
  }

  /// Check if operation exceeds performance thresholds
  void _checkPerformanceThresholds(String operationName, Duration duration) {
    const Map<String, int> thresholds = {
      'navigation': 300, // Navigation should be under 300ms
      'api_call': 5000, // API calls should be under 5 seconds
      'page_load': 2000, // Page loads should be under 2 seconds
      'search': 1000, // Search should be under 1 second
      'authentication': 10000, // Auth can take up to 10 seconds
    };

    for (final entry in thresholds.entries) {
      if (operationName.toLowerCase().contains(entry.key)) {
        if (duration.inMilliseconds > entry.value) {
          if (kDebugMode) {
            debugPrint(
                '🐌 Performance Warning: $operationName took ${duration.inMilliseconds}ms (threshold: ${entry.value}ms)');
          }
          // In production, you might want to send this to analytics
        }
        break;
      }
    }
  }

  /// Get recent performance metrics
  List<PerformanceMetric> getRecentMetrics({int limit = 50}) {
    final sorted = List<PerformanceMetric>.from(_metrics)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operationName) {
    final matching = _metrics.where((m) => m.name == operationName);
    if (matching.isEmpty) return null;

    final totalMs = matching.fold<int>(
        0, (sum, metric) => sum + metric.duration.inMilliseconds);
    return Duration(milliseconds: (totalMs / matching.length).round());
  }

  /// Get performance report
  String getPerformanceReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 SABOHUB Performance Report');
    buffer.writeln('=' * 40);

    // Group metrics by operation name
    final grouped = <String, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      grouped.putIfAbsent(metric.name, () => []).add(metric);
    }

    for (final entry in grouped.entries) {
      final metrics = entry.value;
      final avgMs =
          metrics.fold<int>(0, (sum, m) => sum + m.duration.inMilliseconds) /
              metrics.length;
      final maxMs = metrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);
      final minMs = metrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a < b ? a : b);

      buffer.writeln('${entry.key}:');
      buffer.writeln('  Count: ${metrics.length}');
      buffer.writeln('  Average: ${avgMs.toStringAsFixed(1)}ms');
      buffer.writeln('  Min: ${minMs}ms');
      buffer.writeln('  Max: ${maxMs}ms');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all metrics (useful for testing)
  void clear() {
    _startTimes.clear();
    _measurements.clear();
    _metrics.clear();
  }

  /// Memory usage monitoring
  Future<MemoryInfo?> getMemoryInfo() async {
    try {
      // This is a basic implementation
      // In production, you might want to use more sophisticated monitoring
      return MemoryInfo(
        used: 0, // Would need platform-specific implementation
        total: 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting memory info: $e');
      }
      return null;
    }
  }
}

/// Navigation Performance Tracker
class NavigationPerformanceTracker extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      PerformanceMonitor()
          .startMeasuring('navigation_to_${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      PerformanceMonitor()
          .startMeasuring('navigation_to_${newRoute!.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name != null) {
      PerformanceMonitor()
          .stopMeasuring('navigation_to_${route.settings.name}');
    }
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceMetric(name: $name, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp)';
  }
}

/// Memory information data class
class MemoryInfo {
  final int used; // in bytes
  final int total; // in bytes
  final DateTime timestamp;

  MemoryInfo({
    required this.used,
    required this.total,
    required this.timestamp,
  });

  double get usagePercentage => total > 0 ? (used / total) * 100 : 0;

  @override
  String toString() {
    return 'MemoryInfo(used: ${used ~/ 1024 ~/ 1024}MB, total: ${total ~/ 1024 ~/ 1024}MB, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}

/// Widget to display performance overlay in debug mode
class PerformanceOverlay extends StatefulWidget {
  final Widget child;

  const PerformanceOverlay({super.key, required this.child});

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  bool _showOverlay = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            right: 16,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Performance Monitor',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...PerformanceMonitor().getRecentMetrics(limit: 5).map(
                        (metric) => Text(
                          '${metric.name}: ${metric.duration.inMilliseconds}ms',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                ],
              ),
            ),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'performance_toggle',
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
            backgroundColor: Colors.orange,
            child: Icon(_showOverlay ? Icons.close : Icons.speed),
          ),
        ),
      ],
    );
  }
}
