import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/core/utils/debounce_throttle.dart';

void main() {
  group('Debouncer', () {
    test('should execute after duration', () async {
      var executed = false;
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));

      debouncer.run(() {
        executed = true;
      });

      expect(executed, isFalse);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(executed, isTrue);
    });

    test('should cancel previous call', () async {
      var callCount = 0;
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(callCount, 1);
    });

    test('cancel should prevent execution', () async {
      var executed = false;
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));

      debouncer.run(() {
        executed = true;
      });
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(executed, isFalse);
    });

    test('isActive should return correct state', () {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));

      expect(debouncer.isActive, isFalse);

      debouncer.run(() {});

      expect(debouncer.isActive, isTrue);

      debouncer.cancel();

      expect(debouncer.isActive, isFalse);
    });
  });

  group('Throttler', () {
    test('should execute immediately on first call', () {
      var executed = false;
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.run(() {
        executed = true;
      });

      expect(executed, isTrue);
    });

    test('should throttle subsequent calls', () async {
      var callCount = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      throttler.run(() => callCount++);
      throttler.run(() => callCount++);
      throttler.run(() => callCount++);

      // Only first call should execute immediately
      expect(callCount, 1);

      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Trailing call should have executed
      expect(callCount, 2);
    });
  });
}
