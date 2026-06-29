import 'dart:convert';

/// Represents a crash log entry.
///
/// This model captures information about application crashes,
/// including the error type, message, and stack trace.
class CrashLog {
  /// Creates a crash log.
  CrashLog({
    required this.id,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    this.deviceInfo,
    this.appVersion,
  });

  /// Unique identifier for the crash log.
  final String id;

  /// The type of error (e.g., 'StateError', 'FormatException').
  final String errorType;

  /// The error message.
  final String message;

  /// The stack trace at the time of the crash.
  final String stackTrace;

  /// When the crash occurred.
  final DateTime timestamp;

  /// Optional device information.
  final Map<String, dynamic>? deviceInfo;

  /// Application version when the crash occurred.
  final String? appVersion;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'errorType': errorType,
        'message': message,
        'stackTrace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        'deviceInfo': deviceInfo,
        'appVersion': appVersion,
      };

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Creates from JSON map.
  factory CrashLog.fromJson(Map<String, dynamic> json) {
    return CrashLog(
      id: json['id'] as String,
      errorType: json['errorType'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      appVersion: json['appVersion'] as String?,
    );
  }

  /// Deserializes from JSON string.
  factory CrashLog.fromJsonString(String jsonString) {
    return CrashLog.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
