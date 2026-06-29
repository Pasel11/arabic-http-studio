import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/network_service.dart';
import 'encryption_service.dart';

/// Initialization service for app startup
class InitializationService {
  InitializationService._();
  static final InitializationService instance = InitializationService._();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize encryption service
    await EncryptionService.instance.initialize();

    // Verify Hive boxes are open
    _verifyBoxesOpen();

    // Initialize network service
    NetworkService.instance.initialize();

    _initialized = true;
  }

  void _verifyBoxesOpen() {
    final requiredBoxes = [
      AppConstants.requestsBox,
      AppConstants.historyBox,
      AppConstants.favoritesBox,
      AppConstants.collectionsBox,
      AppConstants.environmentsBox,
      AppConstants.variablesBox,
      AppConstants.settingsBox,
      AppConstants.authBox,
      AppConstants.logsBox,
      AppConstants.websocketMessagesBox,
      AppConstants.cookiesBox,
    ];

    for (final boxName in requiredBoxes) {
      if (!Hive.isBoxOpen(boxName)) {
        throw StateError('Required box "$boxName" is not open');
      }
    }
  }

  /// Get secure storage
  FlutterSecureStorage get secureStorage => _secureStorage;
}
