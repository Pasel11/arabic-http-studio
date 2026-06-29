import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/request/services/syntax_highlighter.dart';

void main() {
  group('SyntaxHighlighter', () {
    group('JSON tokenization', () {
      test('should tokenize simple JSON object', () {
        final tokens = SyntaxHighlighter.tokenize(
          '{"key": "value"}',
          CodeLanguage.json,
        );

        expect(tokens, isNotEmpty);
        expect(tokens.any((t) => t.type == TokenType.property), isTrue);
        expect(tokens.any((t) => t.type == TokenType.string), isTrue);
      });

      test('should tokenize JSON with numbers', () {
        final tokens = SyntaxHighlighter.tokenize(
          '{"count": 42, "price": 9.99}',
          CodeLanguage.json,
        );

        expect(tokens.any((t) => t.type == TokenType.number), isTrue);
      });

      test('should tokenize JSON with booleans and null', () {
        final tokens = SyntaxHighlighter.tokenize(
          '{"active": true, "deleted": false, "data": null}',
          CodeLanguage.json,
        );

        expect(tokens.any((t) => t.type == TokenType.keyword), isTrue);
      });

      test('should tokenize JSON with nested objects', () {
        final tokens = SyntaxHighlighter.tokenize(
          '{"user": {"name": "John", "age": 30}}',
          CodeLanguage.json,
        );

        expect(tokens.any((t) => t.type == TokenType.punctuation), isTrue);
      });
    });

    group('XML tokenization', () {
      test('should tokenize simple XML', () {
        final tokens = SyntaxHighlighter.tokenize(
          '<root><child>text</child></root>',
          CodeLanguage.xml,
        );

        expect(tokens.any((t) => t.type == TokenType.tag), isTrue);
      });

      test('should tokenize XML with comments', () {
        final tokens = SyntaxHighlighter.tokenize(
          '<!-- comment --><root/>',
          CodeLanguage.xml,
        );

        expect(tokens.any((t) => t.type == TokenType.comment), isTrue);
      });
    });

    group('JavaScript tokenization', () {
      test('should tokenize keywords', () {
        final tokens = SyntaxHighlighter.tokenize(
          'const x = function() { return true; }',
          CodeLanguage.javascript,
        );

        expect(tokens.any((t) => t.type == TokenType.keyword), isTrue);
      });

      test('should tokenize strings', () {
        final tokens = SyntaxHighlighter.tokenize(
          'var name = "hello";',
          CodeLanguage.javascript,
        );

        expect(tokens.any((t) => t.type == TokenType.string), isTrue);
      });

      test('should tokenize comments', () {
        final tokens = SyntaxHighlighter.tokenize(
          '// comment\nvar x = 1; /* block */',
          CodeLanguage.javascript,
        );

        expect(tokens.any((t) => t.type == TokenType.comment), isTrue);
      });

      test('should tokenize numbers', () {
        final tokens = SyntaxHighlighter.tokenize(
          'var x = 42;',
          CodeLanguage.javascript,
        );

        expect(tokens.any((t) => t.type == TokenType.number), isTrue);
      });
    });
  });

  group('CodeFormatter', () {
    group('JSON formatting', () {
      test('should beautify JSON', () {
        const input = '{"key":"value","number":42}';
        final result = CodeFormatter.beautify(input, CodeLanguage.json);

        expect(result, contains('"key": "value"'));
        expect(result, contains('\n'));
      });

      test('should minify JSON', () {
        const input = '{\n  "key": "value",\n  "number": 42\n}';
        final result = CodeFormatter.minify(input, CodeLanguage.json);

        expect(result, isNot(contains('\n')));
      });

      test('should validate valid JSON', () {
        const input = '{"key": "value"}';
        final result = CodeFormatter.validate(input, CodeLanguage.json);

        expect(result.isValid, isTrue);
      });

      test('should detect invalid JSON', () {
        const input = '{invalid json}';
        final result = CodeFormatter.validate(input, CodeLanguage.json);

        expect(result.isValid, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('XML formatting', () {
      test('should beautify XML', () {
        const input = '<root><child>text</child></root>';
        final result = CodeFormatter.beautify(input, CodeLanguage.xml);

        expect(result, contains('\n'));
      });

      test('should minify XML', () {
        const input = '<root>\n  <child>text</child>\n</root>';
        final result = CodeFormatter.minify(input, CodeLanguage.xml);

        expect(result, isNot(contains('\n')));
      });

      test('should validate balanced XML', () {
        const input = '<root><child>text</child></root>';
        final result = CodeFormatter.validate(input, CodeLanguage.xml);

        expect(result.isValid, isTrue);
      });

      test('should detect unbalanced XML', () {
        const input = '<root><child>text</root>';
        final result = CodeFormatter.validate(input, CodeLanguage.xml);

        expect(result.isValid, isFalse);
      });
    });
  });

  group('CodeLanguage', () {
    test('should return correct display names', () {
      expect(CodeLanguage.json.displayName, 'JSON');
      expect(CodeLanguage.xml.displayName, 'XML');
      expect(CodeLanguage.html.displayName, 'HTML');
      expect(CodeLanguage.javascript.displayName, 'JavaScript');
    });

    test('should return correct file extensions', () {
      expect(CodeLanguage.json.fileExtension, '.json');
      expect(CodeLanguage.xml.fileExtension, '.xml');
      expect(CodeLanguage.javascript.fileExtension, '.js');
    });

    test('should return correct content types', () {
      expect(CodeLanguage.json.contentType, 'application/json');
      expect(CodeLanguage.xml.contentType, 'application/xml');
      expect(CodeLanguage.html.contentType, 'text/html');
    });
  });
}
