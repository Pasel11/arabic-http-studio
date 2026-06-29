import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/error/app_error.dart';
import '../models/session_model.dart';

/// Repository for managing sessions.
class SessionRepository {
  /// Creates a session repository.
  SessionRepository(this._box);

  final Box<String> _box;

  /// Gets all sessions.
  List<SessionModel> getAll() {
    return _box.values
        .map((e) => SessionModel.fromJsonString(e))
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  /// Gets a session by ID.
  SessionModel? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return SessionModel.fromJsonString(jsonStr);
  }

  /// Searches sessions.
  List<SessionModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          s.description?.toLowerCase().contains(lowerQuery) == true ||
          s.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Saves a session.
  Future<void> save(SessionModel session) async {
    try {
      await _box.put(session.id, session.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ الجلسة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a session.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف الجلسة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Toggles pin status.
  Future<void> togglePin(String id) async {
    final session = getById(id);
    if (session != null) {
      await save(session.copyWith(isPinned: !session.isPinned));
    }
  }

  /// Deletes all sessions.
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع الجلسات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Provider for SessionRepository.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final box = Hive.box<String>('sessions');
  return SessionRepository(box);
});
