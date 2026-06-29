import 'dart:convert';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Log entry model
class LogEntry {
  final String id;
  final LogLevel level;
  final String category;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;
  final String? requestId;

  LogEntry({
    required this.id,
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.stackTrace,
    this.requestId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level.name,
        'category': category,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'stackTrace': stackTrace,
        'requestId': requestId,
      };

  String toJsonString() => jsonEncode(toJson());

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String,
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      category: json['category'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
      requestId: json['requestId'] as String?,
    );
  }

  factory LogEntry.fromJsonString(String jsonString) {
    return LogEntry.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
