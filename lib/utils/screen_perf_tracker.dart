import 'dart:math' as math;
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_logger.dart';

/// Lightweight screen-level performance tracker for debug profiling.
class ScreenPerfTracker {
  ScreenPerfTracker(this.screenName);

  final String screenName;
  final Stopwatch _openStopwatch = Stopwatch();
  final List<double> _frameDurationsMs = [];

  int _droppedFrames = 0;
  bool _started = false;
  bool _firstDataRendered = false;

  late final void Function(List<FrameTiming>) _timingsCallback;

  void start() {
    if (!kDebugMode || _started) return;
    _started = true;
    _openStopwatch.start();

    _timingsCallback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
        _frameDurationsMs.add(totalMs);
        if (totalMs > 16.7) {
          _droppedFrames++;
        }
      }
    };

    WidgetsBinding.instance.addTimingsCallback(_timingsCallback);
    AppLogger.info('Perf[$screenName] session started');
  }

  void logQueryDuration(String queryName, Duration duration,
      {Map<String, dynamic>? extra}) {
    if (!kDebugMode) return;

    AppLogger.info(
      'Perf[$screenName] $queryName: ${duration.inMilliseconds}ms',
      extra,
    );
  }

  void markFirstDataRendered({Map<String, dynamic>? extra}) {
    if (!kDebugMode || !_started || _firstDataRendered) return;

    _firstDataRendered = true;
    final elapsedMs = _openStopwatch.elapsedMilliseconds;
    AppLogger.box('Perf[$screenName] first-data-render', {
      'tti_ms': elapsedMs,
      if (extra != null) ...extra,
    });
  }

  void dispose() {
    if (!kDebugMode || !_started) return;

    WidgetsBinding.instance.removeTimingsCallback(_timingsCallback);
    _openStopwatch.stop();

    final frameCount = _frameDurationsMs.length;
    final p95 = _percentile(_frameDurationsMs, 95);
    final avg =
        frameCount == 0 ? 0.0 : _frameDurationsMs.reduce((a, b) => a + b) / frameCount;
    final droppedRatio = frameCount == 0 ? 0.0 : (_droppedFrames / frameCount) * 100;

    AppLogger.box('Perf[$screenName] session summary', {
      'session_ms': _openStopwatch.elapsedMilliseconds,
      'frames': frameCount,
      'avg_frame_ms': avg.toStringAsFixed(2),
      'p95_frame_ms': p95.toStringAsFixed(2),
      'dropped_frames': _droppedFrames,
      'dropped_ratio_pct': droppedRatio.toStringAsFixed(2),
    });
  }

  double _percentile(List<double> values, int percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final index = ((percentile / 100) * (sorted.length - 1)).round();
    final safeIndex = math.max(0, math.min(sorted.length - 1, index));
    return sorted[safeIndex];
  }
}
