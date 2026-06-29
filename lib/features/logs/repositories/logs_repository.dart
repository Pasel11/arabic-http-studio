import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../logs/models/log_entry.dart';

/// Repository for managing logs
class LogsRepository {
  LogsRepository(this._box);

  final Box<String> _box;

  List<LogEntry> getAll() {
    return _box.values
        .map((e) => LogEntry.fromJsonString(e))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<LogEntry> getRecent({int limit = 100}) {
    return getAll().take(limit).toList();
  }

  List<LogEntry> filter({
    LogLevel? level,
    String? category,
    String? searchQuery,
  }) {
    var entries = getAll();

    if (level != null) {
      entries = entries.where((e) => e.level == level).toList();
    }

    if (category != null) {
      entries = entries.where((e) => e.category == category).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      entries = entries.where((e) {
        return e.message.toLowerCase().contains(lowerQuery) ||
            e.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return entries;
  }

  Future<void> save(LogEntry entry) async {
    try {
      await _box.put(entry.id, entry.toJsonString());

      // Enforce max log limit
      final count = _box.length;
      if (count > AppConstants.maxLogItems) {
        final toDelete = getAll()
            .skip(AppConstants.maxLogItems)
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

  Future<void> log(
    LogLevel level,
    String category,
    String message, {
    Map<String, dynamic>? metadata,
    String? stackTrace,
    String? requestId,
  }) async {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      level: level,
      category: category,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
      stackTrace: stackTrace,
      requestId: requestId,
    );
    await save(entry);
  }

  Future<void> info(String category, String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.info, category, message, metadata: metadata);
  }

  Future<void> warning(String category, String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.warning, category, message, metadata: metadata);
  }

  Future<void> error(String category, String message, {Map<String, dynamic>? metadata, String? stackTrace}) async {
    await log(LogLevel.error, category, message, metadata: metadata, stackTrace: stackTrace);
  }

  Future<void> debug(String category, String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.debug, category, message, metadata: metadata);
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

  /// Export all logs as list of maps
  List<Map<String, dynamic>> exportAll() {
    return getAll().map((e) => e.toJson()).toList();
  }
}

/// Provider for LogsRepository
final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final box = Hive.box<String>(AppConstants.logsBox);
  return LogsRepository(box);
});
