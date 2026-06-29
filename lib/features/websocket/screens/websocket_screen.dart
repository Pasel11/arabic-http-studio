import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/websocket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/websocket_message.dart';
import '../providers/websocket_provider.dart';

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
  bool _autoScroll = true;
  bool _isConnected = false;
  String? _connectionId;
  final List<WebSocketMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (!AppUtils.isValidWebSocketUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط WebSocket غير صالح')),
      );
      return;
    }

    setState(() => _isConnected = true);

    try {
      _connectionId = await WebSocketService.instance.connect(
        url: url,
        pingInterval: const Duration(seconds: 30),
        autoReconnect: true,
      );

      // Listen to messages
      WebSocketService.instance.getMessageStream(_connectionId!).listen((message) {
        setState(() {
          _messages.add(message);
        });
        if (_autoScroll) {
          _scrollToBottom();
        }
      });

      // Listen to state changes
      WebSocketService.instance.getStateStream(_connectionId!).listen((state) {
        setState(() {
          _isConnected = state == WebSocketConnectionState.connected;
        });
      });

      setState(() => _isConnected = true);
    } catch (e) {
      setState(() => _isConnected = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال: $e')),
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
    setState(() => _messages.clear());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket'),
        actions: [
          // Connection status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isConnected ? 'متصل' : 'غير متصل',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearMessages,
            tooltip: 'مسح الرسائل',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الرسائل'),
            Tab(text: 'الإعدادات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesTab(context),
          _buildSettingsTab(context),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    return Column(
      children: [
        // URL bar
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
                  ),
                  enabled: !_isConnected,
                ),
              ),
              const SizedBox(width: 8),
              if (_isConnected)
                FilledButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.stop),
                  label: const Text('قطع'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                )
              else
                FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('اتصال'),
                ),
            ],
          ),
        ),
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('لا توجد رسائل'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),
        // Auto scroll toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Switch(
                value: _autoScroll,
                onChanged: (value) => setState(() => _autoScroll = value),
              ),
              const Text('تمرير تلقائي'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.network_ping),
                tooltip: 'Ping',
                onPressed: _isConnected ? _sendPing : null,
              ),
            ],
          ),
        ),
        // Message input
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
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  enabled: _isConnected,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isConnected ? _sendMessage : null,
                icon: const Icon(Icons.send),
                label: const Text('إرسال'),
              ),
            ],
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
            // Ping interval
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
            // Auto reconnect
            Card(
              child: SwitchListTile(
                title: const Text('إعادة الاتصال التلقائي'),
                value: settings.autoReconnect,
                onChanged: (value) {
                  ref.read(websocketSettingsProvider.notifier).setAutoReconnect(value);
                },
              ),
            ),
            // Max reconnect attempts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الحد الأقصى لمحاولات إعادة الاتصال', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.maxReconnectAttempts.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: settings.maxReconnectAttempts.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier).setMaxReconnectAttempts(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Reconnect delay
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تأخير إعادة الاتصال (بالثواني)', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.reconnectDelaySec.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: settings.reconnectDelaySec.toString(),
                      onChanged: (value) {
                        ref.read(websocketSettingsProvider.notifier).setReconnectDelay(value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Message history limit
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
                        ref.read(websocketSettingsProvider.notifier).setMaxMessages(value.round());
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final WebSocketMessage message;

  @override
  Widget build(BuildContext context) {
    final isIncoming = message.isIncoming;
    final isBinary = message.type == WebSocketMessageType.binary;
    final isError = message.type == WebSocketMessageType.error;
    final isPing = message.type == WebSocketMessageType.ping;
    final isPong = message.type == WebSocketMessageType.pong;
    final isClose = message.type == WebSocketMessageType.close;

    return Align(
      alignment: isIncoming ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.withOpacity(0.1)
              : isPing || isPong
                  ? Colors.orange.withOpacity(0.1)
                  : isClose
                      ? Colors.grey.withOpacity(0.1)
                      : isIncoming
                          ? AppTheme.getColor.withOpacity(0.1)
                          : AppTheme.postColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIcon(),
                  size: 16,
                  color: _getColor(),
                ),
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
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Content
            if (message.text != null)
              SelectableText(
                message.text!,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
              )
            else if (message.binary != null)
              SelectableText(
                'بيانات ثنائية (${message.size ?? message.binary!.length} بايت)\n${utf8.decode(message.binary!, allowMalformed: true)}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (message.type) {
      case WebSocketMessageType.text:
        return Icons.text_snippet;
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
        return AppTheme.deleteColor;
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
        return 'إغلاق';
      case WebSocketMessageType.error:
        return 'خطأ';
    }
  }
}
