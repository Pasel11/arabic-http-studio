import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/ai/contracts/ai_provider.dart';

void main() {
  group('AiProviderConfig', () {
    test('should create with required fields', () {
      const config = AiProviderConfig(
        providerId: 'openai',
        apiKey: 'sk-test',
      );

      expect(config.providerId, 'openai');
      expect(config.apiKey, 'sk-test');
      expect(config.temperature, 0.7);
      expect(config.maxTokens, 4000);
      expect(config.timeoutSeconds, 60);
    });

    test('should copy with updates', () {
      const config = AiProviderConfig(
        providerId: 'openai',
        apiKey: 'sk-old',
      );

      final updated = config.copyWith(
        apiKey: 'sk-new',
        model: 'gpt-4',
        temperature: 0.5,
      );

      expect(updated.apiKey, 'sk-new');
      expect(updated.model, 'gpt-4');
      expect(updated.temperature, 0.5);
      expect(updated.providerId, 'openai');
    });

    test('should serialize to JSON', () {
      const config = AiProviderConfig(
        providerId: 'openai',
        apiKey: 'sk-test',
        model: 'gpt-4',
        temperature: 0.5,
      );

      final json = config.toJson();

      expect(json['providerId'], 'openai');
      expect(json['apiKey'], 'sk-test');
      expect(json['model'], 'gpt-4');
      expect(json['temperature'], 0.5);
    });

    test('should deserialize from JSON', () {
      final json = {
        'providerId': 'anthropic',
        'apiKey': 'sk-ant-test',
        'model': 'claude-3',
        'temperature': 0.3,
        'maxTokens': 2000,
        'timeoutSeconds': 30,
      };

      final config = AiProviderConfig.fromJson(json);

      expect(config.providerId, 'anthropic');
      expect(config.apiKey, 'sk-ant-test');
      expect(config.model, 'claude-3');
      expect(config.temperature, 0.3);
      expect(config.maxTokens, 2000);
    });

    test('should use defaults for missing fields', () {
      final json = {
        'providerId': 'test',
        'apiKey': 'key',
      };

      final config = AiProviderConfig.fromJson(json);

      expect(config.temperature, 0.7);
      expect(config.maxTokens, 4000);
      expect(config.timeoutSeconds, 60);
    });
  });

  group('AiResponse', () {
    test('should create successful response', () {
      const response = AiResponse(
        content: 'Hello',
        tokensUsed: 10,
        model: 'gpt-4',
      );

      expect(response.isSuccess, isTrue);
      expect(response.content, 'Hello');
      expect(response.tokensUsed, 10);
    });

    test('should detect error response', () {
      const response = AiResponse(
        content: '',
        tokensUsed: 0,
        model: 'gpt-4',
        error: 'Connection failed',
      );

      expect(response.isSuccess, isFalse);
      expect(response.error, 'Connection failed');
    });
  });

  group('AiFeatureType', () {
    test('should have all expected types', () {
      expect(AiFeatureType.values, contains(AiFeatureType.explainError));
      expect(AiFeatureType.values, contains(AiFeatureType.suggestFix));
      expect(AiFeatureType.values, contains(AiFeatureType.optimizeHeaders));
      expect(AiFeatureType.values, contains(AiFeatureType.suggestAuth));
      expect(AiFeatureType.values, contains(AiFeatureType.explainStatusCode));
      expect(AiFeatureType.values, contains(AiFeatureType.summarizeResponse));
      expect(AiFeatureType.values, contains(AiFeatureType.generateRequest));
      expect(AiFeatureType.values, contains(AiFeatureType.generateCode));
      expect(AiFeatureType.values, contains(AiFeatureType.searchHistory));
    });
  });

  group('AiFeatureResult', () {
    test('should create with content', () {
      const result = AiFeatureResult(
        content: 'Test content',
        tokensUsed: 50,
      );

      expect(result.content, 'Test content');
      expect(result.tokensUsed, 50);
      expect(result.suggestions, isEmpty);
    });

    test('should include suggestions', () {
      const result = AiFeatureResult(
        content: 'content',
        tokensUsed: 10,
        suggestions: ['suggestion 1', 'suggestion 2'],
      );

      expect(result.suggestions, hasLength(2));
    });

    test('should include metadata', () {
      const result = AiFeatureResult(
        content: 'content',
        tokensUsed: 10,
        metadata: {'key': 'value'},
      );

      expect(result.metadata['key'], 'value');
    });
  });
}
