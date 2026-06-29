import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../models/http_request.dart';
import '../services/code_generator_service.dart';

class CodePreviewDialog extends StatefulWidget {
  const CodePreviewDialog({super.key, required this.request});

  final HttpRequestModel request;

  @override
  State<CodePreviewDialog> createState() => _CodePreviewDialogState();
}

class _CodePreviewDialogState extends State<CodePreviewDialog> {
  String _selectedLanguage = 'curl';
  String _generatedCode = '';

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  void _generateCode() {
    setState(() {
      _generatedCode = CodeGeneratorService.instance.generate(
        widget.request,
        _selectedLanguage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'توليد الكود',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Language selector
            DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'curl', child: Text('cURL')),
                DropdownMenuItem(value: 'dart', child: Text('Dart (Dio)')),
                DropdownMenuItem(value: 'fetch', child: Text('JavaScript (Fetch)')),
                DropdownMenuItem(value: 'python', child: Text('Python (Requests)')),
                DropdownMenuItem(value: 'java', child: Text('Java (OkHttp)')),
                DropdownMenuItem(value: 'kotlin', child: Text('Kotlin')),
                DropdownMenuItem(value: 'php', child: Text('PHP (cURL)')),
                DropdownMenuItem(value: 'nodejs', child: Text('Node.js')),
                DropdownMenuItem(value: 'go', child: Text('Go')),
                DropdownMenuItem(value: 'rust', child: Text('Rust')),
                DropdownMenuItem(value: 'csharp', child: Text('C#')),
                DropdownMenuItem(value: 'javascript', child: Text('JavaScript (Axios)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  _generateCode();
                }
              },
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ'),
                  onPressed: _copyCode,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة'),
                  onPressed: _shareCode,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Code preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _generatedCode,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _generatedCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الكود')),
      );
    }
  }

  Future<void> _shareCode() async {
    await Share.share(_generatedCode);
  }
}
