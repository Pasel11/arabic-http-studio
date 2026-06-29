import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/http_request.dart';
import '../providers/request_provider.dart';

class RequestParamsWidget extends ConsumerWidget {
  const RequestParamsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(currentRequestProvider);
    if (request == null) return const SizedBox.shrink();

    final params = request.queryParams;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('معاملات الاستعلام', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addParam(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (params.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.query_stats, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 8),
                  const Text('لا توجد معاملات'),
                  const SizedBox(height: 4),
                  const Text('اضغط + لإضافة معامل'),
                ],
              ),
            ),
          )
        else
          ...params.map((param) => _ParamItemWidget(param: param)),
      ],
    );
  }

  void _addParam(BuildContext context, WidgetRef ref) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة معامل'),
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
                ref.read(currentRequestProvider.notifier).addQueryParam(
                      QueryParam(
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
}

class _ParamItemWidget extends ConsumerWidget {
  const _ParamItemWidget({required this.param});

  final QueryParam param;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = TextEditingController(text: param.key);
    final valueController = TextEditingController(text: param.value);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                  value: param.enabled,
                  onChanged: (value) {
                    ref.read(currentRequestProvider.notifier).updateQueryParam(
                          param.copyWith(enabled: value),
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
                      ref.read(currentRequestProvider.notifier).updateQueryParam(
                            param.copyWith(key: value),
                          );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(currentRequestProvider.notifier).removeQueryParam(param.key);
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
                ref.read(currentRequestProvider.notifier).updateQueryParam(
                      param.copyWith(value: value),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
