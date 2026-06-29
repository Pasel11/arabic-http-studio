import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../favorites/models/favorite_item.dart';

/// Repository for managing favorites
class FavoritesRepository {
  FavoritesRepository(this._box);

  final Box<String> _box;

  List<FavoriteItem> getAll() {
    return _box.values
        .map((e) => FavoriteItem.fromJsonString(e))
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.addedAt.compareTo(a.addedAt);
      });
  }

  List<FavoriteItem> getPinned() {
    return getAll().where((f) => f.isPinned).toList();
  }

  List<FavoriteItem> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((f) {
      return f.name.toLowerCase().contains(lowerQuery) ||
          f.url.toLowerCase().contains(lowerQuery) ||
          f.method.toLowerCase().contains(lowerQuery) ||
          f.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  FavoriteItem? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return FavoriteItem.fromJsonString(jsonStr);
  }

  bool isFavorite(String requestId) {
    return _box.values.any((e) {
      final fav = FavoriteItem.fromJsonString(e);
      return fav.requestId == requestId;
    });
  }

  Future<void> add(FavoriteItem favorite) async {
    try {
      await _box.put(favorite.id, favorite.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل إضافة المفضلة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> remove(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف المفضلة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeByRequestId(String requestId) async {
    final favorite = getAll().firstWhere(
      (e) => e.requestId == requestId,
      orElse: () => throw StateError('Not found'),
    );
    await remove(favorite.id);
  }

  Future<void> togglePin(String id) async {
    final favorite = getById(id);
    if (favorite != null) {
      await add(favorite.copyWith(isPinned: !favorite.isPinned));
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع المفضلة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Provider for FavoritesRepository
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final box = Hive.box<String>(AppConstants.favoritesBox);
  return FavoritesRepository(box);
});
