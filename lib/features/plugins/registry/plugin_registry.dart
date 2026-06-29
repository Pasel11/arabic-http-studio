import 'package:flutter/foundation.dart';

import '../contracts/plugin.dart';

/// Registry for managing application plugins.
///
/// This class handles plugin lifecycle:
/// - Registration of new plugins
/// - Initialization of registered plugins
/// - Disposal of plugins
/// - Providing access to registered components
///
/// Example:
/// ```dart
/// final plugin = MyCustomPlugin();
/// await PluginRegistry.instance.registerPlugin(plugin, context);
/// ```
class PluginRegistry {
  PluginRegistry._();
  static final PluginRegistry instance = PluginRegistry._();

  final Map<String, AppPlugin> _plugins = {};
  final List<ToolDefinition> _tools = [];
  final List<ExportFormatDefinition> _exportFormats = [];
  final List<ImportFormatDefinition> _importFormats = [];
  final List<ScreenDefinition> _screens = [];
  final List<SettingsSectionDefinition> _settingsSections = [];

  /// All registered plugins.
  List<AppPlugin> get plugins => _plugins.values.toList();

  /// All registered tools.
  List<ToolDefinition> get tools => List.unmodifiable(_tools);

  /// All registered export formats.
  List<ExportFormatDefinition> get exportFormats =>
      List.unmodifiable(_exportFormats);

  /// All registered import formats.
  List<ImportFormatDefinition> get importFormats =>
      List.unmodifiable(_importFormats);

  /// All registered screens.
  List<ScreenDefinition> get screens => List.unmodifiable(_screens);

  /// All registered settings sections.
  List<SettingsSectionDefinition> get settingsSections =>
      List.unmodifiable(_settingsSections);

  /// Registers a plugin.
  Future<void> registerPlugin(
    AppPlugin plugin,
    PluginContext context,
  ) async {
    if (_plugins.containsKey(plugin.id)) {
      debugPrint('Plugin ${plugin.id} is already registered');
      return;
    }

    _plugins[plugin.id] = plugin;

    try {
      plugin.register(context);
      await plugin.initialize();
      debugPrint('Plugin registered: ${plugin.id} v${plugin.version}');
    } catch (e, stackTrace) {
      debugPrint('Failed to register plugin ${plugin.id}: $e\n$stackTrace');
      _plugins.remove(plugin.id);
    }
  }

  /// Unregisters a plugin by ID.
  Future<void> unregisterPlugin(String pluginId, PluginContext context) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return;

    try {
      await plugin.dispose();
      plugin.unregister(context);
    } catch (e, stackTrace) {
      debugPrint('Error unregistering plugin $pluginId: $e\n$stackTrace');
    }

    _plugins.remove(pluginId);

    // Remove registered components
    _tools.removeWhere((t) => t.id.startsWith('$pluginId:'));
    _exportFormats.removeWhere((f) => f.id.startsWith('$pluginId:'));
    _importFormats.removeWhere((f) => f.id.startsWith('$pluginId:'));
    _screens.removeWhere((s) => s.id.startsWith('$pluginId:'));
    _settingsSections.removeWhere((s) => s.id.startsWith('$pluginId:'));

    debugPrint('Plugin unregistered: $pluginId');
  }

  /// Adds a tool to the registry.
  void addTool(String pluginId, ToolDefinition tool) {
    final prefixedTool = ToolDefinition(
      id: '$pluginId:${tool.id}',
      displayName: tool.displayName,
      description: tool.description,
      icon: tool.icon,
      category: tool.category,
      builder: tool.builder,
    );
    _tools.add(prefixedTool);
  }

  /// Adds an export format to the registry.
  void addExportFormat(String pluginId, ExportFormatDefinition format) {
    final prefixedFormat = ExportFormatDefinition(
      id: '$pluginId:${format.id}',
      displayName: format.displayName,
      fileExtension: format.fileExtension,
      exporter: format.exporter,
    );
    _exportFormats.add(prefixedFormat);
  }

  /// Adds an import format to the registry.
  void addImportFormat(String pluginId, ImportFormatDefinition format) {
    final prefixedFormat = ImportFormatDefinition(
      id: '$pluginId:${format.id}',
      displayName: format.displayName,
      fileExtension: format.fileExtension,
      importer: format.importer,
    );
    _importFormats.add(prefixedFormat);
  }

  /// Adds a screen to the registry.
  void addScreen(String pluginId, ScreenDefinition screen) {
    final prefixedScreen = ScreenDefinition(
      id: '$pluginId:${screen.id}',
      displayName: screen.displayName,
      icon: screen.icon,
      route: '/plugins/$pluginId/${screen.route}',
      builder: screen.builder,
    );
    _screens.add(prefixedScreen);
  }

  /// Adds a settings section to the registry.
  void addSettingsSection(String pluginId, SettingsSectionDefinition section) {
    final prefixedSection = SettingsSectionDefinition(
      id: '$pluginId:${section.id}',
      title: section.title,
      icon: section.icon,
      builder: section.builder,
    );
    _settingsSections.add(prefixedSection);
  }

  /// Gets a plugin by ID.
  AppPlugin? getPlugin(String pluginId) => _plugins[pluginId];

  /// Whether a plugin is registered.
  bool isRegistered(String pluginId) => _plugins.containsKey(pluginId);

  /// Disposes all plugins.
  Future<void> disposeAll(PluginContext context) async {
    for (final plugin in _plugins.values.toList()) {
      await unregisterPlugin(plugin.id, context);
    }
  }
}
