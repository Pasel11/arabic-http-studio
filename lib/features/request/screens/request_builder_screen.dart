import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/network_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../favorites/models/favorite_item.dart';
import '../../favorites/repositories/favorites_repository.dart';
import '../../history/models/history_entry.dart';
import '../../history/repositories/history_repository.dart';
import '../../logs/repositories/logs_repository.dart';
import '../models/http_request.dart';
import '../providers/request_provider.dart';
import '../repositories/request_repository.dart';
import '../services/code_generator_service.dart';
import '../widgets/request_headers_widget.dart';
import '../widgets/request_body_widget.dart';
import '../widgets/request_params_widget.dart';
import '../widgets/request_auth_widget.dart';
import '../widgets/request_settings_widget.dart';
import '../widgets/response_viewer_widget.dart';
import '../widgets/code_preview_dialog.dart';

class RequestBuilderScreen extends ConsumerStatefulWidget {
  const RequestBuilderScreen({super.key, this.requestId});

  final String? requestId;

  @override
  ConsumerState<RequestBuilderScreen> createState() => _RequestBuilderScreenState();
}

class _RequestBuilderScreenState extends ConsumerState<RequestBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSending = false;
  HttpResponseData? _response;
  String? _error;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  String _method = 'GET';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequest();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _loadRequest() {
    if (widget.requestId != null) {
      final request = ref.read(requestRepositoryProvider).getById(widget.requestId!);
      if (request != null) {
        _nameController.text = request.name;
        _urlController.text = request.url;
        _method = request.method;
        ref.read(currentRequestProvider.notifier).setRequest(request);
      }
    } else {
      // Create new request
      final newRequest = HttpRequestModel(
        id: AppUtils.generateUuid(),
        name: 'طلب جديد',
        method: 'GET',
        url: 'https://',
      );
      ref.read(currentRequestProvider.notifier).setRequest(newRequest);
      _nameController.text = newRequest.name;
      _urlController.text = newRequest.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRequest = ref.watch(currentRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_nameController.text.isEmpty ? 'طلب جديد' : _nameController.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveRequest,
            tooltip: 'حفظ',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showCodeDialog(context),
            tooltip: 'توليد الكود',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleMenuAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'copy_curl', child: Text('نسخ كـ cURL')),
              const PopupMenuItem(value: 'duplicate', child: Text('تكرار')),
              const PopupMenuItem(value: 'add_favorite', child: Text('إضافة للمفضلة')),
              const PopupMenuItem(value: 'pin', child: Text('تثبيت')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الرؤوس'),
            Tab(text: 'المعاملات'),
            Tab(text: 'المتن'),
            Tab(text: 'المصادقة'),
            Tab(text: 'الكوكيز'),
            Tab(text: 'متقدم'),
            Tab(text: 'الاستجابة'),
          ],
        ),
      ),
      body: currentRequest == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // URL bar
                _buildUrlBar(context),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const RequestHeadersWidget(),
                      const RequestParamsWidget(),
                      const RequestBodyWidget(),
                      const RequestAuthWidget(),
                      _buildCookiesTab(context),
                      const RequestSettingsWidget(),
                      ResponseViewerWidget(
                        response: _response,
                        error: _error,
                        isLoading: _isSending,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUrlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم الطلب',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(currentRequestProvider.notifier).updateName(value);
            },
          ),
          const SizedBox(height: 8),
          // Method + URL + Send
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _method,
                  underline: const SizedBox(),
                  items: AppConstants.httpMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(
                        method,
                        style: TextStyle(
                          color: AppTheme.getMethodColor(method),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _method = value);
                      ref.read(currentRequestProvider.notifier).updateMethod(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://api.example.com/endpoint',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    ref.read(currentRequestProvider.notifier).updateUrl(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSending ? null : _sendRequest,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('إرسال'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCookiesTab(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final request = ref.watch(currentRequestProvider);
        if (request == null) return const SizedBox.shrink();

        final cookies = request.cookies;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الكوكيز', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCookie(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cookies.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('لا توجد كوكيز. اضغط + للإضافة')),
                ),
              )
            else
              ...cookies.map((cookie) => _buildCookieItem(context, cookie)),
          ],
        );
      },
    );
  }

  Widget _buildCookieItem(BuildContext context, CookieItem cookie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Switch(
          value: cookie.enabled,
          onChanged: (value) {
            ref.read(currentRequestProvider.notifier).updateCookie(
                  cookie.copyWith(enabled: value),
                );
          },
        ),
        title: Text(cookie.key),
        subtitle: Text(AppUtils.maskValue(cookie.value)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCookie(context, cookie),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(currentRequestProvider.notifier).removeCookie(cookie.key);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCookie(BuildContext context) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة كوكي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'المفتاح'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'القيمة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                ref.read(currentRequestProvider.notifier).addCookie(
                      CookieItem(
                        key: keyController.text,
                        value: valueController.text,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editCookie(BuildContext context, CookieItem cookie) {
    final keyController = TextEditingController(text: cookie.key);
    final valueController = TextEditingController(text: cookie.value);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل كوكي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'المفتاح'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'القيمة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              ref.read(currentRequestProvider.notifier).removeCookie(cookie.key);
              ref.read(currentRequestProvider.notifier).addCookie(
                    CookieItem(
                      key: keyController.text,
                      value: valueController.text,
                      enabled: cookie.enabled,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    final request = ref.read(currentRequestProvider);
    if (request == null) return;

    setState(() {
      _isSending = true;
      _error = null;
      _response = null;
    });

    // Switch to response tab
    _tabController.animateTo(6);

    try {
      await ref.read(logsRepositoryProvider).info(
        'request',
        'إرسال طلب: ${request.method} ${request.url}',
      );

      final response = await NetworkService.instance.executeRequest(request);

      setState(() {
        _response = response;
        _isSending = false;
      });

      // Save to history
      final historyEntry = HistoryEntry(
        id: AppUtils.generateUuid(),
        requestId: request.id,
        requestName: request.name,
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        statusText: response.statusMessage,
        responseTimeMs: response.durationMs,
        responseSizeBytes: response.sizeBytes,
        requestSizeBytes: 0,
        responseHeaders: response.headers,
        responseBody: response.body,
        requestHeaders: request.enabledHeaders,
        requestBody: request.body?.rawContent,
        timestamp: DateTime.now(),
        isSuccess: response.isSuccess,
        timeline: response.timeline,
        contentType: response.contentType,
      );

      await ref.read(historyRepositoryProvider).save(historyEntry);

      await ref.read(logsRepositoryProvider).info(
        'response',
        'استلام استجابة: ${response.statusCode} (${response.durationMs}ms)',
      );
    } catch (e, stackTrace) {
      setState(() {
        _error = e.toString();
        _isSending = false;
      });

      await ref.read(logsRepositoryProvider).error(
        'request',
        'فشل الطلب: $e',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  Future<void> _saveRequest() async {
    final request = ref.read(currentRequestProvider);
    if (request == null) return;

    await ref.read(requestRepositoryProvider).save(request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ بنجاح')),
      );
    }
  }

  void _showCodeDialog(BuildContext context) {
    final request = ref.read(currentRequestProvider);
    if (request == null) return;

    showDialog(
      context: context,
      builder: (context) => CodePreviewDialog(request: request),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    final request = ref.read(currentRequestProvider);
    if (request == null) return;

    switch (action) {
      case 'copy_curl':
        final curl = CodeGeneratorService.instance.generateCurl(request);
        _copyToClipboard(curl);
        break;
      case 'duplicate':
        final duplicated = request.copyWith(
          id: AppUtils.generateUuid(),
          name: '${request.name} (نسخة)',
        );
        ref.read(requestRepositoryProvider).save(duplicated);
        break;
      case 'add_favorite':
        final isFav =
            ref.read(favoritesRepositoryProvider).isFavorite(request.id);
        if (isFav) {
          await ref
              .read(favoritesRepositoryProvider)
              .removeByRequestId(request.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت الإزالة من المفضلة')),
            );
          }
        } else {
          final favorite = FavoriteItem(
            id: AppUtils.generateUuid(),
            requestId: request.id,
            name: request.name,
            method: request.method,
            url: request.url,
            addedAt: DateTime.now(),
            tags: request.tags,
          );
          await ref.read(favoritesRepositoryProvider).add(favorite);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت الإضافة إلى المفضلة')),
            );
          }
        }
        break;
      case 'pin':
        ref.read(requestRepositoryProvider).togglePin(request.id);
        break;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ إلى الحافظة')),
    );
  }
}
