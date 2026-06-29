import '../models/session_model.dart';

/// Service for comparing sessions.
///
/// This service performs detailed comparison between two sessions,
/// identifying differences in requests, responses, and metadata.
class SessionComparisonService {
  SessionComparisonService._();
  static final SessionComparisonService instance = SessionComparisonService._();

  /// Compares two sessions and returns the differences.
  SessionComparison compare(SessionModel session1, SessionModel session2) {
    final differences = <SessionDifference>[];

    // Compare entry counts
    if (session1.entries.length != session2.entries.length) {
      differences.add(SessionDifference(
        type: SessionDifferenceType.entryCount,
        description: 'عدد الإدخالات مختلف',
        session1Value: '${session1.entries.length}',
        session2Value: '${session2.entries.length}',
      ));
    }

    // Compare each entry
    final maxEntries = session1.entries.length > session2.entries.length
        ? session1.entries.length
        : session2.entries.length;

    for (var i = 0; i < maxEntries; i++) {
      final entry1 = i < session1.entries.length ? session1.entries[i] : null;
      final entry2 = i < session2.entries.length ? session2.entries[i] : null;

      if (entry1 == null || entry2 == null) {
        differences.add(SessionDifference(
          type: SessionDifferenceType.missingEntry,
          description: 'إدخال موجود في ${entry1 != null ? 'الجلسة 1' : 'الجلسة 2'} فقط (موضع ${i + 1})',
          session1Value: entry1?.request.name,
          session2Value: entry2?.request.name,
        ));
        continue;
      }

      _compareEntries(entry1, entry2, differences, i + 1);
    }

    return SessionComparison(
      session1: session1,
      session2: session2,
      differences: differences,
    );
  }

  void _compareEntries(
    SessionEntry entry1,
    SessionEntry entry2,
    List<SessionDifference> differences,
    int position,
  ) {
    final req1 = entry1.request;
    final req2 = entry2.request;

    // Compare method
    if (req1.method != req2.method) {
      differences.add(SessionDifference(
        type: SessionDifferenceType.method,
        description: 'الطريقة مختلفة (إدخال $position)',
        session1Value: req1.method,
        session2Value: req2.method,
      ));
    }

    // Compare URL
    if (req1.url != req2.url) {
      differences.add(SessionDifference(
        type: SessionDifferenceType.url,
        description: 'الرابط مختلف (إدخال $position)',
        session1Value: req1.url,
        session2Value: req2.url,
      ));
    }

    // Compare headers
    final headersDiff = _compareHeaders(req1.headers, req2.headers);
    if (headersDiff != null) {
      differences.add(SessionDifference(
        type: SessionDifferenceType.headers,
        description: 'الرؤوس مختلفة (إدخال $position)',
        session1Value: headersDiff,
        session2Value: '',
      ));
    }

    // Compare body
    final body1 = req1.body?.rawContent;
    final body2 = req2.body?.rawContent;
    if (body1 != body2) {
      differences.add(SessionDifference(
        type: SessionDifferenceType.body,
        description: 'المتن مختلف (إدخال $position)',
        session1Value: body1 ?? 'لا يوجد',
        session2Value: body2 ?? 'لا يوجد',
      ));
    }

    // Compare responses
    final resp1 = entry1.response;
    final resp2 = entry2.response;

    if (resp1 != null && resp2 != null) {
      // Status code
      if (resp1.statusCode != resp2.statusCode) {
        differences.add(SessionDifference(
          type: SessionDifferenceType.statusCode,
          description: 'رمز الحالة مختلف (إدخال $position)',
          session1Value: '${resp1.statusCode}',
          session2Value: '${resp2.statusCode}',
        ));
      }

      // Response body
      if (resp1.responseBody != resp2.responseBody) {
        differences.add(SessionDifference(
          type: SessionDifferenceType.responseBody,
          description: 'متن الاستجابة مختلف (إدخال $position)',
          session1Value: resp1.responseBody?.substring(0, 100) ?? 'لا يوجد',
          session2Value: resp2.responseBody?.substring(0, 100) ?? 'لا يوجد',
        ));
      }

      // Duration
      if (entry1.duration != entry2.duration) {
        differences.add(SessionDifference(
          type: SessionDifferenceType.duration,
          description: 'زمن التنفيذ مختلف (إدخال $position)',
          session1Value: '${entry1.duration ?? 0}ms',
          session2Value: '${entry2.duration ?? 0}ms',
        ));
      }
    }
  }

  String? _compareHeaders(List<dynamic> headers1, List<dynamic> headers2) {
    final map1 = {for (final h in headers1) (h as dynamic).key as String: (h as dynamic).value as String};
    final map2 = {for (final h in headers2) (h as dynamic).key as String: (h as dynamic).value as String};

    final differences = <String>[];

    // Keys only in map1
    for (final key in map1.keys) {
      if (!map2.containsKey(key)) {
        differences.add('محذوف: $key');
      } else if (map1[key] != map2[key]) {
        differences.add('معدّل: $key (${map1[key]} → ${map2[key]})');
      }
    }

    // Keys only in map2
    for (final key in map2.keys) {
      if (!map1.containsKey(key)) {
        differences.add('مضاف: $key');
      }
    }

    return differences.isEmpty ? null : differences.join(', ');
  }
}
