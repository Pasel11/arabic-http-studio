import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/request_provider.dart';

class RequestSettingsWidget extends ConsumerWidget {
  const RequestSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(currentRequestProvider);
    if (request == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('إعدادات متقدمة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),

        // Timeout
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المهلة (بالملي ثانية)', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '30000',
                  ),
                  controller: TextEditingController(
                    text: request.timeout?.toString() ?? '30000',
                  ),
                  onChanged: (value) {
                    final timeout = int.tryParse(value);
                    if (timeout != null) {
                      ref.read(currentRequestProvider.notifier).updateSettings(timeout: timeout);
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Follow redirects
        Card(
          child: SwitchListTile(
            title: const Text('متابعة التحويلات'),
            subtitle: const Text('Follow redirects'),
            value: request.followRedirects,
            onChanged: (value) {
              ref.read(currentRequestProvider.notifier).updateSettings(followRedirects: value);
            },
          ),
        ),

        // Max redirects
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحد الأقصى للتحويلات', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Slider(
                  value: request.maxRedirects.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: request.maxRedirects.toString(),
                  onChanged: (value) {
                    ref.read(currentRequestProvider.notifier).updateSettings(
                          maxRedirects: value.round(),
                        );
                  },
                ),
              ],
            ),
          ),
        ),

        // HTTP version
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إصدار HTTP', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['HTTP/1.1', 'HTTP/2', 'HTTP/3'].map((version) {
                    return ChoiceChip(
                      label: Text(version),
                      selected: request.httpVersion == version,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(currentRequestProvider.notifier).updateSettings(httpVersion: version);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Verify TLS
        Card(
          child: SwitchListTile(
            title: const Text('التحقق من شهادات TLS'),
            subtitle: const Text('Verify TLS certificates'),
            value: request.verifyTls,
            onChanged: (value) {
              ref.read(currentRequestProvider.notifier).updateSettings(verifyTls: value);
            },
          ),
        ),

        // Proxy settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إعدادات البروكسي', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('بدون'),
                      selected: request.proxyType == null,
                      onSelected: (_) {
                        ref.read(currentRequestProvider.notifier).updateSettings(
                              proxyType: null,
                              proxyHost: null,
                              proxyPort: null,
                            );
                      },
                    ),
                    ChoiceChip(
                      label: const Text('HTTP'),
                      selected: request.proxyType == 'http',
                      onSelected: (_) {
                        ref.read(currentRequestProvider.notifier).updateSettings(proxyType: 'http');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('SOCKS5'),
                      selected: request.proxyType == 'socks5',
                      onSelected: (_) {
                        ref.read(currentRequestProvider.notifier).updateSettings(proxyType: 'socks5');
                      },
                    ),
                  ],
                ),
                if (request.proxyType != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'مضيف البروكسي',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: request.proxyHost ?? ''),
                    onChanged: (value) {
                      ref.read(currentRequestProvider.notifier).updateSettings(proxyHost: value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'منفذ البروكسي',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: request.proxyPort?.toString() ?? '',
                    ),
                    onChanged: (value) {
                      final port = int.tryParse(value);
                      ref.read(currentRequestProvider.notifier).updateSettings(proxyPort: port);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
