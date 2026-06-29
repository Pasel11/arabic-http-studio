import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../contracts/ai_provider.dart';

/// AI settings state.
class AiSettings {
  /// Creates AI settings.
  const AiSettings({
    this.enabled = false,
    this.activeProviderId = '',
    this.providers = const {},
    this.defaultTemperature = 0.7,
    this.defaultMaxTokens = 4000,
    this.showSuggestions = true,
    this.autoExplainErrors = false,
    this.cacheResponses = true,
  });

  /// Whether AI features are enabled.
  final bool enabled;

  /// The active provider ID.
  final String activeProviderId;

  /// Map of provider ID to configuration.
  final Map<String, AiProviderConfig> providers;

  /// Default temperature for AI responses.
  final double defaultTemperature;

  /// Default maximum tokens.
  final int defaultMaxTokens;

  /// Whether to show AI suggestions proactively.
  final bool showSuggestions;

  /// Whether to automatically explain errors.
  final bool autoExplainErrors;

  /// Whether to cache AI responses.
  final bool cacheResponses;

  /// Creates a copy with updated fields.
  AiSettings copyWith({
    bool? enabled,
    String? activeProviderId,
    Map<String, AiProviderConfig>? providers,
    double? defaultTemperature,
    int? defaultMaxTokens,
    bool? showSuggestions,
    bool? autoExplainErrors,
    bool? cacheResponses,
  }) {
    return AiSettings(
      enabled: enabled ?? this.enabled,
      activeProviderId: activeProviderId ?? this.activeProviderId,
      providers: providers ?? this.providers,
      defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      autoExplainErrors: autoExplainErrors ?? this.autoExplainErrors,
      cacheResponses: cacheResponses ?? this.cacheResponses,
    );
  }
}

/// Manages AI settings with secure storage.
class AiSettingsProvider {
  AiSettingsProvider._();
  static final AiSettingsProvider instance = AiSettingsProvider._();

  static const String _storageKey = 'ai_settings_v1';
  static const String _enabledKey = 'ai_enabled';
  static const String _activeProviderKey = 'ai_active_provider';
  static const String _providersKey = 'ai_providers';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AiSettings _settings = const AiSettings();
  AiSettings get settings => _settings;

  /// Loads settings from secure storage.
  Future<void> load() async {
    try {
      final enabled = await _secureStorage.read(key: _enabledKey);
      final activeProvider = await _secureStorage.read(key: _activeProviderKey);
      final providersJson = await _secureStorage.read(key: _providersKey);

      final providers = <String, AiProviderConfig>{};
      if (providersJson != null) {
        final decoded = jsonDecode(providersJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          providers[entry.key] = AiProviderConfig.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      _settings = AiSettings(
        enabled: enabled == 'true',
        activeProviderId: activeProvider ?? '',
        providers: providers,
      );
    } catch (e) {
      debugPrint('Failed to load AI settings: $e');
      _settings = const AiSettings();
    }
  }

  /// Enables or disables AI features.
  Future<void> setEnabled(bool enabled) async {
    await _secureStorage.write(key: _enabledKey, value: enabled.toString());
    _settings = _settings.copyWith(enabled: enabled);
  }

  /// Sets the active provider.
  Future<void> setActiveProvider(String providerId) async {
    await _secureStorage.write(key: _activeProviderKey, value: providerId);
    _settings = _settings.copyWith(activeProviderId: providerId);
  }

  /// Saves a provider configuration.
  Future<void> setProviderConfig(AiProviderConfig config) async {
    final providers = Map<String, AiProviderConfig>.from(_settings.providers);
    providers[config.providerId] = config;

    final providersJson = jsonEncode(
      providers.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _secureStorage.write(key: _providersKey, value: providersJson);

    _settings = _settings.copyWith(providers: providers);
  }

  /// Removes a provider configuration.
  Future<void> removeProviderConfig(String providerId) async {
    final providers = Map<String, AiProviderConfig>.from(_settings.providers);
    providers.remove(providerId);

    final providersJson = jsonEncode(
      providers.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _secureStorage.write(key: _providersKey, value: providersJson);

    _settings = _settings.copyWith(providers: providers);
  }

  /// Gets the configuration for the active provider.
  AiProviderConfig? get activeProviderConfig {
    if (_settings.activeProviderId.isEmpty) return null;
    return _settings.providers[_settings.activeProviderId];
  }

  /// Updates default temperature.
  Future<void> setDefaultTemperature(double temperature) async {
    _settings = _settings.copyWith(defaultTemperature: temperature);
  }

  /// Updates default max tokens.
  Future<void> setDefaultMaxTokens(int maxTokens) async {
    _settings = _settings.copyWith(defaultMaxTokens: maxTokens);
  }

  /// Toggles proactive suggestions.
  Future<void> setShowSuggestions(bool show) async {
    _settings = _settings.copyWith(showSuggestions: show);
  }

  /// Toggles automatic error explanation.
  Future<void> setAutoExplainErrors(bool auto) async {
    _settings = _settings.copyWith(autoExplainErrors: auto);
  }

  /// Toggles response caching.
  Future<void> setCacheResponses(bool cache) async {
    _settings = _settings.copyWith(cacheResponses: cache);
  }
}
