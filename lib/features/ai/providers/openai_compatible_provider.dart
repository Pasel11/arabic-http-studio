import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../contracts/ai_provider.dart';

/// A generic OpenAI-compatible AI provider.
///
/// This provider works with any API that follows the OpenAI chat completions
/// format, including:
/// - OpenAI (api.openai.com)
/// - Azure OpenAI
/// - Local models (Ollama, LM Studio, vLLM)
/// - Any OpenAI-compatible endpoint
///
/// To use a custom endpoint, set the [baseUrl] in the configuration.
class OpenAiCompatibleProvider implements AiProvider {
  /// Creates an OpenAI-compatible provider.
  OpenAiCompatibleProvider(this._config);

  final AiProviderConfig _config;
  HttpClient? _client;

  @override
  String get id => _config.providerId.isEmpty ? 'openai_compatible' : _config.providerId;

  @override
  String get displayName {
    if (_config.baseUrl != null && _config.baseUrl!.isNotEmpty) {
      final uri = Uri.tryParse(_config.baseUrl!);
      if (uri != null) {
        return 'مخصص (${uri.host})';
      }
    }
    return 'OpenAI';
  }

  @override
  String get description =>
      'مزود متوافق مع OpenAI - يدعم OpenAI، Azure، النماذج المحلية، وأي نقطة نهاية متوافقة';

  @override
  bool get requiresApiKey => true;

  @override
  bool get isConfigured => _config.apiKey.isNotEmpty || _isLocalEndpoint();

  @override
  int get maxTokens => _config.maxTokens;

  bool _isLocalEndpoint() {
    if (_config.baseUrl == null) return false;
    return _config.baseUrl!.contains('localhost') ||
        _config.baseUrl!.contains('127.0.0.1') ||
        _config.baseUrl!.contains('0.0.0.0');
  }

  @override
  String? validateConfiguration() {
    if (!_isLocalEndpoint() && _config.apiKey.isEmpty) {
      return 'مفتاح API مطلوب';
    }
    return null;
  }

  String get _apiBaseUrl {
    if (_config.baseUrl != null && _config.baseUrl!.isNotEmpty) {
      return _config.baseUrl!.endsWith('/')
          ? _config.baseUrl!.substring(0, _config.baseUrl!.length - 1)
          : _config.baseUrl!;
    }
    return 'https://api.openai.com';
  }

  String get _defaultModel {
    return _config.model ?? 'gpt-3.5-turbo';
  }

  HttpClient get _httpClient {
    _client ??= HttpClient();
    return _client!;
  }

  @override
  Future<AiResponse> chat({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      if (context != null && context.isNotEmpty) {
        messages.add({'role': 'system', 'content': context});
      }

      messages.add({'role': 'user', 'content': userMessage});

      final requestBody = {
        'model': _defaultModel,
        'messages': messages,
        'temperature': temperature ?? _config.temperature,
        'max_tokens': maxTokens ?? _config.maxTokens,
      };

      final uri = Uri.parse('$_apiBaseUrl/v1/chat/completions');
      final request = await _httpClient.postUrl(uri);

      // Headers
      request.headers.contentType = ContentType.json;
      if (_config.apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      }
      if (_config.organizationId != null) {
        request.headers.set('OpenAI-Organization', _config.organizationId!);
      }

      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        Duration(seconds: _config.timeoutSeconds),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        return AiResponse(
          content: '',
          tokensUsed: 0,
          model: _defaultModel,
          error: 'خطأ HTTP ${response.statusCode}: $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        return AiResponse(
          content: '',
          tokensUsed: 0,
          model: _defaultModel,
          error: 'لا توجد استجابة من النموذج',
        );
      }

      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>? ?? {};
      final content = message['content'] as String? ?? '';
      final usage = decoded['usage'] as Map<String, dynamic>? ?? {};

      return AiResponse(
        content: content,
        tokensUsed: usage['total_tokens'] as int? ?? 0,
        model: decoded['model'] as String? ?? _defaultModel,
        finishReason: choice['finish_reason'] as String?,
      );
    } catch (e) {
      return AiResponse(
        content: '',
        tokensUsed: 0,
        model: _defaultModel,
        error: 'خطأ في الاتصال: $e',
      );
    }
  }

  @override
  Stream<String> chatStream({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  }) async* {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      if (context != null && context.isNotEmpty) {
        messages.add({'role': 'system', 'content': context});
      }

      messages.add({'role': 'user', 'content': userMessage});

      final requestBody = {
        'model': _defaultModel,
        'messages': messages,
        'temperature': temperature ?? _config.temperature,
        'max_tokens': maxTokens ?? _config.maxTokens,
        'stream': true,
      };

      final uri = Uri.parse('$_apiBaseUrl/v1/chat/completions');
      final request = await _httpClient.postUrl(uri);

      request.headers.contentType = ContentType.json;
      if (_config.apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      }
      if (_config.organizationId != null) {
        request.headers.set('OpenAI-Organization', _config.organizationId!);
      }

      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        Duration(seconds: _config.timeoutSeconds),
      );

      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        yield 'خطأ: $body';
        return;
      }

      await for (final chunk in response.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;

            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              final choices = decoded['choices'] as List<dynamic>? ?? [];
              if (choices.isNotEmpty) {
                final choice = choices.first as Map<String, dynamic>;
                final delta = choice['delta'] as Map<String, dynamic>?;
                if (delta != null && delta['content'] != null) {
                  yield delta['content'] as String;
                }
              }
            } catch (_) {
              // Ignore malformed chunks
            }
          }
        }
      }
    } catch (e) {
      yield 'خطأ في البث: $e';
    }
  }

  @override
  Future<bool> testConnection() async {
    final response = await chat(
      systemPrompt: 'You are a test assistant.',
      userMessage: 'Say "hello" in one word.',
      maxTokens: 10,
    );
    return response.isSuccess;
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}
