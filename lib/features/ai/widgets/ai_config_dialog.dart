import 'package:flutter/material.dart';

import '../contracts/ai_provider.dart';
import '../providers/ai_provider_registry.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/openai_compatible_provider.dart';
import '../providers/gemini_ai_provider.dart';

/// Dialog for configuring AI providers.
///
/// Supports multiple AI providers:
/// - OpenAI (and OpenAI-compatible APIs)
/// - Google Gemini
/// - Custom OpenAI-compatible endpoints
///
/// Each provider can be configured independently with API key,
/// model selection, and optional base URL.
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

    _loadProviderConfig();
  }

  void _loadProviderConfig() {
    final config = AiSettingsProvider.instance.settings.providers[_selectedProviderId];
    _apiKeyController.text = config?.apiKey ?? '';
    _baseUrlController.text = config?.baseUrl ?? '';
    _modelController.text = config?.model ?? _getDefaultModel();
  }

  String _getDefaultModel() {
    switch (_selectedProviderId) {
      case 'gemini':
        return GeminiAiProvider.defaultModel;
      case 'openai':
      case 'custom':
      default:
        return 'gpt-3.5-turbo';
    }
  }

  String _getDefaultHint() {
    switch (_selectedProviderId) {
      case 'gemini':
        return GeminiAiProvider.defaultModel;
      case 'openai':
      case 'custom':
      default:
        return 'gpt-3.5-turbo';
    }
  }

  String _getKeyHint() {
    switch (_selectedProviderId) {
      case 'gemini':
        return 'AIza...';
      case 'openai':
      case 'custom':
      default:
        return 'sk-...';
    }
  }

  String _getUrlHint() {
    switch (_selectedProviderId) {
      case 'gemini':
        return 'https://generativelanguage.googleapis.com';
      case 'openai':
      case 'custom':
      default:
        return 'https://api.openai.com';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onProviderChanged(String providerId) {
    setState(() {
      _selectedProviderId = providerId;
      _testResult = null;
    });
    _loadProviderConfig();
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

    // Register the appropriate provider instance
    if (_enabled) {
      AiProvider? provider;
      switch (_selectedProviderId) {
        case 'gemini':
          provider = GeminiAiProvider(config);
        case 'openai':
        case 'custom':
        default:
          provider = OpenAiCompatibleProvider(config);
      }
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

      AiProvider provider;
      switch (_selectedProviderId) {
        case 'gemini':
          provider = GeminiAiProvider(config);
        case 'openai':
        case 'custom':
        default:
          provider = OpenAiCompatibleProvider(config);
      }

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
                    onSelected: (_) => _onProviderChanged('openai'),
                  ),
                  ChoiceChip(
                    label: const Text('Google Gemini'),
                    selected: _selectedProviderId == 'gemini',
                    onSelected: (_) => _onProviderChanged('gemini'),
                  ),
                  ChoiceChip(
                    label: const Text('مخصص'),
                    selected: _selectedProviderId == 'custom',
                    onSelected: (_) => _onProviderChanged('custom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // API Key
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: _selectedProviderId == 'gemini'
                      ? 'Gemini API Key'
                      : 'مفتاح API',
                  hintText: _getKeyHint(),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),

              // Model
              if (_selectedProviderId == 'gemini')
                DropdownButtonFormField<String>(
                  value: _modelController.text.isEmpty
                      ? GeminiAiProvider.defaultModel
                      : _modelController.text,
                  decoration: const InputDecoration(
                    labelText: 'النموذج',
                    border: OutlineInputBorder(),
                  ),
                  items: GeminiAiProvider.availableModels.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(model),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _modelController.text = value;
                    }
                  },
                )
              else
                TextField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'النموذج (اختياري)',
                    hintText: _getDefaultHint(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 12),

              // Base URL
              TextField(
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: 'الرابط الأساسي (اختياري)',
                  hintText: _getUrlHint(),
                  helperText: _selectedProviderId == 'gemini'
                      ? 'اتركه فارغًا لاستخدام Gemini الافتراضي'
                      : 'اتركه فارغًا لاستخدام OpenAI الافتراضي',
                  border: const OutlineInputBorder(),
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
