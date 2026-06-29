/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App information
  static const String appName = 'Arabic HTTP Studio';
  static const String appNameAr = 'استوديو HTTP العربي';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '20';

  /// Hive box names
  static const String requestsBox = 'requests';
  static const String historyBox = 'history';
  static const String favoritesBox = 'favorites';
  static const String collectionsBox = 'collections';
  static const String environmentsBox = 'environments';
  static const String variablesBox = 'variables';
  static const String settingsBox = 'settings';
  static const String authBox = 'auth';
  static const String logsBox = 'logs';
  static const String websocketMessagesBox = 'websocket_messages';
  static const String cookiesBox = 'cookies';

  /// Secure storage keys
  static const String secureStorageKey = 'arabic_http_studio_secure';
  static const String encryptionKeyStorage = 'encryption_key';

  /// Default timeouts in milliseconds
  static const int defaultConnectTimeout = 30000;
  static const int defaultSendTimeout = 30000;
  static const int defaultReceiveTimeout = 30000;

  /// Default ports
  static const int defaultHttpPort = 80;
  static const int defaultHttpsPort = 443;
  static const int defaultWsPort = 80;
  static const int defaultWssPort = 443;

  /// UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;
  static const double defaultFontSize = 14.0;

  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxHistoryItems = 1000;
  static const int maxLogItems = 5000;

  /// Supported HTTP methods
  static const List<String> httpMethods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

  /// Supported content types
  static const Map<String, String> contentTypes = {
    'json': 'application/json',
    'xml': 'application/xml',
    'form': 'application/x-www-form-urlencoded',
    'multipart': 'multipart/form-data',
    'text': 'text/plain',
    'html': 'text/html',
    'binary': 'application/octet-stream',
  };

  /// Supported code generation languages
  static const List<String> codeLanguages = [
    'curl',
    'dart',
    'fetch',
    'python',
    'java',
    'kotlin',
    'php',
    'nodejs',
    'go',
    'rust',
    'csharp',
    'javascript',
  ];

  /// Export formats
  static const List<String> exportFormats = [
    'json',
    'yaml',
    'csv',
    'txt',
    'zip',
    'markdown',
    'html',
    'openapi',
    'swagger',
    'postman',
  ];

  /// Import formats
  static const List<String> importFormats = [
    'json',
    'yaml',
    'csv',
    'txt',
    'openapi',
    'swagger',
    'postman',
  ];

  /// HTTP status code ranges
  static const Map<String, List<int>> statusRanges = {
    '1xx': [100, 199],
    '2xx': [200, 299],
    '3xx': [300, 399],
    '4xx': [400, 499],
    '5xx': [500, 599],
  };
}
