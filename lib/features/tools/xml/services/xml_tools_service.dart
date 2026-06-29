import 'package:xml/xml.dart';

/// Comprehensive XML tools service.
///
/// Provides utilities for:
/// - Formatting (pretty-print)
/// - Validation
/// - Tree building
/// - Comparison
class XmlToolsService {
  XmlToolsService._();
  static final XmlToolsService instance = XmlToolsService._();

  /// Formats (beautifies) an XML string.
  String format(String xmlString, {int indent = 2}) {
    try {
      final document = XmlDocument.parse(xmlString);
      final buffer = StringBuffer();
      _writeFormatted(document, buffer, 0, indent);
      return buffer.toString();
    } catch (e) {
      return xmlString;
    }
  }

  void _writeFormatted(
    XmlDocument document,
    StringBuffer buffer,
    int level,
    int indent,
  ) {
    final padding = ' ' * (level * indent);
    for (final node in document.children) {
      _writeNode(node, buffer, level, indent, padding);
    }
  }

  void _writeNode(
    XmlNode node,
    StringBuffer buffer,
    int level,
    int indent,
    String padding,
  ) {
    if (node is XmlElement) {
      buffer.writeln('$padding<${node.name}');
      // Attributes
      for (final attr in node.attributes) {
        buffer.writeln('$padding  ${attr.name}="${attr.value}"');
      }
      buffer.writeln('$padding>');

      // Children
      for (final child in node.children) {
        _writeNode(child, buffer, level + 1, indent, ' ' * ((level + 1) * indent));
      }

      buffer.writeln('$padding</${node.name}>');
    } else if (node is XmlText) {
      final text = node.value.trim();
      if (text.isNotEmpty) {
        buffer.writeln('$padding$text');
      }
    } else if (node is XmlComment) {
      buffer.writeln('$padding<!-- ${node.value} -->');
    }
  }

  /// Validates an XML string.
  XmlValidationResult validate(String xmlString) {
    if (xmlString.trim().isEmpty) {
      return XmlValidationResult(
        isValid: false,
        error: 'السلسلة فارغة',
      );
    }

    try {
      final document = XmlDocument.parse(xmlString);
      return XmlValidationResult(
        isValid: true,
        document: document,
      );
    } catch (e) {
      return XmlValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// Minifies an XML string.
  String minify(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return document.toXmlString(pretty: false);
    } catch (e) {
      return xmlString.replaceAll(RegExp(r'>\s+<'), '><').trim();
    }
  }

  /// Builds a tree structure from an XML string.
  XmlTreeNode buildTree(String xmlString) {
    final result = validate(xmlString);
    if (!result.isValid) {
      return XmlTreeNode(
        name: 'الجذر',
        type: XmlNodeType.invalid,
        children: [],
      );
    }

    final root = result.document!.rootElement;
    return _buildNode(root);
  }

  XmlTreeNode _buildNode(XmlElement element) {
    final children = <XmlTreeNode>[];

    for (final child in element.children) {
      if (child is XmlElement) {
        children.add(_buildNode(child));
      } else if (child is XmlText) {
        final text = child.value.trim();
        if (text.isNotEmpty) {
          children.add(XmlTreeNode(
            name: '#text',
            value: text,
            type: XmlNodeType.text,
            children: [],
          ));
        }
      }
    }

    return XmlTreeNode(
      name: element.name.toString(),
      value: element.innerText.trim().isEmpty ? null : element.innerText.trim(),
      type: XmlNodeType.element,
      attributes: {
        for (final attr in element.attributes)
          attr.name.toString(): attr.value,
      },
      children: children,
    );
  }

  /// Compares two XML strings.
  XmlComparison compare(String xml1, String xml2) {
    final result1 = validate(xml1);
    final result2 = validate(xml2);

    if (!result1.isValid) {
      return XmlComparison(
        areEqual: false,
        error: 'XML الأول غير صالح: ${result1.error}',
      );
    }

    if (!result2.isValid) {
      return XmlComparison(
        areEqual: false,
        error: 'XML الثاني غير صالح: ${result2.error}',
      );
    }

    final differences = <XmlDifference>[];
    _compareNodes(
      result1.document!.rootElement,
      result2.document!.rootElement,
      '',
      differences,
    );

    return XmlComparison(
      areEqual: differences.isEmpty,
      differences: differences,
    );
  }

  void _compareNodes(
    XmlElement node1,
    XmlElement node2,
    String path,
    List<XmlDifference> differences,
  ) {
    final currentPath = path.isEmpty ? node1.name.toString() : '$path/${node1.name}';

    // Compare names
    if (node1.name.toString() != node2.name.toString()) {
      differences.add(XmlDifference(
        path: currentPath,
        type: XmlDifferenceType.nameChanged,
        value1: node1.name.toString(),
        value2: node2.name.toString(),
      ));
    }

    // Compare attributes
    final attrs1 = {for (final a in node1.attributes) a.name.toString(): a.value};
    final attrs2 = {for (final a in node2.attributes) a.name.toString(): a.value};

    for (final key in {...attrs1.keys, ...attrs2.keys}) {
      if (!attrs1.containsKey(key)) {
        differences.add(XmlDifference(
          path: '$currentPath@$key',
          type: XmlDifferenceType.attributeAdded,
          value1: null,
          value2: attrs2[key],
        ));
      } else if (!attrs2.containsKey(key)) {
        differences.add(XmlDifference(
          path: '$currentPath@$key',
          type: XmlDifferenceType.attributeRemoved,
          value1: attrs1[key],
          value2: null,
        ));
      } else if (attrs1[key] != attrs2[key]) {
        differences.add(XmlDifference(
          path: '$currentPath@$key',
          type: XmlDifferenceType.attributeChanged,
          value1: attrs1[key],
          value2: attrs2[key],
        ));
      }
    }

    // Compare text content
    final text1 = node1.innerText.trim();
    final text2 = node2.innerText.trim();
    if (text1 != text2 && node1.children.whereType<XmlElement>().isEmpty &&
        node2.children.whereType<XmlElement>().isEmpty) {
      differences.add(XmlDifference(
        path: currentPath,
        type: XmlDifferenceType.textChanged,
        value1: text1,
        value2: text2,
      ));
    }

    // Compare children
    final children1 = node1.children.whereType<XmlElement>().toList();
    final children2 = node2.children.whereType<XmlElement>().toList();

    if (children1.length != children2.length) {
      differences.add(XmlDifference(
        path: currentPath,
        type: XmlDifferenceType.childCountChanged,
        value1: '${children1.length}',
        value2: '${children2.length}',
      ));
    }

    final minChildren = children1.length < children2.length
        ? children1.length
        : children2.length;

    for (var i = 0; i < minChildren; i++) {
      _compareNodes(children1[i], children2[i], currentPath, differences);
    }
  }
}

/// Result of XML validation.
class XmlValidationResult {
  const XmlValidationResult({
    required this.isValid,
    this.error,
    this.document,
  });

  final bool isValid;
  final String? error;
  final XmlDocument? document;
}

/// Result of XML comparison.
class XmlComparison {
  const XmlComparison({
    required this.areEqual,
    this.differences = const [],
    this.error,
  });

  final bool areEqual;
  final List<XmlDifference> differences;
  final String? error;
}

/// A single difference between two XMLs.
class XmlDifference {
  const XmlDifference({
    required this.path,
    required this.type,
    required this.value1,
    required this.value2,
  });

  final String path;
  final XmlDifferenceType type;
  final String? value1;
  final String? value2;
}

/// Types of XML differences.
enum XmlDifferenceType {
  nameChanged,
  attributeAdded,
  attributeRemoved,
  attributeChanged,
  textChanged,
  childCountChanged,
}

/// Types of XML nodes.
enum XmlNodeType {
  element,
  text,
  comment,
  invalid,
}

/// A node in an XML tree.
class XmlTreeNode {
  const XmlTreeNode({
    required this.name,
    required this.type,
    this.value,
    this.attributes = const {},
    this.children = const [],
  });

  final String name;
  final XmlNodeType type;
  final String? value;
  final Map<String, String> attributes;
  final List<XmlTreeNode> children;
}
