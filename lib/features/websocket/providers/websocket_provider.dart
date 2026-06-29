import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WebSocket settings
class WebSocketSettings {
  final int pingIntervalSec;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final int reconnectDelaySec;
  final int maxMessages;

  const WebSocketSettings({
    this.pingIntervalSec = 30,
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.reconnectDelaySec = 3,
    this.maxMessages = 1000,
  });

  WebSocketSettings copyWith({
    int? pingIntervalSec,
    bool? autoReconnect,
    int? maxReconnectAttempts,
    int? reconnectDelaySec,
    int? maxMessages,
  }) {
    return WebSocketSettings(
      pingIntervalSec: pingIntervalSec ?? this.pingIntervalSec,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      reconnectDelaySec: reconnectDelaySec ?? this.reconnectDelaySec,
      maxMessages: maxMessages ?? this.maxMessages,
    );
  }
}

/// WebSocket settings notifier
class WebSocketSettingsNotifier extends StateNotifier<WebSocketSettings> {
  WebSocketSettingsNotifier() : super(const WebSocketSettings());

  void setPingInterval(int seconds) {
    state = state.copyWith(pingIntervalSec: seconds);
  }

  void setAutoReconnect(bool value) {
    state = state.copyWith(autoReconnect: value);
  }

  void setMaxReconnectAttempts(int value) {
    state = state.copyWith(maxReconnectAttempts: value);
  }

  void setReconnectDelay(int seconds) {
    state = state.copyWith(reconnectDelaySec: seconds);
  }

  void setMaxMessages(int value) {
    state = state.copyWith(maxMessages: value);
  }
}

/// Provider for WebSocket settings
final websocketSettingsProvider =
    StateNotifierProvider<WebSocketSettingsNotifier, WebSocketSettings>((ref) {
  return WebSocketSettingsNotifier();
});
