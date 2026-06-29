import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/database/hive_setup.dart';
import 'core/services/initialization_service.dart';
import 'features/ai/contracts/ai_provider.dart';
import 'features/ai/providers/ai_provider_registry.dart';
import 'features/ai/providers/ai_settings_provider.dart';
import 'features/ai/providers/openai_compatible_provider.dart';
import 'features/ai/providers/gemini_ai_provider.dart';

/// Entry point of the Arabic HTTP Studio application.
///
/// Initializes all required services before launching the app:
/// - Flutter bindings
/// - Orientation preferences
/// - Hive database
/// - Encryption service
/// - Network service
/// - AI provider registry
Future<void> main() async {
  await _initializeApp();
  runApp(
    const ProviderScope(
      child: ArabicHttpStudioApp(),
    ),
  );
}

/// Initializes all application services.
///
/// This function is called before [runApp] to ensure all
/// dependencies are ready.
Future<void> _initializeApp() async {
  // Ensure Flutter bindings are initialized
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.renderView.automaticSystemUiAdjustment = false;

  // Set orientation preferences
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive database
  await Hive.initFlutter();
  await HiveSetup.registerAdapters();
  await HiveSetup.openBoxes();

  // Initialize core services
  await InitializationService.instance.initialize();

  // Initialize AI providers
  await _initializeAiProviders();
}

/// Registers default AI providers and loads saved configurations.
///
/// This ensures the AI system is ready to use immediately after
/// the app starts, without requiring additional setup.
Future<void> _initializeAiProviders() async {
  // Load saved AI settings
  await AiSettingsProvider.instance.load();

  // Register the default OpenAI-compatible provider factory
  // The actual provider instance is created when the user configures it
  final settings = AiSettingsProvider.instance.settings;

  if (settings.enabled && settings.activeProviderId.isNotEmpty) {
    final config = settings.providers[settings.activeProviderId];
    if (config != null) {
      AiProvider provider;
      switch (config.providerId) {
        case 'gemini':
          provider = GeminiAiProvider(config);
        case 'openai':
        case 'custom':
        default:
          provider = OpenAiCompatibleProvider(config);
      }
      AiProviderRegistry.instance.register(provider);
    }
  }
}
