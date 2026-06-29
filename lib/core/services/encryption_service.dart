import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:hive/hive.dart';

/// Service for encrypting/decrypting sensitive data.
///
/// This service uses AES-256 encryption with keys stored in Hive.
/// The encryption key is generated on first run and persisted.
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const String _keyStorageKey = 'encryption_key_v1';
  static const int _keyLength = 32; // 256 bits

  late Key _encryptionKey;
  late IV _iv;
  late Encrypter _encrypter;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initializes the encryption service.
  ///
  /// Loads or generates the encryption key from Hive storage.
  Future<void> initialize() async {
    if (_initialized) return;

    final box = await Hive.openBox<dynamic>('secure_storage');

    var keyString = box.get(_keyStorageKey) as String?;

    if (keyString == null) {
      // Generate new key
      final random = Random.secure();
      final keyBytes = Uint8List(_keyLength);
      for (var i = 0; i < _keyLength; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      keyString = base64.encode(keyBytes);
      await box.put(_keyStorageKey, keyString);
    }

    _encryptionKey = Key.fromBase64(keyString);
    _iv = IV.fromLength(16);
    _encrypter = Encrypter(AES(_encryptionKey, mode: AESMode.cbc));

    _initialized = true;
  }

  /// Encrypts a string.
  String encrypt(String plainText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a string.
  String decrypt(String encryptedText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Encrypts a map.
  String encryptMap(Map<String, dynamic> map) {
    return encrypt(jsonEncode(map));
  }

  /// Decrypts to map.
  Map<String, dynamic> decryptMap(String encryptedText) {
    return jsonDecode(decrypt(encryptedText)) as Map<String, dynamic>;
  }

  /// Encrypts with a random IV (more secure).
  String encryptWithRandomIV(String plainText) {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    final randomIV = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: randomIV);
    return '${randomIV.base64}:${encrypted.base64}';
  }

  /// Decrypts with random IV.
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

  /// Hashes a string (for verification, not encryption).
  String hash(String input) {
    return input.hashCode.toRadixString(16);
  }
}
