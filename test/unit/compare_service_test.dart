import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/compare/services/compare_service.dart';

void main() {
  group('CompareService', () {
    final service = CompareService.instance;

    group('diffText', () {
      test('should detect identical texts', () {
        final result = service.diffText('Hello\nWorld', 'Hello\nWorld');
        expect(result.areEqual, isTrue);
        expect(result.addedCount, 0);
        expect(result.removedCount, 0);
        expect(result.changedCount, 0);
      });

      test('should detect added lines', () {
        final result = service.diffText('Line 1', 'Line 1\nLine 2');
        expect(result.areEqual, isFalse);
        expect(result.addedCount, 1);
      });

      test('should detect removed lines', () {
        final result = service.diffText('Line 1\nLine 2', 'Line 1');
        expect(result.areEqual, isFalse);
        expect(result.removedCount, 1);
      });

      test('should detect changed lines', () {
        final result = service.diffText('Hello', 'World');
        expect(result.areEqual, isFalse);
        expect(result.changedCount, 1);
      });

      test('should handle empty texts', () {
        final result = service.diffText('', '');
        expect(result.areEqual, isTrue);
      });
    });

    group('compareJson', () {
      test('should detect identical JSONs', () {
        final result = service.compareJson('{"a": 1}', '{"a": 1}');
        expect(result.areEqual, isTrue);
      });

      test('should detect different values', () {
        final result = service.compareJson('{"a": 1}', '{"a": 2}');
        expect(result.areEqual, isFalse);
        expect(result.differences, isNotEmpty);
      });

      test('should detect added keys', () {
        final result = service.compareJson('{"a": 1}', '{"a": 1, "b": 2}');
        expect(result.areEqual, isFalse);
        expect(result.differences.any((d) => d.type == DifferenceType.added), isTrue);
      });

      test('should detect removed keys', () {
        final result = service.compareJson('{"a": 1, "b": 2}', '{"a": 1}');
        expect(result.areEqual, isFalse);
        expect(result.differences.any((d) => d.type == DifferenceType.removed), isTrue);
      });

      test('should handle nested objects', () {
        final result = service.compareJson(
          '{"user": {"name": "John"}}',
          '{"user": {"name": "Jane"}}',
        );
        expect(result.areEqual, isFalse);
      });

      test('should detect type mismatches', () {
        final result = service.compareJson('{"a": 1}', '{"a": "string"}');
        expect(result.areEqual, isFalse);
      });

      test('should handle invalid JSON', () {
        final result = service.compareJson('{invalid}', '{"a": 1}');
        expect(result.areEqual, isFalse);
        expect(result.error, isNotNull);
      });
    });
  });

  group('DifferenceType', () {
    test('should have all expected types', () {
      expect(DifferenceType.values, contains(DifferenceType.added));
      expect(DifferenceType.values, contains(DifferenceType.removed));
      expect(DifferenceType.values, contains(DifferenceType.changed));
    });
  });
}
