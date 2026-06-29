import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../request/models/http_request.dart';
import '../../collections/models/collection_item.dart';
import '../../environment/models/environment_model.dart';
import '../../variables/models/variable_model.dart';
import '../../history/models/history_entry.dart';
import '../../favorites/models/favorite_item.dart';

/// Service for exporting data to various formats.
///
/// Supports:
/// - JSON
/// - YAML
/// - CSV
/// - TXT
/// - ZIP
/// - Markdown
/// - HTML
/// - OpenAPI 3.0
/// - Swagger 2.0
/// - Postman Collection v2.1
///
/// Example:
/// ```dart
/// final path = await ExportService.instance.exportToOpenApi(
///   requests: requests,
///   title: 'My API',
///   fileName: 'my-api',
/// );
/// ```
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Exports data to the specified format.
  Future<String> exportData({
    required List<HttpRequestModel> requests,
    required List<HistoryEntry> history,
    required List<FavoriteItem> favorites,
    required List<CollectionItem> collections,
    required List<EnvironmentModel> environments,
    required List<VariableModel> variables,
    required String format,
    required String fileName,
  }) async {
    final data = {
      'requests': requests.map((r) => r.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
      'favorites': favorites.map((f) => f.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'environments': environments.map((e) => e.toJson()).toList(),
      'variables': variables.map((v) => v.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.$format');

    switch (format.toLowerCase()) {
      case 'json':
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      case 'yaml':
        await file.writeAsString(_toYaml(data));
      case 'csv':
        await file.writeAsString(_toCsv(requests));
      case 'txt':
        await file.writeAsString(_toTxt(data));
      case 'markdown':
      case 'md':
        await file.writeAsString(_toMarkdown(requests, collections));
      case 'html':
        await file.writeAsString(_toHtml(requests, collections));
      case 'openapi':
        await file.writeAsString(_toOpenApi(requests, fileName));
      case 'swagger':
        await file.writeAsString(_toSwagger(requests, fileName));
      case 'postman':
        await file.writeAsString(_toPostmanCollection(requests, fileName));
      default:
        throw ArgumentError('صيغة تصدير غير مدعومة: $format');
    }

    return file.path;
  }

  /// Exports requests as OpenAPI 3.0 specification.
  Future<String> exportToOpenApi({
    required List<HttpRequestModel> requests,
    String title = 'API',
    String? description,
    String? version,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.openapi.json');
    await file.writeAsString(_toOpenApi(requests, title, description, version));
    return file.path;
  }

  /// Exports requests as Swagger 2.0 specification.
  Future<String> exportToSwagger({
    required List<HttpRequestModel> requests,
    String title = 'API',
    String? description,
    String? version,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.swagger.json');
    await file.writeAsString(_toSwagger(requests, title, description, version));
    return file.path;
  }

  /// Exports requests as Postman Collection v2.1.
  Future<String> exportToPostman({
    required List<HttpRequestModel> requests,
    String title = 'Collection',
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.postman.json');
    await file.writeAsString(_toPostmanCollection(requests, title));
    return file.path;
  }

  /// Exports requests as Markdown documentation.
  Future<String> exportToMarkdown({
    required List<HttpRequestModel> requests,
    String title = 'API Documentation',
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.md');
    await file.writeAsString(_toMarkdown(requests, [], title));
    return file.path;
  }

  /// Exports requests as HTML documentation.
  Future<String> exportToHtml({
    required List<HttpRequestModel> requests,
    String title = 'API Documentation',
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.html');
    await file.writeAsString(_toHtml(requests, [], title));
    return file.path;
  }

  String _toOpenApi(
    List<HttpRequestModel> requests, [
    String title = 'API',
    String? description,
    String? version,
  ]) {
    final paths = <String, Map<String, dynamic>>{};

    for (final request in requests) {
      final uri = Uri.parse(request.url);
      final path = uri.path.isEmpty ? '/' : uri.path;

      if (!paths.containsKey(path)) {
        paths[path] = {};
      }

      final method = request.method.toLowerCase();
      paths[path]![method] = {
        'summary': request.name,
        'description': request.description ?? '',
        'operationId': request.id,
        'parameters': [
          ...request.queryParams.where((q) => q.enabled).map((q) => {
                'name': q.key,
                'in': 'query',
                'required': false,
                'schema': {'type': 'string'},
              }),
          ...request.headers.where((h) => h.enabled).map((h) => {
                'name': h.key,
                'in': 'header',
                'required': false,
                'schema': {'type': 'string'},
              }),
        ],
        'responses': {
          '200': {
            'description': 'استجابة ناجحة',
            'content': {
              'application/json': {
                'schema': {'type': 'object'},
              },
            },
          },
        },
      };

      if (request.body != null && request.body!.type != 'none') {
        paths[path]![method]['requestBody'] = {
          'content': {
            _getContentTypeForBody(request.body!): {
              'schema': {'type': 'object'},
            },
          },
        };
      }
    }

    final spec = {
      'openapi': '3.0.3',
      'info': {
        'title': title,
        'description': description ?? 'تم التصدير من Arabic HTTP Studio',
        'version': version ?? '1.0.0',
      },
      'paths': paths,
    };

    return const JsonEncoder.withIndent('  ').convert(spec);
  }

  String _toSwagger(
    List<HttpRequestModel> requests, [
    String title = 'API',
    String? description,
    String? version,
  ]) {
    final paths = <String, Map<String, dynamic>>{};
    final definitions = <String, dynamic>{};

    for (final request in requests) {
      final uri = Uri.parse(request.url);
      final path = uri.path.isEmpty ? '/' : uri.path;

      if (!paths.containsKey(path)) {
        paths[path] = {};
      }

      final method = request.method.toLowerCase();
      paths[path]![method] = {
        'summary': request.name,
        'description': request.description ?? '',
        'operationId': request.id,
        'parameters': [
          ...request.queryParams.where((q) => q.enabled).map((q) => {
                'name': q.key,
                'in': 'query',
                'required': false,
                'type': 'string',
              }),
          ...request.headers.where((h) => h.enabled).map((h) => {
                'name': h.key,
                'in': 'header',
                'required': false,
                'type': 'string',
              }),
        ],
        'responses': {
          '200': {'description': 'استجابة ناجحة'},
        },
      };

      if (request.body != null && request.body!.type != 'none') {
        paths[path]![method]['parameters'].add({
          'name': 'body',
          'in': 'body',
          'required': false,
          'schema': {'\$ref': '#/definitions/${request.name.replaceAll(' ', '_')}'},
        });
        definitions[request.name.replaceAll(' ', '_')] = {'type': 'object'};
      }
    }

    final spec = {
      'swagger': '2.0',
      'info': {
        'title': title,
        'description': description ?? 'تم التصدير من Arabic HTTP Studio',
        'version': version ?? '1.0.0',
      },
      'paths': paths,
      'definitions': definitions,
    };

    return const JsonEncoder.withIndent('  ').convert(spec);
  }

  String _toPostmanCollection(
    List<HttpRequestModel> requests, [
    String title = 'Collection',
  ]) {
    final items = requests.map((request) {
      final uri = Uri.parse(request.url);
      return {
        'name': request.name,
        'request': {
          'method': request.method,
          'header': request.headers.where((h) => h.enabled).map((h) => {
                'key': h.key,
                'value': h.value,
                'type': 'text',
              }).toList(),
          'url': {
            'raw': request.url,
            'protocol': uri.scheme,
            'host': uri.host.split('.'),
            'path': uri.path.split('/').where((p) => p.isNotEmpty).toList(),
            'query': request.queryParams.where((q) => q.enabled).map((q) => {
                  'key': q.key,
                  'value': q.value,
                }).toList(),
          },
          if (request.body != null && request.body!.type != 'none')
            'body': _parseBodyForPostman(request.body!),
        },
      };
    }).toList();

    final collection = {
      'info': {
        '_postman_id': DateTime.now().microsecondsSinceEpoch.toString(),
        'name': title,
        'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        '_exporter_id': 'arabic_http_studio',
      },
      'item': items,
    };

    return const JsonEncoder.withIndent('  ').convert(collection);
  }

  Map<String, dynamic> _parseBodyForPostman(BodyItem body) {
    switch (body.type) {
      case 'json':
        return {
          'mode': 'raw',
          'raw': body.rawContent ?? '',
          'options': {
            'raw': {'language': 'json'},
          },
        };
      case 'text':
        return {
          'mode': 'raw',
          'raw': body.rawContent ?? '',
        };
      case 'form':
        return {
          'mode': 'urlencoded',
          'urlencoded': (body.formFields ?? []).map((f) => {
                    'key': f.key,
                    'value': f.value,
                    'type': 'text',
                  }),
        };
      case 'multipart':
        return {
          'mode': 'formdata',
          'formdata': [
            ...(body.formFields ?? []).map((f) => {
                  'key': f.key,
                  'value': f.value,
                  'type': 'text',
                }),
            ...(body.fileFields ?? []).map((f) => {
                  'key': f.key,
                  'type': 'file',
                  'src': f.filePath,
                }),
          ],
        };
      default:
        return {};
    }
  }

  String _toMarkdown(
    List<HttpRequestModel> requests,
    List<CollectionItem> collections, [
    String title = 'API Documentation',
  ]) {
    final buffer = StringBuffer();
    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln('> تم إنشاء هذا المستند بواسطة Arabic HTTP Studio');
    buffer.writeln();
    buffer.writeln('## نظرة عامة');
    buffer.writeln();
    buffer.writeln('عدد الطلبات: ${requests.length}');
    buffer.writeln('عدد المجموعات: ${collections.length}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Group by method
    final byMethod = <String, List<HttpRequestModel>>{};
    for (final request in requests) {
      byMethod.putIfAbsent(request.method, () => []).add(request);
    }

    for (final entry in byMethod.entries) {
      buffer.writeln('## ${entry.key} (${entry.value.length})');
      buffer.writeln();

      for (final request in entry.value) {
        buffer.writeln('### ${request.name}');
        buffer.writeln();

        if (request.description != null) {
          buffer.writeln(request.description);
          buffer.writeln();
        }

        buffer.writeln('**الطريقة:** `${request.method}`  ');
        buffer.writeln('**الرابط:** `${request.url}`  ');
        buffer.writeln();

        if (request.headers.where((h) => h.enabled).isNotEmpty) {
          buffer.writeln('#### الرؤوس');
          buffer.writeln();
          buffer.writeln('| المفتاح | القيمة |');
          buffer.writeln('|---------|--------|');
          for (final header in request.headers.where((h) => h.enabled)) {
            buffer.writeln('| `${header.key}` | `${header.value}` |');
          }
          buffer.writeln();
        }

        if (request.queryParams.where((q) => q.enabled).isNotEmpty) {
          buffer.writeln('#### معاملات الاستعلام');
          buffer.writeln();
          buffer.writeln('| المفتاح | القيمة |');
          buffer.writeln('|---------|--------|');
          for (final param in request.queryParams.where((q) => q.enabled)) {
            buffer.writeln('| `${param.key}` | `${param.value}` |');
          }
          buffer.writeln();
        }

        if (request.body != null && request.body!.type != 'none') {
          buffer.writeln('#### المتن');
          buffer.writeln();
          buffer.writeln('النوع: `${request.body!.type}`');
          buffer.writeln();
          if (request.body!.rawContent != null) {
            buffer.writeln('```json');
            buffer.writeln(request.body!.rawContent);
            buffer.writeln('```');
            buffer.writeln();
          }
        }

        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _toHtml(
    List<HttpRequestModel> requests,
    List<CollectionItem> collections, [
    String title = 'API Documentation',
  ]) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="ar" dir="rtl">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>$title</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: "Cairo", "Segoe UI", sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }');
    buffer.writeln('    h1 { color: #1a73e8; }');
    buffer.writeln('    .method { display: inline-block; padding: 4px 12px; border-radius: 4px; color: white; font-weight: bold; margin-left: 8px; }');
    buffer.writeln('    .GET { background: #34a853; }');
    buffer.writeln('    .POST { background: #4285f4; }');
    buffer.writeln('    .PUT { background: #fbbc04; }');
    buffer.writeln('    .PATCH { background: #9334e8; }');
    buffer.writeln('    .DELETE { background: #ea4335; }');
    buffer.writeln('    .request { background: white; padding: 16px; margin: 16px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }');
    buffer.writeln('    table { width: 100%; border-collapse: collapse; margin: 8px 0; }');
    buffer.writeln('    th, td { padding: 8px; text-align: right; border-bottom: 1px solid #ddd; }');
    buffer.writeln('    th { background: #f8f9fa; }');
    buffer.writeln('    code { background: #f1f3f4; padding: 2px 6px; border-radius: 3px; font-family: "JetBrains Mono", monospace; }');
    buffer.writeln('    pre { background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 8px; overflow-x: auto; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>$title</h1>');
    buffer.writeln('  <p>تم إنشاء هذا المستند بواسطة Arabic HTTP Studio</p>');
    buffer.writeln('  <p>عدد الطلبات: ${requests.length}</p>');

    for (final request in requests) {
      buffer.writeln('  <div class="request">');
      buffer.writeln('    <h2><span class="method ${request.method}">${request.method}</span> ${request.name}</h2>');
      buffer.writeln('    <p><strong>الرابط:</strong> <code>${request.url}</code></p>');

      if (request.description != null) {
        buffer.writeln('    <p>${request.description}</p>');
      }

      if (request.headers.where((h) => h.enabled).isNotEmpty) {
        buffer.writeln('    <h3>الرؤوس</h3>');
        buffer.writeln('    <table>');
        buffer.writeln('      <tr><th>المفتاح</th><th>القيمة</th></tr>');
        for (final header in request.headers.where((h) => h.enabled)) {
          buffer.writeln('      <tr><td><code>${header.key}</code></td><td><code>${header.value}</code></td></tr>');
        }
        buffer.writeln('    </table>');
      }

      if (request.queryParams.where((q) => q.enabled).isNotEmpty) {
        buffer.writeln('    <h3>معاملات الاستعلام</h3>');
        buffer.writeln('    <table>');
        buffer.writeln('      <tr><th>المفتاح</th><th>القيمة</th></tr>');
        for (final param in request.queryParams.where((q) => q.enabled)) {
          buffer.writeln('      <tr><td><code>${param.key}</code></td><td><code>${param.value}</code></td></tr>');
        }
        buffer.writeln('    </table>');
      }

      if (request.body != null && request.body!.rawContent != null) {
        buffer.writeln('    <h3>المتن</h3>');
        buffer.writeln('    <pre><code>${request.body!.rawContent}</code></pre>');
      }

      buffer.writeln('  </div>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _getContentTypeForBody(BodyItem body) {
    switch (body.type) {
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'form':
        return 'application/x-www-form-urlencoded';
      case 'multipart':
        return 'multipart/form-data';
      case 'text':
        return 'text/plain';
      case 'html':
        return 'text/html';
      default:
        return 'application/octet-stream';
    }
  }

  String _toYaml(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _writeYaml(buffer, '', data, 0);
    return buffer.toString();
  }

  void _writeYaml(StringBuffer buffer, String key, dynamic value, int indent) {
    final padding = '  ' * indent;
    if (value is Map) {
      if (key.isNotEmpty) buffer.writeln('$padding$key:');
      value.forEach((k, v) {
        _writeYaml(buffer, k.toString(), v, indent + (key.isNotEmpty ? 1 : 0));
      });
    } else if (value is List) {
      buffer.writeln('$padding$key:');
      for (final item in value) {
        if (item is Map) {
          buffer.writeln('$padding  -');
          item.forEach((k, v) {
            _writeYaml(buffer, k.toString(), v, indent + 2);
          });
        } else {
          buffer.writeln('$padding  - $item');
        }
      }
    } else if (value is String) {
      buffer.writeln('$padding$key: "$value"');
    } else if (value is num || value is bool) {
      buffer.writeln('$padding$key: $value');
    } else if (value == null) {
      buffer.writeln('$padding$key: null');
    }
  }

  String _toCsv(List<HttpRequestModel> requests) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Method,URL,Created,Updated');
    for (final req in requests) {
      buffer.writeln(
        '${req.id},${_escapeCsv(req.name)},${req.method},${_escapeCsv(req.url)},${req.createdAt.toIso8601String()},${req.updatedAt.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _toTxt(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('Arabic HTTP Studio - Export');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    final requests = data['requests'] as List;
    buffer.writeln('Requests (${requests.length}):');
    for (final req in requests) {
      final r = req as Map<String, dynamic>;
      buffer.writeln('  ${r['method']} ${r['url']} - ${r['name']}');
    }

    return buffer.toString();
  }
}
