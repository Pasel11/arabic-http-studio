import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service.dart';
import '../providers/ai_settings_provider.dart';
import '../widgets/ai_chat_widget.dart';
import '../widgets/ai_config_dialog.dart';

/// AI Assistant screen.
///
/// This screen provides access to all AI-powered features:
/// - Chat with AI about HTTP requests and responses
/// - Configure AI providers
/// - Enable/disable AI features
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AiSettingsProvider.instance.load();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AiSettingsProvider.instance.settings;
    final isAvailable = AiService.instance.isAvailable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساعد الذكاء الاصطناعي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات الذكاء الاصطناعي',
            onPressed: () => _showConfigDialog(context),
          ),
        ],
      ),
      body: !settings.enabled
          ? _buildDisabledView(context)
          : !isAvailable
              ? _buildNotConfiguredView(context)
              : const AiChatWidget(),
    );
  }

  Widget _buildDisabledView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'الذكاء الاصطناعي غير مُفعّل',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'فعّل الذكاء الاصطناعي للحصول على مساعدة في:\n'
              '• شرح الأخطاء\n'
              '• اقتراح إصلاحات\n'
              '• تحسين الطلبات\n'
              '• توليد الكود\n'
              '• والكثير أكثر',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showConfigDialog(context),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('تفعيل الذكاء الاصطناعي'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConfiguredView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'مزود الذكاء الاصطناعي غير مُكوّن',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'يجب تكوين مزود ذكاء اصطناعي لاستخدام هذه الميزة.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showConfigDialog(context),
              icon: const Icon(Icons.settings),
              label: const Text('تكوين المزود'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AiConfigDialog(),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}
