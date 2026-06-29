import 'dart:async';
import 'dart:convert';

import '../contracts/ai_provider.dart';
import '../providers/ai_provider_registry.dart';
import '../providers/ai_settings_provider.dart';
import '../../request/models/http_request.dart';
import '../../history/models/history_entry.dart';

/// Central AI service that coordinates between providers and features.
///
/// This service is the main entry point for all AI-powered features.
/// It handles provider selection, prompt building, and response processing.
///
/// The service is designed to be:
/// - **Optional**: AI features can be disabled entirely
/// - **Provider-agnostic**: Works with any registered AI provider
/// - **Contextual**: Builds appropriate prompts based on the feature
///
/// Example:
/// ```dart
/// final result = await AiService.instance.explainError(
///   statusCode: 404,
///   response: entry,
/// );
/// ```
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  /// Gets the currently active provider.
  ///
  /// Returns `null` if AI is disabled or no provider is configured.
  AiProvider? get activeProvider {
    final settings = AiSettingsProvider.instance.settings;
    if (!settings.enabled) return null;

    final provider = AiProviderRegistry.instance.getProvider(settings.activeProviderId);
    if (provider == null || !provider.isConfigured) return null;

    return provider;
  }

  /// Whether AI features are available.
  bool get isAvailable => activeProvider != null;

  /// Explains an HTTP error.
  ///
  /// Analyzes the status code, response body, and headers to provide
  /// a human-readable explanation of what went wrong and how to fix it.
  Future<AiFeatureResult> explainError({
    required int statusCode,
    required HistoryEntry response,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في بروتوكول HTTP وتحليل الأخطاء.
مهمتك هي شرح أخطاء HTTP بالعربية بشكل واضح ومفيد.

يجب أن يتضمن شرحك:
1. معنى رمز الحالة
2. السبب المحتمل للخطأ
3. خطوات الحل المقترحة

كن موجزًا ومباشرًا. استخدم التنسيق Markdown.''';

    final userMessage = '''رمز الحالة: $statusCode
الرابط: ${response.url}
الطريقة: ${response.method}
الاستجابة: ${response.responseBody?.substring(0, response.responseBody!.length.clamp(0, 2000)) ?? 'لا يوجد'}

اشرح هذا الخطأ.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.3,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Suggests fixes for a failed request.
  Future<AiFeatureResult> suggestFix({
    required HttpRequestModel request,
    required HistoryEntry response,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في تطوير واجهات برمجة التطبيقات (API).
مهمتك هي اقتراح إصلاحات للطلبات الفاشلة.

حلل الطلب والاستجابة، ثم اقترح:
1. المشاكل المحتملة
2. الإصلاحات المقترحة (مع الكود إذا لزم الأمر)
3. أفضل الممارسات

استخدم التنسيق Markdown.''';

    final userMessage = '''الطلب:
الطريقة: ${request.method}
الرابط: ${request.url}
الرؤوس: ${_formatHeaders(request.headers)}
المتن: ${request.body?.rawContent ?? 'لا يوجد'}

الاستجابة:
رمز الحالة: ${response.statusCode}
الاستجابة: ${response.responseBody?.substring(0, response.responseBody!.length.clamp(0, 2000)) ?? 'لا يوجد'}

اقترح إصلاحات.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.4,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Optimizes request headers.
  Future<AiFeatureResult> optimizeHeaders({
    required HttpRequestModel request,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في تحسين طلبات HTTP.
مهمتك هي اقتراح رؤوس (Headers) أفضل للطلب.

حلل الطلب الحالي واقترح:
1. رؤوس مفقودة يجب إضافتها
2. رؤوس غير ضرورية يجب إزالتها
3. تحسينات على الرؤوس الحالية

قدم النتائج بصيغة JSON:
{"suggestions": [{"action": "add|remove|modify", "key": "...", "value": "...", "reason": "..."}]}''';

    final userMessage = '''الطلب:
الطريقة: ${request.method}
الرابط: ${request.url}
الرؤوس الحالية: ${_formatHeaders(request.headers)}
نوع المتن: ${request.body?.type ?? 'none'}''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.3,
    );

    // Try to parse suggestions from JSON
    final suggestions = <String>[];
    try {
      final jsonStart = aiResponse.content.indexOf('{');
      final jsonEnd = aiResponse.content.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = aiResponse.content.substring(jsonStart, jsonEnd + 1);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final suggestionsList = decoded['suggestions'] as List<dynamic>? ?? [];
        for (final s in suggestionsList) {
          final suggestion = s as Map<String, dynamic>;
          suggestions.add('${suggestion['action']}: ${suggestion['key']} = ${suggestion['value']} (${suggestion['reason']})');
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors
    }

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
      suggestions: suggestions,
    );
  }

  /// Suggests authentication configuration.
  Future<AiFeatureResult> suggestAuth({
    required HttpRequestModel request,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في مصادقة APIs.
مهمتك هي اقتراح أفضل طريقة مصادقة للطلب.

حلل الطلب واقترح:
1. نوع المصادقة المناسب (Bearer, Basic, API Key, OAuth, JWT)
2. كيفية تكوينها
3. أفضل الممارسات الأمنية

استخدم التنسيق Markdown.''';

    final userMessage = '''الطلب:
الطريقة: ${request.method}
الرابط: ${request.url}
الرؤوس الحالية: ${_formatHeaders(request.headers)}
المصادقة الحالية: ${request.auth?.type ?? 'none'}''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.4,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Explains a response status code.
  Future<AiFeatureResult> explainStatusCode({
    required int statusCode,
    String? responseHeaders,
    String? responseBody,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في بروتوكول HTTP.
اشرح رمز الحالة المُعطى بشكل واضح ومفصل بالعربية.

يتضمن الشرح:
1. المعنى الرسمي للرمز
2. متى يحدث عادةً
3. ما يجب فعله عند استلامه
4. الفرق بينه وبين الرموز المشابهة

استخدم التنسيق Markdown.''';

    final userMessage = '''رمز الحالة: $statusCode
${responseHeaders != null ? 'الرؤوس:\n$responseHeaders\n' : ''}
${responseBody != null ? 'الاستجابة:\n${responseBody.substring(0, responseBody.length.clamp(0, 1000))}\n' : ''}
اشرح هذا الرمز.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.3,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Summarizes a long response.
  Future<AiFeatureResult> summarizeResponse({
    required String responseBody,
    String? contentType,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في تحليل وتلخيص استجابات APIs.
مهمتك هي تلخيص الاستجابة بشكل موجز وواضح بالعربية.

يتضمن التلخيص:
1. نوع البيانات المُستلمة
2. النقاط الرئيسية
3. أي أخطاء أو تحذيرات
4. الحقول المهمة (إن وجدت)

استخدم التنسيق Markdown. كن موجزًا.''';

    final userMessage = '''نوع المحتوى: ${contentType ?? 'غير معروف'}
حجم الاستجابة: ${responseBody.length} حرف

الاستجابة:
${responseBody.substring(0, responseBody.length.clamp(0, 4000))}

لخّص هذه الاستجابة.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.3,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Generates a request from natural language description.
  Future<AiFeatureResult> generateRequest({
    required String description,
    String? baseUrl,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في إنشاء طلبات HTTP.
مهمتك هي تحويل وصف نصي إلى طلب HTTP كامل.

أعد النتيجة بصيغة JSON فقط (بدون نص إضافي):
{
  "method": "GET|POST|PUT|PATCH|DELETE",
  "url": "الرابط الكامل",
  "headers": [{"key": "...", "value": "..."}],
  "queryParams": [{"key": "...", "value": "..."}],
  "body": {"type": "json", "content": "..."},
  "auth": {"type": "bearer|basic|apiKey|none"}
}''';

    final userMessage = '''${baseUrl != null ? 'الرابط الأساسي: $baseUrl\n' : ''}الوصف: $description

أنشئ طلب HTTP مطابق.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.2,
    );

    // Try to parse the generated request
    Map<String, dynamic>? generatedRequest;
    try {
      final jsonStart = aiResponse.content.indexOf('{');
      final jsonEnd = aiResponse.content.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = aiResponse.content.substring(jsonStart, jsonEnd + 1);
        generatedRequest = jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (_) {
      // Ignore parsing errors
    }

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
      metadata: generatedRequest != null ? {'request': generatedRequest} : {},
    );
  }

  /// Generates code from a request in multiple languages.
  Future<AiFeatureResult> generateCode({
    required HttpRequestModel request,
    required String language,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت خبير في توليد الكود.
مهمتك هي توليد كود $language من طلب HTTP المُعطى.

أعد الكود فقط بدون شرح إضافي. استخدم أفضل الممارسات.''';

    final userMessage = '''الطريقة: ${request.method}
الرابط: ${request.url}
الرؤوس: ${_formatHeaders(request.headers)}
المتن: ${request.body?.rawContent ?? 'لا يوجد'}

ولّد كود $language.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.2,
    );

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
    );
  }

  /// Searches history using natural language.
  Future<AiFeatureResult> searchHistory({
    required String query,
    required List<HistoryEntry> history,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    final systemPrompt = '''أنت مساعد للبحث في سجل طلبات HTTP.
مهمتك هي العثور على الطلبات المطابقة لوصف المستخدم.

أعد النتائج بصيغة JSON:
{"matches": [{"id": "...", "reason": "..."}]}''';

    // Limit history size to avoid token overflow
    final limitedHistory = history.take(100).map((h) => {
          'id': h.id,
          'method': h.method,
          'url': h.url,
          'statusCode': h.statusCode,
          'timestamp': h.timestamp.toIso8601String(),
        }).toList();

    final userMessage = '''سجل الطلبات:
${jsonEncode(limitedHistory)}

سؤال المستخدم: $query

أوجد الطلبات المطابقة.''';

    final aiResponse = await provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.2,
    );

    // Parse matching IDs
    final suggestions = <String>[];
    try {
      final jsonStart = aiResponse.content.indexOf('{');
      final jsonEnd = aiResponse.content.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = aiResponse.content.substring(jsonStart, jsonEnd + 1);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final matches = decoded['matches'] as List<dynamic>? ?? [];
        for (final m in matches) {
          final match = m as Map<String, dynamic>;
          suggestions.add('${match['id']}: ${match['reason']}');
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

    return AiFeatureResult(
      content: aiResponse.content,
      tokensUsed: aiResponse.tokensUsed,
      suggestions: suggestions,
    );
  }

  /// Generic chat method for custom AI interactions.
  Future<AiResponse> chat({
    required String systemPrompt,
    required String userMessage,
    String? context,
    double? temperature,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    return provider.chat(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      context: context,
      temperature: temperature,
    );
  }

  /// Generic streaming chat method.
  Stream<String> chatStream({
    required String systemPrompt,
    required String userMessage,
    String? context,
    double? temperature,
  }) async* {
    final provider = activeProvider;
    if (provider == null) {
      throw StateError('الذكاء الاصطناعي غير مُفعّل أو غير مُكوّن');
    }

    yield* provider.chatStream(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      context: context,
      temperature: temperature,
    );
  }

  String _formatHeaders(List<dynamic> headers) {
    if (headers.isEmpty) return 'لا يوجد';
    return headers
        .where((h) => (h as dynamic).enabled as bool? ?? true)
        .map((h) => '${(h as dynamic).key}: ${h.value}')
        .join('\n');
  }
}
