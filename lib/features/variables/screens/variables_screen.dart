import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/variable_model.dart';
import '../repositories/variables_repository.dart';

class VariablesScreen extends ConsumerStatefulWidget {
  const VariablesScreen({super.key});

  @override
  ConsumerState<VariablesScreen> createState() => _VariablesScreenState();
}

class _VariablesScreenState extends ConsumerState<VariablesScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, global, secret, dynamic

  @override
  Widget build(BuildContext context) {
    final variables = ref.watch(variablesRepositoryProvider).getAll();

    var filtered = variables;
    if (_searchQuery.isNotEmpty) {
      filtered = ref.read(variablesRepositoryProvider).search(_searchQuery);
    }

    switch (_filterType) {
      case 'global':
        filtered = filtered.where((v) => v.isGlobal).toList();
        break;
      case 'secret':
        filtered = filtered.where((v) => v.isEncrypted || v.type == 'secret').toList();
        break;
      case 'dynamic':
        filtered = filtered.where((v) => v.isDynamic).toList();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتغيرات'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في المتغيرات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip('all', 'الكل'),
                _buildFilterChip('global', 'عامة'),
                _buildFilterChip('secret', 'أسرار'),
                _buildFilterChip('dynamic', 'ديناميكية'),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final variable = filtered[index];
                      return _VariableItemTile(variable: variable);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVariable(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterType == type,
        onSelected: (_) => setState(() => _filterType = type),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد متغيرات'),
          const SizedBox(height: 8),
          const Text('أضف متغيرات لإعادة استخدامها في الطلبات'),
        ],
      ),
    );
  }

  void _addVariable(BuildContext context) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final descController = TextEditingController();
    bool isGlobal = false;
    bool isSecret = false;
    bool isDynamic = false;
    String type = 'string';
    String? dynamicType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('متغير جديد'),
          content: SingleChildScrollView(
            child: Column(
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
                  obscureText: isSecret,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('متغير عام'),
                  value: isGlobal,
                  onChanged: (v) => setState(() => isGlobal = v),
                ),
                SwitchListTile(
                  title: const Text('سري (مشفر)'),
                  value: isSecret,
                  onChanged: (v) {
                    setState(() {
                      isSecret = v;
                      if (v) type = 'secret';
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('ديناميكي'),
                  value: isDynamic,
                  onChanged: (v) => setState(() => isDynamic = v),
                ),
                if (isDynamic)
                  DropdownButton<String>(
                    value: dynamicType,
                    hint: const Text('نوع القيمة الديناميكية'),
                    items: const [
                      DropdownMenuItem(value: 'timestamp', child: Text('Timestamp')),
                      DropdownMenuItem(value: 'uuid', child: Text('UUID')),
                      DropdownMenuItem(value: 'random_number', child: Text('رقم عشوائي')),
                      DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                      DropdownMenuItem(value: 'time', child: Text('الوقت')),
                    ],
                    onChanged: (v) => setState(() => dynamicType = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (keyController.text.isNotEmpty) {
                  final variable = VariableModel(
                    id: AppUtils.generateUuid(),
                    key: keyController.text,
                    value: valueController.text,
                    type: type,
                    description: descController.text,
                    isGlobal: isGlobal,
                    isEncrypted: isSecret,
                    isDynamic: isDynamic,
                    dynamicType: dynamicType,
                  );
                  await ref.read(variablesRepositoryProvider).save(variable);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableItemTile extends ConsumerWidget {
  const _VariableItemTile({required this.variable});

  final VariableModel variable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSecret = variable.isEncrypted || variable.type == 'secret';
    final value = isSecret
        ? '••••••••'
        : ref.read(variablesRepositoryProvider).getValue(variable);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Row(
          children: [
            Text(
              variable.key,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
            ),
            if (variable.isGlobal) ...[
              const SizedBox(width: 8),
              const Icon(Icons.public, size: 16, color: Colors.blue),
            ],
            if (isSecret) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock, size: 16, color: Colors.red),
            ],
            if (variable.isDynamic) ...[
              const SizedBox(width: 8),
              const Icon(Icons.sync, size: 16, color: Colors.purple),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontFamily: 'JetBrains Mono'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (variable.description != null)
              Text(
                variable.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await ref.read(variablesRepositoryProvider).delete(variable.id);
          },
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (variable.isEncrypted || variable.type == 'secret') {
      return const Icon(Icons.lock, color: Colors.red);
    }
    if (variable.isDynamic) {
      return const Icon(Icons.sync, color: Colors.purple);
    }
    if (variable.isGlobal) {
      return const Icon(Icons.public, color: Colors.blue);
    }
    return const Icon(Icons.code, color: AppTheme.infoColor);
  }
}
