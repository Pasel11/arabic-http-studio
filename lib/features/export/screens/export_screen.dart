import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

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
///
/// This screen allows users to export their data in various formats
/// and import data from external sources.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _selectedFormat = 'json';
  final _fileNameController =
      TextEditingController(text: 'arabic_http_studio_export');

  /// All supported export formats with labels.
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
          // Export section
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
                            setState(() => _selectedFormat = format['value'] as String);
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

          // Import section
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
                    'استورد بياناتك من ملف. الصيغ المدعومة:\n'
                    '• OpenAPI 3.0 / Swagger 2.0\n'
                    '• Postman Collections v2.1\n'
                    '• JSON, YAML, CSV, TXT',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('اختر ملفًا للاستيراد'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text('معلومات',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('سيتم تصدير جميع البيانات بما في ذلك:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const _ExportListItem(text: 'الطلبات المحفوظة'),
                  const _ExportListItem(text: 'المحفوظات'),
                  const _ExportListItem(text: 'المفضلة'),
                  const _ExportListItem(text: 'المجموعات'),
                  const _ExportListItem(text: 'البيئات'),
                  const _ExportListItem(text: 'المتغيرات (بدون الأسرار المشفرة)'),
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

      String filePath;

      // Handle special formats
      if (_selectedFormat == 'openapi' || _selectedFormat == 'swagger' || _selectedFormat == 'postman') {
        filePath = await ExportService.instance.exportData(
          requests: requests,
          history: history,
          favorites: favorites,
          collections: collections,
          environments: environments,
          variables: variables,
          format: _selectedFormat,
          fileName: _fileNameController.text,
        );
      } else {
        filePath = await ExportService.instance.exportData(
          requests: requests,
          history: history,
          favorites: favorites,
          collections: collections,
          environments: environments,
          variables: variables,
          format: _selectedFormat,
          fileName: _fileNameController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التصدير بنجاح: $filePath')),
        );
        await Share.shareXFiles([XFile(filePath)]);
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
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path!;
      final fileContent = await _readFile(filePath);
      final extension = filePath.split('.').last.toLowerCase();

      final importResult = ImportService.instance.importFromString(
        fileContent,
        extension,
      );

      // Save imported requests
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

  Future<String> _readFile(String filePath) async {
    final file = File(filePath);
    return file.readAsString();
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
