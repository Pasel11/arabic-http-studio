import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../models/http_request.dart';
import '../providers/request_provider.dart';

class RequestBodyWidget extends ConsumerStatefulWidget {
  const RequestBodyWidget({super.key});

  @override
  ConsumerState<RequestBodyWidget> createState() => _RequestBodyWidgetState();
}

class _RequestBodyWidgetState extends ConsumerState<RequestBodyWidget> {
  String _bodyType = 'none';

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(currentRequestProvider);
    if (request == null) return const SizedBox.shrink();

    final body = request.body;
    _bodyType = body?.type ?? 'none';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('المتن', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Body type selector
        Wrap(
          spacing: 8,
          children: [
            _buildTypeChip('none', 'بدون'),
            _buildTypeChip('json', 'JSON'),
            _buildTypeChip('xml', 'XML'),
            _buildTypeChip('text', 'نص'),
            _buildTypeChip('html', 'HTML'),
            _buildTypeChip('form', 'نموذج'),
            _buildTypeChip('multipart', 'Multipart'),
            _buildTypeChip('binary', 'ثنائي'),
          ],
        ),
        const SizedBox(height: 16),
        // Body content based on type
        _buildBodyContent(context, body),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _bodyType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() => _bodyType = type);
          ref.read(currentRequestProvider.notifier).updateBody(
                BodyItem(type: type),
              );
        }
      },
    );
  }

  Widget _buildBodyContent(BuildContext context, BodyItem? body) {
    switch (_bodyType) {
      case 'none':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.block, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 8),
                const Text('لا يوجد متن'),
              ],
            ),
          ),
        );
      case 'json':
      case 'xml':
      case 'text':
      case 'html':
        return _RawBodyEditor(
          body: body,
          type: _bodyType,
        );
      case 'form':
        return _FormBodyEditor(body: body);
      case 'multipart':
        return _MultipartBodyEditor(body: body);
      case 'binary':
        return _BinaryBodyEditor(body: body);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RawBodyEditor extends ConsumerStatefulWidget {
  const _RawBodyEditor({required this.body, required this.type});

  final BodyItem? body;
  final String type;

  @override
  ConsumerState<_RawBodyEditor> createState() => _RawBodyEditorState();
}

class _RawBodyEditorState extends ConsumerState<_RawBodyEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.body?.rawContent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('محتوى ${widget.type.toUpperCase()}'),
            if (widget.type == 'json')
              IconButton(
                icon: const Icon(Icons.format_align_left),
                tooltip: 'تنسيق JSON',
                onPressed: _formatJson,
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 15,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          onChanged: (value) {
            ref.read(currentRequestProvider.notifier).updateBody(
                  BodyItem(
                    type: widget.type,
                    rawContent: value,
                  ),
                );
          },
        ),
      ],
    );
  }

  void _formatJson() {
    try {
      final text = _controller.text;
      final decoded = jsonDecode(text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _controller.text = formatted;
      ref.read(currentRequestProvider.notifier).updateBody(
            BodyItem(
              type: widget.type,
              rawContent: formatted,
            ),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON غير صالح: $e')),
      );
    }
  }
}

class _FormBodyEditor extends ConsumerStatefulWidget {
  const _FormBodyEditor({this.body});

  final BodyItem? body;

  @override
  ConsumerState<_FormBodyEditor> createState() => _FormBodyEditorState();
}

class _FormBodyEditorState extends ConsumerState<_FormBodyEditor> {
  late List<FormFieldItem> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List<FormFieldItem>.from(widget.body?.formFields ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('حقول النموذج'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addField,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._fields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Switch(
                    value: field.enabled,
                    onChanged: (value) => _updateField(index, field.copyWith(enabled: value)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'المفتاح',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _updateField(index, FormFieldItem(key: value, value: field.value, enabled: field.enabled)),
                          controller: TextEditingController(text: field.key),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'القيمة',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _updateField(index, FormFieldItem(key: field.key, value: value, enabled: field.enabled)),
                          controller: TextEditingController(text: field.value),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeField(index),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _addField() {
    setState(() {
      _fields.add(FormFieldItem(key: '', value: ''));
    });
    _saveBody();
  }

  void _updateField(int index, FormFieldItem field) {
    setState(() {
      _fields[index] = field;
    });
    _saveBody();
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
    _saveBody();
  }

  void _saveBody() {
    ref.read(currentRequestProvider.notifier).updateBody(
          BodyItem(
            type: 'form',
            formFields: _fields,
          ),
        );
  }
}

class _MultipartBodyEditor extends ConsumerStatefulWidget {
  const _MultipartBodyEditor({this.body});

  final BodyItem? body;

  @override
  ConsumerState<_MultipartBodyEditor> createState() => _MultipartBodyEditorState();
}

class _MultipartBodyEditorState extends ConsumerState<_MultipartBodyEditor> {
  late List<FormFieldItem> _formFields;
  late List<FileFieldItem> _fileFields;

  @override
  void initState() {
    super.initState();
    _formFields = List<FormFieldItem>.from(widget.body?.formFields ?? []);
    _fileFields = List<FileFieldItem>.from(widget.body?.fileFields ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form fields section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('حقول النص'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addFormField,
            ),
          ],
        ),
        ..._formFields.asMap().entries.map((entry) {
          return Card(
            child: ListTile(
              title: Text(entry.value.key),
              subtitle: Text(entry.value.value),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => _formFields.removeAt(entry.key)),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // File fields section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الملفات'),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _addFileField,
            ),
          ],
        ),
        ..._fileFields.asMap().entries.map((entry) {
          return Card(
            child: ListTile(
              title: Text(entry.value.fileName),
              subtitle: Text(entry.value.key),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => _fileFields.removeAt(entry.key)),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _addFormField() {
    setState(() {
      _formFields.add(FormFieldItem(key: 'field${_formFields.length + 1}', value: ''));
    });
    _saveBody();
  }

  Future<void> _addFileField() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _fileFields.add(FileFieldItem(
          key: 'file${_fileFields.length + 1}',
          filePath: file.path!,
          fileName: file.name,
        ));
      });
      _saveBody();
    }
  }

  void _saveBody() {
    ref.read(currentRequestProvider.notifier).updateBody(
          BodyItem(
            type: 'multipart',
            formFields: _formFields,
            fileFields: _fileFields,
          ),
        );
  }
}

class _BinaryBodyEditor extends ConsumerStatefulWidget {
  const _BinaryBodyEditor({this.body});

  final BodyItem? body;

  @override
  ConsumerState<_BinaryBodyEditor> createState() => _BinaryBodyEditorState();
}

class _BinaryBodyEditorState extends ConsumerState<_BinaryBodyEditor> {
  String? _filePath;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _filePath = widget.body?.filePath;
    _fileName = widget.body?.fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.upload_file, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(_fileName ?? 'لم يتم اختيار ملف'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('اختر ملفًا'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _filePath = file.path;
        _fileName = file.name;
      });
      ref.read(currentRequestProvider.notifier).updateBody(
            BodyItem(
              type: 'binary',
              filePath: _filePath,
              fileName: _fileName,
            ),
          );
    }
  }
}
