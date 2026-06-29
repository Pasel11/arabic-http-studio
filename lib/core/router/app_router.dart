import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/screens/ai_assistant_screen.dart';
import '../../features/authentication/screens/auth_screen.dart';
import '../../features/collections/screens/collections_screen.dart';
import '../../features/developer_tools/screens/developer_tools_screen.dart';
import '../../features/environment/screens/environment_screen.dart';
import '../../features/export/screens/export_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/logs/screens/logs_screen.dart';
import '../../features/request/screens/request_builder_screen.dart';
import '../../features/settings/screens/backup_restore_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/tools/crypto/screens/encoding_crypto_screen.dart';
import '../../features/tools/json/screens/json_tools_screen.dart';
import '../../features/tools/screens/tools_hub_screen.dart';
import '../../features/variables/screens/variables_screen.dart';
import '../../features/websocket/screens/websocket_screen.dart';
import '../../widgets/main_shell.dart';

/// Application router configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Main shell with bottom navigation
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainShell(),
      ),
      // Request builder
      GoRoute(
        path: '/request',
        name: 'request',
        builder: (context, state) => const RequestBuilderScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'requestById',
            builder: (context, state) => RequestBuilderScreen(
              requestId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      // Standalone screens
      GoRoute(path: '/history-full', builder: (c, s) => const HistoryScreen()),
      GoRoute(path: '/favorites-full', builder: (c, s) => const FavoritesScreen()),
      GoRoute(path: '/collections-full', builder: (c, s) => const CollectionsScreen()),
      GoRoute(path: '/settings-full', builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/variables', builder: (c, s) => const VariablesScreen()),
      GoRoute(path: '/environment', builder: (c, s) => const EnvironmentScreen()),
      GoRoute(path: '/websocket', builder: (c, s) => const WebSocketScreen()),
      GoRoute(path: '/authentication', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/logs', builder: (c, s) => const LogsScreen()),
      GoRoute(path: '/export', builder: (c, s) => const ExportScreen()),
      GoRoute(path: '/developer-tools', builder: (c, s) => const DeveloperToolsScreen()),
      GoRoute(path: '/backup', builder: (c, s) => const BackupRestoreScreen()),
      // Tools
      GoRoute(path: '/tools', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/json', builder: (c, s) => const JsonToolsScreen()),
      GoRoute(path: '/tools/json/compare', builder: (c, s) => const JsonToolsScreen()),
      GoRoute(path: '/tools/xml', builder: (c, s) => const JsonToolsScreen()),
      GoRoute(path: '/tools/base64', builder: (c, s) => const EncodingCryptoToolsScreen()),
      GoRoute(path: '/tools/hash', builder: (c, s) => const EncodingCryptoToolsScreen()),
      GoRoute(path: '/tools/url-encode', builder: (c, s) => const EncodingCryptoToolsScreen()),
      GoRoute(path: '/tools/unicode', builder: (c, s) => const EncodingCryptoToolsScreen()),
      GoRoute(path: '/tools/sessions', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/sessions/compare', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/compare/requests', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/compare/responses', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/compare/text', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/files', builder: (c, s) => const ToolsHubScreen()),
      GoRoute(path: '/tools/reports', builder: (c, s) => const ToolsHubScreen()),
      // AI Assistant
      GoRoute(path: '/ai-assistant', builder: (c, s) => const AiAssistantScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('الصفحة غير موجودة: ${state.uri}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => GoRouter.of(context).go('/'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
