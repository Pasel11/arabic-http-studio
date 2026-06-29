import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/http_request.dart';
import '../providers/request_provider.dart';

class RequestHeadersWidget extends ConsumerWidget {
  const RequestHeadersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(currentRequestProvider);
    if (request == null) return const SizedBox.shrink();

    final headers = request.headers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('الرؤوس', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addHeader(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (headers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.http, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 8),
                  const Text('لا توجد رؤوس'),
                  const SizedBox(height: 4),
                  const Text('اضغط + لإضافة رأس'),
                ],
              ),
            ),
          )
        else
          ...headers.map((header) => _HeaderItemWidget(header: header)),
        const SizedBox(height: 16),
        // Common headers section
        Text('رؤوس شائعة', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _commonHeaders.map((header) {
            return ActionChip(
              label: Text(header),
              onPressed: () {
                ref.read(currentRequestProvider.notifier).addHeader(
                      HeaderItem(key: header, value: ''),
                    );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addHeader(BuildContext context, WidgetRef ref) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة رأس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'المفتاح',
                hintText: 'Content-Type',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'القيمة',
                hintText: 'application/json',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                ref.read(currentRequestProvider.notifier).addHeader(
                      HeaderItem(
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

  static const _commonHeaders = [
    'Content-Type',
    'Accept',
    'Authorization',
    'User-Agent',
    'Accept-Language',
    'Accept-Encoding',
    'Cache-Control',
    'Cookie',
    'X-Requested-With',
    'X-API-Key',
  ];
}

class _HeaderItemWidget extends ConsumerWidget {
  const _HeaderItemWidget({required this.header});

  final HeaderItem header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = TextEditingController(text: header.key);
    final valueController = TextEditingController(text: header.value);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                  value: header.enabled,
                  onChanged: (value) {
                    ref.read(currentRequestProvider.notifier).updateHeader(
                          header.copyWith(enabled: value),
                        );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'المفتاح',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref.read(currentRequestProvider.notifier).updateHeader(
                            header.copyWith(key: value),
                          );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(currentRequestProvider.notifier).removeHeader(header.key);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'القيمة',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateHeader(
                      header.copyWith(value: value),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
