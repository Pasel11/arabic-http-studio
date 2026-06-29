import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Comprehensive encoding and crypto tools service.
///
/// Provides utilities for:
/// - Base64 encode/decode
/// - URL encode/decode
/// - Unicode encode/decode
/// - Hashing (MD5, SHA1, SHA256, SHA512)
/// - HMAC
/// - Hex encode/decode
class EncodingCryptoService {
  EncodingCryptoService._();
  static final EncodingCryptoService instance = EncodingCryptoService._();

  // ===========================================================================
  // Base64
  // ===========================================================================

  /// Encodes a string to Base64.
  String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }

  /// Decodes a Base64 string.
  String base64Decode(String input) {
    try {
      return utf8.decode(base64.decode(input));
    } catch (e) {
      return 'خطأ في فك الترميز: $e';
    }
  }

  /// Encodes file bytes to Base64.
  String base64EncodeBytes(List<int> bytes) {
    return base64.encode(bytes);
  }

  /// Decodes Base64 to bytes.
  List<int> base64DecodeToBytes(String input) {
    try {
      return base64.decode(input);
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // URL Encoding
  // ===========================================================================

  /// URL-encodes a string.
  String urlEncode(String input) {
    return Uri.encodeComponent(input);
  }

  /// URL-decodes a string.
  String urlDecode(String input) {
    try {
      return Uri.decodeComponent(input);
    } catch (e) {
      return 'خطأ في فك الترميز: $e';
    }
  }

  // ===========================================================================
  // Unicode
  // ===========================================================================

  /// Encodes a string to Unicode escape sequences.
  String unicodeEncode(String input) {
    final buffer = StringBuffer();
    for (final char in input.codeUnits) {
      if (char > 127) {
        buffer.write('\\u${char.toRadixString(16).padLeft(4, '0')}');
      } else {
        buffer.write(String.fromCharCode(char));
      }
    }
    return buffer.toString();
  }

  /// Decodes Unicode escape sequences.
  String unicodeDecode(String input) {
    return input.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) {
        final code = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(code);
      },
    );
  }

  // ===========================================================================
  // Hex
  // ===========================================================================

  /// Encodes a string to hex.
  String hexEncode(String input) {
    return input.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Decodes a hex string.
  String hexDecode(String input) {
    final cleanInput = input.replaceAll(RegExp(r'[\s-]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleanInput.length; i += 2) {
      if (i + 2 <= cleanInput.length) {
        final hex = cleanInput.substring(i, i + 2);
        final code = int.tryParse(hex, radix: 16);
        if (code != null) {
          buffer.write(String.fromCharCode(code));
        }
      }
    }
    return buffer.toString();
  }

  // ===========================================================================
  // Hashing
  // ===========================================================================

  /// Computes MD5 hash.
  String md5Hash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// Computes SHA-1 hash.
  String sha1Hash(String input) {
    return sha1.convert(utf8.encode(input)).toString();
  }

  /// Computes SHA-256 hash.
  String sha256Hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Computes SHA-512 hash.
  String sha512Hash(String input) {
    return sha512.convert(utf8.encode(input)).toString();
  }

  /// Computes HMAC-SHA256.
  String hmacSha256(String key, String message) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// Computes HMAC-SHA512.
  String hmacSha512(String key, String message) {
    final hmac = Hmac(sha512, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// Computes HMAC-MD5.
  String hmacMd5(String key, String message) {
    final hmac = Hmac(md5, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// Computes HMAC-SHA1.
  String hmacSha1(String key, String message) {
    final hmac = Hmac(sha1, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  // ===========================================================================
  // Utility
  // ===========================================================================

  /// Generates a UUID v4.
  String generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now ^ (now >> 32);
    final hex = random.toRadixString(16).padLeft(16, '0');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-a${hex.substring(16, 19)}-${hex.substring(0, 12)}';
  }

  /// Generates a random hex string of the specified length.
  String generateRandomHex(int length) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    var seed = now;
    for (var i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(seed.toRadixString(16).substring(0, 1));
    }
    return buffer.toString();
  }
}
