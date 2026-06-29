import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/log_entry.dart';
import '../repositories/logs_repository.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  LogLevel? _levelFilter;
  String? _categoryFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsRepositoryProvider).filter(
          level: _levelFilter,
          category: _categoryFilter,
          searchQuery: _searchQuery,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('السجلات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'مسح السجلات',
            onPressed: () async {
              await ref.read(logsRepositoryProvider).deleteAll();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في السجلات...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: _levelFilter == null,
                  onSelected: (_) => setState(() => _levelFilter = null),
                ),
                const SizedBox(width: 8),
                ...LogLevel.values.map((level) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(level.name.toUpperCase()),
                      selected: _levelFilter == level,
                      onSelected: (_) => setState(() => _levelFilter = level),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Logs list
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _LogItemTile(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logs, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد سجلات'),
        ],
      ),
    );
  }
}

class _LogItemTile extends StatelessWidget {
  const _LogItemTile({required this.log});

  final LogEntry log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: _buildLevelIcon(),
        title: Text(
          log.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _getLevelColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getLevelColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.level.name.toUpperCase(),
                style: TextStyle(
                  color: _getLevelColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(log.category),
            const SizedBox(width: 8),
            Text(AppUtils.formatTime(log.timestamp)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرسالة الكاملة:'),
                const SizedBox(height: 4),
                Text(log.message),
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('البيانات الإضافية:'),
                  const SizedBox(height: 4),
                  ...log.metadata!.entries.map((entry) {
                    return Text('${entry.key}: ${entry.value}');
                  }),
                ],
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 16),
                  Text('تتبع المكدس:'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      log.stackTrace!,
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIcon() {
    switch (log.level) {
      case LogLevel.debug:
        return const Icon(Icons.bug_report, color: Colors.grey);
      case LogLevel.info:
        return const Icon(Icons.info, color: AppTheme.infoColor);
      case LogLevel.warning:
        return const Icon(Icons.warning, color: AppTheme.warningColor);
      case LogLevel.error:
        return const Icon(Icons.error, color: AppTheme.errorColor);
      case LogLevel.fatal:
        return const Icon(Icons.dangerous, color: Colors.red);
    }
  }

  Color _getLevelColor() {
    switch (log.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return AppTheme.infoColor;
      case LogLevel.warning:
        return AppTheme.warningColor;
      case LogLevel.error:
        return AppTheme.errorColor;
      case LogLevel.fatal:
        return Colors.red;
    }
  }
}
