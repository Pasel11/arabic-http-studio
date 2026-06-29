import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Hive database setup and configuration.
///
/// This class handles initialization of Hive database boxes
/// used throughout the application for local storage.
class HiveSetup {
  HiveSetup._();

  static bool _initialized = false;

  /// Registers all Hive type adapters.
  ///
  /// Note: Currently using JSON string storage, so no adapters needed.
  static Future<void> registerAdapters() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Opens all required Hive boxes.
  ///
  /// This must be called before any repository is used.
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<String>(AppConstants.requestsBox),
      Hive.openBox<String>(AppConstants.historyBox),
      Hive.openBox<String>(AppConstants.favoritesBox),
      Hive.openBox<String>(AppConstants.collectionsBox),
      Hive.openBox<String>(AppConstants.environmentsBox),
      Hive.openBox<String>(AppConstants.variablesBox),
      Hive.openBox<dynamic>(AppConstants.settingsBox),
      Hive.openBox<String>(AppConstants.authBox),
      Hive.openBox<String>(AppConstants.logsBox),
      Hive.openBox<String>(AppConstants.websocketMessagesBox),
      Hive.openBox<String>(AppConstants.cookiesBox),
      // New boxes for project management
      Hive.openBox<String>('workspaces'),
      Hive.openBox<String>('projects'),
      Hive.openBox<String>('tags'),
      Hive.openBox<String>('notes'),
      Hive.openBox<String>('backups'),
      Hive.openBox<String>('crash_logs'),
      // Enterprise Edition boxes
      Hive.openBox<String>('sessions'),
      Hive.openBox<String>('file_bookmarks'),
    ]);
  }

  /// Closes all Hive boxes.
  static Future<void> closeBoxes() async {
    await Hive.close();
  }

  /// Clears all data from all boxes.
  ///
  /// WARNING: This is a destructive operation and cannot be undone.
  static Future<void> clearAllBoxes() async {
    final boxNames = [
      AppConstants.requestsBox,
      AppConstants.historyBox,
      AppConstants.favoritesBox,
      AppConstants.collectionsBox,
      AppConstants.environmentsBox,
      AppConstants.variablesBox,
      AppConstants.settingsBox,
      AppConstants.authBox,
      AppConstants.logsBox,
      AppConstants.websocketMessagesBox,
      AppConstants.cookiesBox,
      'workspaces',
      'projects',
      'tags',
      'notes',
      'backups',
      'crash_logs',
    ];

    await Future.wait(
      boxNames.map((name) => Hive.box<String>(name).clear()),
    );
  }

  /// Gets the total size of all boxes in bytes.
  static Future<int> getTotalSize() async {
    var total = 0;
    final boxNames = [
      AppConstants.requestsBox,
      AppConstants.historyBox,
      AppConstants.favoritesBox,
      AppConstants.collectionsBox,
      AppConstants.environmentsBox,
      AppConstants.variablesBox,
      AppConstants.logsBox,
      'workspaces',
      'projects',
      'tags',
      'notes',
      'backups',
    ];

    for (final name in boxNames) {
      final box = Hive.box<String>(name);
      for (final value in box.values) {
        total += value.length;
      }
    }

    return total;
  }
}
