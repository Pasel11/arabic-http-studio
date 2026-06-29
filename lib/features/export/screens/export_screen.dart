import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../request/models/http_request.dart';
import '../../request/repositories/request_repository.dart';
import '../../history/repositories/history_repository.dart';
import '../../favorites/repositories/favorites_repository.dart';
import '../../collections/repositories/collections_repository.dart';
import '../../environment/repositories/environment_repository.dart';
import '../../variables/repositories/variables_repository.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

/// Export and Import screen.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _selectedFormat = 'json';
  final _fileNameController =
      TextEditingController(text: 'arabic_http_studio_export');

  static const _exportFormats = [
    {'value': 'json', 'label': 'JSON', 'icon': Icons.code},
    {'value': 'yaml', 'label': 'YAML', 'icon': Icons.code},
    {'value': 'csv', 'label': 'CSV', 'icon': Icons.table_chart},
    {'value': 'txt', 'label': 'TXT', 'icon': Icons.text_snippet},
    {'value': 'markdown', 'label': 'Markdown', 'icon': Icons.description},
    {'value': 'html', 'label': 'HTML', 'icon': Icons.web},
    {'value': 'openapi', 'label': 'OpenAPI 3.0', 'icon': Icons.api},
    {'value': 'swagger', 'label': 'Swagger 2.0', 'icon': Icons.api},
    {'value': 'postman', 'label': 'Postman', 'icon': Icons.collections_bookmark},
  ];

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد / تصدير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upload, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text('تصدير البيانات',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('صيغة التصدير',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _exportFormats.map((format) {
                      return ChoiceChip(
                        avatar: Icon(format['icon'] as IconData, size: 18),
                        label: Text(format['label'] as String),
                        selected: _selectedFormat == format['value'],
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                                () => _selectedFormat = format['value'] as String);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fileNameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الملف',
                      suffixText: '.$_selectedFormat',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.file_download),
                      label: const Text('تصدير'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text('استيراد البيانات',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'استورد بياناتك من ملف.\nالصيغ المدعومة: JSON, YAML, CSV, TXT',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('أدخل مسار الملف للاستيراد'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final requests = ref.read(requestRepositoryProvider).getAll();
      final history = ref.read(historyRepositoryProvider).getAll();
      final favorites = ref.read(favoritesRepositoryProvider).getAll();
      final collections = ref.read(collectionsRepositoryProvider).getAll();
      final environments = ref.read(environmentRepositoryProvider).getAll();
      final variables = ref.read(variablesRepositoryProvider).getAll();

      final filePath = await ExportService.instance.exportData(
        requests: requests,
        history: history,
        favorites: favorites,
        collections: collections,
        environments: environments,
        variables: variables,
        format: _selectedFormat,
        fileName: _fileNameController.text,
      );

      if (mounted) {
        // Copy path to clipboard instead of sharing
        await Clipboard.setData(ClipboardData(text: filePath));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التصدير بنجاح: $filePath (تم نسخ المسار)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التصدير: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    // Show dialog to input file path
    final pathController = TextEditingController();

    final filePath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد من ملف'),
        content: TextField(
          controller: pathController,
          decoration: const InputDecoration(
            labelText: 'مسار الملف',
            hintText: '/path/to/file.json',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, pathController.text.trim()),
            child: const Text('استيراد'),
          ),
        ],
      ),
    );

    if (filePath == null || filePath.isEmpty) return;

    try {
      final file = File(filePath);
      final fileContent = await file.readAsString();
      final extension = filePath.split('.').last.toLowerCase();

      final importResult = ImportService.instance.importFromString(
        fileContent,
        extension,
      );

      for (final request in importResult.requests) {
        await ref.read(requestRepositoryProvider).save(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استيراد ${importResult.requests.length} طلب من ${importResult.source}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاستيراد: $e')),
        );
      }
    }
  }
}

class _ExportListItem extends StatelessWidget {
  const _ExportListItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
