import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/export/services/import_service.dart';
import 'package:arabic_http_studio/features/export/models/collection_import_models.dart';

void main() {
  group('ImportService', () {
    final service = ImportService.instance;

    group('JSON import', () {
      test('should import native format', () {
        const json = '''
        {
          "requests": [
            {
              "id": "1",
              "name": "Test",
              "method": "GET",
              "url": "https://api.example.com",
              "headers": [],
              "queryParams": [],
              "cookies": [],
              "isPinned": false,
              "createdAt": "2024-01-01T00:00:00.000",
              "updatedAt": "2024-01-01T00:00:00.000",
              "followRedirects": true,
              "maxRedirects": 5,
              "httpVersion": "HTTP/1.1",
              "verifyTls": true
            }
          ]
        }
        ''';

        final result = service.importFromString(json, 'json');

        expect(result.requests, hasLength(1));
        expect(result.requests.first.name, 'Test');
        expect(result.requests.first.method, 'GET');
        expect(result.source, 'Arabic HTTP Studio');
      });

      test('should import OpenAPI 3.0', () {
        const openapi = '''
        {
          "openapi": "3.0.3",
          "info": {
            "title": "Test API",
            "version": "1.0.0"
          },
          "paths": {
            "/users": {
              "get": {
                "summary": "Get users",
                "operationId": "getUsers"
              },
              "post": {
                "summary": "Create user",
                "operationId": "createUser"
              }
            }
          }
        }
        ''';

        final result = service.importFromString(openapi, 'json');

        expect(result.requests, hasLength(2));
        expect(result.source, contains('OpenAPI'));
        expect(result.collections, hasLength(1));
      });

      test('should import Postman collection', () {
        const postman = '''
        {
          "info": {
            "name": "Test Collection",
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
          },
          "item": [
            {
              "name": "Get Users",
              "request": {
                "method": "GET",
                "url": "https://api.example.com/users",
                "header": [
                  {"key": "Content-Type", "value": "application/json", "type": "text"}
                ]
              }
            }
          ]
        }
        ''';

        final result = service.importFromString(postman, 'json');

        expect(result.requests, hasLength(1));
        expect(result.requests.first.name, 'Get Users');
        expect(result.requests.first.method, 'GET');
        expect(result.source, contains('Postman'));
      });

      test('should throw for unknown JSON format', () {
        const json = '{"unknown": "format"}';

        expect(
          () => service.importFromString(json, 'json'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('CSV import', () {
      test('should import CSV with headers', () {
        const csv = '''
Name,Method,URL
Get Users,GET,https://api.example.com/users
Create User,POST,https://api.example.com/users
''';

        final result = service.importFromString(csv, 'csv');

        expect(result.requests, hasLength(2));
        expect(result.requests.first.name, 'Get Users');
        expect(result.requests.first.method, 'GET');
        expect(result.requests.first.url, 'https://api.example.com/users');
      });
    });

    group('TXT import', () {
      test('should import from text lines', () {
        const txt = '''
GET https://api.example.com/users
POST https://api.example.com/users
DELETE https://api.example.com/users/1
''';

        final result = service.importFromString(txt, 'txt');

        expect(result.requests, hasLength(3));
        expect(result.requests[0].method, 'GET');
        expect(result.requests[1].method, 'POST');
        expect(result.requests[2].method, 'DELETE');
      });
    });

    group('Unsupported format', () {
      test('should throw for unsupported format', () {
        expect(
          () => service.importFromString('content', 'unsupported'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });

  group('ImportResult', () {
    test('should detect errors', () {
      final result = ImportResult(
        requests: [],
        source: 'test',
        errors: ['error 1'],
      );

      expect(result.hasErrors, isTrue);
    });

    test('should calculate total count', () {
      final result = ImportResult(
        requests: [],
        collections: [
          CollectionFolder(id: '1', name: 'test'),
        ],
        source: 'test',
      );

      expect(result.totalCount, 1);
    });
  });
}
