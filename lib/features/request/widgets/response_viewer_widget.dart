import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/network_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class ResponseViewerWidget extends StatefulWidget {
  const ResponseViewerWidget({
    super.key,
    required this.response,
    required this.error,
    required this.isLoading,
  });

  final HttpResponseData? response;
  final String? error;
  final bool isLoading;

  @override
  State<ResponseViewerWidget> createState() => _ResponseViewerWidgetState();
}

class _ResponseViewerWidgetState extends State<ResponseViewerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _viewMode = 'pretty'; // pretty, raw, hex, base64
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري إرسال الطلب...'),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return _buildErrorView(context);
    }

    if (widget.response == null) {
      return _buildEmptyView(context);
    }

    final response = widget.response!;

    return Column(
      children: [
        // Status bar
        _buildStatusBar(context, response),
        // Tab bar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الاستجابة'),
            Tab(text: 'الرؤوس'),
            Tab(text: 'الخط الزمني'),
            Tab(text: 'الكوكيز'),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResponseBodyTab(context, response),
              _buildHeadersTab(context, response),
              _buildTimelineTab(context, response),
              _buildCookiesTab(context, response),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context, HttpResponseData response) {
    final statusColor = AppTheme.getStatusColor(response.statusCode);

    return Container(
      padding: const EdgeInsets.all(12),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${response.statusCode}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _StatusItem(
                  label: 'الوقت',
                  value: AppUtils.formatDuration(Duration(milliseconds: response.durationMs)),
                ),
                _StatusItem(
                  label: 'الحجم',
                  value: AppUtils.formatBytes(response.sizeBytes),
                ),
                _StatusItem(
                  label: 'النوع',
                  value: response.contentType ?? 'غير معروف',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseBodyTab(BuildContext context, HttpResponseData response) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // View mode selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pretty', label: Text('منسّق')),
                  ButtonSegment(value: 'raw', label: Text('خام')),
                  ButtonSegment(value: 'hex', label: Text('Hex')),
                  ButtonSegment(value: 'base64', label: Text('Base64')),
                ],
                selected: {_viewMode},
                onSelectionChanged: (selection) {
                  setState(() => _viewMode = selection.first);
                },
              ),
              const Spacer(),
              // Search
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'بحث في الاستجابة...',
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'نسخ',
                onPressed: () => _copyToClipboard(response.body),
              ),
            ],
          ),
        ),
        // Body content
        Expanded(
          child: SingleChildScrollView(
            child: _buildBodyContent(context, response),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context, HttpResponseData response) {
    final body = response.body;
    final contentType = response.contentType ?? '';

    // If it's an image, show image preview
    if (contentType.contains('image')) {
      return Image.memory(
        Uint8List.fromList(response.bodyBytes),
        errorBuilder: (context, error, _) => _buildCodeView(context, 'فشل تحميل الصورة: $error'),
      );
    }

    switch (_viewMode) {
      case 'raw':
        return _buildCodeView(context, body);
      case 'hex':
        return _buildHexView(context, response.bodyBytes);
      case 'base64':
        return _buildCodeView(context, base64.encode(response.bodyBytes));
      case 'pretty':
      default:
        return _buildPrettyView(context, body, response.contentType);
    }
  }

  Widget _buildPrettyView(BuildContext context, String body, String? contentType) {
    if (contentType != null && contentType.contains('json')) {
      try {
        final decoded = jsonDecode(body);
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        return _buildCodeView(context, pretty, isJson: true);
      } catch (_) {
        return _buildCodeView(context, body);
      }
    }

    if (contentType != null && contentType.contains('xml')) {
      return _buildCodeView(context, body);
    }

    if (contentType != null && contentType.contains('html')) {
      return _buildCodeView(context, body);
    }

    return _buildCodeView(context, body);
  }

  Widget _buildCodeView(BuildContext context, String content, {bool isJson = false}) {
    final lines = content.split('\n');
    final filteredLines = _searchQuery.isEmpty
        ? lines
        : lines.where((line) => line.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: filteredLines.asMap().entries.map((entry) {
                  return Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filteredLines.map((line) {
                  return Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      color: _searchQuery.isNotEmpty && line.toLowerCase().contains(_searchQuery.toLowerCase())
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHexView(BuildContext context, List<int> bytes) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i += 16) {
      final end = (i + 16 > bytes.length) ? bytes.length : i + 16;
      final hex = bytes
          .sublist(i, end)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      final ascii = bytes
          .sublist(i, end)
          .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
          .join('');
      buffer.writeln('${i.toRadixString(16).padLeft(8, '0')}  $hex  $ascii');
    }
    return _buildCodeView(context, buffer.toString());
  }

  Widget _buildHeadersTab(BuildContext context, HttpResponseData response) {
    final headers = response.headers.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        final header = headers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              header.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(header.value),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyToClipboard('${header.key}: ${header.value}'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab(BuildContext context, HttpResponseData response) {
    if (response.timeline == null) {
      return const Center(child: Text('لا توجد بيانات الخط الزمني'));
    }

    final timeline = response.timeline!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TimelineItem(
          label: 'بحث DNS',
          duration: Duration(milliseconds: timeline.dnsLookupMs),
          color: AppTheme.getColor,
        ),
        _TimelineItem(
          label: 'الاتصال',
          duration: Duration(milliseconds: timeline.connectionMs),
          color: AppTheme.postColor,
        ),
        _TimelineItem(
          label: 'مصافحة SSL',
          duration: Duration(milliseconds: timeline.sslHandshakeMs),
          color: AppTheme.patchColor,
        ),
        _TimelineItem(
          label: 'الإرسال',
          duration: Duration(milliseconds: timeline.sendingMs),
          color: AppTheme.warningColor,
        ),
        _TimelineItem(
          label: 'الانتظار',
          duration: Duration(milliseconds: timeline.waitingMs),
          color: AppTheme.optionsColor,
        ),
        _TimelineItem(
          label: 'التنزيل',
          duration: Duration(milliseconds: timeline.downloadingMs),
          color: AppTheme.deleteColor,
        ),
        const Divider(),
        _TimelineItem(
          label: 'الإجمالي',
          duration: Duration(milliseconds: timeline.totalMs),
          color: AppTheme.infoColor,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildCookiesTab(BuildContext context, HttpResponseData response) {
    final cookies = response.responseCookies.entries.toList();

    if (cookies.isEmpty) {
      return const Center(child: Text('لا توجد كوكيز'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cookies.length,
      itemBuilder: (context, index) {
        final cookie = cookies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(cookie.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(cookie.value),
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'لم يتم إرسال الطلب بعد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('اضغط زر الإرسال لرؤية الاستجابة'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'فشل الطلب',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم النسخ إلى الحافظة')),
      );
    }
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.label,
    required this.duration,
    required this.color,
    this.isTotal = false,
  });

  final String label;
  final Duration duration;
  final Color color;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isTotal ? color.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              AppUtils.formatDuration(duration),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
