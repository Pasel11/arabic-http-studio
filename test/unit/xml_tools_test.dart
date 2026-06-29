import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/xml/services/xml_tools_service.dart';

void main() {
  group('XmlToolsService', () {
    final service = XmlToolsService.instance;

    group('validate', () {
      test('should validate valid XML', () {
        const xml = '<root><child>text</child></root>';
        final result = service.validate(xml);
        expect(result.isValid, isTrue);
      });

      test('should detect invalid XML', () {
        const xml = '<root><child>text</root>';
        final result = service.validate(xml);
        expect(result.isValid, isFalse);
        expect(result.error, isNotNull);
      });

      test('should reject empty string', () {
        const xml = '';
        final result = service.validate(xml);
        expect(result.isValid, isFalse);
      });

      test('should validate XML with attributes', () {
        const xml = '<root attr="value"><child/></root>';
        final result = service.validate(xml);
        expect(result.isValid, isTrue);
      });

      test('should validate XML with comments', () {
        const xml = '<!-- comment --><root/>';
        final result = service.validate(xml);
        expect(result.isValid, isTrue);
      });
    });

    group('minify', () {
      test('should minify XML', () {
        const xml = '<root>\n  <child>text</child>\n</root>';
        final result = service.minify(xml);
        expect(result, isNot(contains('\n')));
      });
    });

    group('buildTree', () {
      test('should build tree for simple XML', () {
        const xml = '<root><child>text</child></root>';
        final tree = service.buildTree(xml);
        expect(tree.type, XmlNodeType.element);
        expect(tree.name, 'root');
        expect(tree.children, isNotEmpty);
      });

      test('should build tree with attributes', () {
        const xml = '<root attr="value"><child/></root>';
        final tree = service.buildTree(xml);
        expect(tree.attributes['attr'], 'value');
      });

      test('should return invalid node for bad XML', () {
        const xml = '<invalid';
        final tree = service.buildTree(xml);
        expect(tree.type, XmlNodeType.invalid);
      });
    });

    group('compare', () {
      test('should detect identical XMLs', () {
        const xml1 = '<root><child>text</child></root>';
        const xml2 = '<root><child>text</child></root>';
        final result = service.compare(xml1, xml2);
        expect(result.areEqual, isTrue);
      });

      test('should detect different text content', () {
        const xml1 = '<root>text1</root>';
        const xml2 = '<root>text2</root>';
        final result = service.compare(xml1, xml2);
        expect(result.areEqual, isFalse);
      });

      test('should detect attribute changes', () {
        const xml1 = '<root attr="value1"/>';
        const xml2 = '<root attr="value2"/>';
        final result = service.compare(xml1, xml2);
        expect(result.areEqual, isFalse);
      });

      test('should handle invalid XML', () {
        const xml1 = '<invalid';
        const xml2 = '<root/>';
        final result = service.compare(xml1, xml2);
        expect(result.areEqual, isFalse);
        expect(result.error, isNotNull);
      });
    });
  });

  group('XmlNodeType', () {
    test('should have all expected types', () {
      expect(XmlNodeType.values, contains(XmlNodeType.element));
      expect(XmlNodeType.values, contains(XmlNodeType.text));
      expect(XmlNodeType.values, contains(XmlNodeType.comment));
      expect(XmlNodeType.values, contains(XmlNodeType.invalid));
    });
  });

  group('XmlDifferenceType', () {
    test('should have all expected types', () {
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.nameChanged));
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.attributeAdded));
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.attributeRemoved));
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.attributeChanged));
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.textChanged));
      expect(XmlDifferenceType.values, contains(XmlDifferenceType.childCountChanged));
    });
  });
}
