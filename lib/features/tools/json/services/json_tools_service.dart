import 'dart:convert';

/// Comprehensive JSON tools service.
///
/// Provides utilities for:
/// - Formatting (pretty-print)
/// - Validation
/// - Comparison
/// - Tree building
/// - Searching
/// - Statistics
class JsonToolsService {
  JsonToolsService._();
  static final JsonToolsService instance = JsonToolsService._();

  /// Formats (beautifies) a JSON string.
  ///
  /// Returns the formatted JSON, or the original string if parsing fails.
  String format(String jsonString, {int indent = 2}) {
    try {
      final decoded = jsonDecode(jsonString);
      return const JsonEncoder().convert(decoded);
    } catch (e) {
      return jsonString;
    }
  }

  /// Validates a JSON string.
  ///
  /// Returns a [JsonValidationResult] indicating whether the JSON is valid.
  JsonValidationResult validate(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return JsonValidationResult(
        isValid: false,
        error: 'السلسلة فارغة',
      );
    }

    try {
      final decoded = jsonDecode(jsonString);
      return JsonValidationResult(
        isValid: true,
        decoded: decoded,
      );
    } catch (e) {
      return JsonValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// Minifies a JSON string.
  String minify(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return jsonEncode(decoded);
    } catch (e) {
      return jsonString;
    }
  }

  /// Compares two JSON strings and returns the differences.
  JsonComparison compare(String json1, String json2) {
    final result1 = validate(json1);
    final result2 = validate(json2);

    if (!result1.isValid) {
      return JsonComparison(
        areEqual: false,
        error: 'JSON الأول غير صالح: ${result1.error}',
      );
    }

    if (!result2.isValid) {
      return JsonComparison(
        areEqual: false,
        error: 'JSON الثاني غير صالح: ${result2.error}',
      );
    }

    final differences = <JsonDifference>[];
    _compareValues('', result1.decoded, result2.decoded, differences);

    return JsonComparison(
      areEqual: differences.isEmpty,
      differences: differences,
    );
  }

  void _compareValues(
    String path,
    dynamic value1,
    dynamic value2,
    List<JsonDifference> differences,
  ) {
    if (value1.runtimeType != value2.runtimeType) {
      differences.add(JsonDifference(
        path: path.isEmpty ? 'الجذر' : path,
        type: JsonDifferenceType.typeMismatch,
        value1: value1.toString(),
        value2: value2.toString(),
      ));
      return;
    }

    if (value1 is Map && value2 is Map) {
      final allKeys = {...value1.keys, ...value2.keys};
      for (final key in allKeys) {
        final newPath = path.isEmpty ? key.toString() : '$path.$key';
        if (!value1.containsKey(key)) {
          differences.add(JsonDifference(
            path: newPath,
            type: JsonDifferenceType.added,
            value1: null,
            value2: value2[key].toString(),
          ));
        } else if (!value2.containsKey(key)) {
          differences.add(JsonDifference(
            path: newPath,
            type: JsonDifferenceType.removed,
            value1: value1[key].toString(),
            value2: null,
          ));
        } else {
          _compareValues(newPath, value1[key], value2[key], differences);
        }
      }
    } else if (value1 is List && value2 is List) {
      final maxLen = value1.length > value2.length ? value1.length : value2.length;
      for (var i = 0; i < maxLen; i++) {
        final newPath = '$path[$i]';
        if (i >= value1.length) {
          differences.add(JsonDifference(
            path: newPath,
            type: JsonDifferenceType.added,
            value1: null,
            value2: value2[i].toString(),
          ));
        } else if (i >= value2.length) {
          differences.add(JsonDifference(
            path: newPath,
            type: JsonDifferenceType.removed,
            value1: value1[i].toString(),
            value2: null,
          ));
        } else {
          _compareValues(newPath, value1[i], value2[i], differences);
        }
      }
    } else if (value1 != value2) {
      differences.add(JsonDifference(
        path: path.isEmpty ? 'الجذر' : path,
        type: JsonDifferenceType.valueChanged,
        value1: value1.toString(),
        value2: value2.toString(),
      ));
    }
  }

  /// Builds a tree structure from a JSON string.
  JsonTreeNode buildTree(String jsonString) {
    final result = validate(jsonString);
    if (!result.isValid) {
      return JsonTreeNode(
        key: 'الجذر',
        value: null,
        type: JsonValueType.invalid,
        children: [],
      );
    }
    return _buildNode('الجذر', result.decoded);
  }

  JsonTreeNode _buildNode(String key, dynamic value) {
    if (value == null) {
      return JsonTreeNode(key: key, value: 'null', type: JsonValueType.nullValue);
    } else if (value is bool) {
      return JsonTreeNode(key: key, value: value, type: JsonValueType.boolean);
    } else if (value is num) {
      return JsonTreeNode(key: key, value: value, type: JsonValueType.number);
    } else if (value is String) {
      return JsonTreeNode(key: key, value: value, type: JsonValueType.string);
    } else if (value is List) {
      return JsonTreeNode(
        key: key,
        value: 'صفيف[${value.length}]',
        type: JsonValueType.array,
        children: value.asMap().entries.map((e) {
          return _buildNode('[${e.key}]', e.value);
        }).toList(),
      );
    } else if (value is Map) {
      return JsonTreeNode(
        key: key,
        value: 'كائن{${value.length}}',
        type: JsonValueType.object,
        children: value.entries.map((e) {
          return _buildNode(e.key.toString(), e.value);
        }).toList(),
      );
    }
    return JsonTreeNode(key: key, value: value.toString(), type: JsonValueType.string);
  }

  /// Searches within a JSON string.
  ///
  /// Returns all paths where the query is found.
  List<JsonSearchResult> search(String jsonString, String query,
      {bool caseSensitive = false}) {
    final result = validate(jsonString);
    if (!result.isValid) return [];

    final matches = <JsonSearchResult>[];
    _searchValues('', result.decoded, query, caseSensitive, matches);
    return matches;
  }

  void _searchValues(
    String path,
    dynamic value,
    String query,
    bool caseSensitive,
    List<JsonSearchResult> matches,
  ) {
    final searchQuery = caseSensitive ? query : query.toLowerCase();

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final keyToCheck = caseSensitive ? key : key.toLowerCase();
        if (keyToCheck.contains(searchQuery)) {
          matches.add(JsonSearchResult(
            path: path.isEmpty ? key : '$path.$key',
            key: key,
            value: entry.value.toString(),
          ));
        }
        _searchValues(
          path.isEmpty ? key : '$path.$key',
          entry.value,
          query,
          caseSensitive,
          matches,
        );
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _searchValues('$path[$i]', value[i], query, caseSensitive, matches);
      }
    } else {
      final valueStr = value?.toString() ?? '';
      final valueToCheck = caseSensitive ? valueStr : valueStr.toLowerCase();
      if (valueToCheck.contains(searchQuery)) {
        matches.add(JsonSearchResult(
          path: path,
          key: '',
          value: valueStr,
        ));
      }
    }
  }

  /// Calculates statistics for a JSON string.
  JsonStatistics getStatistics(String jsonString) {
    final result = validate(jsonString);
    if (!result.isValid) {
      return JsonStatistics(
        totalKeys: 0,
        totalValues: 0,
        objects: 0,
        arrays: 0,
        strings: 0,
        numbers: 0,
        booleans: 0,
        nulls: 0,
        maxDepth: 0,
        size: jsonString.length,
      );
    }

    final stats = _JsonStatsCollector();
    stats.collect(result.decoded, 0);

    return JsonStatistics(
      totalKeys: stats.totalKeys,
      totalValues: stats.totalValues,
      objects: stats.objects,
      arrays: stats.arrays,
      strings: stats.strings,
      numbers: stats.numbers,
      booleans: stats.booleans,
      nulls: stats.nulls,
      maxDepth: stats.maxDepth,
      size: jsonString.length,
    );
  }
}

/// Result of JSON validation.
class JsonValidationResult {
  const JsonValidationResult({
    required this.isValid,
    this.error,
    this.decoded,
  });

  final bool isValid;
  final String? error;
  final dynamic decoded;
}

/// Result of JSON comparison.
class JsonComparison {
  const JsonComparison({
    required this.areEqual,
    this.differences = const [],
    this.error,
  });

  final bool areEqual;
  final List<JsonDifference> differences;
  final String? error;
}

/// A single difference between two JSONs.
class JsonDifference {
  const JsonDifference({
    required this.path,
    required this.type,
    required this.value1,
    required this.value2,
  });

  final String path;
  final JsonDifferenceType type;
  final String? value1;
  final String? value2;
}

/// Types of JSON differences.
enum JsonDifferenceType {
  added,
  removed,
  valueChanged,
  typeMismatch,
}

/// Types of JSON values.
enum JsonValueType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue,
  invalid,
}

/// A node in a JSON tree.
class JsonTreeNode {
  const JsonTreeNode({
    required this.key,
    required this.value,
    required this.type,
    this.children = const [],
  });

  final String key;
  final dynamic value;
  final JsonValueType type;
  final List<JsonTreeNode> children;
}

/// A search result in JSON.
class JsonSearchResult {
  const JsonSearchResult({
    required this.path,
    required this.key,
    required this.value,
  });

  final String path;
  final String key;
  final String value;
}

/// Statistics for a JSON document.
class JsonStatistics {
  const JsonStatistics({
    required this.totalKeys,
    required this.totalValues,
    required this.objects,
    required this.arrays,
    required this.strings,
    required this.numbers,
    required this.booleans,
    required this.nulls,
    required this.maxDepth,
    required this.size,
  });

  final int totalKeys;
  final int totalValues;
  final int objects;
  final int arrays;
  final int strings;
  final int numbers;
  final int booleans;
  final int nulls;
  final int maxDepth;
  final int size;
}

/// Helper class for collecting JSON statistics.
class _JsonStatsCollector {
  int totalKeys = 0;
  int totalValues = 0;
  int objects = 0;
  int arrays = 0;
  int strings = 0;
  int numbers = 0;
  int booleans = 0;
  int nulls = 0;
  int maxDepth = 0;

  void collect(dynamic value, int depth) {
    if (depth > maxDepth) maxDepth = depth;

    if (value == null) {
      nulls++;
      totalValues++;
    } else if (value is bool) {
      booleans++;
      totalValues++;
    } else if (value is num) {
      numbers++;
      totalValues++;
    } else if (value is String) {
      strings++;
      totalValues++;
    } else if (value is List) {
      arrays++;
      for (final item in value) {
        collect(item, depth + 1);
      }
    } else if (value is Map) {
      objects++;
      totalKeys += value.length;
      for (final entry in value.entries) {
        collect(entry.value, depth + 1);
      }
    }
  }
}
