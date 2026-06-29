import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Utility functions for the application
class AppUtils {
  AppUtils._();

  /// Format bytes to human readable size
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${suffixes[index]}';
  }

  /// Format duration to human readable string
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }
    if (duration.inSeconds < 60) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  /// Format timestamp to readable date
  static String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'الآن';
    }
    if (diff.inHours < 1) {
      return 'منذ ${diff.inMinutes} دقيقة';
    }
    if (diff.inDays < 1) {
      return 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Format timestamp to readable time
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// Format timestamp to full date and time
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Validate WebSocket URL
  static bool isValidWebSocketUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'ws' || uri.scheme == 'wss') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Validate JSON string
  static bool isValidJson(String json) {
    try {
      // ignore: avoid_dynamic_calls
      jsonDecode(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pretty print JSON
  static String prettyJson(String json) {
    try {
      final decoded = jsonDecode(json);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return json;
    }
  }

  /// Encode JSON
  static dynamic jsonDecode(String json) {
    return _jsonDecoder.convert(json);
  }

  /// Decode JSON
  static String jsonEncode(dynamic object, {bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(object);
    }
    return _jsonEncoder.convert(object);
  }

  static final _jsonDecoder = const JsonDecoder();
  static final _jsonEncoder = const JsonEncoder();

  /// Generate UUID
  static String generateUuid() {
    return _uuid.v4();
  }

  static final _uuid = const Uuid();

  /// Base64 encode
  static String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }

  /// Base64 decode
  static String base64Decode(String input) {
    return utf8.decode(base64.decode(input));
  }

  /// String to bytes
  static List<int> toBytes(String input) {
    return utf8.encode(input);
  }

  /// Bytes to string
  static String fromBytes(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Convert hex string to bytes
  static List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byte = hex.substring(i, i + 2);
      result.add(int.parse(byte, radix: 16));
    }
    return result;
  }

  /// Convert bytes to hex string
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Mask sensitive value
  static String maskValue(String value) {
    if (value.length <= 4) return '****';
    return '${value.substring(0, 2)}${'*' * (value.length - 4)}${value.substring(value.length - 2)}';
  }

  /// Truncate string
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Remove duplicate items from list
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  /// Check if string is numeric
  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  /// Check if string is email
  static bool isEmail(String s) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(s);
  }

  /// Get file extension
  static String getFileExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  /// Get filename without extension
  static String getFilenameWithoutExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return filename;
    return filename.substring(0, dotIndex);
  }

  /// Escape string for JSON
  static String escapeJson(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Parse query string to map
  static Map<String, String> parseQueryString(String query) {
    final result = <String, String>{};
    final pairs = query.split('&');
    for (final pair in pairs) {
      final idx = pair.indexOf('=');
      if (idx == -1) {
        result[Uri.decodeQueryComponent(pair)] = '';
      } else {
        final key = Uri.decodeQueryComponent(pair.substring(0, idx));
        final value = Uri.decodeQueryComponent(pair.substring(idx + 1));
        result[key] = value;
      }
    }
    return result;
  }

  /// Build query string from map
  static String buildQueryString(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  /// Replace variables in template
  static String replaceVariables(
    String template,
    Map<String, String> variables,
  ) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
      result = result.replaceAll('\$${entry.key}', entry.value);
    }
    return result;
  }
}
