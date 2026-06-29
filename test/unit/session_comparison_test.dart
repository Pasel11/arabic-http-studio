import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/sessions/models/session_model.dart';
import 'package:arabic_http_studio/features/tools/sessions/services/session_comparison_service.dart';

void main() {
  group('SessionComparisonService', () {
    final service = SessionComparisonService.instance;

    group('compare', () {
      test('should detect identical sessions', () {
        final session1 = SessionModel(id: '1', name: 'Session 1');
        final session2 = SessionModel(id: '2', name: 'Session 2');

        final result = service.compare(session1, session2);

        expect(result.isIdentical, isTrue);
        expect(result.differences, isEmpty);
      });

      test('should detect different entry counts', () {
        final session1 = SessionModel(id: '1', name: 'S1', entries: []);
        final session2 = SessionModel(
          id: '2',
          name: 'S2',
          entries: [
            SessionEntry(
              id: 'e1',
              request: _createTestRequest('GET', 'https://api.example.com'),
            ),
          ],
        );

        final result = service.compare(session1, session2);

        expect(result.isIdentical, isFalse);
        expect(
          result.differences.any((d) => d.type == SessionDifferenceType.entryCount),
          isTrue,
        );
      });
    });

    group('SessionDifferenceType', () {
      test('should have all expected types', () {
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.entryCount));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.method));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.url));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.headers));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.body));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.statusCode));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.responseBody));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.duration));
        expect(SessionDifferenceType.values,
            contains(SessionDifferenceType.missingEntry));
      });
    });
  });
}

/// Creates a minimal test request for testing.
HttpRequestModelPlaceholder _createTestRequest(String method, String url) {
  return HttpRequestModelPlaceholder(method: method, url: url);
}

/// Placeholder class that mimics HttpRequestModel for testing.
class HttpRequestModelPlaceholder {
  HttpRequestModelPlaceholder({required this.method, required this.url});

  final String method;
  final String url;
}
