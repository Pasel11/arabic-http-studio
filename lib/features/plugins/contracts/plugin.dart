/// Contracts and interfaces for the plugin system.
///
/// This file defines the abstractions that all plugins must implement,
/// enabling third-party extensions to be loaded at runtime.
library;

import 'package:flutter/widgets.dart';

/// Contract that all plugins must implement.
///
/// Plugins extend the application's functionality without modifying
/// the core codebase. Each plugin can register:
/// - Custom tools
/// - Custom AI providers
/// - Custom export/import formats
/// - Custom UI screens
/// - Custom request transformers
///
/// Example:
/// ```dart
/// class MyCustomPlugin implements AppPlugin {
///   @override
///   String get id => 'my_custom_plugin';
///
///   @override
///   String get displayName => 'My Custom Plugin';
///
///   @override
///   void register(PluginContext context) {
///     context.registerTool(MyTool());
///   }
/// }
/// ```
abstract class AppPlugin {
  /// Unique identifier for this plugin.
  String get id;

  /// Human-readable display name.
  String get displayName;

  /// Description of what this plugin does.
  String get description;

  /// Version of this plugin.
  String get version;

  /// Author of this plugin.
  String? get author;

  /// Whether this plugin is enabled.
  bool get isEnabled => true;

  /// Called when the plugin is loaded.
  ///
  /// Use [context] to register the plugin's components.
  void register(PluginContext context);

  /// Called when the plugin is unloaded.
  ///
  /// Clean up any resources used by the plugin.
  void unregister(PluginContext context) {}

  /// Initializes the plugin.
  ///
  /// Called after [register]. Use this for async initialization.
  Future<void> initialize() async {}

  /// Disposes the plugin.
  ///
  /// Called before [unregister]. Use this for cleanup.
  Future<void> dispose() async {}
}

/// Context provided to plugins for registration.
///
/// This object gives plugins access to register their components
/// with the application.
class PluginContext {
  /// Creates a plugin context.
  PluginContext({
    required this.registerTool,
    required this.registerAiProvider,
    required this.registerExportFormat,
    required this.registerImportFormat,
    required this.registerScreen,
    required this.registerSettingsSection,
    this.getSetting,
    this.setSetting,
  });

  /// Registers a custom tool.
  final void Function(ToolDefinition tool) registerTool;

  /// Registers a custom AI provider.
  final void Function(dynamic provider) registerAiProvider;

  /// Registers a custom export format.
  final void Function(ExportFormatDefinition format) registerExportFormat;

  /// Registers a custom import format.
  final void Function(ImportFormatDefinition format) registerImportFormat;

  /// Registers a custom screen accessible via navigation.
  final void Function(ScreenDefinition screen) registerScreen;

  /// Registers a custom settings section.
  final void Function(SettingsSectionDefinition section) registerSettingsSection;

  /// Gets a setting value.
  final T? Function<T>(String key)? getSetting;

  /// Sets a setting value.
  final Future<void> Function<T>(String key, T? value)? setSetting;
}

/// Definition of a custom tool.
class ToolDefinition {
  /// Creates a tool definition.
  const ToolDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.category,
    required this.builder,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String displayName;

  /// Description.
  final String description;

  /// Icon for the tool.
  final IconData icon;

  /// Category (e.g., 'json', 'xml', 'encoding').
  final String category;

  /// Builder for the tool's UI.
  final WidgetBuilder builder;
}

/// Definition of a custom export format.
class ExportFormatDefinition {
  /// Creates an export format definition.
  const ExportFormatDefinition({
    required this.id,
    required this.displayName,
    required this.fileExtension,
    required this.exporter,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String displayName;

  /// File extension (without dot).
  final String fileExtension;

  /// Function that performs the export.
  final Future<String> Function(Map<String, dynamic> data) exporter;
}

/// Definition of a custom import format.
class ImportFormatDefinition {
  /// Creates an import format definition.
  const ImportFormatDefinition({
    required this.id,
    required this.displayName,
    required this.fileExtension,
    required this.importer,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String displayName;

  /// File extension (without dot).
  final String fileExtension;

  /// Function that performs the import.
  final Map<String, dynamic> Function(String content) importer;
}

/// Definition of a custom screen.
class ScreenDefinition {
  /// Creates a screen definition.
  const ScreenDefinition({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.route,
    required this.builder,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String displayName;

  /// Icon for navigation.
  final IconData icon;

  /// Route path.
  final String route;

  /// Builder for the screen.
  final WidgetBuilder builder;
}

/// Definition of a custom settings section.
class SettingsSectionDefinition {
  /// Creates a settings section definition.
  const SettingsSectionDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
  });

  /// Unique identifier.
  final String id;

  /// Section title.
  final String title;

  /// Section icon.
  final IconData icon;

  /// Builder for the section content.
  final WidgetBuilder builder;
}
