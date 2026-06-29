import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Service for running heavy operations in background isolates.
///
/// This service provides utilities for offloading CPU-intensive tasks
/// to separate isolates, preventing UI jank. It includes methods for
/// JSON parsing, data processing, and custom task execution.
///
/// Example:
/// ```dart
/// final result = await IsolateService.runJsonParse(largeJsonString);
/// ```
class IsolateService {
  IsolateService._();
  static final IsolateService instance = IsolateService._();

  /// Parses a JSON string in a background isolate.
  ///
  /// This is useful for parsing large JSON payloads without
  /// blocking the UI thread.
  static Future<dynamic> parseJson(String jsonString) async {
    if (jsonString.length < 10000) {
      // For small payloads, parse in main isolate
      return jsonDecode(jsonString);
    }

    return compute(_parseJsonInIsolate, jsonString);
  }

  /// Parses JSON in isolate.
  static dynamic _parseJsonInIsolate(String jsonString) {
    return jsonDecode(jsonString);
  }

  /// Stringifies a JSON-encodable object in a background isolate.
  ///
  /// This is useful for serializing large objects without
  /// blocking the UI thread.
  static Future<String> stringifyJson(dynamic object, {bool pretty = false}) async {
    if (object is! Map && object is! List) {
      // Simple objects can be stringified in main isolate
      return pretty
          ? const JsonEncoder.withIndent('  ').convert(object)
          : jsonEncode(object);
    }

    return compute(_stringifyJsonInIsolate, _StringifyParams(object, pretty));
  }

  /// Stringifies JSON in isolate.
  static String _stringifyJsonInIsolate(_StringifyParams params) {
    return params.pretty
        ? const JsonEncoder.withIndent('  ').convert(params.object)
        : jsonEncode(params.object);
  }

  /// Runs a custom function in a background isolate.
  ///
  /// The function must be a top-level function or static method
  /// that takes a single argument and returns a value.
  static Future<T> run<Q, T>(
    T Function(Q) function,
    Q argument,
  ) {
    return compute(function, argument);
  }

  /// Formats a large JSON string in a background isolate.
  static Future<String> formatJson(String jsonString) async {
    if (jsonString.length < 5000) {
      return _formatJsonSync(jsonString);
    }
    return compute(_formatJsonInIsolate, jsonString);
  }

  /// Formats JSON synchronously.
  static String _formatJsonSync(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return jsonString;
    }
  }

  /// Formats JSON in isolate.
  static String _formatJsonInIsolate(String jsonString) {
    return _formatJsonSync(jsonString);
  }

  /// Minifies a JSON string in a background isolate.
  static Future<String> minifyJson(String jsonString) async {
    if (jsonString.length < 5000) {
      return _minifyJsonSync(jsonString);
    }
    return compute(_minifyJsonInIsolate, jsonString);
  }

  /// Minifies JSON synchronously.
  static String _minifyJsonSync(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return jsonEncode(decoded);
    } catch (_) {
      return jsonString;
    }
  }

  /// Minifies JSON in isolate.
  static String _minifyJsonInIsolate(String jsonString) {
    return _minifyJsonSync(jsonString);
  }

  /// Searches through a large text in a background isolate.
  ///
  /// Returns a list of match positions.
  static Future<List<MatchResult>> searchText(
    String text,
    String query, {
    bool caseSensitive = false,
    bool useRegex = false,
  }) async {
    if (text.length < 50000) {
      return _searchTextSync(text, query, caseSensitive, useRegex);
    }
    return compute(
      _searchTextInIsolate,
      _SearchParams(text, query, caseSensitive, useRegex),
    );
  }

  /// Searches text synchronously.
  static List<MatchResult> _searchTextSync(
    String text,
    String query,
    bool caseSensitive,
    bool useRegex,
  ) {
    final results = <MatchResult>[];

    if (useRegex) {
      try {
        final pattern = caseSensitive
            ? RegExp(query)
            : RegExp(query, caseSensitive: false);
        for (final match in pattern.allMatches(text)) {
          results.add(MatchResult(
            start: match.start,
            end: match.end,
            text: match.group(0) ?? '',
          ));
        }
      } catch (_) {
        // Invalid regex
      }
    } else {
      final searchText = caseSensitive ? text : text.toLowerCase();
      final searchQuery = caseSensitive ? query : query.toLowerCase();
      var index = searchText.indexOf(searchQuery);
      while (index != -1) {
        results.add(MatchResult(
          start: index,
          end: index + query.length,
          text: text.substring(index, index + query.length),
        ));
        index = searchText.indexOf(searchQuery, index + 1);
      }
    }

    return results;
  }

  /// Searches text in isolate.
  static List<MatchResult> _searchTextInIsolate(_SearchParams params) {
    return _searchTextSync(
      params.text,
      params.query,
      params.caseSensitive,
      params.useRegex,
    );
  }

  /// Generates a hash for a large string in a background isolate.
  static Future<String> generateHash(String input) async {
    if (input.length < 10000) {
      return input.hashCode.toRadixString(16);
    }
    return compute(_generateHashInIsolate, input);
  }

  /// Generates hash in isolate.
  static String _generateHashInIsolate(String input) {
    return input.hashCode.toRadixString(16);
  }
}

/// Parameters for JSON stringify operation.
class _StringifyParams {
  const _StringifyParams(this.object, this.pretty);

  final dynamic object;
  final bool pretty;
}

/// Parameters for text search operation.
class _SearchParams {
  const _SearchParams(
    this.text,
    this.query,
    this.caseSensitive,
    this.useRegex,
  );

  final String text;
  final String query;
  final bool caseSensitive;
  final bool useRegex;
}

/// Result of a text search match.
class MatchResult {
  /// Creates a match result.
  const MatchResult({
    required this.start,
    required this.end,
    required this.text,
  });

  /// The start index of the match.
  final int start;

  /// The end index of the match.
  final int end;

  /// The matched text.
  final String text;

  @override
  String toString() => 'MatchResult($start-$end: "$text")';
}

/// A persistent background isolate for long-running tasks.
///
/// Unlike [compute], this allows sending multiple messages to the
/// same isolate, which is more efficient for repeated operations.
class PersistentIsolate {
  /// Creates a persistent isolate.
  PersistentIsolate();

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _subscription;
  final Map<int, Completer<dynamic>> _completers = {};
  int _messageId = 0;

  /// Starts the isolate with the given entry point.
  Future<void> start(void Function(SendPort) entryPoint) async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, _receivePort!.sendPort);

    _subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is _IsolateResponse) {
        final completer = _completers.remove(message.id);
        if (completer != null) {
          if (message.error != null) {
            completer.completeError(message.error!);
          } else {
            completer.complete(message.result);
          }
        }
      }
    });
  }

  /// Sends a message to the isolate and waits for a response.
  Future<T> sendMessage<T>(dynamic message) async {
    if (_sendPort == null) {
      throw StateError('Isolate not started');
    }

    final id = _messageId++;
    final completer = Completer<T>();
    _completers[id] = completer;

    _sendPort!.send(_IsolateRequest(id, message));

    return completer.future;
  }

  /// Stops the isolate and releases resources.
  void stop() {
    _subscription?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _completers.clear();
    _isolate = null;
    _sendPort = null;
    _receivePort = null;
  }
}

/// Request message sent to isolate.
class _IsolateRequest {
  const _IsolateRequest(this.id, this.message);

  final int id;
  final dynamic message;
}

/// Response message received from isolate.
class _IsolateResponse {
  const _IsolateResponse(this.id, this.result, this.error);

  final int id;
  final dynamic result;
  final String? error;
}
