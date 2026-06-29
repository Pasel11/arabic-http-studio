import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collections/models/collection_item.dart';
import '../../collections/repositories/collections_repository.dart';
import '../../favorites/models/favorite_item.dart';
import '../../favorites/repositories/favorites_repository.dart';
import '../../history/models/history_entry.dart';
import '../../history/repositories/history_repository.dart';
import '../../request/models/http_request.dart';
import '../../request/repositories/request_repository.dart';

/// App statistics
class AppStats {
  final int totalRequests;
  final int totalHistory;
  final int totalFavorites;
  final int totalCollections;

  const AppStats({
    required this.totalRequests,
    required this.totalHistory,
    required this.totalFavorites,
    required this.totalCollections,
  });
}

/// Provider for app statistics
final appStatsProvider = Provider<AppStats>((ref) {
  final requestRepo = ref.read(requestRepositoryProvider);
  final historyRepo = ref.read(historyRepositoryProvider);
  final favoritesRepo = ref.read(favoritesRepositoryProvider);
  final collectionsRepo = ref.read(collectionsRepositoryProvider);

  return AppStats(
    totalRequests: requestRepo.getAll().length,
    totalHistory: historyRepo.getAll().length,
    totalFavorites: favoritesRepo.getAll().length,
    totalCollections: collectionsRepo.getAll().length,
  );
});

/// Provider for recent requests
final recentRequestsProvider = Provider<List<HttpRequestModel>>((ref) {
  final repo = ref.read(requestRepositoryProvider);
  return repo.getRecent(limit: 10);
});

/// Provider for all requests
final allRequestsProvider = Provider<List<HttpRequestModel>>((ref) {
  final repo = ref.read(requestRepositoryProvider);
  return repo.getAll();
});

/// Provider for pinned requests
final pinnedRequestsProvider = Provider<List<HttpRequestModel>>((ref) {
  final repo = ref.read(requestRepositoryProvider);
  return repo.getPinned();
});

/// Provider for searching requests
final searchRequestsProvider = Provider.family<List<HttpRequestModel>, String>((ref, query) {
  final repo = ref.read(requestRepositoryProvider);
  if (query.isEmpty) return [];
  return repo.search(query);
});

/// Provider for recent history
final recentHistoryProvider = Provider<List<HistoryEntry>>((ref) {
  final repo = ref.read(historyRepositoryProvider);
  return repo.getRecent(limit: 20);
});

/// Provider for all favorites
final allFavoritesProvider = Provider<List<FavoriteItem>>((ref) {
  final repo = ref.read(favoritesRepositoryProvider);
  return repo.getAll();
});

/// Provider for all collections
final allCollectionsProvider = Provider<List<CollectionItem>>((ref) {
  final repo = ref.read(collectionsRepositoryProvider);
  return repo.getAll();
});

/// Provider for root collections
final rootCollectionsProvider = Provider<List<CollectionItem>>((ref) {
  final repo = ref.read(collectionsRepositoryProvider);
  return repo.getRoot();
});
