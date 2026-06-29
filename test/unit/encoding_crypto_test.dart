import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/crypto/services/encoding_crypto_service.dart';

void main() {
  group('EncodingCryptoService', () {
    final service = EncodingCryptoService.instance;

    group('Base64', () {
      test('should encode string to Base64', () {
        final result = service.base64Encode('Hello');
        expect(result, 'SGVsbG8=');
      });

      test('should decode Base64 to string', () {
        final result = service.base64Decode('SGVsbG8=');
        expect(result, 'Hello');
      });

      test('should handle Arabic text', () {
        final encoded = service.base64Encode('مرحبا');
        final decoded = service.base64Decode(encoded);
        expect(decoded, 'مرحبا');
      });

      test('should handle empty string', () {
        expect(service.base64Encode(''), '');
        expect(service.base64Decode(''), '');
      });
    });

    group('URL Encoding', () {
      test('should encode URL', () {
        final result = service.urlEncode('hello world');
        expect(result, 'hello%20world');
      });

      test('should decode URL', () {
        final result = service.urlDecode('hello%20world');
        expect(result, 'hello world');
      });

      test('should encode special characters', () {
        final result = service.urlEncode('a=1&b=2');
        expect(result, contains('%3D'));
        expect(result, contains('%26'));
      });
    });

    group('Unicode', () {
      test('should encode non-ASCII characters', () {
        final result = service.unicodeEncode('مرحبا');
        expect(result, contains('\\u'));
      });

      test('should decode Unicode escapes', () {
        final result = service.unicodeDecode('\\u0041');
        expect(result, 'A');
      });

      test('should keep ASCII as-is', () {
        final result = service.unicodeEncode('Hello');
        expect(result, 'Hello');
      });
    });

    group('Hex', () {
      test('should encode to hex', () {
        final result = service.hexEncode('AB');
        expect(result, '4142');
      });

      test('should decode from hex', () {
        final result = service.hexDecode('4142');
        expect(result, 'AB');
      });

      test('should handle empty string', () {
        expect(service.hexEncode(''), '');
      });
    });

    group('Hashing', () {
      test('should compute MD5', () {
        final result = service.md5Hash('Hello');
        expect(result, '8b1a9953c4611296a827abf8c47804d7');
      });

      test('should compute SHA-1', () {
        final result = service.sha1Hash('Hello');
        expect(result, 'f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0');
      });

      test('should compute SHA-256', () {
        final result = service.sha256Hash('Hello');
        expect(result, '185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969');
      });

      test('should compute SHA-512', () {
        final result = service.sha512Hash('Hello');
        expect(result.length, 128);
      });

      test('should produce consistent hashes', () {
        final hash1 = service.md5Hash('test');
        final hash2 = service.md5Hash('test');
        expect(hash1, hash2);
      });
    });

    group('HMAC', () {
      test('should compute HMAC-SHA256', () {
        final result = service.hmacSha256('key', 'message');
        expect(result, isNotEmpty);
        expect(result.length, 64);
      });

      test('should compute HMAC-SHA512', () {
        final result = service.hmacSha512('key', 'message');
        expect(result, isNotEmpty);
        expect(result.length, 128);
      });

      test('should produce different results for different keys', () {
        final hash1 = service.hmacSha256('key1', 'message');
        final hash2 = service.hmacSha256('key2', 'message');
        expect(hash1, isNot(hash2));
      });
    });

    group('UUID', () {
      test('should generate UUID', () {
        final uuid = service.generateUuid();
        expect(uuid, isNotEmpty);
        expect(uuid.contains('-'), isTrue);
      });

      test('should generate unique UUIDs', () {
        final uuid1 = service.generateUuid();
        final uuid2 = service.generateUuid();
        expect(uuid1, isNot(uuid2));
      });
    });
  });
}
