import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/providers/settings_providers.dart';

class ArabicHttpStudioApp extends ConsumerWidget {
  const ArabicHttpStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Arabic HTTP Studio',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routing
      routerConfig: router,

      // Builder for system UI overlay
      builder: (context, child) {
        return Directionality(
          textDirection: _getTextDirection(locale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  TextDirection _getTextDirection(Locale locale) {
    return locale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
