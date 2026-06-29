import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/json/services/json_tools_service.dart';

void main() {
  group('JsonToolsService', () {
    final service = JsonToolsService.instance;

    group('format', () {
      test('should format valid JSON', () {
        const input = '{"name":"John","age":30}';
        final result = service.format(input);
        expect(result, contains('"name":'));
        expect(result, contains('"John"'));
        expect(result, contains('\n'));
      });

      test('should return original for invalid JSON', () {
        const input = '{invalid}';
        final result = service.format(input);
        expect(result, input);
      });
    });

    group('validate', () {
      test('should validate valid JSON object', () {
        const input = '{"key": "value"}';
        final result = service.validate(input);
        expect(result.isValid, isTrue);
      });

      test('should validate valid JSON array', () {
        const input = '[1, 2, 3]';
        final result = service.validate(input);
        expect(result.isValid, isTrue);
      });

      test('should reject invalid JSON', () {
        const input = '{invalid}';
        final result = service.validate(input);
        expect(result.isValid, isFalse);
        expect(result.error, isNotNull);
      });

      test('should reject empty string', () {
        const input = '';
        final result = service.validate(input);
        expect(result.isValid, isFalse);
      });
    });

    group('minify', () {
      test('should minify formatted JSON', () {
        const input = '{\n  "key": "value"\n}';
        final result = service.minify(input);
        expect(result, '{"key":"value"}');
      });
    });

    group('compare', () {
      test('should detect identical JSONs', () {
        const json1 = '{"a": 1, "b": 2}';
        const json2 = '{"a": 1, "b": 2}';
        final result = service.compare(json1, json2);
        expect(result.areEqual, isTrue);
        expect(result.differences, isEmpty);
      });

      test('should detect added keys', () {
        const json1 = '{"a": 1}';
        const json2 = '{"a": 1, "b": 2}';
        final result = service.compare(json1, json2);
        expect(result.areEqual, isFalse);
        expect(result.differences.any((d) => d.type == JsonDifferenceType.added), isTrue);
      });

      test('should detect removed keys', () {
        const json1 = '{"a": 1, "b": 2}';
        const json2 = '{"a": 1}';
        final result = service.compare(json1, json2);
        expect(result.areEqual, isFalse);
        expect(result.differences.any((d) => d.type == JsonDifferenceType.removed), isTrue);
      });

      test('should detect changed values', () {
        const json1 = '{"a": 1}';
        const json2 = '{"a": 2}';
        final result = service.compare(json1, json2);
        expect(result.areEqual, isFalse);
        expect(result.differences.any((d) => d.type == JsonDifferenceType.valueChanged), isTrue);
      });

      test('should handle invalid JSON', () {
        const json1 = '{invalid}';
        const json2 = '{"a": 1}';
        final result = service.compare(json1, json2);
        expect(result.areEqual, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('buildTree', () {
      test('should build tree for object', () {
        const input = '{"name": "John", "age": 30}';
        final tree = service.buildTree(input);
        expect(tree.type, JsonValueType.object);
        expect(tree.children.length, 2);
      });

      test('should build tree for array', () {
        const input = '[1, 2, 3]';
        final tree = service.buildTree(input);
        expect(tree.type, JsonValueType.array);
        expect(tree.children.length, 3);
      });

      test('should build tree for nested objects', () {
        const input = '{"user": {"name": "John", "address": {"city": "NYC"}}}';
        final tree = service.buildTree(input);
        expect(tree.type, JsonValueType.object);
        expect(tree.children.length, 1);
        expect(tree.children.first.type, JsonValueType.object);
      });
    });

    group('search', () {
      test('should find matching keys', () {
        const input = '{"name": "John", "age": 30}';
        final results = service.search(input, 'name');
        expect(results, isNotEmpty);
        expect(results.any((r) => r.key == 'name'), isTrue);
      });

      test('should find matching values', () {
        const input = '{"name": "John", "age": 30}';
        final results = service.search(input, 'John');
        expect(results, isNotEmpty);
      });

      test('should be case insensitive by default', () {
        const input = '{"Name": "John"}';
        final results = service.search(input, 'name');
        expect(results, isNotEmpty);
      });

      test('should search in nested objects', () {
        const input = '{"user": {"name": "John", "email": "john@test.com"}}';
        final results = service.search(input, 'email');
        expect(results, isNotEmpty);
      });
    });

    group('getStatistics', () {
      test('should calculate statistics correctly', () {
        const input = '{"name": "John", "age": 30, "active": true, "data": null}';
        final stats = service.getStatistics(input);
        expect(stats.totalKeys, 4);
        expect(stats.strings, 1);
        expect(stats.numbers, 1);
        expect(stats.booleans, 1);
        expect(stats.nulls, 1);
      });

      test('should count objects and arrays', () {
        const input = '{"obj": {"a": 1}, "arr": [1, 2]}';
        final stats = service.getStatistics(input);
        expect(stats.objects, 2); // root + inner
        expect(stats.arrays, 1);
      });

      test('should calculate max depth', () {
        const input = '{"a": {"b": {"c": 1}}}';
        final stats = service.getStatistics(input);
        expect(stats.maxDepth, 3);
      });
    });
  });
}
