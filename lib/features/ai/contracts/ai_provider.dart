/// Contracts and interfaces for AI providers.
///
/// This file defines the abstractions that all AI providers must implement,
/// enabling the application to work with any AI service (OpenAI, Anthropic,
/// Google Gemini, local models, etc.) without coupling to a specific vendor.
library;

import '../../request/models/http_request.dart';
import '../../history/models/history_entry.dart';

/// Contract that all AI providers must implement.
///
/// Implementations of this interface connect to a specific AI service
/// (e.g., OpenAI, Anthropic, Google Gemini) and provide AI-powered
/// features to the application.
///
/// To add a new AI provider:
/// 1. Create a class that implements [AiProvider]
/// 2. Register it in [AiProviderRegistry]
/// 3. Configure it in settings
abstract class AiProvider {
  /// Unique identifier for this provider.
  String get id;

  /// Human-readable display name.
  String get displayName;

  /// Description of the provider.
  String get description;

  /// Whether this provider requires an API key.
  bool get requiresApiKey;

  /// Whether this provider is currently configured and ready to use.
  bool get isConfigured;

  /// Maximum tokens supported by this provider.
  int get maxTokens;

  /// Validates the configuration.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  String? validateConfiguration();

  /// Sends a chat completion request and returns the response.
  ///
  /// [systemPrompt] sets the behavior of the AI.
  /// [userMessage] is the user's input.
  /// [context] provides additional context (optional).
  Future<AiResponse> chat({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  });

  /// Streams a chat completion response.
  ///
  /// Emits chunks of text as they are received from the AI service.
  Stream<String> chatStream({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  });

  /// Tests the connection to the AI service.
  ///
  /// Returns `true` if the connection is successful.
  Future<bool> testConnection();

  /// Releases any resources used by this provider.
  void dispose();
}

/// Response from an AI chat request.
class AiResponse {
  /// Creates an AI response.
  const AiResponse({
    required this.content,
    required this.tokensUsed,
    required this.model,
    this.finishReason,
    this.error,
  });

  /// The generated text content.
  final String content;

  /// Number of tokens used in this request.
  final int tokensUsed;

  /// The model that generated this response.
  final String model;

  /// The reason the generation finished.
  final String? finishReason;

  /// Error message if the request failed.
  final String? error;

  /// Whether the response was successful.
  bool get isSuccess => error == null;
}

/// Configuration for an AI provider.
class AiProviderConfig {
  /// Creates an AI provider configuration.
  const AiProviderConfig({
    required this.providerId,
    required this.apiKey,
    this.baseUrl,
    this.model,
    this.organizationId,
    this.temperature = 0.7,
    this.maxTokens = 4000,
    this.timeoutSeconds = 60,
  });

  /// The provider identifier (e.g., 'openai', 'anthropic').
  final String providerId;

  /// API key for authentication.
  final String apiKey;

  /// Base URL for the API (optional, for custom endpoints).
  final String? baseUrl;

  /// Specific model to use.
  final String? model;

  /// Organization ID (for providers that support it).
  final String? organizationId;

  /// Temperature for response generation (0.0 - 1.0).
  final double temperature;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Request timeout in seconds.
  final int timeoutSeconds;

  /// Creates a copy with updated fields.
  AiProviderConfig copyWith({
    String? providerId,
    String? apiKey,
    String? baseUrl,
    String? model,
    String? organizationId,
    double? temperature,
    int? maxTokens,
    int? timeoutSeconds,
  }) {
    return AiProviderConfig(
      providerId: providerId ?? this.providerId,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      organizationId: organizationId ?? this.organizationId,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'organizationId': organizationId,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'timeoutSeconds': timeoutSeconds,
      };

  /// Creates from JSON map.
  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    return AiProviderConfig(
      providerId: json['providerId'] as String,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String?,
      organizationId: json['organizationId'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4000,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 60,
    );
  }
}

/// AI feature type.
enum AiFeatureType {
  /// Explain an HTTP error.
  explainError,

  /// Suggest fixes for a request.
  suggestFix,

  /// Optimize request headers.
  optimizeHeaders,

  /// Suggest authentication configuration.
  suggestAuth,

  /// Explain a response status code.
  explainStatusCode,

  /// Summarize a long response.
  summarizeResponse,

  /// Generate a request from natural language.
  generateRequest,

  /// Generate code in multiple languages.
  generateCode,

  /// Search history using natural language.
  searchHistory,
}

/// Request for an AI feature.
class AiFeatureRequest {
  /// Creates an AI feature request.
  const AiFeatureRequest({
    required this.type,
    required this.userInput,
    this.request,
    this.response,
    this.history,
    this.language,
    this.additionalContext,
  });

  /// The type of AI feature.
  final AiFeatureType type;

  /// The user's input text.
  final String userInput;

  /// The HTTP request (if relevant).
  final HttpRequestModel? request;

  /// The HTTP response (if relevant).
  final HistoryEntry? response;

  /// Search history (for history search).
  final List<HistoryEntry>? history;

  /// Target language (for code generation).
  final String? language;

  /// Additional context.
  final String? additionalContext;
}

/// Result of an AI feature.
class AiFeatureResult {
  /// Creates an AI feature result.
  const AiFeatureResult({
    required this.content,
    required this.tokensUsed,
    this.suggestions = const [],
    this.metadata = const {},
  });

  /// The main content of the result.
  final String content;

  /// Number of tokens used.
  final int tokensUsed;

  /// Additional suggestions (e.g., suggested headers).
  final List<String> suggestions;

  /// Additional metadata.
  final Map<String, dynamic> metadata;
}
