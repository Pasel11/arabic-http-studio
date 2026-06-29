import 'dart:convert';

/// WebSocket message types
enum WebSocketMessageType {
  text,
  binary,
  ping,
  pong,
  close,
  error,
}

/// WebSocket message model
class WebSocketMessage {
  final String id;
  final String connectionId;
  final WebSocketMessageType type;
  final String? text;
  final List<int>? binary;
  final DateTime timestamp;
  final bool isIncoming;
  final int? size;

  WebSocketMessage({
    required this.id,
    required this.connectionId,
    required this.type,
    this.text,
    this.binary,
    required this.timestamp,
    required this.isIncoming,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'connectionId': connectionId,
        'type': type.name,
        'text': text,
        'binary': binary,
        'timestamp': timestamp.toIso8601String(),
        'isIncoming': isIncoming,
        'size': size,
      };

  String toJsonString() => jsonEncode(toJson());

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      id: json['id'] as String,
      connectionId: json['connectionId'] as String,
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketMessageType.text,
      ),
      text: json['text'] as String?,
      binary: (json['binary'] as List<dynamic>?)?.map((e) => e as int).toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isIncoming: json['isIncoming'] as bool,
      size: json['size'] as int?,
    );
  }

  factory WebSocketMessage.fromJsonString(String jsonString) {
    return WebSocketMessage.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
