import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backup_service.dart';

/// Provider for list of backups.
final backupsListProvider = FutureProvider<List<BackupEntry>>((ref) async {
  return BackupService.instance.getAllBackups();
});
