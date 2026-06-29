import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/sessions/models/session_model.dart';

void main() {
  group('SessionModel', () {
    test('should create session with required fields', () {
      final session = SessionModel(
        id: 'session-1',
        name: 'Test Session',
      );

      expect(session.id, 'session-1');
      expect(session.name, 'Test Session');
      expect(session.entries, isEmpty);
      expect(session.isPinned, isFalse);
    });

    test('should serialize to JSON', () {
      final session = SessionModel(
        id: 'session-1',
        name: 'Test Session',
        description: 'A test session',
        tags: ['api', 'test'],
      );

      final json = session.toJson();

      expect(json['id'], 'session-1');
      expect(json['name'], 'Test Session');
      expect(json['description'], 'A test session');
      expect(json['tags'], ['api', 'test']);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'session-1',
        'name': 'Test Session',
        'description': 'A test session',
        'entries': [],
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'tags': ['api'],
        'isPinned': false,
      };

      final session = SessionModel.fromJson(json);

      expect(session.id, 'session-1');
      expect(session.name, 'Test Session');
      expect(session.tags, ['api']);
    });

    test('should serialize/deserialize with entries', () {
      final session = SessionModel(
        id: 'session-1',
        name: 'Test Session',
        entries: [
          SessionEntry(
            id: 'entry-1',
            request: _createTestRequest(),
          ),
        ],
      );

      final jsonStr = session.toJsonString();
      final restored = SessionModel.fromJsonString(jsonStr);

      expect(restored.id, session.id);
      expect(restored.name, session.name);
      expect(restored.entries.length, 1);
      expect(restored.entries.first.id, 'entry-1');
    });

    test('should copy with updates', () {
      final session = SessionModel(id: '1', name: 'Original');
      final updated = session.copyWith(name: 'Updated', isPinned: true);

      expect(updated.name, 'Updated');
      expect(updated.isPinned, isTrue);
      expect(updated.id, session.id);
    });
  });

  group('SessionEntry', () {
    test('should create entry with request', () {
      final entry = SessionEntry(
        id: 'entry-1',
        request: _createTestRequest(),
        notes: 'Test notes',
      );

      expect(entry.id, 'entry-1');
      expect(entry.request.method, 'GET');
      expect(entry.notes, 'Test notes');
      expect(entry.response, isNull);
    });

    test('should serialize to JSON', () {
      final entry = SessionEntry(
        id: 'entry-1',
        request: _createTestRequest(),
      );

      final json = entry.toJson();

      expect(json['id'], 'entry-1');
      expect(json['request'], isNotNull);
    });
  });
}

_createTestRequest() {
  // Import the model
  return _MinimalRequest();
}

class _MinimalRequest {
  Map<String, dynamic> toJson() => {
        'id': 'req-1',
        'name': 'Test Request',
        'method': 'GET',
        'url': 'https://api.example.com',
        'headers': [],
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
}
