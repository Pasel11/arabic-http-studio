import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/core/utils/cache_manager.dart';

void main() {
  group('LruCache', () {
    test('should store and retrieve values', () {
      final cache = LruCache<String, int>(maxSize: 3);

      cache.put('a', 1);
      cache.put('b', 2);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
    });

    test('should return null for non-existent keys', () {
      final cache = LruCache<String, int>();

      expect(cache.get('nonexistent'), isNull);
    });

    test('should evict LRU item when full', () {
      final cache = LruCache<String, int>(maxSize: 2);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3); // Should evict 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('should update existing key', () {
      final cache = LruCache<String, int>();

      cache.put('a', 1);
      cache.put('a', 2);

      expect(cache.get('a'), 2);
    });

    test('should mark accessed item as recently used', () {
      final cache = LruCache<String, int>(maxSize: 2);

      cache.put('a', 1);
      cache.put('b', 2);

      // Access 'a' to mark it as recently used
      cache.get('a');

      // Add 'c' - should evict 'b' instead of 'a'
      cache.put('c', 3);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
    });

    test('should remove items', () {
      final cache = LruCache<String, int>();

      cache.put('a', 1);
      cache.remove('a');

      expect(cache.get('a'), isNull);
    });

    test('should clear all items', () {
      final cache = LruCache<String, int>();

      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();

      expect(cache.isEmpty, isTrue);
    });

    test('should track length', () {
      final cache = LruCache<String, int>();

      expect(cache.length, 0);

      cache.put('a', 1);
      cache.put('b', 2);

      expect(cache.length, 2);
    });

    test('containsKey should work correctly', () {
      final cache = LruCache<String, int>();

      cache.put('a', 1);

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });
  });

  group('TimedCache', () {
    test('should store and retrieve values', () {
      final cache = TimedCache<String, int>(
        expiryDuration: const Duration(minutes: 5),
      );

      cache.put('a', 1);

      expect(cache.get('a'), 1);
    });

    test('should return null for expired items', () async {
      final cache = TimedCache<String, int>(
        expiryDuration: const Duration(milliseconds: 50),
      );

      cache.put('a', 1);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(cache.get('a'), isNull);
    });

    test('should clean expired items', () async {
      final cache = TimedCache<String, int>(
        expiryDuration: const Duration(milliseconds: 50),
      );

      cache.put('a', 1);
      cache.put('b', 2);

      await Future.delayed(const Duration(milliseconds: 100));

      cache.cleanExpired();

      expect(cache.length, 0);
    });

    test('containsKey should return false for expired items', () async {
      final cache = TimedCache<String, int>(
        expiryDuration: const Duration(milliseconds: 50),
      );

      cache.put('a', 1);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(cache.containsKey('a'), isFalse);
    });
  });

  group('CacheManager', () {
    test('should have separate caches', () {
      final manager = CacheManager.instance;

      expect(manager.httpResponseCache, isNotNull);
      expect(manager.computedCache, isNotNull);
      expect(manager.longTermCache, isNotNull);
    });

    test('clearAll should clear all caches', () {
      final manager = CacheManager.instance;

      manager.httpResponseCache.put('a', 1);
      manager.computedCache.put('b', 2);
      manager.longTermCache.put('c', 3);

      manager.clearAll();

      expect(manager.httpResponseCache.length, 0);
      expect(manager.computedCache.length, 0);
      expect(manager.longTermCache.length, 0);
    });
  });
}
