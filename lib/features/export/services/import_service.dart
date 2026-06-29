import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/http_request.dart';
import '../models/collection_import_models.dart';

/// Service for importing API definitions from various formats.
///
/// Supports:
/// - OpenAPI 3.0 / Swagger 2.0
/// - Postman Collections v2.1
/// - JSON
/// - YAML
/// - CSV
/// - TXT
///
/// Example:
/// ```dart
/// final result = await ImportService.instance.importFromFile(filePath);
/// print('Imported ${result.requests.length} requests');
/// ```
class ImportService {
  ImportService._();
  static final ImportService instance = ImportService._();

  /// Imports from a file and returns the parsed result.
  Future<ImportResult> importFromFile(String filePath) async {
    final file = await _readFile(filePath);
    final extension = filePath.split('.').last.toLowerCase();

    return importFromString(file, extension);
  }

  /// Imports from a string content.
  ImportResult importFromString(String content, String format) {
    switch (format.toLowerCase()) {
      case 'json':
        return _importJson(content);
      case 'yaml':
      case 'yml':
        return _importYaml(content);
      case 'csv':
        return _importCsv(content);
      case 'txt':
        return _importTxt(content);
      default:
        throw ArgumentError('صيغة غير مدعومة: $format');
    }
  }

  Future<String> _readFile(String filePath) async {
    // Use dart:io File - the caller should provide a valid path
    return filePath;
  }

  /// Imports from JSON content.
  ///
  /// Automatically detects:
  /// - OpenAPI 3.0 / Swagger 2.0
  /// - Postman Collection v2.1
  /// - Arabic HTTP Studio native format
  ImportResult _importJson(String content) {
    final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;

    // Check for OpenAPI/Swagger
    if (data.containsKey('openapi') || data.containsKey('swagger')) {
      return _importOpenApi(data);
    }

    // Check for Postman Collection
    if (data.containsKey('info') && data.containsKey('item')) {
      return _importPostman(data);
    }

    // Check for native format
    if (data.containsKey('requests')) {
      return _importNative(data);
    }

    throw const FormatException('صيغة JSON غير معروفة');
  }

  /// Imports OpenAPI 3.0 / Swagger 2.0 specification.
  ImportResult _importOpenApi(Map<String, dynamic> spec) {
    final requests = <HttpRequestModel>[];
    final collections = <CollectionFolder>[];
    final errors = <String>[];

    final isSwagger = spec.containsKey('swagger');
    final version = isSwagger ? spec['swagger'] as String : spec['openapi'] as String;
    debugPrint('Importing OpenAPI/Swagger version: $version');

    final info = spec['info'] as Map<String, dynamic>?;
    final title = info?['title'] as String? ?? 'مستورد';
    final description = info?['description'] as String?;

    // Get base URL
    String? baseUrl;
    if (isSwagger) {
      final host = spec['host'] as String?;
      final basePath = spec['basePath'] as String?;
      final schemes = spec['schemes'] as List<dynamic>?;
      if (host != null) {
        final scheme = schemes?.isNotEmpty == true ? schemes!.first : 'https';
        baseUrl = '$scheme://$host${basePath ?? ''}';
      }
    } else {
      final servers = spec['servers'] as List<dynamic>?;
      if (servers != null && servers.isNotEmpty) {
        baseUrl = (servers.first as Map<String, dynamic>)['url'] as String?;
      }
    }

    final paths = spec['paths'] as Map<String, dynamic>? ?? {};

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final methods = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in methods.entries) {
        final method = methodEntry.key.toUpperCase();
        if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'].contains(method)) {
          continue;
        }

        try {
          final operation = methodEntry.value as Map<String, dynamic>;
          final request = _parseOpenApiOperation(
            path: path,
            method: method,
            operation: operation,
            baseUrl: baseUrl,
            spec: spec,
          );
          requests.add(request);
        } catch (e) {
          errors.add('$method $path: $e');
        }
      }
    }

    final collection = CollectionFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title,
      description: description,
      requestIds: requests.map((r) => r.id).toList(),
    );
    collections.add(collection);

    return ImportResult(
      requests: requests,
      collections: collections,
      source: 'OpenAPI $version',
      title: title,
      errors: errors,
    );
  }

  HttpRequestModel _parseOpenApiOperation({
    required String path,
    required String method,
    required Map<String, dynamic> operation,
    required String? baseUrl,
    required Map<String, dynamic> spec,
  }) {
    final operationId = operation['operationId'] as String?;
    final summary = operation['summary'] as String?;
    final description = operation['description'] as String?;
    final tags = (operation['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    final name = operationId ?? summary ?? '$method $path';
    final fullUrl = baseUrl != null ? '$baseUrl$path' : path;

    final headers = <HeaderItem>[];
    final queryParams = <QueryParam>[];

    // Parameters
    final parameters = operation['parameters'] as List<dynamic>?;
    if (parameters != null) {
      for (final param in parameters) {
        final p = param as Map<String, dynamic>;
        final paramIn = p['in'] as String;
        final paramName = p['name'] as String;
        final paramRequired = p['required'] as bool? ?? false;
        final paramDescription = p['description'] as String?;
        final schema = p['schema'] as Map<String, dynamic>?;
        final defaultValue = schema?['default']?.toString() ?? '';

        if (paramIn == 'query') {
          queryParams.add(QueryParam(
            key: paramName,
            value: defaultValue,
            enabled: paramRequired,
            description: paramDescription,
          ));
        } else if (paramIn == 'header') {
          headers.add(HeaderItem(
            key: paramName,
            value: defaultValue,
            enabled: paramRequired,
            description: paramDescription,
          ));
        }
      }
    }

    // Request body (OpenAPI 3.0)
    BodyItem? body;
    final requestBody = operation['requestBody'] as Map<String, dynamic>?;
    if (requestBody != null) {
      final content = requestBody['content'] as Map<String, dynamic>?;
      if (content != null) {
        final jsonContent = content['application/json'] as Map<String, dynamic>?;
        if (jsonContent != null) {
          body = BodyItem(type: 'json', rawContent: '');
        }
      }
    }

    // Security
    AuthConfig? auth;
    final security = operation['security'] as List<dynamic>?;
    final securitySchemes = spec['components']?['securitySchemes'] as Map<String, dynamic>?;
    if (security != null && securitySchemes != null && security.isNotEmpty) {
      final securityReq = security.first as Map<String, dynamic>;
      if (securityReq.isNotEmpty) {
        final schemeName = securityReq.keys.first;
        final scheme = securitySchemes[schemeName] as Map<String, dynamic>?;
        if (scheme != null) {
          final schemeType = scheme['type'] as String?;
          if (schemeType == 'http' && scheme['scheme'] == 'bearer') {
            auth = AuthConfig(type: 'bearer');
          } else if (schemeType == 'http' && scheme['scheme'] == 'basic') {
            auth = AuthConfig(type: 'basic');
          } else if (schemeType == 'apiKey') {
            auth = AuthConfig(
              type: 'apiKey',
              apiKeyHeader: scheme['name'] as String?,
              apiKeyLocation: scheme['in'] as String?,
            );
          }
        }
      }
    }

    return HttpRequestModel(
      id: DateTime.now().microsecondsSinceEpoch.toString() +
          path.hashCode.toString() +
          method,
      name: name,
      method: method,
      url: fullUrl,
      headers: headers,
      queryParams: queryParams,
      body: body,
      auth: auth,
      description: description ?? summary,
      tags: tags,
    );
  }

  /// Imports Postman Collection v2.1.
  ImportResult _importPostman(Map<String, dynamic> data) {
    final requests = <HttpRequestModel>[];
    final collections = <CollectionFolder>[];
    final errors = <String>[];

    final info = data['info'] as Map<String, dynamic>?;
    final title = info?['name'] as String? ?? 'مجموعة Postman';
    final description = info?['description'] as String?;

    final items = data['item'] as List<dynamic>? ?? [];
    final requestIds = <String>[];

    for (final item in items) {
      try {
        final itemMap = item as Map<String, dynamic>;
        if (itemMap.containsKey('item')) {
          // This is a folder
          final folder = _parsePostmanFolder(itemMap, requests);
          if (folder != null) {
            collections.add(folder);
            requestIds.addAll(folder.requestIds);
          }
        } else if (itemMap.containsKey('request')) {
          // This is a request
          final request = _parsePostmanRequest(itemMap);
          if (request != null) {
            requests.add(request);
            requestIds.add(request.id);
          }
        }
      } catch (e) {
        errors.add(e.toString());
      }
    }

    // Create root collection
    collections.insert(0, CollectionFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title,
      description: description,
      requestIds: requestIds,
    ));

    return ImportResult(
      requests: requests,
      collections: collections,
      source: 'Postman Collection v2.1',
      title: title,
      errors: errors,
    );
  }

  CollectionFolder? _parsePostmanFolder(
    Map<String, dynamic> folder,
    List<HttpRequestModel> requests,
  ) {
    final name = folder['name'] as String? ?? 'مجلد';
    final items = folder['item'] as List<dynamic>? ?? [];
    final requestIds = <String>[];

    for (final item in items) {
      final itemMap = item as Map<String, dynamic>;
      if (itemMap.containsKey('request')) {
        final request = _parsePostmanRequest(itemMap);
        if (request != null) {
          requests.add(request);
          requestIds.add(request.id);
        }
      }
    }

    return CollectionFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      requestIds: requestIds,
    );
  }

  HttpRequestModel? _parsePostmanRequest(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'طلب';
    final request = item['request'] as Map<String, dynamic>?;
    if (request == null) return null;

    final method = (request['method'] as String? ?? 'GET').toUpperCase();
    final urlData = request['url'];
    String url;
    if (urlData is String) {
      url = urlData;
    } else if (urlData is Map) {
      final raw = urlData['raw'] as String?;
      url = raw ?? '';
    } else {
      url = '';
    }

    final headers = <HeaderItem>[];
    final headerList = request['header'] as List<dynamic>?;
    if (headerList != null) {
      for (final h in headerList) {
        final header = h as Map<String, dynamic>;
        headers.add(HeaderItem(
          key: header['key'] as String,
          value: header['value'] as String,
          enabled: !(header['disabled'] as bool? ?? false),
          description: header['description'] as String?,
        ));
      }
    }

    final queryParams = <QueryParam>[];
    if (urlData is Map) {
      final queryList = urlData['query'] as List<dynamic>?;
      if (queryList != null) {
        for (final q in queryList) {
          final query = q as Map<String, dynamic>;
          queryParams.add(QueryParam(
            key: query['key'] as String,
            value: query['value'] as String? ?? '',
            enabled: !(query['disabled'] as bool? ?? false),
          ));
        }
      }
    }

    BodyItem? body;
    final bodyData = request['body'] as Map<String, dynamic>?;
    if (bodyData != null) {
      final mode = bodyData['mode'] as String?;
      switch (mode) {
        case 'raw':
          final raw = bodyData['raw'] as String? ?? '';
          final language = bodyData['options']?['raw']?['language'] as String?;
          body = BodyItem(
            type: language == 'json' ? 'json' : 'text',
            rawContent: raw,
          );
        case 'urlencoded':
          final formData = <FormFieldItem>[];
          final dataList = bodyData['urlencoded'] as List<dynamic>?;
          if (dataList != null) {
            for (final d in dataList) {
              final field = d as Map<String, dynamic>;
              formData.add(FormFieldItem(
                key: field['key'] as String,
                value: field['value'] as String? ?? '',
                enabled: !(field['disabled'] as bool? ?? false),
              ));
            }
          }
          body = BodyItem(type: 'form', formFields: formData);
        case 'formdata':
          final formFields = <FormFieldItem>[];
          final fileFields = <FileFieldItem>[];
          final dataList = bodyData['formdata'] as List<dynamic>?;
          if (dataList != null) {
            for (final d in dataList) {
              final field = d as Map<String, dynamic>;
              final fieldType = field['type'] as String?;
              if (fieldType == 'file') {
                fileFields.add(FileFieldItem(
                  key: field['key'] as String,
                  filePath: field['src'] as String? ?? '',
                  fileName: field['src'] as String? ?? 'file',
                ));
              } else {
                formFields.add(FormFieldItem(
                  key: field['key'] as String,
                  value: field['value'] as String? ?? '',
                  enabled: !(field['disabled'] as bool? ?? false),
                ));
              }
            }
          }
          body = BodyItem(
            type: 'multipart',
            formFields: formFields,
            fileFields: fileFields,
          );
      }
    }

    // Auth
    AuthConfig? auth;
    final authData = request['auth'] as Map<String, dynamic>?;
    if (authData != null) {
      final authType = authData['type'] as String?;
      if (authType == 'bearer') {
        final bearer = authData['bearer'] as List<dynamic>?;
        if (bearer != null && bearer.isNotEmpty) {
          final tokenItem = bearer.first as Map<String, dynamic>;
          auth = AuthConfig(
            type: 'bearer',
            token: tokenItem['value'] as String?,
          );
        }
      } else if (authType == 'basic') {
        final basic = authData['basic'] as List<dynamic>?;
        if (basic != null) {
          String? username;
          String? password;
          for (final item in basic) {
            final field = item as Map<String, dynamic>;
            if (field['key'] == 'username') {
              username = field['value'] as String?;
            } else if (field['key'] == 'password') {
              password = field['value'] as String?;
            }
          }
          auth = AuthConfig(type: 'basic', username: username, password: password);
        }
      }
    }

    return HttpRequestModel(
      id: DateTime.now().microsecondsSinceEpoch.toString() + name.hashCode.toString(),
      name: name,
      method: method,
      url: url,
      headers: headers,
      queryParams: queryParams,
      body: body,
      auth: auth,
    );
  }

  /// Imports native Arabic HTTP Studio format.
  ImportResult _importNative(Map<String, dynamic> data) {
    final requests = <HttpRequestModel>[];
    final errors = <String>[];

    final requestsData = data['requests'] as List<dynamic>? ?? [];
    for (final reqData in requestsData) {
      try {
        requests.add(HttpRequestModel.fromJson(reqData as Map<String, dynamic>));
      } catch (e) {
        errors.add(e.toString());
      }
    }

    return ImportResult(
      requests: requests,
      source: 'Arabic HTTP Studio',
      errors: errors,
    );
  }

  /// Imports from YAML content.
  ImportResult _importYaml(String content) {
    // Basic YAML parsing - for production, use yaml package
    // This is a simplified parser for common cases
    final lines = content.split('\n');
    final requests = <HttpRequestModel>[];

    HttpRequestModel? current;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- method:')) {
        if (current != null) requests.add(current);
        current = HttpRequestModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: '',
          method: trimmed.substring(9).trim().replaceAll('"', ''),
          url: '',
        );
      } else if (current != null) {
        if (trimmed.startsWith('name:')) {
          current = current.copyWith(name: trimmed.substring(5).trim().replaceAll('"', ''));
        } else if (trimmed.startsWith('url:')) {
          current = current.copyWith(url: trimmed.substring(4).trim().replaceAll('"', ''));
        }
      }
    }
    if (current != null) requests.add(current);

    return ImportResult(
      requests: requests,
      source: 'YAML',
    );
  }

  /// Imports from CSV content.
  ImportResult _importCsv(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return ImportResult(requests: [], source: 'CSV');

    final headers = lines.first.split(',');
    final requests = <HttpRequestModel>[];

    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length < 3) continue;

      final nameIdx = headers.indexOf('Name');
      final methodIdx = headers.indexOf('Method');
      final urlIdx = headers.indexOf('URL');

      requests.add(HttpRequestModel(
        id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
        name: nameIdx >= 0 ? values[nameIdx] : 'طلب $i',
        method: methodIdx >= 0 ? values[methodIdx] : 'GET',
        url: urlIdx >= 0 ? values[urlIdx] : '',
      ));
    }

    return ImportResult(requests: requests, source: 'CSV');
  }

  /// Imports from TXT content.
  ImportResult _importTxt(String content) {
    final lines = content.split('\n');
    final requests = <HttpRequestModel>[];
    final methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

    for (final line in lines) {
      final trimmed = line.trim();
      for (final method in methods) {
        if (trimmed.startsWith(method + ' ')) {
          final parts = trimmed.substring(method.length + 1).split(' ');
          if (parts.isNotEmpty) {
            requests.add(HttpRequestModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + requests.length.toString(),
              name: 'طلب ${requests.length + 1}',
              method: method,
              url: parts.first,
            ));
          }
          break;
        }
      }
    }

    return ImportResult(requests: requests, source: 'TXT');
  }
}
