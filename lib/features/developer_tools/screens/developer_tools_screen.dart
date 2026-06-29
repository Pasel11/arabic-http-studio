import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_setup.dart';
import '../../../core/utils/app_utils.dart';
import '../../logs/models/log_entry.dart';
import '../../logs/repositories/logs_repository.dart';
import '../../history/repositories/history_repository.dart';
import '../models/crash_log.dart';
import '../services/performance_monitor.dart';

/// Developer Tools screen providing advanced debugging and monitoring.
///
/// This screen provides developers with tools to monitor app performance,
/// view logs, inspect network traffic, view crash logs, and explore
/// the local storage.
class DeveloperToolsScreen extends ConsumerStatefulWidget {
  /// Creates the developer tools screen.
  const DeveloperToolsScreen({super.key});

  @override
  ConsumerState<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends ConsumerState<DeveloperToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _monitorTimer;
  PerformanceStats _currentStats = const PerformanceStats();
  final List<PerformanceStats> _statsHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final stats = PerformanceMonitor.instance.getStats();
      setState(() {
        _currentStats = stats;
        _statsHistory.add(stats);
        if (_statsHistory.length > 60) {
          _statsHistory.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات المطور'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'الأداء'),
            Tab(icon: Icon(Icons.list), text: 'السجلات'),
            Tab(icon: Icon(Icons.network_check), text: 'الشبكة'),
            Tab(icon: Icon(Icons.bug_report), text: 'الأعطال'),
            Tab(icon: Icon(Icons.storage), text: 'التخزين'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            Tab(icon: Icon(Icons.memory), text: 'الذاكرة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PerformanceTab(stats: _currentStats, history: _statsHistory),
          _LogsTab(),
          const _NetworkInspectorTab(),
          const _CrashLogsTab(),
          const _StorageViewerTab(),
          const _SharedPrefsTab(),
          _MemoryTab(stats: _currentStats),
        ],
      ),
    );
  }
}

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab({required this.stats, required this.history});

  final PerformanceStats stats;
  final List<PerformanceStats> history;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          title: 'معدل الإطارات (FPS)',
          value: stats.fps.toStringAsFixed(1),
          unit: 'FPS',
          color: _getFpsColor(stats.fps),
          icon: Icons.animation,
          progress: (stats.fps / 60).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'استهلاك الذاكرة',
          value: AppUtils.formatBytes(stats.memoryUsage),
          unit: '',
          color: _getMemoryColor(stats.memoryUsage),
          icon: Icons.memory,
          progress: (stats.memoryUsage / (512 * 1024 * 1024)).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'استهلاك المعالج',
          value: stats.cpuUsage.toStringAsFixed(1),
          unit: '%',
          color: _getCpuColor(stats.cpuUsage),
          icon: Icons.developer_board,
          progress: (stats.cpuUsage / 100).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'عدد العناصر',
          value: stats.widgetCount.toString(),
          unit: '',
          color: Colors.blue,
          icon: Icons.widgets,
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'العمليات المنعزلة',
          value: stats.isolateCount.toString(),
          unit: '',
          color: Colors.purple,
          icon: Icons.layers,
        ),
        const SizedBox(height: 24),
        if (history.isNotEmpty) ...[
          Text('مخطط الأداء', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 120,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PerformanceChartPainter(history),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(int bytes) {
    if (bytes < 100 * 1024 * 1024) return Colors.green;
    if (bytes < 300 * 1024 * 1024) return Colors.orange;
    return Colors.red;
  }

  Color _getCpuColor(double cpu) {
    if (cpu < 30) return Colors.green;
    if (cpu < 70) return Colors.orange;
    return Colors.red;
  }
}

class _PerformanceChartPainter extends CustomPainter {
  _PerformanceChartPainter(this.history);
  final List<PerformanceStats> history;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = history.length > 1 ? size.width / (history.length - 1) : size.width;

    for (var i = 0; i < history.length; i++) {
      final x = i * stepX;
      final y = size.height - (history[i].fps / 60) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    this.progress,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
                Text(
                  '$value $unit',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsRepositoryProvider).getRecent(limit: 200);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('عدد السجلات: ${logs.length}'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'مسح السجلات',
                onPressed: () async {
                  await ref.read(logsRepositoryProvider).deleteAll();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(child: Text('لا توجد سجلات'))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      leading: Icon(
                        _getLevelIcon(log.level),
                        color: _getLevelColor(log.level),
                        size: 20,
                      ),
                      title: Text(
                        log.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${log.category} • ${AppUtils.formatTime(log.timestamp)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _showLogDetails(context, log),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.fatal:
        return Icons.dangerous;
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  void _showLogDetails(BuildContext context, LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل السجل'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المستوى: ${log.level.name.toUpperCase()}'),
              Text('الفئة: ${log.category}'),
              Text('الوقت: ${AppUtils.formatDateTime(log.timestamp)}'),
              const SizedBox(height: 8),
              const Text('الرسالة:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log.message),
              if (log.metadata != null) ...[
                const SizedBox(height: 8),
                const Text('البيانات:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(jsonEncode(log.metadata)),
              ],
              if (log.stackTrace != null) ...[
                const SizedBox(height: 8),
                const Text('تتبع المكدس:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black12,
                  child: SelectableText(
                    log.stackTrace!,
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

class _NetworkInspectorTab extends ConsumerWidget {
  const _NetworkInspectorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyRepositoryProvider).getRecent(limit: 100);

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getMethodColor(entry.method).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.method,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getMethodColor(entry.method),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              entry.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${entry.statusCode} • ${entry.responseTimeMs}ms • ${AppUtils.formatBytes(entry.responseSizeBytes)}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _CrashLogsTab extends StatefulWidget {
  const _CrashLogsTab();

  @override
  State<_CrashLogsTab> createState() => _CrashLogsTabState();
}

class _CrashLogsTabState extends State<_CrashLogsTab> {
  List<CrashLog> _crashLogs = [];

  @override
  void initState() {
    super.initState();
    _loadCrashLogs();
  }

  Future<void> _loadCrashLogs() async {
    final box = Hive.box<String>('crash_logs');
    setState(() {
      _crashLogs = box.values
          .map((e) => CrashLog.fromJsonString(e))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_crashLogs.isEmpty) {
      return const Center(child: Text('لا توجد سجلات أعطال'));
    }

    return ListView.builder(
      itemCount: _crashLogs.length,
      itemBuilder: (context, index) {
        final crash = _crashLogs[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: const Icon(Icons.error, color: Colors.red),
            title: Text(crash.errorType),
            subtitle: Text(AppUtils.formatDateTime(crash.timestamp)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الرسالة: ${crash.message}'),
                    const SizedBox(height: 8),
                    const Text('تتبع المكدس:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black12,
                      child: SelectableText(
                        crash.stackTrace,
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StorageViewerTab extends StatefulWidget {
  const _StorageViewerTab();

  @override
  State<_StorageViewerTab> createState() => _StorageViewerTabState();
}

class _StorageViewerTabState extends State<_StorageViewerTab> {
  String? _selectedBox;

  final _boxNames = [
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
    'crash_logs',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButton<String>(
            value: _selectedBox,
            hint: const Text('اختر صندوق البيانات'),
            isExpanded: true,
            items: _boxNames.map((name) {
              return DropdownMenuItem(value: name, child: Text(name));
            }).toList(),
            onChanged: (value) => setState(() => _selectedBox = value),
          ),
        ),
        Expanded(
          child: _selectedBox == null
              ? const Center(child: Text('اختر صندوقًا للعرض'))
              : _BoxViewer(boxName: _selectedBox!),
        ),
      ],
    );
  }
}

class _BoxViewer extends StatelessWidget {
  const _BoxViewer({required this.boxName});
  final String boxName;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<String>(boxName);
    final keys = box.keys.toList();
    final totalSize = box.values.fold<int>(0, (sum, value) => sum + (value as String).length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('العناصر: ${box.length}'),
              const SizedBox(width: 16),
              Text('الحجم: ${AppUtils.formatBytes(totalSize)}'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final value = box.get(key) as String?;
              return ListTile(
                title: Text(
                  key.toString(),
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
                ),
                subtitle: Text(
                  value != null && value.length > 100
                      ? '${value.substring(0, 100)}...'
                      : value ?? '',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _showValue(context, key.toString(), value ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showValue(BuildContext context, String key, String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(key),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

class _SharedPrefsTab extends StatelessWidget {
  const _SharedPrefsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_applications, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('عارض الإعدادات المشتركة'),
            SizedBox(height: 8),
            Text(
              'يتم استخدام flutter_secure_storage للتخزين الآمن.\n'
              'لا يمكن عرض القيم المشفرة لأسباب أمنية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryTab extends StatelessWidget {
  const _MemoryTab({required this.stats});
  final PerformanceStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('معلومات الذاكرة', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _InfoRow(label: 'إجمالي الاستخدام', value: AppUtils.formatBytes(stats.memoryUsage)),
                _InfoRow(label: 'العمليات المنعزلة', value: '${stats.isolateCount}'),
                _InfoRow(label: 'عدد العناصر', value: '${stats.widgetCount}'),
                _InfoRow(
                  label: 'متوسط لكل عنصر',
                  value: AppUtils.formatBytes(
                    stats.widgetCount > 0 ? stats.memoryUsage ~/ stats.widgetCount : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('صناديق البيانات', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FutureBuilder<int>(
                  future: HiveSetup.getTotalSize(),
                  builder: (context, snapshot) {
                    return _InfoRow(
                      label: 'إجمالي حجم البيانات',
                      value: snapshot.hasData
                          ? AppUtils.formatBytes(snapshot.data!)
                          : 'جاري الحساب...',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await HiveSetup.clearAllBoxes();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح جميع البيانات')),
              );
            }
          },
          icon: const Icon(Icons.delete_forever),
          label: const Text('مسح جميع البيانات'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
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
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
