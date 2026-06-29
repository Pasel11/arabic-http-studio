import 'dart:convert';

/// Supported code languages for the editor.
enum CodeLanguage {
  json,
  xml,
  html,
  javascript,
  dart,
  python,
  yaml,
  markdown,
  text,
}

/// Extension methods for [CodeLanguage].
extension CodeLanguageExtension on CodeLanguage {
  /// Returns the display name of the language.
  String get displayName {
    switch (this) {
      case CodeLanguage.json:
        return 'JSON';
      case CodeLanguage.xml:
        return 'XML';
      case CodeLanguage.html:
        return 'HTML';
      case CodeLanguage.javascript:
        return 'JavaScript';
      case CodeLanguage.dart:
        return 'Dart';
      case CodeLanguage.python:
        return 'Python';
      case CodeLanguage.yaml:
        return 'YAML';
      case CodeLanguage.markdown:
        return 'Markdown';
      case CodeLanguage.text:
        return 'Text';
    }
  }

  /// Returns the file extension for the language.
  String get fileExtension {
    switch (this) {
      case CodeLanguage.json:
        return '.json';
      case CodeLanguage.xml:
        return '.xml';
      case CodeLanguage.html:
        return '.html';
      case CodeLanguage.javascript:
        return '.js';
      case CodeLanguage.dart:
        return '.dart';
      case CodeLanguage.python:
        return '.py';
      case CodeLanguage.yaml:
        return '.yaml';
      case CodeLanguage.markdown:
        return '.md';
      case CodeLanguage.text:
        return '.txt';
    }
  }

  /// Returns the default content type for the language.
  String get contentType {
    switch (this) {
      case CodeLanguage.json:
        return 'application/json';
      case CodeLanguage.xml:
        return 'application/xml';
      case CodeLanguage.html:
        return 'text/html';
      case CodeLanguage.javascript:
        return 'application/javascript';
      case CodeLanguage.dart:
        return 'text/x-dart';
      case CodeLanguage.python:
        return 'text/x-python';
      case CodeLanguage.yaml:
        return 'application/x-yaml';
      case CodeLanguage.markdown:
        return 'text/markdown';
      case CodeLanguage.text:
        return 'text/plain';
    }
  }
}

/// A token in the code, representing a syntactic element.
class CodeToken {
  /// Creates a code token.
  const CodeToken({
    required this.type,
    required this.text,
    required this.start,
    required this.end,
  });

  /// The type of the token.
  final TokenType type;

  /// The text content of the token.
  final String text;

  /// The start position in the source text.
  final int start;

  /// The end position in the source text.
  final int end;
}

/// Types of code tokens for syntax highlighting.
enum TokenType {
  keyword,
  string,
  number,
  comment,
  operator,
  punctuation,
  identifier,
  property,
  tag,
  attribute,
  value,
  plain,
}

/// Syntax highlighter for code.
///
/// This class tokenizes source code and applies syntax highlighting
/// based on the language.
class SyntaxHighlighter {
  SyntaxHighlighter._();

  /// Tokenizes the given source code based on the language.
  static List<CodeToken> tokenize(String source, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.json:
        return _tokenizeJson(source);
      case CodeLanguage.xml:
        return _tokenizeXml(source);
      case CodeLanguage.html:
        return _tokenizeHtml(source);
      case CodeLanguage.javascript:
        return _tokenizeJavaScript(source);
      case CodeLanguage.yaml:
        return _tokenizeYaml(source);
      default:
        return [CodeToken(type: TokenType.plain, text: source, start: 0, end: source.length)];
    }
  }

  /// Tokenizes JSON source code.
  static List<CodeToken> _tokenizeJson(String source) {
    final tokens = <CodeToken>[];
    var i = 0;

    while (i < source.length) {
      final char = source[i];

      // Skip whitespace
      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        final start = i;
        while (i < source.length &&
            (source[i] == ' ' || source[i] == '\t' || source[i] == '\n' || source[i] == '\r')) {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.plain,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Strings
      if (char == '"') {
        final start = i;
        i++;
        while (i < source.length && source[i] != '"') {
          if (source[i] == '\\' && i + 1 < source.length) {
            i += 2;
          } else {
            i++;
          }
        }
        i++; // closing quote

        // Check if it's a property name (followed by colon)
        var j = i;
        while (j < source.length && (source[j] == ' ' || source[j] == '\t')) {
          j++;
        }

        final isProperty = j < source.length && source[j] == ':';
        tokens.add(CodeToken(
          type: isProperty ? TokenType.property : TokenType.string,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Numbers
      if (char == '-' || (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57)) {
        final start = i;
        if (char == '-') i++;
        while (i < source.length &&
            ((source[i].codeUnitAt(0) >= 48 && source[i].codeUnitAt(0) <= 57) ||
                source[i] == '.' ||
                source[i] == 'e' ||
                source[i] == 'E' ||
                source[i] == '+' ||
                source[i] == '-')) {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.number,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Keywords
      if (source.startsWith('true', i) || source.startsWith('false', i) || source.startsWith('null', i)) {
        final keyword = source.startsWith('true', i)
            ? 'true'
            : source.startsWith('false', i)
                ? 'false'
                : 'null';
        tokens.add(CodeToken(
          type: TokenType.keyword,
          text: keyword,
          start: i,
          end: i + keyword.length,
        ));
        i += keyword.length;
        continue;
      }

      // Punctuation
      if (char == '{' || char == '}' || char == '[' || char == ']' || char == ':' || char == ',') {
        tokens.add(CodeToken(
          type: TokenType.punctuation,
          text: char,
          start: i,
          end: i + 1,
        ));
        i++;
        continue;
      }

      // Default
      tokens.add(CodeToken(
        type: TokenType.plain,
        text: char,
        start: i,
        end: i + 1,
      ));
      i++;
    }

    return tokens;
  }

  /// Tokenizes XML source code.
  static List<CodeToken> _tokenizeXml(String source) {
    final tokens = <CodeToken>[];
    var i = 0;

    while (i < source.length) {
      // Comments
      if (source.startsWith('<!--', i)) {
        final start = i;
        i += 4;
        while (i < source.length && !source.startsWith('-->', i)) {
          i++;
        }
        i += 3;
        tokens.add(CodeToken(
          type: TokenType.comment,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Tags
      if (source[i] == '<') {
        final start = i;
        i++;
        while (i < source.length && source[i] != '>') {
          i++;
        }
        i++; // closing >
        tokens.add(CodeToken(
          type: TokenType.tag,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Text content
      final start = i;
      while (i < source.length && source[i] != '<') {
        i++;
      }
      if (i > start) {
        tokens.add(CodeToken(
          type: TokenType.plain,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
      }
    }

    return tokens;
  }

  /// Tokenizes HTML source code (similar to XML but with attributes).
  static List<CodeToken> _tokenizeHtml(String source) {
    return _tokenizeXml(source);
  }

  /// Tokenizes JavaScript source code.
  static List<CodeToken> _tokenizeJavaScript(String source) {
    final tokens = <CodeToken>[];
    final keywords = {
      'var', 'let', 'const', 'function', 'return', 'if', 'else', 'for',
      'while', 'do', 'switch', 'case', 'break', 'continue', 'new',
      'this', 'class', 'extends', 'super', 'import', 'export', 'from',
      'default', 'try', 'catch', 'finally', 'throw', 'typeof', 'instanceof',
      'in', 'of', 'async', 'await', 'yield', 'true', 'false', 'null',
      'undefined', 'void', 'delete',
    };

    var i = 0;
    while (i < source.length) {
      final char = source[i];

      // Whitespace
      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        final start = i;
        while (i < source.length &&
            (source[i] == ' ' || source[i] == '\t' || source[i] == '\n' || source[i] == '\r')) {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.plain,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Comments
      if (source.startsWith('//', i)) {
        final start = i;
        while (i < source.length && source[i] != '\n') {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.comment,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      if (source.startsWith('/*', i)) {
        final start = i;
        i += 2;
        while (i < source.length && !source.startsWith('*/', i)) {
          i++;
        }
        i += 2;
        tokens.add(CodeToken(
          type: TokenType.comment,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Strings
      if (char == '"' || char == "'" || char == '`') {
        final quote = char;
        final start = i;
        i++;
        while (i < source.length && source[i] != quote) {
          if (source[i] == '\\' && i + 1 < source.length) {
            i += 2;
          } else {
            i++;
          }
        }
        i++;
        tokens.add(CodeToken(
          type: TokenType.string,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Numbers
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        final start = i;
        while (i < source.length &&
            ((source[i].codeUnitAt(0) >= 48 && source[i].codeUnitAt(0) <= 57) ||
                source[i] == '.')) {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.number,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Identifiers and keywords
      if (_isIdentifierChar(char)) {
        final start = i;
        while (i < source.length && _isIdentifierChar(source[i])) {
          i++;
        }
        final word = source.substring(start, i);
        tokens.add(CodeToken(
          type: keywords.contains(word) ? TokenType.keyword : TokenType.identifier,
          text: word,
          start: start,
          end: i,
        ));
        continue;
      }

      // Operators
      if (_isOperator(char)) {
        final start = i;
        while (i < source.length && _isOperator(source[i])) {
          i++;
        }
        tokens.add(CodeToken(
          type: TokenType.operator,
          text: source.substring(start, i),
          start: start,
          end: i,
        ));
        continue;
      }

      // Punctuation
      tokens.add(CodeToken(
        type: TokenType.punctuation,
        text: char,
        start: i,
        end: i + 1,
      ));
      i++;
    }

    return tokens;
  }

  /// Tokenizes YAML source code.
  static List<CodeToken> _tokenizeYaml(String source) {
    final tokens = <CodeToken>[];
    final lines = source.split('\n');
    var position = 0;

    for (final line in lines) {
      // Comments
      if (line.trimLeft().startsWith('#')) {
        tokens.add(CodeToken(
          type: TokenType.comment,
          text: line,
          start: position,
          end: position + line.length,
        ));
      } else {
        // Key-value pairs
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          tokens.add(CodeToken(
            type: TokenType.property,
            text: line.substring(0, colonIndex),
            start: position,
            end: position + colonIndex,
          ));
          tokens.add(CodeToken(
            type: TokenType.punctuation,
            text: ':',
            start: position + colonIndex,
            end: position + colonIndex + 1,
          ));
          if (colonIndex + 1 < line.length) {
            tokens.add(CodeToken(
              type: TokenType.string,
              text: line.substring(colonIndex + 1),
              start: position + colonIndex + 1,
              end: position + line.length,
            ));
          }
        } else {
          tokens.add(CodeToken(
            type: TokenType.plain,
            text: line,
            start: position,
            end: position + line.length,
          ));
        }
      }
      position += line.length + 1; // +1 for newline
    }

    return tokens;
  }

  static bool _isIdentifierChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        (code >= 48 && code <= 57) || // 0-9
        char == '_' ||
        char == '$';
  }

  static bool _isOperator(String char) {
    return '+-*/%=<>!&|^~?'.contains(char);
  }
}

/// Code formatter for various languages.
class CodeFormatter {
  CodeFormatter._();

  /// Beautifies (pretty-prints) the given source code.
  static String beautify(String source, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.json:
        return _beautifyJson(source);
      case CodeLanguage.xml:
        return _beautifyXml(source);
      case CodeLanguage.html:
        return _beautifyHtml(source);
      default:
        return source;
    }
  }

  /// Minifies the given source code.
  static String minify(String source, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.json:
        return _minifyJson(source);
      case CodeLanguage.xml:
        return _minifyXml(source);
      case CodeLanguage.html:
        return _minifyHtml(source);
      default:
        return source;
    }
  }

  /// Validates the given source code.
  static ValidationResult validate(String source, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.json:
        return _validateJson(source);
      case CodeLanguage.xml:
        return _validateXml(source);
      default:
        return ValidationResult(isValid: true);
    }
  }

  /// Beautifies JSON.
  static String _beautifyJson(String source) {
    try {
      final decoded = jsonDecode(source);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      return source;
    }
  }

  /// Minifies JSON.
  static String _minifyJson(String source) {
    try {
      final decoded = jsonDecode(source);
      return jsonEncode(decoded);
    } catch (e) {
      return source;
    }
  }

  /// Beautifies XML.
  static String _beautifyXml(String source) {
    final buffer = StringBuffer();
    var indent = 0;
    var i = 0;

    while (i < source.length) {
      if (source[i] == '<') {
        if (i + 1 < source.length && source[i + 1] == '/') {
          indent--;
          buffer.writeln();
          buffer.write('  ' * indent);
        } else if (i + 1 < source.length && source[i + 1] == '!') {
          buffer.writeln();
          buffer.write('  ' * indent);
        } else {
          if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
            buffer.writeln();
            buffer.write('  ' * indent);
          }
        }

        while (i < source.length && source[i] != '>') {
          buffer.write(source[i]);
          i++;
        }
        buffer.write('>');

        if (i > 0 && source[i - 1] != '/' && source[i - 1] != '?') {
          indent++;
        }
      } else {
        buffer.write(source[i]);
      }
      i++;
    }

    return buffer.toString();
  }

  /// Minifies XML.
  static String _minifyXml(String source) {
    return source.replaceAll(RegExp(r'>\s+<'), '><').trim();
  }

  /// Beautifies HTML.
  static String _beautifyHtml(String source) {
    return _beautifyXml(source);
  }

  /// Minifies HTML.
  static String _minifyHtml(String source) {
    return source
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Validates JSON.
  static ValidationResult _validateJson(String source) {
    try {
      jsonDecode(source);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// Validates XML.
  static ValidationResult _validateXml(String source) {
    // Basic validation - check for balanced tags
    final openTags = <String>[];
    final tagPattern = RegExp(r'<(/?)(\w+)[^>]*?(/?)>');

    for (final match in tagPattern.allMatches(source)) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!;
      final isSelfClosing = match.group(3) == '/';

      if (isClosing) {
        if (openTags.isEmpty || openTags.last != tagName) {
          return ValidationResult(
            isValid: false,
            error: 'وسم الإغلاق غير متطابق: $tagName',
          );
        }
        openTags.removeLast();
      } else if (!isSelfClosing) {
        openTags.add(tagName);
      }
    }

    if (openTags.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'وسوم غير مغلقة: ${openTags.join(', ')}',
      );
    }

    return ValidationResult(isValid: true);
  }
}

/// Result of code validation.
class ValidationResult {
  /// Creates a validation result.
  const ValidationResult({
    required this.isValid,
    this.error,
  });

  /// Whether the code is valid.
  final bool isValid;

  /// The error message if invalid.
  final String? error;
}
