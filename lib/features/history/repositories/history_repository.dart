import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../history/models/history_entry.dart';

/// Repository for managing history entries
class HistoryRepository {
  HistoryRepository(this._box);

  final Box<String> _box;

  List<HistoryEntry> getAll() {
    return _box.values
        .map((e) => HistoryEntry.fromJsonString(e))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<HistoryEntry> getRecent({int limit = 50}) {
    final all = getAll();
    return all.take(limit).toList();
  }

  List<HistoryEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((h) {
      return h.requestName.toLowerCase().contains(lowerQuery) ||
          h.url.toLowerCase().contains(lowerQuery) ||
          h.method.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<HistoryEntry> filterByMethod(String method) {
    return getAll().where((h) => h.method == method).toList();
  }

  List<HistoryEntry> filterByStatusRange(int min, int max) {
    return getAll().where((h) => h.statusCode >= min && h.statusCode <= max).toList();
  }

  HistoryEntry? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return HistoryEntry.fromJsonString(jsonStr);
  }

  Future<void> save(HistoryEntry entry) async {
    try {
      await _box.put(entry.id, entry.toJsonString());

      // Enforce max history limit
      final count = _box.length;
      if (count > AppConstants.maxHistoryItems) {
        final toDelete = getAll()
            .skip(AppConstants.maxHistoryItems)
            .map((e) => e.id)
            .toList();
        await _box.deleteAll(toDelete);
      }
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ السجل',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف السجل',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع السجلات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Export all history as list of maps
  List<Map<String, dynamic>> exportAll() {
    return getAll().map((e) => e.toJson()).toList();
  }
}

/// Provider for HistoryRepository
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final box = Hive.box<String>(AppConstants.historyBox);
  return HistoryRepository(box);
});
