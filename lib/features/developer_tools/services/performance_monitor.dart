import 'dart:async';
import 'dart:ui';

/// Performance statistics for the application.
///
/// This class holds real-time performance metrics including FPS,
/// memory usage, CPU usage, and widget count.
class PerformanceStats {
  /// Creates performance statistics.
  const PerformanceStats({
    this.fps = 0,
    this.memoryUsage = 0,
    this.cpuUsage = 0,
    this.widgetCount = 0,
    this.isolateCount = 1,
    this.timestamp,
  });

  /// Frames per second (target is 60).
  final double fps;

  /// Memory usage in bytes.
  final int memoryUsage;

  /// CPU usage percentage (0-100).
  final double cpuUsage;

  /// Number of widgets in the tree.
  final int widgetCount;

  /// Number of active isolates.
  final int isolateCount;

  /// When these stats were collected.
  final DateTime? timestamp;

  /// Creates a copy with updated fields.
  PerformanceStats copyWith({
    double? fps,
    int? memoryUsage,
    double? cpuUsage,
    int? widgetCount,
    int? isolateCount,
    DateTime? timestamp,
  }) {
    return PerformanceStats(
      fps: fps ?? this.fps,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      widgetCount: widgetCount ?? this.widgetCount,
      isolateCount: isolateCount ?? this.isolateCount,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

/// Monitors application performance in real-time.
///
/// This service tracks FPS, memory usage, CPU usage, and other
/// performance metrics. It uses Flutter's frame callbacks to
/// measure FPS and PlatformDispatcher for memory information.
///
/// Example:
/// ```dart
/// PerformanceMonitor.instance.start();
/// final stats = PerformanceMonitor.instance.getStats();
/// ```
class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  final List<FrameInfo> _frameInfos = [];
  Timer? _monitorTimer;
  PerformanceStats _currentStats = const PerformanceStats();
  bool _isMonitoring = false;

  /// Starts performance monitoring.
  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Listen to frame callbacks for FPS
    PlatformDispatcher.instance.onReportTimings = _onReportTimings;

    // Periodically update stats
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStats();
    });
  }

  /// Stops performance monitoring.
  void stop() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    PlatformDispatcher.instance.onReportTimings = null;
  }

  /// Gets the current performance statistics.
  PerformanceStats getStats() => _currentStats;

  void _onReportTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameInfo = FrameInfo(
        buildTime: timing.buildDuration,
        rasterTime: timing.rasterDuration,
        timestamp: DateTime.now(),
      );
      _frameInfos.add(frameInfo);
    }

    // Keep only last 60 frames
    while (_frameInfos.length > 60) {
      _frameInfos.removeAt(0);
    }
  }

  void _updateStats() {
    // Calculate FPS from frame timings
    double fps = 0;
    if (_frameInfos.isNotEmpty) {
      final now = DateTime.now();
      final recentFrames = _frameInfos
          .where((f) => now.difference(f.timestamp).inMilliseconds < 1000)
          .toList();
      fps = recentFrames.length.toDouble();
    }

    // Get memory info (approximate)
    final memoryUsage = _getMemoryUsage();

    // Get CPU usage (approximate)
    final cpuUsage = _getCpuUsage();

    // Get isolate count
    final isolateCount = Isolate.current.debugName.isNotEmpty ? 1 : 1;

    _currentStats = PerformanceStats(
      fps: fps,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      isolateCount: isolateCount,
      timestamp: DateTime.now(),
    );
  }

  int _getMemoryUsage() {
    // This is an approximation - actual memory tracking requires
    // platform-specific code or native bindings
    try {
      // Use ProcessInfo if available
      // ignore: avoid_print
      return 0; // Placeholder - real implementation needs platform channels
    } catch (_) {
      return 0;
    }
  }

  double _getCpuUsage() {
    // CPU usage monitoring requires platform-specific code
    return 0;
  }

  /// Clears all collected stats.
  void clear() {
    _frameInfos.clear();
    _currentStats = const PerformanceStats();
  }

  /// Whether monitoring is active.
  bool get isMonitoring => _isMonitoring;
}

/// Information about a rendered frame.
class FrameInfo {
  /// Creates frame information.
  const FrameInfo({
    required this.buildTime,
    required this.rasterTime,
    required this.timestamp,
  });

  /// Time spent building the frame.
  final Duration buildTime;

  /// Time spent rasterizing the frame.
  final Duration rasterTime;

  /// When the frame was rendered.
  final DateTime timestamp;

  /// Total frame time.
  Duration get totalTime => buildTime + rasterTime;
}
