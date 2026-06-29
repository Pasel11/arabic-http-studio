import 'package:flutter/foundation.dart';

import '../contracts/ai_provider.dart';

/// Registry for AI providers.
///
/// This class manages all available AI providers and allows the application
/// to dynamically register new providers at runtime. This enables the
/// plugin system to add custom AI providers.
///
/// Example:
/// ```dart
/// AiProviderRegistry.instance.register(MyCustomProvider());
/// final provider = AiProviderRegistry.instance.getProvider('my_custom');
/// ```
class AiProviderRegistry {
  AiProviderRegistry._();
  static final AiProviderRegistry instance = AiProviderRegistry._();

  final Map<String, AiProvider> _providers = {};

  /// Registers a new AI provider.
  ///
  /// If a provider with the same ID already exists, it will be replaced.
  void register(AiProvider provider) {
    _providers[provider.id] = provider;
    debugPrint('AI Provider registered: ${provider.id} (${provider.displayName})');
  }

  /// Unregisters an AI provider.
  void unregister(String providerId) {
    final provider = _providers.remove(providerId);
    provider?.dispose();
  }

  /// Gets a provider by ID.
  AiProvider? getProvider(String providerId) {
    return _providers[providerId];
  }

  /// Gets all registered providers.
  List<AiProvider> get allProviders => _providers.values.toList();

  /// Gets all provider IDs.
  List<String> get providerIds => _providers.keys.toList();

  /// Whether a provider is registered.
  bool isRegistered(String providerId) {
    return _providers.containsKey(providerId);
  }

  /// Clears all registered providers.
  void clear() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
  }
}
