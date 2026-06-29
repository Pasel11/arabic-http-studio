import 'dart:async';

/// Utility class for debouncing function calls.
///
/// Debounce ensures that a function is only executed after a specified
/// duration has elapsed since the last call. This is useful for search
/// inputs, text field changes, and other frequent events.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(duration: Duration(milliseconds: 500));
/// debouncer.run(() => performSearch(query));
/// ```
class Debouncer {
  /// Creates a debouncer with the specified duration.
  Debouncer({this.duration = const Duration(milliseconds: 500)});

  /// The duration to wait before executing the function.
  final Duration duration;

  Timer? _timer;

  /// Runs the given callback after the specified duration.
  ///
  /// If called again before the duration elapses, the previous call
  /// is cancelled and the timer restarts.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Runs the given async callback after the specified duration.
  Future<void> runAsync(Future<void> Function() action) async {
    _timer?.cancel();
    final completer = Completer<void>();
    _timer = Timer(duration, () async {
      try {
        await action();
        completer.complete();
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      }
    });
    return completer.future;
  }

  /// Cancels any pending debounced call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether there is a pending debounced call.
  bool get isActive => _timer?.isActive ?? false;

  /// Disposes the debouncer and cancels any pending call.
  void dispose() {
    cancel();
  }
}

/// Utility class for throttling function calls.
///
/// Throttle ensures that a function is executed at most once per
/// specified duration. This is useful for scroll events, resize events,
/// and other high-frequency events.
///
/// Example:
/// ```dart
/// final throttler = Throttler(duration: Duration(milliseconds: 200));
/// throttler.run(() => handleScroll());
/// ```
class Throttler {
  /// Creates a throttler with the specified duration.
  Throttler({this.duration = const Duration(milliseconds: 200)});

  /// The minimum duration between function executions.
  final Duration duration;

  DateTime? _lastRun;
  Timer? _timer;
  bool _isWaiting = false;

  /// Runs the given callback, throttled to the specified duration.
  ///
  /// If called during the throttle period, the callback will be
  /// executed once at the end of the period (trailing call).
  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    } else if (!_isWaiting) {
      _isWaiting = true;
      _timer?.cancel();
      _timer = Timer(duration - now.difference(_lastRun!), () {
        _lastRun = DateTime.now();
        _isWaiting = false;
        action();
      });
    }
  }

  /// Cancels any pending throttled call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isWaiting = false;
  }

  /// Disposes the throttler and cancels any pending call.
  void dispose() {
    cancel();
  }
}

/// Extension to add debounce and throttle to Stream.
extension StreamDebounceExtension<T> on Stream<T> {
  /// Debounces the stream by the specified duration.
  Stream<T> debounce(Duration duration) {
    Timer? timer;
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              controller?.add(data);
            });
          },
          onError: (e, s) => controller?.addError(e, s),
          onDone: () {
            timer?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Throttles the stream by the specified duration.
  Stream<T> throttle(Duration duration) {
    DateTime? lastEmitted;
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
          final now = DateTime.now();
          if (lastEmitted == null ||
              now.difference(lastEmitted!) >= duration) {
            lastEmitted = now;
            controller?.add(data);
          }
        },
          onError: (e, s) => controller?.addError(e, s),
          onDone: () => controller?.close(),
        );
      },
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }
}
