import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/authentication/models/auth_config.dart';
import 'package:arabic_http_studio/features/request/models/http_request.dart';

void main() {
  group('HttpRequestModel', () {
    test('creates instance with required fields', () {
      final request = HttpRequestModel(
        id: 'test-id',
        name: 'Test Request',
        method: 'GET',
        url: 'https://api.example.com/test',
      );

      expect(request.id, 'test-id');
      expect(request.name, 'Test Request');
      expect(request.method, 'GET');
      expect(request.url, 'https://api.example.com/test');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = HttpRequestModel(
        id: 'test-id',
        name: 'Original',
        method: 'GET',
        url: 'https://example.com',
      );

      final copied = original.copyWith(name: 'Updated', method: 'POST');

      expect(copied.name, 'Updated');
      expect(copied.method, 'POST');
      expect(copied.url, 'https://example.com');
      expect(copied.id, original.id);
    });

    test('toJson serializes correctly', () {
      final request = HttpRequestModel(
        id: 'test-id',
        name: 'Test',
        method: 'GET',
        url: 'https://example.com',
        headers: [HeaderItem(key: 'Content-Type', value: 'application/json')],
      );

      final json = request.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test');
      expect(json['method'], 'GET');
      expect(json['url'], 'https://example.com');
      expect((json['headers'] as List).length, 1);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'Test',
        'method': 'POST',
        'url': 'https://example.com',
        'headers': [
          {'key': 'Content-Type', 'value': 'application/json', 'enabled': true}
        ],
        'queryParams': [],
        'cookies': [],
        'isPinned': false,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'followRedirects': true,
        'maxRedirects': 5,
        'httpVersion': 'HTTP/1.1',
        'verifyTls': true,
      };

      final request = HttpRequestModel.fromJson(json);

      expect(request.id, 'test-id');
      expect(request.name, 'Test');
      expect(request.method, 'POST');
      expect(request.headers.length, 1);
    });

    test('enabledHeaders returns only enabled headers', () {
      final request = HttpRequestModel(
        id: 'test-id',
        name: 'Test',
        method: 'GET',
        url: 'https://example.com',
        headers: [
          HeaderItem(key: 'Enabled', value: 'true', enabled: true),
          HeaderItem(key: 'Disabled', value: 'false', enabled: false),
        ],
      );

      final headers = request.enabledHeaders;

      expect(headers.length, 1);
      expect(headers['Enabled'], 'true');
      expect(headers.containsKey('Disabled'), isFalse);
    });

    test('enabledQueryParams returns only enabled params', () {
      final request = HttpRequestModel(
        id: 'test-id',
        name: 'Test',
        method: 'GET',
        url: 'https://example.com',
        queryParams: [
          QueryParam(key: 'page', value: '1', enabled: true),
          QueryParam(key: 'disabled', value: 'x', enabled: false),
        ],
      );

      final params = request.enabledQueryParams;

      expect(params.length, 1);
      expect(params['page'], '1');
    });

    test('toJsonString and fromJsonString work correctly', () {
      final original = HttpRequestModel(
        id: 'test-id',
        name: 'Test',
        method: 'GET',
        url: 'https://example.com',
      );

      final jsonString = original.toJsonString();
      final restored = HttpRequestModel.fromJsonString(jsonString);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.method, original.method);
      expect(restored.url, original.url);
    });
  });

  group('HeaderItem', () {
    test('creates instance', () {
      final header = HeaderItem(key: 'Content-Type', value: 'application/json');
      expect(header.key, 'Content-Type');
      expect(header.value, 'application/json');
      expect(header.enabled, isTrue);
    });

    test('toJson serializes correctly', () {
      final header = HeaderItem(key: 'Key', value: 'Value', description: 'Test');
      final json = header.toJson();

      expect(json['key'], 'Key');
      expect(json['value'], 'Value');
      expect(json['enabled'], isTrue);
      expect(json['description'], 'Test');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'key': 'Content-Type',
        'value': 'application/json',
        'enabled': true,
        'description': null,
      };

      final header = HeaderItem.fromJson(json);

      expect(header.key, 'Content-Type');
      expect(header.value, 'application/json');
    });

    test('copyWith works correctly', () {
      final original = HeaderItem(key: 'Key', value: 'Value');
      final copied = original.copyWith(value: 'NewValue');

      expect(copied.key, 'Key');
      expect(copied.value, 'NewValue');
    });
  });

  group('AuthConfig', () {
    test('bearer token generates correct header', () {
      final auth = AuthConfig(type: 'bearer', token: 'my-token');
      expect(auth.getAuthorizationHeader(), 'Bearer my-token');
    });

    test('basic auth generates correct header', () {
      final auth = AuthConfig(
        type: 'basic',
        username: 'user',
        password: 'pass',
      );
      final header = auth.getAuthorizationHeader();
      expect(header, isNotNull);
      expect(header, startsWith('Basic '));
    });

    test('api key in header generates additional headers', () {
      final auth = AuthConfig(
        type: 'apiKey',
        apiKey: 'my-api-key',
        apiKeyHeader: 'X-API-Key',
        apiKeyLocation: 'header',
      );

      final headers = auth.getAdditionalHeaders();
      expect(headers['X-API-Key'], 'my-api-key');
    });

    test('api key in query generates additional query params', () {
      final auth = AuthConfig(
        type: 'apiKey',
        apiKey: 'my-api-key',
        apiKeyHeader: 'api_key',
        apiKeyLocation: 'query',
      );

      final params = auth.getAdditionalQueryParams();
      expect(params['api_key'], 'my-api-key');
    });

    test('none type returns null', () {
      final auth = AuthConfig(type: 'none');
      expect(auth.getAuthorizationHeader(), isNull);
    });

    test('copyWith works correctly', () {
      final original = AuthConfig(type: 'bearer', token: 'old-token');
      final copied = original.copyWith(token: 'new-token');

      expect(copied.type, 'bearer');
      expect(copied.token, 'new-token');
    });
  });
}
