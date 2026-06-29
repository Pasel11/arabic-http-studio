import 'dart:convert';

/// History entry for a completed request
class HistoryEntry {
  final String id;
  final String requestId;
  final String requestName;
  final String method;
  final String url;
  final int statusCode;
  final String statusText;
  final int responseTimeMs;
  final int responseSizeBytes;
  final int requestSizeBytes;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;
  final TimelineData? timeline;
  final String? contentType;

  HistoryEntry({
    required this.id,
    required this.requestId,
    required this.requestName,
    required this.method,
    required this.url,
    required this.statusCode,
    required this.statusText,
    required this.responseTimeMs,
    required this.responseSizeBytes,
    required this.requestSizeBytes,
    required this.responseHeaders,
    this.responseBody,
    required this.requestHeaders,
    this.requestBody,
    required this.timestamp,
    required this.isSuccess,
    this.errorMessage,
    this.timeline,
    this.contentType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'requestName': requestName,
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'statusText': statusText,
        'responseTimeMs': responseTimeMs,
        'responseSizeBytes': responseSizeBytes,
        'requestSizeBytes': requestSizeBytes,
        'responseHeaders': responseHeaders,
        'responseBody': responseBody,
        'requestHeaders': requestHeaders,
        'requestBody': requestBody,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        'errorMessage': errorMessage,
        'timeline': timeline?.toJson(),
        'contentType': contentType,
      };

  String toJsonString() => jsonEncode(toJson());

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      requestName: json['requestName'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      statusCode: json['statusCode'] as int,
      statusText: json['statusText'] as String,
      responseTimeMs: json['responseTimeMs'] as int,
      responseSizeBytes: json['responseSizeBytes'] as int,
      requestSizeBytes: json['requestSizeBytes'] as int,
      responseHeaders: Map<String, String>.from(json['responseHeaders'] as Map),
      responseBody: json['responseBody'] as String?,
      requestHeaders: Map<String, String>.from(json['requestHeaders'] as Map),
      requestBody: json['requestBody'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccess: json['isSuccess'] as bool,
      errorMessage: json['errorMessage'] as String?,
      timeline: json['timeline'] != null
          ? TimelineData.fromJson(json['timeline'] as Map<String, dynamic>)
          : null,
      contentType: json['contentType'] as String?,
    );
  }

  factory HistoryEntry.fromJsonString(String jsonString) {
    return HistoryEntry.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}

/// Timeline data for request execution
class TimelineData {
  final int dnsLookupMs;
  final int connectionMs;
  final int sslHandshakeMs;
  final int sendingMs;
  final int waitingMs;
  final int downloadingMs;
  final int totalMs;

  TimelineData({
    required this.dnsLookupMs,
    required this.connectionMs,
    required this.sslHandshakeMs,
    required this.sendingMs,
    required this.waitingMs,
    required this.downloadingMs,
    required this.totalMs,
  });

  Map<String, dynamic> toJson() => {
        'dnsLookupMs': dnsLookupMs,
        'connectionMs': connectionMs,
        'sslHandshakeMs': sslHandshakeMs,
        'sendingMs': sendingMs,
        'waitingMs': waitingMs,
        'downloadingMs': downloadingMs,
        'totalMs': totalMs,
      };

  factory TimelineData.fromJson(Map<String, dynamic> json) {
    return TimelineData(
      dnsLookupMs: json['dnsLookupMs'] as int,
      connectionMs: json['connectionMs'] as int,
      sslHandshakeMs: json['sslHandshakeMs'] as int,
      sendingMs: json['sendingMs'] as int,
      waitingMs: json['waitingMs'] as int,
      downloadingMs: json['downloadingMs'] as int,
      totalMs: json['totalMs'] as int,
    );
  }
}
