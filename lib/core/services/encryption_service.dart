import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for encrypting/decrypting sensitive data
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const String _keyStorageKey = 'encryption_key_v1';
  static const int _keyLength = 32; // 256 bits

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late Key _encryptionKey;
  late IV _iv;
  late Encrypter _encrypter;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    var keyString = await _secureStorage.read(key: _keyStorageKey);

    if (keyString == null) {
      // Generate new key
      final random = Random.secure();
      final keyBytes = Uint8List(_keyLength);
      for (var i = 0; i < _keyLength; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      keyString = base64.encode(keyBytes);
      await _secureStorage.write(key: _keyStorageKey, value: keyString);
    }

    _encryptionKey = Key.fromBase64(keyString);
    _iv = IV.fromLength(16);
    _encrypter = Encrypter(AES(_encryptionKey, mode: AESMode.cbc));

    _initialized = true;
  }

  /// Encrypt a string
  String encrypt(String plainText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt a string
  String decrypt(String encryptedText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Encrypt a map
  String encryptMap(Map<String, dynamic> map) {
    return encrypt(jsonEncode(map));
  }

  /// Decrypt to map
  Map<String, dynamic> decryptMap(String encryptedText) {
    return jsonDecode(decrypt(encryptedText)) as Map<String, dynamic>;
  }

  /// Generate a random IV for each encryption (more secure)
  String encryptWithRandomIV(String plainText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final randomIV = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: randomIV);
    // Prepend IV to encrypted data
    return '${randomIV.base64}:${encrypted.base64}';
  }

  /// Decrypt with random IV
  String decryptWithRandomIV(String encryptedWithIV) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final parts = encryptedWithIV.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted format');
    }
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  /// Hash a string (for verification, not encryption)
  String hash(String input) {
    // Simple hash - use proper crypto in production
    return input.hashCode.toRadixString(16);
  }
}
