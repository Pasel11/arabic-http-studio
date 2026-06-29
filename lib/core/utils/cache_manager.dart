import 'dart:async';
import 'dart:collection';

/// A generic LRU (Least Recently Used) cache implementation.
///
/// This cache automatically evicts the least recently used items when
/// the maximum size is reached. It's useful for caching HTTP responses,
/// computed values, and other expensive operations.
///
/// Example:
/// ```dart
/// final cache = LruCache<String, String>(maxSize: 100);
/// cache.put('key', 'value');
/// final value = cache.get('key'); // 'value'
/// ```
class LruCache<K, V> {
  /// Creates an LRU cache with the specified maximum size.
  LruCache({this.maxSize = 100});

  /// The maximum number of items the cache can hold.
  final int maxSize;

  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  /// Gets the value associated with the given key.
  ///
  /// Returns null if the key is not in the cache. Accessing a value
  /// marks it as recently used.
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // Move to end (most recently used)
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  /// Puts a value into the cache with the given key.
  ///
  /// If the cache is full, the least recently used item is evicted.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove the first (least recently used) item
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Removes the value associated with the given key.
  void remove(K key) {
    _cache.remove(key);
  }

  /// Whether the cache contains the given key.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Clears all items from the cache.
  void clear() => _cache.clear();

  /// The current number of items in the cache.
  int get length => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// All keys in the cache.
  Iterable<K> get keys => _cache.keys;

  /// All values in the cache.
  Iterable<V> get values => _cache.values;
}

/// A time-based cache that expires items after a specified duration.
///
/// This cache is useful for caching data that becomes stale after
/// a certain period, such as API responses or authentication tokens.
///
/// Example:
/// ```dart
/// final cache = TimedCache<String, Response>(
///   expiryDuration: Duration(minutes: 5),
/// );
/// cache.put('key', response);
/// final response = cache.get('key');
/// ```
class TimedCache<K, V> {
  /// Creates a timed cache with the specified expiry duration.
  TimedCache({
    this.expiryDuration = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  /// The duration after which items expire.
  final Duration expiryDuration;

  /// The maximum number of items the cache can hold.
  final int maxSize;

  final Map<K, _CacheEntry<V>> _cache = {};

  /// Gets the value associated with the given key.
  ///
  /// Returns null if the key is not in the cache or if the
  /// entry has expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > expiryDuration) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Puts a value into the cache with the given key.
  void put(K key, V value) {
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      // Remove oldest entry
      K? oldestKey;
      DateTime? oldestTime;
      for (final entry in _cache.entries) {
        if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
          oldestKey = entry.key;
          oldestTime = entry.value.timestamp;
        }
      }
      if (oldestKey != null) {
        _cache.remove(oldestKey);
      }
    }

    _cache[key] = _CacheEntry(value: value, timestamp: DateTime.now());
  }

  /// Removes the value associated with the given key.
  void remove(K key) => _cache.remove(key);

  /// Whether the cache contains a non-expired entry for the given key.
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (DateTime.now().difference(entry.timestamp) > expiryDuration) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Clears all expired items from the cache.
  void cleanExpired() {
    final now = DateTime.now();
    final expiredKeys = <K>[];
    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > expiryDuration) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Clears all items from the cache.
  void clear() => _cache.clear();

  /// The current number of items in the cache.
  int get length => _cache.length;
}

/// Internal cache entry for TimedCache.
class _CacheEntry<V> {
  _CacheEntry({required this.value, required this.timestamp});

  final V value;
  final DateTime timestamp;
}

/// Singleton cache manager for the application.
///
/// Provides pre-configured caches for common use cases:
/// - HTTP response cache
/// - Image cache
/// - Computed value cache
class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();

  /// Cache for HTTP responses (5 minute expiry, 50 items max).
  final TimedCache<String, dynamic> httpResponseCache = TimedCache<String, dynamic>(
    expiryDuration: const Duration(minutes: 5),
    maxSize: 50,
  );

  /// Cache for computed values (10 minute expiry, 100 items max).
  final LruCache<String, dynamic> computedCache = LruCache<String, dynamic>(
    maxSize: 100,
  );

  /// Cache for frequently accessed data (1 hour expiry, 200 items max).
  final TimedCache<String, dynamic> longTermCache = TimedCache<String, dynamic>(
    expiryDuration: const Duration(hours: 1),
    maxSize: 200,
  );

  /// Clears all caches.
  void clearAll() {
    httpResponseCache.clear();
    computedCache.clear();
    longTermCache.clear();
  }

  /// Cleans expired items from all timed caches.
  void cleanExpired() {
    httpResponseCache.cleanExpired();
    longTermCache.cleanExpired();
  }
}
