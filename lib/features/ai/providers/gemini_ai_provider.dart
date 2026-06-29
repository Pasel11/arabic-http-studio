import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../contracts/ai_provider.dart';

/// Google Gemini AI provider.
///
/// This provider connects to Google's Gemini API and supports:
/// - Text generation via `generateContent` endpoint
/// - Streaming responses via `streamGenerateContent`
/// - Model selection (default: gemini-2.5-flash)
/// - Custom base URL for proxies or alternative endpoints
/// - Comprehensive error handling with user-friendly messages
///
/// The provider is completely independent from the OpenAI provider,
/// following the same [AiProvider] contract for seamless integration.
///
/// Example:
/// ```dart
/// final provider = GeminiAiProvider(config);
/// final response = await provider.chat(
///   systemPrompt: 'You are helpful',
///   userMessage: 'Hello',
/// );
/// ```
class GeminiAiProvider implements AiProvider {
  /// Creates a Google Gemini AI provider.
  GeminiAiProvider(this._config);

  final AiProviderConfig _config;
  HttpClient? _client;

  @override
  String get id => _config.providerId.isEmpty ? 'gemini' : _config.providerId;

  @override
  String get displayName => 'Google Gemini';

  @override
  String get description =>
      'مزود Google Gemini - يدعم نماذج Gemini المختلفة مع بث الاستجابات';

  @override
  bool get requiresApiKey => true;

  @override
  bool get isConfigured => _config.apiKey.isNotEmpty;

  @override
  int get maxTokens => _config.maxTokens;

  /// Default Gemini model.
  static const String defaultModel = 'gemini-2.5-flash';

  /// Available Gemini models.
  static const List<String> availableModels = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
  ];

  @override
  String? validateConfiguration() {
    if (_config.apiKey.isEmpty) {
      return 'مفتاح Gemini API مطلوب';
    }
    return null;
  }

  /// Gets the API base URL.
  String get _apiBaseUrl {
    if (_config.baseUrl != null && _config.baseUrl!.isNotEmpty) {
      final url = _config.baseUrl!;
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
    return 'https://generativelanguage.googleapis.com';
  }

  /// Gets the model to use.
  String get _model => _config.model ?? defaultModel;

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
      final contents = <Map<String, dynamic>>[];

      // Gemini uses systemInstruction for system prompts
      // User message
      contents.add({
        'role': 'user',
        'parts': [{'text': userMessage}],
      });

      // If there's additional context, prepend it
      if (context != null && context.isNotEmpty) {
        contents.insert(0, {
          'role': 'user',
          'parts': [{'text': '$systemPrompt\n\n$context'}],
        });
      }

      final requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [{'text': systemPrompt}],
        },
        'generationConfig': {
          'temperature': temperature ?? _config.temperature,
          'maxOutputTokens': maxTokens ?? _config.maxTokens,
        },
      };

      final uri = Uri.parse(
        '$_apiBaseUrl/v1beta/models/$_model:generateContent?key=${_config.apiKey}',
      );

      final request = await _httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        Duration(seconds: _config.timeoutSeconds),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        return AiResponse(
          content: '',
          tokensUsed: 0,
          model: _model,
          error: _parseError(response.statusCode, responseBody),
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      // Extract text from candidates[0].content.parts[0].text
      final candidates = decoded['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) {
        // Check for prompt feedback
        final promptFeedback = decoded['promptFeedback'];
        if (promptFeedback != null) {
          final blockReason = promptFeedback['blockReason'];
          if (blockReason != null) {
            return AiResponse(
              content: '',
              tokensUsed: 0,
              model: _model,
              error: 'تم حظر الطلب: $blockReason',
            );
          }
        }
        return AiResponse(
          content: '',
          tokensUsed: 0,
          model: _model,
          error: 'لا توجد استجابة من Gemini',
        );
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>? ?? {};
      final parts = content['parts'] as List<dynamic>? ?? [];

      if (parts.isEmpty) {
        final finishReason = candidate['finishReason'];
        return AiResponse(
          content: '',
          tokensUsed: 0,
          model: _model,
          error: 'استجاجة فارغة. سبب الانتهاء: $finishReason',
        );
      }

      final firstPart = parts.first as Map<String, dynamic>;
      final text = firstPart['text'] as String? ?? '';

      // Extract usage metadata
      final usageMetadata = decoded['usageMetadata'] as Map<String, dynamic>? ?? {};
      final tokensUsed = usageMetadata['totalTokenCount'] as int? ?? 0;

      return AiResponse(
        content: text,
        tokensUsed: tokensUsed,
        model: _model,
        finishReason: candidate['finishReason'] as String?,
      );
    } catch (e) {
      return AiResponse(
        content: '',
        tokensUsed: 0,
        model: _model,
        error: _parseException(e),
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
      final contents = <Map<String, dynamic>>[
        {
          'role': 'user',
          'parts': [{'text': userMessage}],
        },
      ];

      final requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [{'text': systemPrompt}],
        },
        'generationConfig': {
          'temperature': temperature ?? _config.temperature,
          'maxOutputTokens': maxTokens ?? _config.maxTokens,
        },
      };

      final uri = Uri.parse(
        '$_apiBaseUrl/v1beta/models/$_model:streamGenerateContent'
        '?key=${_config.apiKey}&alt=sse',
      );

      final request = await _httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        Duration(seconds: _config.timeoutSeconds),
      );

      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        yield 'خطأ: ${_parseError(response.statusCode, body)}';
        return;
      }

      await for (final chunk in response.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty || data == '[DONE]') continue;

            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              final candidates = decoded['candidates'] as List<dynamic>? ?? [];
              if (candidates.isNotEmpty) {
                final candidate = candidates.first as Map<String, dynamic>;
                final content = candidate['content'] as Map<String, dynamic>? ?? {};
                final parts = content['parts'] as List<dynamic>? ?? [];
                if (parts.isNotEmpty) {
                  final firstPart = parts.first as Map<String, dynamic>;
                  final text = firstPart['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
              }
            } catch (_) {
              // Ignore malformed chunks
            }
          }
        }
      }
    } catch (e) {
      yield 'خطأ في البث: ${_parseException(e)}';
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

  /// Parses HTTP error status codes into user-friendly Arabic messages.
  String _parseError(int statusCode, String responseBody) {
    String detail = '';
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      if (error != null) {
        detail = error['message'] as String? ?? '';
      }
    } catch (_) {
      // Use raw response if not JSON
      detail = responseBody;
    }

    switch (statusCode) {
      case 400:
        return 'طلب غير صالح (400): $detail';
      case 401:
        return 'مفتاح API غير صالح (401) - تأكد من صحة مفتاح Gemini API';
      case 403:
        return 'تم رفض الوصول (403) - تحقق من صلاحيات مفتاح API';
      case 404:
        return 'النموذج غير موجود (404) - تأكد من اسم النموذج: $_model';
      case 429:
        return 'تم تجاوز الحصة (429) - لقد تجاوزت حد الطلبات. حاول لاحقًا';
      case 500:
        return 'خطأ في خادم Gemini (500): $detail';
      case 503:
        return 'الخدمة غير متاحة (503) - Gemini غير متاح حاليًا';
      default:
        return 'خطأ HTTP $statusCode: $detail';
    }
  }

  /// Parses exceptions into user-friendly Arabic messages.
  String _parseException(dynamic e) {
    if (e is SocketException) {
      return 'خطأ في الاتصال بالشبكة - تحقق من اتصالك بالإنترنت';
    }
    if (e is TimeoutException) {
      return 'انتهت مهلة الاتصال - حاول مرة أخرى';
    }
    if (e is HandshakeException) {
      return 'فشل في مصافحة SSL - تحقق من إعدادات الشبكة';
    }
    return 'خطأ غير متوقع: $e';
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}
