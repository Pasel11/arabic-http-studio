import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:arabic_http_studio/features/plugins/contracts/plugin.dart';
import 'package:arabic_http_studio/features/plugins/registry/plugin_registry.dart';

void main() {
  group('PluginRegistry', () {
    setUp(() {
      PluginRegistry.instance.disposeAll(_createTestContext());
    });

    tearDown(() {
      PluginRegistry.instance.disposeAll(_createTestContext());
    });

    test('should register a plugin', () async {
      final plugin = _TestPlugin();
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      expect(PluginRegistry.instance.isRegistered(plugin.id), isTrue);
    });

    test('should not register the same plugin twice', () async {
      final plugin = _TestPlugin();
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      expect(PluginRegistry.instance.plugins.where((p) => p.id == plugin.id).length, 1);
    });

    test('should unregister a plugin', () async {
      final plugin = _TestPlugin();
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      await PluginRegistry.instance.unregisterPlugin(plugin.id, _createTestContext());
      expect(PluginRegistry.instance.isRegistered(plugin.id), isFalse);
    });

    test('should get plugin by id', () async {
      final plugin = _TestPlugin();
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      final retrieved = PluginRegistry.instance.getPlugin(plugin.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, plugin.id);
    });

    test('should register tools from plugin', () async {
      final plugin = _TestPluginWithTool();
      await PluginRegistry.instance.registerPlugin(plugin, _createTestContext());
      expect(PluginRegistry.instance.tools, isNotEmpty);
    });

    test('should clear all plugins', () async {
      await PluginRegistry.instance.registerPlugin(_TestPlugin(), _createTestContext());
      await PluginRegistry.instance.registerPlugin(_TestPlugin2(), _createTestContext());
      await PluginRegistry.instance.disposeAll(_createTestContext());
      expect(PluginRegistry.instance.plugins, isEmpty);
    });
  });

  group('AppPlugin', () {
    test('should have required properties', () {
      final plugin = _TestPlugin();
      expect(plugin.id, isNotEmpty);
      expect(plugin.displayName, isNotEmpty);
      expect(plugin.description, isNotEmpty);
      expect(plugin.version, isNotEmpty);
    });
  });

  group('PluginContext', () {
    test('should register components', () async {
      final tools = <ToolDefinition>[];
      final context = PluginContext(
        registerTool: (tool) => tools.add(tool),
        registerAiProvider: (_) {},
        registerExportFormat: (_) {},
        registerImportFormat: (_) {},
        registerScreen: (_) {},
        registerSettingsSection: (_) {},
        getSetting: (_) => null,
        setSetting: (_, __) async {},
      );

      context.registerTool(ToolDefinition(
        id: 'test_tool',
        displayName: 'Test Tool',
        description: 'A test tool',
        icon: Icons.extension,
        category: 'test',
        builder: (context) => const SizedBox(),
      ));

      expect(tools, hasLength(1));
      expect(tools.first.id, 'test_tool');
    });
  });
}

PluginContext _createTestContext() {
  return PluginContext(
    registerTool: (tool) => PluginRegistry.instance.addTool('test', tool),
    registerAiProvider: (_) {},
    registerExportFormat: (format) => PluginRegistry.instance.addExportFormat('test', format),
    registerImportFormat: (format) => PluginRegistry.instance.addImportFormat('test', format),
    registerScreen: (screen) => PluginRegistry.instance.addScreen('test', screen),
    registerSettingsSection: (section) => PluginRegistry.instance.addSettingsSection('test', section),
    getSetting: (_) => null,
    setSetting: (_, __) async {},
  );
}

class _TestPlugin implements AppPlugin {
  @override
  String get id => 'test_plugin_1';

  @override
  String get displayName => 'Test Plugin';

  @override
  String get description => 'A test plugin';

  @override
  String get version => '1.0.0';

  @override
  String? get author => 'Test';

  @override
  void register(PluginContext context) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}

class _TestPlugin2 implements AppPlugin {
  @override
  String get id => 'test_plugin_2';

  @override
  String get displayName => 'Test Plugin 2';

  @override
  String get description => 'Another test plugin';

  @override
  String get version => '1.0.0';

  @override
  String? get author => 'Test';

  @override
  void register(PluginContext context) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}

class _TestPluginWithTool implements AppPlugin {
  @override
  String get id => 'test_plugin_with_tool';

  @override
  String get displayName => 'Test Plugin With Tool';

  @override
  String get description => 'A plugin with a tool';

  @override
  String get version => '1.0.0';

  @override
  String? get author => 'Test';

  @override
  void register(PluginContext context) {
    context.registerTool(ToolDefinition(
      id: 'my_tool',
      displayName: 'My Tool',
      description: 'My custom tool',
      icon: Icons.extension,
      category: 'custom',
      builder: (context) => const SizedBox(),
    ));
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
