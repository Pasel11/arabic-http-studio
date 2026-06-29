import 'package:flutter/material.dart';

import '../contracts/ai_provider.dart';
import '../providers/ai_provider_registry.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/openai_compatible_provider.dart';

/// Dialog for configuring AI providers.
///
/// This dialog allows users to:
/// - Enable/disable AI features
/// - Select an AI provider
/// - Configure API keys and endpoints
/// - Test the connection
class AiConfigDialog extends StatefulWidget {
  const AiConfigDialog({super.key});

  @override
  State<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends State<AiConfigDialog> {
  late bool _enabled;
  late String _selectedProviderId;
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = AiSettingsProvider.instance.settings;
    _enabled = settings.enabled;
    _selectedProviderId = settings.activeProviderId.isNotEmpty
        ? settings.activeProviderId
        : 'openai';

    final config = settings.providers[_selectedProviderId];
    _apiKeyController.text = config?.apiKey ?? '';
    _baseUrlController.text = config?.baseUrl ?? '';
    _modelController.text = config?.model ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final config = AiProviderConfig(
      providerId: _selectedProviderId,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim().isEmpty
          ? null
          : _baseUrlController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
    );

    await AiSettingsProvider.instance.setProviderConfig(config);
    await AiSettingsProvider.instance.setActiveProvider(_selectedProviderId);
    await AiSettingsProvider.instance.setEnabled(_enabled);

    // Register the provider instance
    if (_enabled) {
      final provider = OpenAiCompatibleProvider(config);
      AiProviderRegistry.instance.register(provider);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الذكاء الاصطناعي')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final config = AiProviderConfig(
        providerId: _selectedProviderId,
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim().isEmpty
            ? null
            : _baseUrlController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
      );

      final provider = OpenAiCompatibleProvider(config);
      final success = await provider.testConnection();
      provider.dispose();

      setState(() {
        _testResult = success ? 'الاتصال ناجح ✓' : 'فشل الاتصال ✗';
      });
    } catch (e) {
      setState(() {
        _testResult = 'خطأ: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعدادات الذكاء الاصطناعي'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enable toggle
              SwitchListTile(
                title: const Text('تفعيل الذكاء الاصطناعي'),
                subtitle: const Text('السماح بميزات AI في التطبيق'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const Divider(),

              // Provider selection
              Text('المزود', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('OpenAI'),
                    selected: _selectedProviderId == 'openai',
                    onSelected: (_) =>
                        setState(() => _selectedProviderId = 'openai'),
                  ),
                  ChoiceChip(
                    label: const Text('مخصص'),
                    selected: _selectedProviderId == 'custom',
                    onSelected: (_) =>
                        setState(() => _selectedProviderId = 'custom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // API Key
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'مفتاح API',
                  hintText: 'sk-...',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),

              // Base URL
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'الرابط الأساسي (اختياري)',
                  hintText: 'https://api.openai.com',
                  helperText: 'اتركه فارغًا لاستخدام OpenAI الافتراضي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Model
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'النموذج (اختياري)',
                  hintText: 'gpt-3.5-turbo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Test button
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: const Text('اختبار الاتصال'),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testResult!.contains('✓')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
