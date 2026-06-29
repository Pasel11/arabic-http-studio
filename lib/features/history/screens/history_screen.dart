import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/history_entry.dart';
import '../repositories/history_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String? _methodFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyRepositoryProvider).getAll();

    var filtered = history;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((h) =>
              h.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.requestName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_methodFilter != null) {
      filtered = filtered.where((h) => h.method == _methodFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفوظات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'مسح الكل',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث في المحفوظات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Method filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: _methodFilter == null,
                  onSelected: (_) => setState(() => _methodFilter = null),
                ),
                const SizedBox(width: 8),
                ...['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'].map((method) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(method),
                      selected: _methodFilter == method,
                      onSelected: (_) => setState(() => _methodFilter = method),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // History list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _HistoryItemTile(entry: entry);
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
          Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد محفوظات'),
          const SizedBox(height: 8),
          const Text('سيتم عرض الطلبات المرسلة هنا'),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح جميع المحفوظات'),
        content: const Text('هل أنت متأكد من مسح جميع المحفوظات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(historyRepositoryProvider).deleteAll();
              if (mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}

final _historyStreamProvider = StreamProvider<List<HistoryEntry>>((ref) {
  // Return a stream that emits periodically
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return ref.read(historyRepositoryProvider).getAll();
  });
});


class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final methodColor = AppTheme.getMethodColor(entry.method);
    final statusColor = AppTheme.getStatusColor(entry.statusCode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            entry.method,
            style: TextStyle(
              color: methodColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        title: Text(
          entry.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.statusCode.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(AppUtils.formatDuration(Duration(milliseconds: entry.responseTimeMs))),
            const SizedBox(width: 8),
            Text(AppUtils.formatBytes(entry.responseSizeBytes)),
            const SizedBox(width: 8),
            Text(AppUtils.formatDate(entry.timestamp)),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          // Show response details
          _showResponseDetails(context, entry);
        },
      ),
    );
  }

  void _showResponseDetails(BuildContext context, HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              AppBar(
                title: Text(entry.requestName),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'إعادة الإرسال',
                    onPressed: () {
                      Navigator.pop(context);
                      GoRouter.of(context).push('/request/${entry.requestId}');
                    },
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Request info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('معلومات الطلب', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'الطريقة', value: entry.method),
                            _InfoRow(label: 'الرابط', value: entry.url),
                            _InfoRow(label: 'الحالة', value: '${entry.statusCode} ${entry.statusText}'),
                            _InfoRow(label: 'الوقت', value: AppUtils.formatDuration(Duration(milliseconds: entry.responseTimeMs))),
                            _InfoRow(label: 'الحجم', value: AppUtils.formatBytes(entry.responseSizeBytes)),
                            _InfoRow(label: 'التاريخ', value: AppUtils.formatDateTime(entry.timestamp)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Response headers
                    Text('رؤوس الاستجابة', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...entry.responseHeaders.entries.map((header) {
                      return Card(
                        child: ListTile(
                          dense: true,
                          title: Text(header.key),
                          subtitle: Text(header.value),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Response body
                    Text('متن الاستجابة', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          entry.responseBody ?? 'لا يوجد متن',
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
