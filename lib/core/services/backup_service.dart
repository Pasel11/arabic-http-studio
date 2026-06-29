import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';

/// Service for creating and restoring backups.
///
/// This service handles:
/// - Creating local backups of all application data
/// - Restoring from backup files
/// - Automatic periodic backups
/// - Exporting and importing backup files
///
/// Example:
/// ```dart
/// final backupPath = await BackupService.instance.createBackup();
/// await BackupService.instance.restoreBackup(backupPath);
/// ```
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Creates a backup of all application data.
  ///
  /// Returns the path to the backup file.
  Future<String> createBackup({String? name}) async {
    try {
      final backupData = await _collectAllData();
      final backupName = name ?? 'backup_${_formatDateForFileName(DateTime.now())}';
      final backupJson = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to Hive box for tracking
      final backupsBox = Hive.box<String>('backups');
      final backupId = DateTime.now().microsecondsSinceEpoch.toString();
      final backupEntry = BackupEntry(
        id: backupId,
        name: backupName,
        createdAt: DateTime.now(),
        sizeBytes: backupJson.length,
        data: backupJson,
      ).toJsonString();
      await backupsBox.put(backupId, backupEntry);

      // Also save to file system
      final directory = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${directory.path}/backups');
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }
      final file = File('${backupsDir.path}/$backupName.json');
      await file.writeAsString(backupJson);

      return file.path;
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل إنشاء النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Restores data from a backup file.
  Future<void> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AppError(message: 'ملف النسخة الاحتياطية غير موجود', code: 'FILE_NOT_FOUND');
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      await _restoreAllData(data);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل استعادة النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Restores data from a backup entry stored in Hive.
  Future<void> restoreFromEntry(String backupId) async {
    try {
      final backupsBox = Hive.box<String>('backups');
      final entryJson = backupsBox.get(backupId);
      if (entryJson == null) {
        throw const AppError(message: 'النسخة الاحتياطية غير موجودة', code: 'BACKUP_NOT_FOUND');
      }

      final entry = BackupEntry.fromJsonString(entryJson);
      final data = jsonDecode(entry.data) as Map<String, dynamic>;
      await _restoreAllData(data);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل استعادة النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gets all backup entries.
  List<BackupEntry> getAllBackups() {
    final box = Hive.box<String>('backups');
    return box.values
        .map((e) => BackupEntry.fromJsonString(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Deletes a backup by ID.
  Future<void> deleteBackup(String backupId) async {
    try {
      final box = Hive.box<String>('backups');
      await box.delete(backupId);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Exports a backup to a file.
  Future<String> exportBackup(String backupId) async {
    try {
      final box = Hive.box<String>('backups');
      final entryJson = box.get(backupId);
      if (entryJson == null) {
        throw const AppError(message: 'النسخة الاحتياطية غير موجودة', code: 'BACKUP_NOT_FOUND');
      }

      final entry = BackupEntry.fromJsonString(entryJson);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${entry.name}_export.json');
      await file.writeAsString(entry.data);

      return file.path;
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل تصدير النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Imports a backup from a file.
  Future<String> importBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AppError(message: 'الملف غير موجود', code: 'FILE_NOT_FOUND');
      }

      final content = await file.readAsString();
      // Validate it's valid JSON
      jsonDecode(content);

      // Save as new backup
      final fileName = filePath.split('/').last.replaceAll('.json', '');
      final backupsBox = Hive.box<String>('backups');
      final backupId = DateTime.now().microsecondsSinceEpoch.toString();
      final entry = BackupEntry(
        id: backupId,
        name: fileName,
        createdAt: DateTime.now(),
        sizeBytes: content.length,
        data: content,
      ).toJsonString();
      await backupsBox.put(backupId, entry);

      return backupId;
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل استيراد النسخة الاحتياطية',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Enables automatic backups at the specified interval.
  Future<void> enableAutoBackup({Duration interval = const Duration(hours: 24)}) async {
    // In a real app, this would use workmanager or similar
    // For now, we just track the setting
    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBox);
    await settingsBox.put('autoBackupEnabled', true);
    await settingsBox.put('autoBackupInterval', interval.inHours);
    await settingsBox.put('lastAutoBackup', DateTime.now().toIso8601String());
  }

  /// Disables automatic backups.
  Future<void> disableAutoBackup() async {
    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBox);
    await settingsBox.put('autoBackupEnabled', false);
  }

  /// Checks if auto backup is enabled.
  bool isAutoBackupEnabled() {
    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBox);
    return settingsBox.get('autoBackupEnabled', defaultValue: false) as bool;
  }

  /// Gets the last backup time.
  DateTime? getLastBackupTime() {
    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBox);
    final lastBackup = settingsBox.get('lastAutoBackup') as String?;
    return lastBackup != null ? DateTime.parse(lastBackup) : null;
  }

  Future<Map<String, dynamic>> _collectAllData() async {
    final result = <String, dynamic>{};

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
    ];

    for (final boxName in boxNames) {
      final box = Hive.box<String>(boxName);
      final data = <String, String>{};
      for (final key in box.keys) {
        data[key.toString()] = box.get(key) as String;
      }
      result[boxName] = data;
    }

    // Add metadata
    result['_metadata'] = {
      'version': AppConstants.appVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
    };

    return result;
  }

  Future<void> _restoreAllData(Map<String, dynamic> data) async {
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
    ];

    for (final boxName in boxNames) {
      final box = Hive.box<String>(boxName);
      await box.clear();

      final boxData = data[boxName] as Map<String, dynamic>?;
      if (boxData != null) {
        for (final entry in boxData.entries) {
          await box.put(entry.key, entry.value as String);
        }
      }
    }
  }

  String _formatDateForFileName(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Represents a backup entry.
class BackupEntry {
  /// Creates a backup entry.
  BackupEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.data,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// When the backup was created.
  final DateTime createdAt;

  /// Size of the backup data in bytes.
  final int sizeBytes;

  /// The backup data as JSON string.
  final String data;

  /// Converts to JSON string.
  String toJsonString() => jsonEncode({
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'data': data,
      });

  /// Creates from JSON string.
  factory BackupEntry.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sizeBytes: json['sizeBytes'] as int,
      data: json['data'] as String,
    );
  }
}

/// Provider for BackupService.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService.instance;
});
