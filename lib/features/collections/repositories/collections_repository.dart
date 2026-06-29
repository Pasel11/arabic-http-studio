import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../collections/models/collection_item.dart';

/// Repository for managing collections
class CollectionsRepository {
  CollectionsRepository(this._box);

  final Box<String> _box;

  List<CollectionItem> getAll() {
    return _box.values
        .map((e) => CollectionItem.fromJsonString(e))
        .toList()
      ..sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.compareTo(b.name);
      });
  }

  List<CollectionItem> getRoot() {
    return getAll().where((c) => c.parentId == null).toList();
  }

  List<CollectionItem> getByParent(String? parentId) {
    return getAll().where((c) => c.parentId == parentId).toList();
  }

  List<CollectionItem> getFolders() {
    return getAll().where((c) => c.isFolder).toList();
  }

  List<CollectionItem> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          c.description?.toLowerCase().contains(lowerQuery) == true ||
          c.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  CollectionItem? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return CollectionItem.fromJsonString(jsonStr);
  }

  Future<void> save(CollectionItem collection) async {
    try {
      await _box.put(collection.id, collection.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ المجموعة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      // Delete all children recursively
      final children = getByParent(id);
      for (final child in children) {
        await delete(child.id);
      }
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف المجموعة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addRequest(String collectionId, String requestId) async {
    final collection = getById(collectionId);
    if (collection != null) {
      final updatedRequestIds = [...collection.requestIds, requestId];
      final updated = CollectionItem(
        id: collection.id,
        name: collection.name,
        description: collection.description,
        requestIds: updatedRequestIds,
        folderIds: collection.folderIds,
        parentId: collection.parentId,
        tags: collection.tags,
        isFolder: collection.isFolder,
        createdAt: collection.createdAt,
        updatedAt: DateTime.now(),
        color: collection.color,
        icon: collection.icon,
      );
      await save(updated);
    }
  }

  Future<void> removeRequest(String collectionId, String requestId) async {
    final collection = getById(collectionId);
    if (collection != null) {
      final updatedRequestIds = collection.requestIds
          .where((id) => id != requestId)
          .toList();
      final updated = CollectionItem(
        id: collection.id,
        name: collection.name,
        description: collection.description,
        requestIds: updatedRequestIds,
        folderIds: collection.folderIds,
        parentId: collection.parentId,
        tags: collection.tags,
        isFolder: collection.isFolder,
        createdAt: collection.createdAt,
        updatedAt: DateTime.now(),
        color: collection.color,
        icon: collection.icon,
      );
      await save(updated);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع المجموعات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Provider for CollectionsRepository
final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  final box = Hive.box<String>(AppConstants.collectionsBox);
  return CollectionsRepository(box);
});
