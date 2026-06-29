import 'dart:convert';

import '../../request/models/http_request.dart';
import '../../history/models/history_entry.dart';

/// Represents a saved session containing requests and responses.
///
/// A session captures the complete state of a testing workflow,
/// allowing users to save, restore, and compare different test scenarios.
class SessionModel {
  /// Creates a session.
  SessionModel({
    required this.id,
    required this.name,
    this.description,
    List<SessionEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
    this.color,
    this.isPinned = false,
  })  : entries = entries ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// Session entries (request + response pairs).
  final List<SessionEntry> entries;

  /// When the session was created.
  final DateTime createdAt;

  /// When the session was last updated.
  final DateTime updatedAt;

  /// Tags for organization.
  final List<String> tags;

  /// Custom color (hex string).
  final String? color;

  /// Whether this session is pinned.
  final bool isPinned;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'color': color,
        'isPinned': isPinned,
      };

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Creates from JSON map.
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => SessionEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      color: json['color'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// Deserializes from JSON string.
  factory SessionModel.fromJsonString(String jsonString) {
    return SessionModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Creates a copy with updated fields.
  SessionModel copyWith({
    String? id,
    String? name,
    String? description,
    List<SessionEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? color,
    bool? isPinned,
  }) {
    return SessionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// A single entry in a session (request + optional response).
class SessionEntry {
  /// Creates a session entry.
  SessionEntry({
    required this.id,
    required this.request,
    this.response,
    this.notes,
    this.executedAt,
    this.duration,
  });

  /// Unique identifier.
  final String id;

  /// The HTTP request.
  final HttpRequestModel request;

  /// The HTTP response (null if not yet executed).
  final HistoryEntry? response;

  /// User notes for this entry.
  final String? notes;

  /// When this entry was executed.
  final DateTime? executedAt;

  /// Execution duration in milliseconds.
  final int? duration;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'response': response?.toJson(),
        'notes': notes,
        'executedAt': executedAt?.toIso8601String(),
        'duration': duration,
      };

  /// Creates from JSON map.
  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    return SessionEntry(
      id: json['id'] as String,
      request: HttpRequestModel.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      response: json['response'] != null
          ? HistoryEntry.fromJson(json['response'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : null,
      duration: json['duration'] as int?,
    );
  }

  /// Creates a copy with updated fields.
  SessionEntry copyWith({
    String? id,
    HttpRequestModel? request,
    HistoryEntry? response,
    String? notes,
    DateTime? executedAt,
    int? duration,
  }) {
    return SessionEntry(
      id: id ?? this.id,
      request: request ?? this.request,
      response: response ?? this.response,
      notes: notes ?? this.notes,
      executedAt: executedAt ?? this.executedAt,
      duration: duration ?? this.duration,
    );
  }
}

/// Result of comparing two sessions.
class SessionComparison {
  /// Creates a session comparison.
  SessionComparison({
    required this.session1,
    required this.session2,
    required this.differences,
  });

  /// First session.
  final SessionModel session1;

  /// Second session.
  final SessionModel session2;

  /// List of differences.
  final List<SessionDifference> differences;

  /// Whether the sessions are identical.
  bool get isIdentical => differences.isEmpty;

  /// Number of differences.
  int get differenceCount => differences.length;
}

/// A single difference between two sessions.
class SessionDifference {
  /// Creates a session difference.
  SessionDifference({
    required this.type,
    required this.description,
    this.session1Value,
    this.session2Value,
  });

  /// Type of difference.
  final SessionDifferenceType type;

  /// Description of the difference.
  final String description;

  /// Value in session 1.
  final String? session1Value;

  /// Value in session 2.
  final String? session2Value;
}

/// Types of session differences.
enum SessionDifferenceType {
  /// Different number of entries.
  entryCount,

  /// Different request method.
  method,

  /// Different request URL.
  url,

  /// Different request headers.
  headers,

  /// Different request body.
  body,

  /// Different response status code.
  statusCode,

  /// Different response body.
  responseBody,

  /// Different execution time.
  duration,

  /// Entry only in one session.
  missingEntry,
}
