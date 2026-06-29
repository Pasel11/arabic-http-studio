import 'dart:async';

import 'package:flutter/foundation.dart';

/// A generic paginated data source.
///
/// This class provides infrastructure for loading data in pages,
/// which is essential for handling large datasets efficiently.
///
/// Example:
/// ```dart
/// final paginator = Paginator<String>(
///   fetchPage: (page, pageSize) => fetchItems(page, pageSize),
///   pageSize: 20,
/// );
/// await paginator.loadFirstPage();
/// await paginator.loadNextPage();
/// ```
class Paginator<T> {
  /// Creates a paginator with the given fetch function.
  Paginator({
    required this.fetchPage,
    this.pageSize = 20,
    this.maxCachePages = 5,
  });

  /// Function that fetches a page of data.
  ///
  /// Takes the page number (0-indexed) and page size, returns
  /// a list of items for that page.
  final Future<List<T>> Function(int page, int pageSize) fetchPage;

  /// The number of items per page.
  final int pageSize;

  /// Maximum number of pages to cache.
  final int maxCachePages;

  final List<T> _items = [];
  final Map<int, List<T>> _pageCache = {};

  int _currentPage = -1;
  bool _isLoading = false;
  bool _hasReachedEnd = false;
  Object? _lastError;

  /// All loaded items.
  List<T> get items => List.unmodifiable(_items);

  /// Whether data is currently loading.
  bool get isLoading => _isLoading;

  /// Whether all available data has been loaded.
  bool get hasReachedEnd => _hasReachedEnd;

  /// The current page number (0-indexed), or -1 if no page loaded.
  int get currentPage => _currentPage;

  /// The total number of items loaded.
  int get itemCount => _items.length;

  /// The last error that occurred, if any.
  Object? get lastError => _lastError;

  /// Whether there was an error.
  bool get hasError => _lastError != null;

  /// Loads the first page of data.
  Future<List<T>> loadFirstPage() async {
    _items.clear();
    _pageCache.clear();
    _currentPage = -1;
    _hasReachedEnd = false;
    _lastError = null;
    return loadNextPage();
  }

  /// Loads the next page of data.
  Future<List<T>> loadNextPage() async {
    if (_isLoading || _hasReachedEnd) return [];

    _isLoading = true;
    _lastError = null;

    try {
      final nextPage = _currentPage + 1;

      // Check cache first
      List<T>? cachedPage = _pageCache[nextPage];
      if (cachedPage != null) {
        _isLoading = false;
        return cachedPage;
      }

      final pageData = await fetchPage(nextPage, pageSize);

      // Cache the page
      _pageCache[nextPage] = pageData;
      _evictOldPages();

      _items.addAll(pageData);
      _currentPage = nextPage;

      if (pageData.length < pageSize) {
        _hasReachedEnd = true;
      }

      _isLoading = false;
      return pageData;
    } catch (e, stackTrace) {
      _lastError = e;
      _isLoading = false;
      debugPrint('Pagination error: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Refreshes data by reloading from the first page.
  Future<List<T>> refresh() async {
    return loadFirstPage();
  }

  /// Resets the paginator to its initial state.
  void reset() {
    _items.clear();
    _pageCache.clear();
    _currentPage = -1;
    _hasReachedEnd = false;
    _lastError = null;
    _isLoading = false;
  }

  /// Evicts old cached pages to limit memory usage.
  void _evictOldPages() {
    while (_pageCache.length > maxCachePages) {
      // Remove the oldest page (lowest key)
      final oldestPage = _pageCache.keys.reduce(
        (a, b) => a < b ? a : b,
      );
      _pageCache.remove(oldestPage);
    }
  }
}

/// An infinite scroll controller for paginated lists.
///
/// This controller works with [Paginator] to automatically load
/// more data as the user scrolls.
class InfiniteScrollController<T> extends ChangeNotifier {
  /// Creates an infinite scroll controller.
  InfiniteScrollController({
    required this.paginator,
    this.loadThreshold = 200,
  });

  /// The paginator that provides data.
  final Paginator<T> paginator;

  /// The scroll threshold (in pixels) from the bottom at which
  /// to trigger loading the next page.
  final double loadThreshold;

  bool _disposed = false;

  /// Loads the first page of data.
  Future<void> loadFirstPage() async {
    await paginator.loadFirstPage();
    if (!_disposed) notifyListeners();
  }

  /// Handles scroll position changes and loads more data if needed.
  Future<void> onScroll(double scrollOffset, double maxScrollExtent) async {
    if (paginator.isLoading || paginator.hasReachedEnd) return;

    if (maxScrollExtent - scrollOffset <= loadThreshold) {
      await paginator.loadNextPage();
      if (!_disposed) notifyListeners();
    }
  }

  /// Refreshes all data.
  Future<void> refresh() async {
    await paginator.refresh();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
