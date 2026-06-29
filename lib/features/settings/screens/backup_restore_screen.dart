import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/utils/app_utils.dart';
import '../providers/backup_providers.dart';

/// Backup and Restore screen.
///
/// This screen allows users to:
/// - Create local backups
/// - Restore from backups
/// - Export backup files
/// - Import backup files
/// - Enable/disable automatic backups
class BackupRestoreScreen extends ConsumerStatefulWidget {
  /// Creates the backup screen.
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _autoBackupEnabled = false;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoBackupEnabled = BackupService.instance.isAutoBackupEnabled();
      _lastBackup = BackupService.instance.getLastBackupTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(backupsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto backup section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text('النسخ الاحتياطي التلقائي', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('تفعيل النسخ الاحتياطي التلقائي'),
                    subtitle: const Text('إنشاء نسخة احتياطية كل 24 ساعة'),
                    value: _autoBackupEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await BackupService.instance.enableAutoBackup();
                      } else {
                        await BackupService.instance.disableAutoBackup();
                      }
                      _loadSettings();
                    },
                  ),
                  if (_lastBackup != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'آخر نسخة احتياطية: ${AppUtils.formatDateTime(_lastBackup!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إجراءات', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _createBackup(context),
                      icon: const Icon(Icons.add_circle),
                      label: const Text('إنشاء نسخة احتياطية جديدة'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _importBackup(context),
                      icon: const Icon(Icons.file_upload),
                      label: const Text('استيراد نسخة احتياطية'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backups list
          Text('النسخ الاحتياطية', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          backups.when(
            data: (backupList) {
              if (backupList.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.backup_table, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 8),
                        const Text('لا توجد نسخ احتياطية'),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: backupList.map((backup) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.archive),
                      title: Text(backup.name),
                      subtitle: Text(
                        '${AppUtils.formatDateTime(backup.createdAt)} • ${AppUtils.formatBytes(backup.sizeBytes)}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) => _handleBackupAction(context, action, backup.id),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'restore', child: Text('استعادة')),
                          const PopupMenuItem(value: 'export', child: Text('تصدير')),
                          const PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('خطأ: $error')),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final path = await BackupService.instance.createBackup();
      ref.invalidate(backupsListProvider);
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path!;
      await BackupService.instance.importBackup(filePath);
      ref.invalidate(backupsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استيراد النسخة الاحتياطية')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاستيراد: $e')),
        );
      }
    }
  }

  Future<void> _handleBackupAction(BuildContext context, String action, String backupId) async {
    switch (action) {
      case 'restore':
        _confirmRestore(context, backupId);
      case 'export':
        try {
          final path = await BackupService.instance.exportBackup(backupId);
          await Share.shareXFiles([XFile(path)]);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل التصدير: $e')),
            );
          }
        }
      case 'delete':
        _confirmDelete(context, backupId);
    }
  }

  void _confirmRestore(BuildContext context, String backupId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية بالبيانات من النسخة الاحتياطية. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await BackupService.instance.restoreFromEntry(backupId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت الاستعادة بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الاستعادة: $e')),
                  );
                }
              }
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String backupId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف النسخة الاحتياطية'),
        content: const Text('هل أنت متأكد من حذف هذه النسخة الاحتياطية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await BackupService.instance.deleteBackup(backupId);
              ref.invalidate(backupsListProvider);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
