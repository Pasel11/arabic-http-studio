import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/models/auth_config.dart';
import '../providers/request_provider.dart';

class RequestAuthWidget extends ConsumerStatefulWidget {
  const RequestAuthWidget({super.key});

  @override
  ConsumerState<RequestAuthWidget> createState() => _RequestAuthWidgetState();
}

class _RequestAuthWidgetState extends ConsumerState<RequestAuthWidget> {
  String _authType = 'none';

  @override
  void initState() {
    super.initState();
    final request = ref.read(currentRequestProvider);
    _authType = request?.auth?.type ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(currentRequestProvider);
    if (request == null) return const SizedBox.shrink();

    final auth = request.auth;
    _authType = auth?.type ?? 'none';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('المصادقة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Auth type selector
        Wrap(
          spacing: 8,
          children: [
            _buildTypeChip('none', 'بدون'),
            _buildTypeChip('bearer', 'Bearer Token'),
            _buildTypeChip('basic', 'Basic Auth'),
            _buildTypeChip('digest', 'Digest Auth'),
            _buildTypeChip('apiKey', 'API Key'),
            _buildTypeChip('jwt', 'JWT'),
            _buildTypeChip('custom', 'مخصص'),
          ],
        ),
        const SizedBox(height: 16),
        // Auth config based on type
        _buildAuthConfig(context, auth),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _authType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() => _authType = type);
          if (type == 'none') {
            ref.read(currentRequestProvider.notifier).updateAuth(null);
          } else {
            ref.read(currentRequestProvider.notifier).updateAuth(
                  AuthConfig(type: type),
                );
          }
        }
      },
    );
  }

  Widget _buildAuthConfig(BuildContext context, AuthConfig? auth) {
    switch (_authType) {
      case 'none':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.lock_open, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 8),
                const Text('بدون مصادقة'),
              ],
            ),
          ),
        );
      case 'bearer':
        return _BearerAuthConfig(auth: auth);
      case 'basic':
        return _BasicAuthConfig(auth: auth);
      case 'digest':
        return _DigestAuthConfig(auth: auth);
      case 'apiKey':
        return _ApiKeyAuthConfig(auth: auth);
      case 'jwt':
        return _JwtAuthConfig(auth: auth);
      case 'custom':
        return _CustomAuthConfig(auth: auth);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BearerAuthConfig extends ConsumerWidget {
  const _BearerAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenController = TextEditingController(text: auth?.token ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bearer Token', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'الرمز (Token)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'bearer')).copyWith(token: value),
                    );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إضافة الرأس: Authorization: Bearer <token>',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicAuthConfig extends ConsumerWidget {
  const _BasicAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController(text: auth?.username ?? '');
    final passwordController = TextEditingController(text: auth?.password ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Authentication', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'basic')).copyWith(username: value),
                    );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'basic')).copyWith(password: value),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DigestAuthConfig extends ConsumerWidget {
  const _DigestAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController(text: auth?.username ?? '');
    final passwordController = TextEditingController(text: auth?.password ?? '');
    final realmController = TextEditingController(text: auth?.realm ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digest Authentication', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'digest')).copyWith(username: value),
                    );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'digest')).copyWith(password: value),
                    );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: realmController,
              decoration: const InputDecoration(
                labelText: 'Realm',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'digest')).copyWith(realm: value),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyAuthConfig extends ConsumerWidget {
  const _ApiKeyAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = TextEditingController(text: auth?.apiKey ?? '');
    final headerController = TextEditingController(text: auth?.apiKeyHeader ?? 'X-API-Key');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'apiKey')).copyWith(apiKey: value),
                    );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: headerController,
              decoration: const InputDecoration(
                labelText: 'اسم الرأس / معامل الاستعلام',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'apiKey')).copyWith(apiKeyHeader: value),
                    );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('الموقع: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('رأس'),
                  selected: auth?.apiKeyLocation == 'header',
                  onSelected: (_) {
                    ref.read(currentRequestProvider.notifier).updateAuth(
                          (auth ?? AuthConfig(type: 'apiKey')).copyWith(apiKeyLocation: 'header'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('استعلام'),
                  selected: auth?.apiKeyLocation == 'query',
                  onSelected: (_) {
                    ref.read(currentRequestProvider.notifier).updateAuth(
                          (auth ?? AuthConfig(type: 'apiKey')).copyWith(apiKeyLocation: 'query'),
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JwtAuthConfig extends ConsumerWidget {
  const _JwtAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenController = TextEditingController(text: auth?.token ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JWT Token', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'JWT Token',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                ref.read(currentRequestProvider.notifier).updateAuth(
                      (auth ?? AuthConfig(type: 'jwt')).copyWith(token: value),
                    );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إضافة JWT في رأس Authorization',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomAuthConfig extends ConsumerStatefulWidget {
  const _CustomAuthConfig({this.auth});

  final AuthConfig? auth;

  @override
  ConsumerState<_CustomAuthConfig> createState() => _CustomAuthConfigState();
}

class _CustomAuthConfigState extends ConsumerState<_CustomAuthConfig> {
  late Map<String, String> _headers;

  @override
  void initState() {
    super.initState();
    _headers = Map<String, String>.from(widget.auth?.customHeaders ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مصادقة مخصصة', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addHeader,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'رؤوس مخصصة',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ..._headers.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _headers.remove(entry.key);
                      });
                      _saveAuth();
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _addHeader() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة رأس مخصص'),
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
                setState(() {
                  _headers[keyController.text] = valueController.text;
                });
                _saveAuth();
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _saveAuth() {
    ref.read(currentRequestProvider.notifier).updateAuth(
          (widget.auth ?? AuthConfig(type: 'custom')).copyWith(customHeaders: _headers),
        );
  }
}
