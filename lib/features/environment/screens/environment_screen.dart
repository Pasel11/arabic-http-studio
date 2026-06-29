import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/environment_model.dart';
import '../repositories/environment_repository.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  @override
  Widget build(BuildContext context) {
    final environments = ref.watch(environmentRepositoryProvider).getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('البيئات'),
      ),
      body: environments.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: environments.length,
              itemBuilder: (context, index) {
                final env = environments[index];
                return _EnvironmentCard(environment: env);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEnvironment(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد بيئات'),
          const SizedBox(height: 8),
          const Text('أنشئ بيئات لإدارة متغيرات مختلفة (تطوير، إنتاج، اختبار)'),
        ],
      ),
    );
  }

  void _createEnvironment(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بيئة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final env = EnvironmentModel(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descController.text,
                );
                await ref.read(environmentRepositoryProvider).save(env);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentCard extends ConsumerStatefulWidget {
  const _EnvironmentCard({required this.environment});

  final EnvironmentModel environment;

  @override
  ConsumerState<_EnvironmentCard> createState() => _EnvironmentCardState();
}

class _EnvironmentCardState extends ConsumerState<_EnvironmentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final env = widget.environment;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              env.isActive ? Icons.check_circle : Icons.circle_outlined,
              color: env.isActive ? AppTheme.successColor : null,
            ),
            title: Text(env.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: env.description != null ? Text(env.description!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.power_settings_new),
                  tooltip: env.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                  onPressed: () {
                    ref.read(environmentRepositoryProvider).setActive(env.id);
                  },
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'delete') {
                      ref.read(environmentRepositoryProvider).delete(env.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المتغيرات (${env.variables.length})', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (env.variables.isEmpty)
                    const Text('لا توجد متغيرات')
                  else
                    ...env.variables.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Text(': '),
                            Expanded(
                              flex: 3,
                              child: Text(entry.value),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text('الأسرار (${env.secrets.length})', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (env.secrets.isEmpty)
                    const Text('لا توجد أسرار')
                  else
                    ...env.secrets.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontFamily: 'JetBrains Mono'),
                              ),
                            ),
                            const Text(': '),
                            const Text('••••••••'),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
