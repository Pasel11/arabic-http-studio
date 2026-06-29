import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/websocket/models/websocket_message.dart';

/// WebSocket connection states
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// WebSocket service for managing WebSocket connections
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  final Map<String, _WebSocketConnection> _connections = {};

  /// Connect to a WebSocket server
  Future<String> connect({
    required String url,
    Map<String, String>? headers,
    Duration? pingInterval,
    bool autoReconnect = false,
    int maxReconnectAttempts = 5,
    Duration reconnectDelay = const Duration(seconds: 3),
  }) async {
    final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
    final connection = _WebSocketConnection(
      connectionId: connectionId,
      url: url,
      headers: headers ?? {},
      pingInterval: pingInterval,
      autoReconnect: autoReconnect,
      maxReconnectAttempts: maxReconnectAttempts,
      reconnectDelay: reconnectDelay,
    );

    _connections[connectionId] = connection;
    await connection.connect();

    return connectionId;
  }

  /// Disconnect from a WebSocket connection
  Future<void> disconnect(String connectionId) async {
    final connection = _connections[connectionId];
    if (connection != null) {
      await connection.disconnect();
      _connections.remove(connectionId);
    }
  }

  /// Send text message
  void sendText(String connectionId, String message) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('Connection not found: $connectionId');
    }
    connection.sendText(message);
  }

  /// Send binary message
  void sendBinary(String connectionId, List<int> data) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('Connection not found: $connectionId');
    }
    connection.sendBinary(data);
  }

  /// Send ping
  void sendPing(String connectionId) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('Connection not found: $connectionId');
    }
    connection.sendPing();
  }

  /// Get message stream for a connection
  Stream<WebSocketMessage> getMessageStream(String connectionId) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('Connection not found: $connectionId');
    }
    return connection.messageStream;
  }

  /// Get connection state stream
  Stream<WebSocketConnectionState> getStateStream(String connectionId) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('Connection not found: $connectionId');
    }
    return connection.stateStream;
  }

  /// Get current connection state
  WebSocketConnectionState getConnectionState(String connectionId) {
    final connection = _connections[connectionId];
    if (connection == null) {
      return WebSocketConnectionState.disconnected;
    }
    return connection.state;
  }

  /// Get all active connections
  List<String> getActiveConnections() {
    return _connections.entries
        .where((e) => e.value.state == WebSocketConnectionState.connected)
        .map((e) => e.key)
        .toList();
  }

  /// Disconnect all connections
  Future<void> disconnectAll() async {
    await Future.wait(
      _connections.values.map((c) => c.disconnect()),
    );
    _connections.clear();
  }
}

/// Internal WebSocket connection wrapper
class _WebSocketConnection {
  _WebSocketConnection({
    required this.connectionId,
    required this.url,
    required this.headers,
    this.pingInterval,
    required this.autoReconnect,
    required this.maxReconnectAttempts,
    required this.reconnectDelay,
  });

  final String connectionId;
  final String url;
  final Map<String, String> headers;
  final Duration? pingInterval;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _reconnectAttempts = 0;
  Timer? _pingTimer;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get state => _state;

  final _stateController = StreamController<WebSocketConnectionState>.broadcast();
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  final _messageController = StreamController<WebSocketMessage>.broadcast();
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_state == WebSocketConnectionState.connected ||
        _state == WebSocketConnectionState.connecting) {
      return;
    }

    _setState(WebSocketConnectionState.connecting);

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      // Start ping timer if interval is set
      if (pingInterval != null) {
        _pingTimer = Timer.periodic(pingInterval!, (_) => sendPing());
      }

      _setState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
    } catch (e, stackTrace) {
      _setState(WebSocketConnectionState.error);
      _addMessage(
        WebSocketMessage(
          id: _generateId(),
          connectionId: connectionId,
          type: WebSocketMessageType.error,
          text: 'فشل الاتصال: $e',
          timestamp: DateTime.now(),
          isIncoming: true,
        ),
      );

      if (autoReconnect && _reconnectAttempts < maxReconnectAttempts) {
        _reconnectAttempts++;
        await Future.delayed(reconnectDelay);
        await connect();
      }
    }
  }

  Future<void> disconnect() async {
    _setState(WebSocketConnectionState.disconnecting);
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _setState(WebSocketConnectionState.disconnected);
  }

  void sendText(String message) {
    if (_channel == null || _state != WebSocketConnectionState.connected) {
      throw StateError('WebSocket not connected');
    }
    _channel!.sink.add(message);

    _addMessage(
      WebSocketMessage(
        id: _generateId(),
        connectionId: connectionId,
        type: WebSocketMessageType.text,
        text: message,
        timestamp: DateTime.now(),
        isIncoming: false,
        size: utf8.encode(message).length,
      ),
    );
  }

  void sendBinary(List<int> data) {
    if (_channel == null || _state != WebSocketConnectionState.connected) {
      throw StateError('WebSocket not connected');
    }
    _channel!.sink.add(Uint8List.fromList(data));

    _addMessage(
      WebSocketMessage(
        id: _generateId(),
        connectionId: connectionId,
        type: WebSocketMessageType.binary,
        binary: data,
        timestamp: DateTime.now(),
        isIncoming: false,
        size: data.length,
      ),
    );
  }

  void sendPing() {
    if (_channel == null || _state != WebSocketConnectionState.connected) {
      return;
    }

    try {
      _channel!.sink.add('ping');
      _addMessage(
        WebSocketMessage(
          id: _generateId(),
          connectionId: connectionId,
          type: WebSocketMessageType.ping,
          text: 'ping',
          timestamp: DateTime.now(),
          isIncoming: false,
          size: 4,
        ),
      );
    } catch (_) {
      // Ignore ping errors
    }
  }

  void _onData(dynamic data) {
    if (data is String) {
      if (data == 'pong') {
        _addMessage(
          WebSocketMessage(
            id: _generateId(),
            connectionId: connectionId,
            type: WebSocketMessageType.pong,
            text: 'pong',
            timestamp: DateTime.now(),
            isIncoming: true,
            size: 4,
          ),
        );
      } else {
        _addMessage(
          WebSocketMessage(
            id: _generateId(),
            connectionId: connectionId,
            type: WebSocketMessageType.text,
            text: data,
            timestamp: DateTime.now(),
            isIncoming: true,
            size: utf8.encode(data).length,
          ),
        );
      }
    } else if (data is List<int>) {
      _addMessage(
        WebSocketMessage(
          id: _generateId(),
          connectionId: connectionId,
          type: WebSocketMessageType.binary,
          binary: data,
          timestamp: DateTime.now(),
          isIncoming: true,
          size: data.length,
        ),
      );
    }
  }

  void _onError(Object error) {
    _setState(WebSocketConnectionState.error);
    _addMessage(
      WebSocketMessage(
        id: _generateId(),
        connectionId: connectionId,
        type: WebSocketMessageType.error,
        text: 'خطأ: $error',
        timestamp: DateTime.now(),
        isIncoming: true,
      ),
    );

    if (autoReconnect && _reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(reconnectDelay, connect);
    }
  }

  void _onDone() {
    _setState(WebSocketConnectionState.disconnected);
    _addMessage(
      WebSocketMessage(
        id: _generateId(),
        connectionId: connectionId,
        type: WebSocketMessageType.close,
        text: 'تم إغلاق الاتصال',
        timestamp: DateTime.now(),
        isIncoming: true,
      ),
    );

    if (autoReconnect && _reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(reconnectDelay, connect);
    }
  }

  void _setState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _addMessage(WebSocketMessage message) {
    _messageController.add(message);
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  void dispose() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _messageController.close();
  }
}

/// SSE (Server-Sent Events) service
class SseService {
  SseService._();
  static final SseService instance = SseService._();

  final Map<String, _SseConnection> _connections = {};

  /// Connect to SSE endpoint
  Future<String> connect({
    required String url,
    Map<String, String>? headers,
  }) async {
    final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
    final connection = _SseConnection(
      connectionId: connectionId,
      url: url,
      headers: headers ?? {},
    );

    _connections[connectionId] = connection;
    await connection.connect();

    return connectionId;
  }

  /// Disconnect from SSE
  Future<void> disconnect(String connectionId) async {
    final connection = _connections[connectionId];
    if (connection != null) {
      await connection.disconnect();
      _connections.remove(connectionId);
    }
  }

  /// Get event stream
  Stream<SseEvent> getEventStream(String connectionId) {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw StateError('SSE connection not found: $connectionId');
    }
    return connection.eventStream;
  }

  /// Disconnect all SSE connections
  Future<void> disconnectAll() async {
    await Future.wait(
      _connections.values.map((c) => c.disconnect()),
    );
    _connections.clear();
  }
}

/// SSE event
class SseEvent {
  final String? id;
  final String? event;
  final String data;
  final DateTime timestamp;

  SseEvent({
    this.id,
    this.event,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _SseConnection {
  _SseConnection({
    required this.connectionId,
    required this.url,
    required this.headers,
  });

  final String connectionId;
  final String url;
  final Map<String, String> headers;

  HttpClient? _client;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  StreamSubscription<List<int>>? _subscription;

  final _eventController = StreamController<SseEvent>.broadcast();
  Stream<SseEvent> get eventStream => _eventController.stream;

  Future<void> connect() async {
    _client = HttpClient();
    _request = await _client!.openUrl('GET', Uri.parse(url));

    // Set headers
    _request!.headers.set('Accept', 'text/event-stream');
    _request!.headers.set('Cache-Control', 'no-cache');
    headers.forEach((key, value) {
      _request!.headers.set(key, value);
    });

    _response = await _request!.close();

    final buffer = StringBuffer();
    _subscription = _response!.listen(
      (List<int> data) {
        buffer.write(utf8.decode(data));

        // Process complete events (separated by \n\n)
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.toString().indexOf('\n\n');
          final eventData = buffer.toString().substring(0, eventEnd);
          buffer.clear();
          buffer.write(
            // ignore: substr_then_add_all
            eventData.substring(0, 0),
          );

          final event = _parseEvent(eventData);
          if (event != null) {
            _eventController.add(event);
          }
        }
      },
      onError: (Object error) {
        _eventController.addError(error);
      },
      onDone: () {
        _eventController.add(
          SseEvent(
            event: 'close',
            data: 'Connection closed',
          ),
        );
      },
    );
  }

  SseEvent? _parseEvent(String eventData) {
    String? id;
    String? eventType;
    final dataLines = <String>[];

    for (final line in eventData.split('\n')) {
      if (line.startsWith('id:')) {
        id = line.substring(3).trim();
      } else if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }

    if (dataLines.isEmpty && id == null && eventType == null) {
      return null;
    }

    return SseEvent(
      id: id,
      event: eventType,
      data: dataLines.join('\n'),
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _response?.detach();
    _client?.close();
  }
}
