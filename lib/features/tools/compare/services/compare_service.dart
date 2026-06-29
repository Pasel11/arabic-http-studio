import 'dart:convert';

import '../../request/models/http_request.dart';
import '../../history/models/history_entry.dart';

/// Service for comparing HTTP requests, responses, and text.
///
/// Provides multiple comparison modes:
/// - Request vs Request
/// - Response vs Response
/// - Header vs Header
/// - JSON vs JSON
/// - Text diff (line-by-line)
class CompareService {
  CompareService._();
  static final CompareService instance = CompareService._();

  /// Compares two HTTP requests.
  RequestComparison compareRequests(
    HttpRequestModel request1,
    HttpRequestModel request2,
  ) {
    final differences = <ComparisonDifference>[];

    // Method
    if (request1.method != request2.method) {
      differences.add(ComparisonDifference(
        field: 'الطريقة',
        value1: request1.method,
        value2: request2.method,
        type: DifferenceType.changed,
      ));
    }

    // URL
    if (request1.url != request2.url) {
      differences.add(ComparisonDifference(
        field: 'الرابط',
        value1: request1.url,
        value2: request2.url,
        type: DifferenceType.changed,
      ));
    }

    // Headers
    _compareMaps(
      'الرؤوس',
      {for (final h in request1.headers) h.key: h.value},
      {for (final h in request2.headers) h.key: h.value},
      differences,
    );

    // Query params
    _compareMaps(
      'معاملات الاستعلام',
      {for (final q in request1.queryParams) q.key: q.value},
      {for (final q in request2.queryParams) q.key: q.value},
      differences,
    );

    // Body
    final body1 = request1.body?.rawContent;
    final body2 = request2.body?.rawContent;
    if (body1 != body2) {
      differences.add(ComparisonDifference(
        field: 'المتن',
        value1: body1 ?? 'لا يوجد',
        value2: body2 ?? 'لا يوجد',
        type: DifferenceType.changed,
      ));
    }

    return RequestComparison(
      request1: request1,
      request2: request2,
      differences: differences,
      areEqual: differences.isEmpty,
    );
  }

  /// Compares two HTTP responses.
  ResponseComparison compareResponses(
    HistoryEntry response1,
    HistoryEntry response2,
  ) {
    final differences = <ComparisonDifference>[];

    // Status code
    if (response1.statusCode != response2.statusCode) {
      differences.add(ComparisonDifference(
        field: 'رمز الحالة',
        value1: '${response1.statusCode}',
        value2: '${response2.statusCode}',
        type: DifferenceType.changed,
      ));
    }

    // Response time
    if (response1.responseTimeMs != response2.responseTimeMs) {
      differences.add(ComparisonDifference(
        field: 'زمن الاستجابة',
        value1: '${response1.responseTimeMs}ms',
        value2: '${response2.responseTimeMs}ms',
        type: DifferenceType.changed,
      ));
    }

    // Size
    if (response1.responseSizeBytes != response2.responseSizeBytes) {
      differences.add(ComparisonDifference(
        field: 'حجم الاستجابة',
        value1: '${response1.responseSizeBytes} bytes',
        value2: '${response2.responseSizeBytes} bytes',
        type: DifferenceType.changed,
      ));
    }

    // Headers
    _compareMaps(
      'رؤوس الاستجابة',
      response1.responseHeaders,
      response2.responseHeaders,
      differences,
    );

    // Body
    if (response1.responseBody != response2.responseBody) {
      differences.add(ComparisonDifference(
        field: 'متن الاستجابة',
        value1: response1.responseBody ?? 'لا يوجد',
        value2: response2.responseBody ?? 'لا يوجد',
        type: DifferenceType.changed,
      ));
    }

    return ResponseComparison(
      response1: response1,
      response2: response2,
      differences: differences,
      areEqual: differences.isEmpty,
    );
  }

  void _compareMaps(
    String fieldName,
    Map<String, String> map1,
    Map<String, String> map2,
    List<ComparisonDifference> differences,
  ) {
    final allKeys = {...map1.keys, ...map2.keys};

    for (final key in allKeys) {
      if (!map1.containsKey(key)) {
        differences.add(ComparisonDifference(
          field: '$fieldName: $key',
          value1: null,
          value2: map2[key],
          type: DifferenceType.added,
        ));
      } else if (!map2.containsKey(key)) {
        differences.add(ComparisonDifference(
          field: '$fieldName: $key',
          value1: map1[key],
          value2: null,
          type: DifferenceType.removed,
        ));
      } else if (map1[key] != map2[key]) {
        differences.add(ComparisonDifference(
          field: '$fieldName: $key',
          value1: map1[key],
          value2: map2[key],
          type: DifferenceType.changed,
        ));
      }
    }
  }

  /// Performs a line-by-line text diff.
  TextDiffResult diffText(String text1, String text2) {
    final lines1 = text1.split('\n');
    final lines2 = text2.split('\n');

    final diffLines = <TextDiffLine>[];
    final maxLines = lines1.length > lines2.length ? lines1.length : lines2.length;

    for (var i = 0; i < maxLines; i++) {
      final line1 = i < lines1.length ? lines1[i] : null;
      final line2 = i < lines2.length ? lines2[i] : null;

      if (line1 == null) {
        diffLines.add(TextDiffLine(
          lineNumber: i + 1,
          left: null,
          right: line2,
          type: DiffLineType.added,
        ));
      } else if (line2 == null) {
        diffLines.add(TextDiffLine(
          lineNumber: i + 1,
          left: line1,
          right: null,
          type: DiffLineType.removed,
        ));
      } else if (line1 == line2) {
        diffLines.add(TextDiffLine(
          lineNumber: i + 1,
          left: line1,
          right: line2,
          type: DiffLineType.same,
        ));
      } else {
        diffLines.add(TextDiffLine(
          lineNumber: i + 1,
          left: line1,
          right: line2,
          type: DiffLineType.changed,
        ));
      }
    }

    final addedCount = diffLines.where((d) => d.type == DiffLineType.added).length;
    final removedCount = diffLines.where((d) => d.type == DiffLineType.removed).length;
    final changedCount = diffLines.where((d) => d.type == DiffLineType.changed).length;

    return TextDiffResult(
      lines: diffLines,
      addedCount: addedCount,
      removedCount: removedCount,
      changedCount: changedCount,
      areEqual: addedCount == 0 && removedCount == 0 && changedCount == 0,
    );
  }

  /// Compares two JSON strings.
  MapComparison compareJson(String json1, String json2) {
    try {
      final decoded1 = jsonDecode(json1);
      final decoded2 = jsonDecode(json2);

      final differences = <ComparisonDifference>[];
      _compareJsonValues('الجذر', decoded1, decoded2, differences);

      return MapComparison(
        areEqual: differences.isEmpty,
        differences: differences,
      );
    } catch (e) {
      return MapComparison(
        areEqual: false,
        differences: [],
        error: 'JSON غير صالح: $e',
      );
    }
  }

  void _compareJsonValues(
    String path,
    dynamic value1,
    dynamic value2,
    List<ComparisonDifference> differences,
  ) {
    if (value1.runtimeType != value2.runtimeType) {
      differences.add(ComparisonDifference(
        field: path,
        value1: value1?.toString() ?? 'null',
        value2: value2?.toString() ?? 'null',
        type: DifferenceType.changed,
      ));
      return;
    }

    if (value1 is Map) {
      final allKeys = {...value1.keys.cast<String>(), ...value2.keys.cast<String>()};
      for (final key in allKeys) {
        final newPath = '$path.$key';
        if (!value1.containsKey(key)) {
          differences.add(ComparisonDifference(
            field: newPath,
            value1: null,
            value2: value2[key].toString(),
            type: DifferenceType.added,
          ));
        } else if (!value2.containsKey(key)) {
          differences.add(ComparisonDifference(
            field: newPath,
            value1: value1[key].toString(),
            value2: null,
            type: DifferenceType.removed,
          ));
        } else {
          _compareJsonValues(newPath, value1[key], value2[key], differences);
        }
      }
    } else if (value1 is List) {
      final maxLen = value1.length > value2.length ? value1.length : value2.length;
      for (var i = 0; i < maxLen; i++) {
        if (i >= value1.length) {
          differences.add(ComparisonDifference(
            field: '$path[$i]',
            value1: null,
            value2: value2[i].toString(),
            type: DifferenceType.added,
          ));
        } else if (i >= value2.length) {
          differences.add(ComparisonDifference(
            field: '$path[$i]',
            value1: value1[i].toString(),
            value2: null,
            type: DifferenceType.removed,
          ));
        } else {
          _compareJsonValues('$path[$i]', value1[i], value2[i], differences);
        }
      }
    } else if (value1 != value2) {
      differences.add(ComparisonDifference(
        field: path,
        value1: value1.toString(),
        value2: value2.toString(),
        type: DifferenceType.changed,
      ));
    }
  }
}

/// Types of differences.
enum DifferenceType {
  added,
  removed,
  changed,
}

/// A single difference between two values.
class ComparisonDifference {
  const ComparisonDifference({
    required this.field,
    required this.value1,
    required this.value2,
    required this.type,
  });

  final String field;
  final String? value1;
  final String? value2;
  final DifferenceType type;
}

/// Result of comparing two requests.
class RequestComparison {
  const RequestComparison({
    required this.request1,
    required this.request2,
    required this.differences,
    required this.areEqual,
  });

  final HttpRequestModel request1;
  final HttpRequestModel request2;
  final List<ComparisonDifference> differences;
  final bool areEqual;
}

/// Result of comparing two responses.
class ResponseComparison {
  const ResponseComparison({
    required this.response1,
    required this.response2,
    required this.differences,
    required this.areEqual,
  });

  final HistoryEntry response1;
  final HistoryEntry response2;
  final List<ComparisonDifference> differences;
  final bool areEqual;
}

/// Result of comparing two maps/JSON.
class MapComparison {
  const MapComparison({
    required this.areEqual,
    required this.differences,
    this.error,
  });

  final bool areEqual;
  final List<ComparisonDifference> differences;
  final String? error;
}

/// Types of diff lines.
enum DiffLineType {
  same,
  added,
  removed,
  changed,
}

/// A single line in a text diff.
class TextDiffLine {
  const TextDiffLine({
    required this.lineNumber,
    required this.left,
    required this.right,
    required this.type,
  });

  final int lineNumber;
  final String? left;
  final String? right;
  final DiffLineType type;
}

/// Result of a text diff.
class TextDiffResult {
  const TextDiffResult({
    required this.lines,
    required this.addedCount,
    required this.removedCount,
    required this.changedCount,
    required this.areEqual,
  });

  final List<TextDiffLine> lines;
  final int addedCount;
  final int removedCount;
  final int changedCount;
  final bool areEqual;
}
