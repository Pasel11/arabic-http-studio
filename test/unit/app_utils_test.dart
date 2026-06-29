import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/core/utils/app_utils.dart';

void main() {
  group('AppUtils', () {
    group('formatBytes', () {
      test('formats 0 bytes', () {
        expect(AppUtils.formatBytes(0), '0 B');
      });

      test('formats bytes', () {
        expect(AppUtils.formatBytes(500), '500 B');
      });

      test('formats kilobytes', () {
        expect(AppUtils.formatBytes(1024), '1.0 KB');
      });

      test('formats megabytes', () {
        expect(AppUtils.formatBytes(1024 * 1024), '1.0 MB');
      });

      test('formats gigabytes', () {
        expect(AppUtils.formatBytes(1024 * 1024 * 1024), '1.0 GB');
      });
    });

    group('formatDuration', () {
      test('formats milliseconds', () {
        expect(AppUtils.formatDuration(const Duration(milliseconds: 500)), '500 ms');
      });

      test('formats seconds', () {
        expect(AppUtils.formatDuration(const Duration(milliseconds: 1500)), '1.50 s');
      });

      test('formats minutes', () {
        expect(AppUtils.formatDuration(const Duration(minutes: 5)), '5m 0s');
      });
    });

    group('isValidUrl', () {
      test('validates HTTP URL', () {
        expect(AppUtils.isValidUrl('http://example.com'), isTrue);
      });

      test('validates HTTPS URL', () {
        expect(AppUtils.isValidUrl('https://example.com'), isTrue);
      });

      test('rejects invalid URL', () {
        expect(AppUtils.isValidUrl('not-a-url'), isFalse);
      });

      test('rejects FTP URL', () {
        expect(AppUtils.isValidUrl('ftp://example.com'), isFalse);
      });
    });

    group('isValidWebSocketUrl', () {
      test('validates WS URL', () {
        expect(AppUtils.isValidWebSocketUrl('ws://example.com'), isTrue);
      });

      test('validates WSS URL', () {
        expect(AppUtils.isValidWebSocketUrl('wss://example.com'), isTrue);
      });

      test('rejects HTTP URL', () {
        expect(AppUtils.isValidWebSocketUrl('https://example.com'), isFalse);
      });
    });

    group('isValidJson', () {
      test('validates valid JSON object', () {
        expect(AppUtils.isValidJson('{"key": "value"}'), isTrue);
      });

      test('validates valid JSON array', () {
        expect(AppUtils.isValidJson('[1, 2, 3]'), isTrue);
      });

      test('rejects invalid JSON', () {
        expect(AppUtils.isValidJson('{invalid}'), isFalse);
      });
    });

    group('maskValue', () {
      test('masks short values', () {
        expect(AppUtils.maskValue('abc'), '****');
      });

      test('masks long values', () {
        expect(AppUtils.maskValue('abcdefgh'), 'ab****gh');
      });
    });

    group('truncate', () {
      test('returns original if shorter than max', () {
        expect(AppUtils.truncate('hello', 10), 'hello');
      });

      test('truncates if longer than max', () {
        expect(AppUtils.truncate('hello world', 5), 'hello...');
      });
    });

    group('getFileExtension', () {
      test('gets extension', () {
        expect(AppUtils.getFileExtension('file.txt'), 'txt');
      });

      test('handles no extension', () {
        expect(AppUtils.getFileExtension('file'), '');
      });

      test('handles multiple dots', () {
        expect(AppUtils.getFileExtension('file.name.txt'), 'txt');
      });
    });

    group('parseQueryString', () {
      test('parses query string', () {
        final result = AppUtils.parseQueryString('key1=value1&key2=value2');
        expect(result['key1'], 'value1');
        expect(result['key2'], 'value2');
      });

      test('handles encoded values', () {
        final result = AppUtils.parseQueryString('key=hello%20world');
        expect(result['key'], 'hello world');
      });
    });

    group('buildQueryString', () {
      test('builds query string', () {
        final result = AppUtils.buildQueryString({'key1': 'value1', 'key2': 'value2'});
        expect(result, contains('key1=value1'));
        expect(result, contains('key2=value2'));
      });
    });

    group('replaceVariables', () {
      test('replaces {{var}} syntax', () {
        final result = AppUtils.replaceVariables(
          'Hello {{name}}!',
          {'name': 'World'},
        );
        expect(result, 'Hello World!');
      });

      test('replaces \$var syntax', () {
        final result = AppUtils.replaceVariables(
          'Hello \$name!',
          {'name': 'World'},
        );
        expect(result, 'Hello World!');
      });
    });

    group('isNumeric', () {
      test('validates integers', () {
        expect(AppUtils.isNumeric('123'), isTrue);
      });

      test('validates decimals', () {
        expect(AppUtils.isNumeric('12.34'), isTrue);
      });

      test('rejects non-numeric', () {
        expect(AppUtils.isNumeric('abc'), isFalse);
      });
    });

    group('isEmail', () {
      test('validates email', () {
        expect(AppUtils.isEmail('test@example.com'), isTrue);
      });

      test('rejects invalid email', () {
        expect(AppUtils.isEmail('not-an-email'), isFalse);
      });
    });
  });
}
