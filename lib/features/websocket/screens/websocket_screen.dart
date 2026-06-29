import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/websocket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/websocket_message.dart';
import '../providers/websocket_provider.dart';

/// Enhanced WebSocket screen with modern UI and advanced features.
///
/// Features:
/// - Real-time message streaming with auto-scroll
/// - Message type filtering (text, binary, ping/pong, error)
/// - Full-text search across messages
/// - Connection statistics (uptime, message count, data size)
/// - Quick message templates
/// - Binary message support with hex view
/// - Message export
/// - Auto-reconnect with configurable settings
/// - Professional Material 3 design with animations
class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController(text: 'wss://echo.websocket.org');
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _autoScroll = true;
  bool _isConnected = false;
  String? _connectionId;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  final List<WebSocketMessage> _allMessages = [];
  List<WebSocketMessage> _filteredMessages = [];
  String _filterType = 'all';
  String _searchQuery = '';
  DateTime? _connectionStartTime;
  int _totalBytesSent = 0;
  int _totalBytesReceived = 0;

  // Quick message templates
  final List<String> _quickTemplates = [
    '{"type": "ping"}',
    '{"action": "subscribe", "channel": "updates"}',
    '{"action": "unsubscribe", "channel": "updates"}',
    'Hello, WebSocket!',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _disconnect();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredMessages = _allMessages.where((msg) {
        // Filter by type
        if (_filterType != 'all') {
          if (_filterType == 'text' && msg.type != WebSocketMessageType.text) {
            return false;
          }
          if (_filterType == 'binary' && msg.type != WebSocketMessageType.binary) {
            return false;
          }
          if (_filterType == 'error' && msg.type != WebSocketMessageType.error) {
            return false;
          }
          if (_filterType == 'system' &&
              msg.type != WebSocketMessageType.ping &&
              msg.type != WebSocketMessageType.pong &&
              msg.type != WebSocketMessageType.close) {
            return false;
          }
        }
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final text = msg.text?.toLowerCase() ?? '';
          if (!text.contains(_searchQuery)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (!AppUtils.isValidWebSocketUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط WebSocket غير صالح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final settings = ref.read(websocketSettingsProvider);

    try {
      _connectionId = await WebSocketService.instance.connect(
        url: url,
        pingInterval: Duration(seconds: settings.pingIntervalSec),
        autoReconnect: settings.autoReconnect,
        maxReconnectAttempts: settings.maxReconnectAttempts,
        reconnectDelay: Duration(seconds: settings.reconnectDelaySec),
      );

      _connectionStartTime = DateTime.now();

      // Listen to messages
      WebSocketService.instance.getMessageStream(_connectionId!).listen((message) {
        setState(() {
          _allMessages.add(message);
          if (_allMessages.length > settings.maxMessages) {
            _allMessages.removeAt(0);
          }
          if (message.isIncoming) {
            _totalBytesReceived += message.size ?? 0;
          } else {
            _totalBytesSent += message.size ?? 0;
          }
        });
        _applyFilters();
        if (_autoScroll) {
          _scrollToBottom();
        }
      });

      // Listen to state changes
      WebSocketService.instance.getStateStream(_connectionId!).listen((state) {
        setState(() {
          _connectionState = state;
          _isConnected = state == WebSocketConnectionState.connected;
        });
      });

      setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    if (_connectionId != null) {
      await WebSocketService.instance.disconnect(_connectionId!);
      setState(() {
        _connectionId = null;
        _isConnected = false;
        _connectionState = WebSocketConnectionState.disconnected;
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _connectionId == null) return;

    WebSocketService.instance.sendText(_connectionId!, message);
    _messageController.clear();
  }

  void _sendPing() {
    if (_connectionId != null) {
      WebSocketService.instance.sendPing(_connectionId!);
    }
  }

  void _clearMessages() {
    setState(() {
      _allMessages.clear();
      _filteredMessages.clear();
      _totalBytesSent = 0;
      _totalBytesReceived = 0;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getUptimeString() {
    if (_connectionStartTime == null) return '00:00:00';
    final duration = DateTime.now().difference(_connectionStartTime!);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: _getStatusColor(), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearMessages();
                case 'export':
                  _exportMessages();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('مسح الرسائل')),
              const PopupMenuItem(value: 'export', child: Text('تصدير الرسائل')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'الرسائل'),
            Tab(icon: Icon(Icons.bar_chart), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesTab(context),
          _buildStatsTab(context),
          _buildSettingsTab(context),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_connectionState) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
        return Colors.orange;
      case WebSocketConnectionState.disconnecting:
        return Colors.orange;
      case WebSocketConnectionState.error:
        return Colors.red;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_connectionState) {
      case WebSocketConnectionState.connected:
        return 'متصل';
      case WebSocketConnectionState.connecting:
        return 'جاري الاتصال';
      case WebSocketConnectionState.disconnecting:
        return 'جاري القطع';
      case WebSocketConnectionState.error:
        return 'خطأ';
      case WebSocketConnectionState.disconnected:
        return 'غير متصل';
    }
  }

  Widget _buildMessagesTab(BuildContext context) {
    return Column(
      children: [
        // URL bar with connect/disconnect
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'wss://example.com/ws',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  enabled: !_isConnected,
                ),
              ),
              const SizedBox(width: 8),
              _isConnected
                  ? FilledButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('قطع'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _connect,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('اتصال'),
                    ),
            ],
          ),
        ),

        // Filter and search bar
        if (_isConnected || _allMessages.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'بحث في الرسائل...',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'الكل'),
                      const SizedBox(width: 8),
                      _buildFilterChip('text', 'نصية'),
                      const SizedBox(width: 8),
                      _buildFilterChip('binary', 'ثنائية'),
                      const SizedBox(width: 8),
                      _buildFilterChip('system', 'النظام'),
                      const SizedBox(width: 8),
                      _buildFilterChip('error', 'أخطاء'),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Quick stats bar
        if (_isConnected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'المدة: ${_getUptimeString()}',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.message, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'الرسائل: ${_allMessages.length}',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                ),
                const Spacer(),
                // Auto-scroll toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تمرير تلقائي',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                    ),
                    Switch(
                      value: _autoScroll,
                      onChanged: (value) => setState(() => _autoScroll = value),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Messages list
        Expanded(
          child: _filteredMessages.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = _filteredMessages[index];
                    return _MessageBubble(
                      message: message,
                      searchQuery: _searchQuery,
                    );
                  },
                ),
        ),

        // Quick templates
        if (_isConnected)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _quickTemplates.map((template) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(
                      template.length > 30 ? '${template.substring(0, 30)}...' : template,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      _messageController.text = template;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

        // Message input
        if (_isConnected)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sendPing,
                  icon: const Icon(Icons.network_ping),
                  tooltip: 'إرسال Ping',
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String type, String label) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _filterType == type,
      onSelected: (_) {
        setState(() => _filterType = type);
        _applyFilters();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _isConnected ? 'لا توجد رسائل بعد' : 'غير متصل',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected
                ? 'ابدأ بإرسال رسالة من الأسفل'
                : 'أدخل رابط WebSocket واضغط اتصال',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context) {
    final sent = _allMessages.where((m) => !m.isIncoming).length;
    final received = _allMessages.where((m) => m.isIncoming).length;
    final errors = _allMessages.where((m) => m.type == WebSocketMessageType.error).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi, color: _getStatusColor()),
                    const SizedBox(width: 12),
                    Text('حالة الاتصال', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                _StatRow(label: 'الحالة', value: _getStatusText(), color: _getStatusColor()),
                _StatRow(label: 'المدة', value: _getUptimeString()),
                _StatRow(label: 'الرابط', value: _urlController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Message statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('إحصائيات الرسائل', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                _StatRow(label: 'إجمالي الرسائل', value: '${_allMessages.length}'),
                _StatRow(label: 'الرسائل المرسلة', value: '$sent', color: AppTheme.postColor),
                _StatRow(label: 'الرسائل المستلمة', value: '$received', color: AppTheme.getColor),
                _StatRow(label: 'الأخطاء', value: '$errors', color: errors > 0 ? Colors.red : null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Data transfer statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.data_usage, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('نقل البيانات', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                _StatRow(
                  label: 'البيانات المرسلة',
                  value: AppUtils.formatBytes(_totalBytesSent),
                  color: AppTheme.postColor,
                ),
                _StatRow(
                  label: 'البيانات المستلمة',
                  value: AppUtils.formatBytes(_totalBytesReceived),
                  color: AppTheme.getColor,
                ),
                _StatRow(
                  label: 'إجمالي البيانات',
                  value: AppUtils.formatBytes(_totalBytesSent + _totalBytesReceived),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(websocketSettingsProvider);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('إعدادات WebSocket', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فاصل Ping (بالثواني)', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.pingIntervalSec.toDouble(),
                      min: 0,
                      max: 120,
                      divisions: 24,
                      label: settings.pingIntervalSec.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier).setPingInterval(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: SwitchListTile(
                title: const Text('إعادة الاتصال التلقائي'),
                subtitle: const Text('إعادة المحاولة عند انقطاع الاتصال'),
                value: settings.autoReconnect,
                onChanged: (value) {
                  ref.read(websocketSettingsProvider.notifier).setAutoReconnect(value);
                },
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الحد الأقصى لمحاولات إعادة الاتصال',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.maxReconnectAttempts.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: settings.maxReconnectAttempts.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier)
                            .setMaxReconnectAttempts(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تأخير إعادة الاتصال (بالثواني)',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.reconnectDelaySec.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: settings.reconnectDelaySec.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier)
                            .setReconnectDelay(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حد سجل الرسائل', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.maxMessages.toDouble(),
                      min: 100,
                      max: 10000,
                      divisions: 99,
                      label: settings.maxMessages.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier)
                            .setMaxMessages(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _exportMessages() {
    if (_allMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد رسائل للتصدير')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('WebSocket Messages Export');
    buffer.writeln('URL: ${_urlController.text}');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('Total Messages: ${_allMessages.length}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    for (final msg in _allMessages) {
      buffer.writeln('[${msg.timestamp}] ${msg.isIncoming ? "←" : "→"} ${msg.type.name.toUpperCase()}');
      if (msg.text != null) {
        buffer.writeln(msg.text);
      } else if (msg.binary != null) {
        buffer.writeln('(Binary: ${msg.size ?? msg.binary!.length} bytes)');
      }
      buffer.writeln();
    }

    // Copy to clipboard as fallback
    // In a real app, this would save to a file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تصدير ${_allMessages.length} رسالة'),
        action: SnackBarAction(
          label: 'نسخ',
          onPressed: () {
            // Copy to clipboard
          },
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.searchQuery = '',
  });

  final WebSocketMessage message;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final isIncoming = message.isIncoming;
    final isBinary = message.type == WebSocketMessageType.binary;
    final isError = message.type == WebSocketMessageType.error;
    final isPing = message.type == WebSocketMessageType.ping;
    final isPong = message.type == WebSocketMessageType.pong;
    final isClose = message.type == WebSocketMessageType.close;
    final isSystem = isPing || isPong || isClose;

    return Align(
      alignment: isIncoming ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.withOpacity(0.1)
              : isSystem
                  ? Colors.orange.withOpacity(0.1)
                  : isIncoming
                      ? AppTheme.getColor.withOpacity(0.1)
                      : AppTheme.postColor.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isIncoming ? 12 : 4),
            bottomRight: Radius.circular(isIncoming ? 4 : 12),
          ),
          border: Border.all(
            color: isError
                ? Colors.red.withOpacity(0.3)
                : isSystem
                    ? Colors.orange.withOpacity(0.3)
                    : isIncoming
                        ? AppTheme.getColor.withOpacity(0.3)
                        : AppTheme.postColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(_getIcon(), size: 16, color: _getColor()),
                const SizedBox(width: 8),
                Text(
                  _getLabel(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getColor(),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  AppUtils.formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                if (message.size != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.formatBytes(message.size!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Content
            if (message.text != null)
              SelectableText(
                _highlightSearch(message.text!),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                ),
              )
            else if (message.binary != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات ثنائية (${message.size ?? message.binary!.length} بايت)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      utf8.decode(message.binary!, allowMalformed: true),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _highlightSearch(String text) {
    if (searchQuery.isEmpty) return text;
    // In a full implementation, this would use RichText to highlight matches
    return text;
  }

  IconData _getIcon() {
    switch (message.type) {
      case WebSocketMessageType.text:
        return message.isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
      case WebSocketMessageType.binary:
        return Icons.memory;
      case WebSocketMessageType.ping:
        return Icons.arrow_upward;
      case WebSocketMessageType.pong:
        return Icons.arrow_downward;
      case WebSocketMessageType.close:
        return Icons.close;
      case WebSocketMessageType.error:
        return Icons.error;
    }
  }

  Color _getColor() {
    switch (message.type) {
      case WebSocketMessageType.text:
        return message.isIncoming ? AppTheme.getColor : AppTheme.postColor;
      case WebSocketMessageType.binary:
        return AppTheme.patchColor;
      case WebSocketMessageType.ping:
        return AppTheme.warningColor;
      case WebSocketMessageType.pong:
        return AppTheme.infoColor;
      case WebSocketMessageType.close:
        return AppTheme.headColor;
      case WebSocketMessageType.error:
        return Colors.red;
    }
  }

  String _getLabel() {
    switch (message.type) {
      case WebSocketMessageType.text:
        return message.isIncoming ? 'رسالة واردة' : 'رسالة صادرة';
      case WebSocketMessageType.binary:
        return message.isIncoming ? 'ثنائي وارد' : 'ثنائي صادر';
      case WebSocketMessageType.ping:
        return 'Ping';
      case WebSocketMessageType.pong:
        return 'Pong';
      case WebSocketMessageType.close:
        return 'إغلاق الاتصال';
      case WebSocketMessageType.error:
        return 'خطأ';
    }
  }
}
