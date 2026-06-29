import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

/// Settings state
class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final String fontFamily;
  final double fontSize;
  final String codeFontFamily;
  final double codeFontSize;
  final bool autoSave;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool syntaxHighlight;
  final int defaultTimeout;
  final bool followRedirects;
  final int maxRedirects;
  final bool verifyTls;
  final String httpVersion;
  final bool enableNotifications;
  final bool soundEffects;
  final bool hapticFeedback;
  final bool keepScreenOn;
  final bool confirmOnExit;
  final bool verboseLogging;
  final String? proxyType;
  final String? proxyHost;
  final int? proxyPort;
  final bool useDynamicColor;
  final Color? primaryColor;
  final int retryCount;
  final int retryDelay;
  final String? customDns;
  final bool autoBackup;
  final int autoBackupIntervalHours;
  final bool developerMode;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.fontFamily = 'Cairo',
    this.fontSize = 14.0,
    this.codeFontFamily = 'JetBrains Mono',
    this.codeFontSize = 13.0,
    this.autoSave = true,
    this.showLineNumbers = true,
    this.wordWrap = true,
    this.syntaxHighlight = true,
    this.defaultTimeout = 30000,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.verifyTls = true,
    this.httpVersion = 'HTTP/1.1',
    this.enableNotifications = true,
    this.soundEffects = false,
    this.hapticFeedback = true,
    this.keepScreenOn = false,
    this.confirmOnExit = true,
    this.verboseLogging = false,
    this.proxyType,
    this.proxyHost,
    this.proxyPort,
    this.useDynamicColor = false,
    this.primaryColor,
    this.retryCount = 3,
    this.retryDelay = 1000,
    this.customDns,
    this.autoBackup = false,
    this.autoBackupIntervalHours = 24,
    this.developerMode = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? fontFamily,
    double? fontSize,
    String? codeFontFamily,
    double? codeFontSize,
    bool? autoSave,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? syntaxHighlight,
    int? defaultTimeout,
    bool? followRedirects,
    int? maxRedirects,
    bool? verifyTls,
    String? httpVersion,
    bool? enableNotifications,
    bool? soundEffects,
    bool? hapticFeedback,
    bool? keepScreenOn,
    bool? confirmOnExit,
    bool? verboseLogging,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    bool? useDynamicColor,
    Color? primaryColor,
    int? retryCount,
    int? retryDelay,
    String? customDns,
    bool? autoBackup,
    int? autoBackupIntervalHours,
    bool? developerMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      codeFontFamily: codeFontFamily ?? this.codeFontFamily,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      autoSave: autoSave ?? this.autoSave,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      syntaxHighlight: syntaxHighlight ?? this.syntaxHighlight,
      defaultTimeout: defaultTimeout ?? this.defaultTimeout,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      verifyTls: verifyTls ?? this.verifyTls,
      httpVersion: httpVersion ?? this.httpVersion,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      confirmOnExit: confirmOnExit ?? this.confirmOnExit,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      primaryColor: primaryColor ?? this.primaryColor,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      customDns: customDns ?? this.customDns,
      autoBackup: autoBackup ?? this.autoBackup,
      autoBackupIntervalHours: autoBackupIntervalHours ?? this.autoBackupIntervalHours,
      developerMode: developerMode ?? this.developerMode,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._box) : super(const SettingsState()) {
    _loadSettings();
  }

  final Box<dynamic> _box;

  void _loadSettings() {
    state = SettingsState(
      themeMode: _getThemeMode(_box.get('themeMode', defaultValue: 'system') as String),
      locale: Locale(_box.get('locale', defaultValue: 'ar') as String),
      fontFamily: _box.get('fontFamily', defaultValue: 'Cairo') as String,
      fontSize: (_box.get('fontSize', defaultValue: 14.0) as num).toDouble(),
      codeFontFamily: _box.get('codeFontFamily', defaultValue: 'JetBrains Mono') as String,
      codeFontSize: (_box.get('codeFontSize', defaultValue: 13.0) as num).toDouble(),
      autoSave: _box.get('autoSave', defaultValue: true) as bool,
      showLineNumbers: _box.get('showLineNumbers', defaultValue: true) as bool,
      wordWrap: _box.get('wordWrap', defaultValue: true) as bool,
      syntaxHighlight: _box.get('syntaxHighlight', defaultValue: true) as bool,
      defaultTimeout: _box.get('defaultTimeout', defaultValue: 30000) as int,
      followRedirects: _box.get('followRedirects', defaultValue: true) as bool,
      maxRedirects: _box.get('maxRedirects', defaultValue: 5) as int,
      verifyTls: _box.get('verifyTls', defaultValue: true) as bool,
      httpVersion: _box.get('httpVersion', defaultValue: 'HTTP/1.1') as String,
      enableNotifications: _box.get('enableNotifications', defaultValue: true) as bool,
      soundEffects: _box.get('soundEffects', defaultValue: false) as bool,
      hapticFeedback: _box.get('hapticFeedback', defaultValue: true) as bool,
      keepScreenOn: _box.get('keepScreenOn', defaultValue: false) as bool,
      confirmOnExit: _box.get('confirmOnExit', defaultValue: true) as bool,
      verboseLogging: _box.get('verboseLogging', defaultValue: false) as bool,
      proxyType: _box.get('proxyType') as String?,
      proxyHost: _box.get('proxyHost') as String?,
      proxyPort: _box.get('proxyPort') as int?,
      useDynamicColor: _box.get('useDynamicColor', defaultValue: false) as bool,
      primaryColor: _box.get('primaryColor') != null
          ? Color(_box.get('primaryColor') as int)
          : null,
      retryCount: _box.get('retryCount', defaultValue: 3) as int,
      retryDelay: _box.get('retryDelay', defaultValue: 1000) as int,
      customDns: _box.get('customDns') as String?,
      autoBackup: _box.get('autoBackup', defaultValue: false) as bool,
      autoBackupIntervalHours: _box.get('autoBackupIntervalHours', defaultValue: 24) as int,
      developerMode: _box.get('developerMode', defaultValue: false) as bool,
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put('themeMode', _themeModeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    await _box.put('locale', locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setFontFamily(String fontFamily) async {
    await _box.put('fontFamily', fontFamily);
    state = state.copyWith(fontFamily: fontFamily);
  }

  Future<void> setFontSize(double size) async {
    await _box.put('fontSize', size);
    state = state.copyWith(fontSize: size);
  }

  Future<void> setCodeFontFamily(String fontFamily) async {
    await _box.put('codeFontFamily', fontFamily);
    state = state.copyWith(codeFontFamily: fontFamily);
  }

  Future<void> setCodeFontSize(double size) async {
    await _box.put('codeFontSize', size);
    state = state.copyWith(codeFontSize: size);
  }

  Future<void> setAutoSave(bool value) async {
    await _box.put('autoSave', value);
    state = state.copyWith(autoSave: value);
  }

  Future<void> setShowLineNumbers(bool value) async {
    await _box.put('showLineNumbers', value);
    state = state.copyWith(showLineNumbers: value);
  }

  Future<void> setWordWrap(bool value) async {
    await _box.put('wordWrap', value);
    state = state.copyWith(wordWrap: value);
  }

  Future<void> setSyntaxHighlight(bool value) async {
    await _box.put('syntaxHighlight', value);
    state = state.copyWith(syntaxHighlight: value);
  }

  Future<void> setDefaultTimeout(int timeout) async {
    await _box.put('defaultTimeout', timeout);
    state = state.copyWith(defaultTimeout: timeout);
  }

  Future<void> setFollowRedirects(bool value) async {
    await _box.put('followRedirects', value);
    state = state.copyWith(followRedirects: value);
  }

  Future<void> setMaxRedirects(int value) async {
    await _box.put('maxRedirects', value);
    state = state.copyWith(maxRedirects: value);
  }

  Future<void> setVerifyTls(bool value) async {
    await _box.put('verifyTls', value);
    state = state.copyWith(verifyTls: value);
  }

  Future<void> setHttpVersion(String version) async {
    await _box.put('httpVersion', version);
    state = state.copyWith(httpVersion: version);
  }

  Future<void> setEnableNotifications(bool value) async {
    await _box.put('enableNotifications', value);
    state = state.copyWith(enableNotifications: value);
  }

  Future<void> setSoundEffects(bool value) async {
    await _box.put('soundEffects', value);
    state = state.copyWith(soundEffects: value);
  }

  Future<void> setHapticFeedback(bool value) async {
    await _box.put('hapticFeedback', value);
    state = state.copyWith(hapticFeedback: value);
  }

  Future<void> setKeepScreenOn(bool value) async {
    await _box.put('keepScreenOn', value);
    state = state.copyWith(keepScreenOn: value);
  }

  Future<void> setConfirmOnExit(bool value) async {
    await _box.put('confirmOnExit', value);
    state = state.copyWith(confirmOnExit: value);
  }

  Future<void> setVerboseLogging(bool value) async {
    await _box.put('verboseLogging', value);
    state = state.copyWith(verboseLogging: value);
  }

  Future<void> setProxySettings({
    String? type,
    String? host,
    int? port,
  }) async {
    await _box.put('proxyType', type);
    await _box.put('proxyHost', host);
    await _box.put('proxyPort', port);
    state = state.copyWith(
      proxyType: type,
      proxyHost: host,
      proxyPort: port,
    );
  }

  Future<void> setUseDynamicColor(bool value) async {
    await _box.put('useDynamicColor', value);
    state = state.copyWith(useDynamicColor: value);
  }

  Future<void> setPrimaryColor(Color color) async {
    await _box.put('primaryColor', color.value);
    state = state.copyWith(primaryColor: color);
  }

  Future<void> setRetryCount(int value) async {
    await _box.put('retryCount', value);
    state = state.copyWith(retryCount: value);
  }

  Future<void> setRetryDelay(int value) async {
    await _box.put('retryDelay', value);
    state = state.copyWith(retryDelay: value);
  }

  Future<void> setCustomDns(String? dns) async {
    await _box.put('customDns', dns);
    state = state.copyWith(customDns: dns);
  }

  Future<void> setAutoBackup(bool value) async {
    await _box.put('autoBackup', value);
    state = state.copyWith(autoBackup: value);
  }

  Future<void> setAutoBackupInterval(int hours) async {
    await _box.put('autoBackupIntervalHours', hours);
    state = state.copyWith(autoBackupIntervalHours: hours);
  }

  Future<void> setDeveloperMode(bool value) async {
    await _box.put('developerMode', value);
    state = state.copyWith(developerMode: value);
  }

  Future<void> resetSettings() async {
    await _box.clear();
    _loadSettings();
  }
}

/// Providers
final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(AppConstants.settingsBox);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(settingsBoxProvider));
});

/// Convenience providers
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final localeProvider = Provider<Locale>((ref) {
  return ref.watch(settingsProvider).locale;
});
