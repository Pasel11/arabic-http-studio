import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Tools Hub screen - central access point for all developer tools.
///
/// This screen organizes all available tools into categories:
/// - JSON tools
/// - XML tools
/// - Encoding tools
/// - Crypto tools
/// - Sessions
/// - Comparison
/// - File Explorer
/// - Reports
class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأدوات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCategory(
            title: 'أدوات JSON',
            tools: [
              _ToolItem(
                icon: Icons.data_object,
                title: 'JSON Formatter',
                description: 'تنسيق وتجميل JSON',
                color: Colors.blue,
                onTap: () => context.push('/tools/json'),
              ),
              _ToolItem(
                icon: Icons.compare_arrows,
                title: 'JSON Compare',
                description: 'مقارنة ملفي JSON',
                color: Colors.blue,
                onTap: () => context.push('/tools/json/compare'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'أدوات XML',
            tools: [
              _ToolItem(
                icon: Icons.code,
                title: 'XML Formatter',
                description: 'تنسيق وتجميل XML',
                color: Colors.green,
                onTap: () => context.push('/tools/xml'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'الترميز والتشفير',
            tools: [
              _ToolItem(
                icon: Icons.translate,
                title: 'Base64',
                description: 'ترميز وفك ترميز Base64',
                color: Colors.orange,
                onTap: () => context.push('/tools/base64'),
              ),
              _ToolItem(
                icon: Icons.fingerprint,
                title: 'Hash',
                description: 'MD5, SHA1, SHA256, SHA512',
                color: Colors.purple,
                onTap: () => context.push('/tools/hash'),
              ),
              _ToolItem(
                icon: Icons.link,
                title: 'URL Encode/Decode',
                description: 'ترميز وفك ترميز URL',
                color: Colors.teal,
                onTap: () => context.push('/tools/url-encode'),
              ),
              _ToolItem(
                icon: Icons.text_fields,
                title: 'Unicode',
                description: 'ترميز وفك ترميز Unicode',
                color: Colors.indigo,
                onTap: () => context.push('/tools/unicode'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'إدارة الجلسات',
            tools: [
              _ToolItem(
                icon: Icons.save,
                title: 'الجلسات',
                description: 'حفظ واستعادة الجلسات',
                color: AppTheme.patchColor,
                onTap: () => context.push('/tools/sessions'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'المقارنة',
            tools: [
              _ToolItem(
                icon: Icons.compare_arrows,
                title: 'مقارنة الطلبات',
                description: 'مقارنة طلبين HTTP',
                color: Colors.red,
                onTap: () => context.push('/tools/compare/requests'),
              ),
              _ToolItem(
                icon: Icons.text_snippet,
                title: 'Text Diff',
                description: 'مقارنة نصية',
                color: Colors.red,
                onTap: () => context.push('/tools/compare/text'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'إدارة الملفات',
            tools: [
              _ToolItem(
                icon: Icons.folder,
                title: 'مستكشف الملفات',
                description: 'تصفح الملفات',
                color: Colors.brown,
                onTap: () => context.push('/tools/files'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'التقارير',
            tools: [
              _ToolItem(
                icon: Icons.assessment,
                title: 'إنشاء تقرير',
                description: 'تقارير احترافية',
                color: AppTheme.successColor,
                onTap: () => context.push('/tools/reports'),
              ),
            ],
          ),
          _ToolCategory(
            title: 'الذكاء الاصطناعي',
            tools: [
              _ToolItem(
                icon: Icons.psychology,
                title: 'مساعد AI',
                description: 'مساعد ذكي للطلبات',
                color: AppTheme.infoColor,
                onTap: () => context.push('/ai-assistant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolCategory extends StatelessWidget {
  const _ToolCategory({required this.title, required this.tools});

  final String title;
  final List<_ToolItem> tools;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) => tools[index],
        ),
      ],
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
