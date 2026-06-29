import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../../../core/error/app_error.dart';
import '../../collections/models/collection_item.dart';
import '../../environment/models/environment_model.dart';
import '../../favorites/models/favorite_item.dart';
import '../../history/models/history_entry.dart';
import '../../request/models/http_request.dart';
import '../../variables/models/variable_model.dart';

/// Service for exporting and importing data in various formats
class ExportImportService {
  ExportImportService._();
  static final ExportImportService instance = ExportImportService._();

  /// Export data to specified format
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
        break;
      case 'yaml':
        final yamlStr = _toYaml(data);
        await file.writeAsString(yamlStr);
        break;
      case 'csv':
        final csvData = _toCsv(requests);
        await file.writeAsString(csvData);
        break;
      case 'txt':
        final txtData = _toTxt(data);
        await file.writeAsString(txtData);
        break;
      case 'zip':
        final zipBytes = _toZip(data);
        await file.writeAsBytes(zipBytes);
        break;
      default:
        throw ArgumentError('Unsupported export format: $format');
    }

    return file.path;
  }

  /// Import data from file
  Future<Map<String, dynamic>> importData(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const AppError(message: 'الملف غير موجود', code: 'FILE_NOT_FOUND');
    }

    final extension = filePath.split('.').last.toLowerCase();
    final content = await file.readAsString();

    switch (extension) {
      case 'json':
        return jsonDecode(content) as Map<String, dynamic>;
      case 'yaml':
      case 'yml':
        final yamlData = yaml.loadYaml(content);
        return _yamlToMap(yamlData);
      case 'csv':
        return _parseCsv(content);
      case 'txt':
        return _parseTxt(content);
      case 'zip':
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final jsonFile = archive.firstWhere(
          (f) => f.name.endsWith('.json'),
          orElse: () => throw const AppError(message: 'لا يوجد ملف JSON في الأرشيف', code: 'INVALID_ZIP'),
        );
        final jsonContent = utf8.decode(jsonFile.content as List<int>);
        return jsonDecode(jsonContent) as Map<String, dynamic>;
      default:
        throw ArgumentError('Unsupported import format: $extension');
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
      if (key.isNotEmpty) {
        buffer.writeln('$padding$key:');
      }
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
      if (value.contains('\n') || value.contains(':')) {
        buffer.writeln('$padding$key: |');
        for (final line in value.split('\n')) {
          buffer.writeln('$padding  $line');
        }
      } else {
        buffer.writeln('$padding$key: $value');
      }
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
          '${req.id},${_escapeCsv(req.name)},${req.method},${_escapeCsv(req.url)},${req.createdAt.toIso8601String()},${req.updatedAt.toIso8601String()}');
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
    buffer.writeln('-' * 30);
    for (final req in requests) {
      final r = req as Map<String, dynamic>;
      buffer.writeln('${r['method']} ${r['url']} - ${r['name']}');
    }
    buffer.writeln();

    final history = data['history'] as List;
    buffer.writeln('History (${history.length}):');
    buffer.writeln('-' * 30);
    for (final h in history) {
      final entry = h as Map<String, dynamic>;
      buffer.writeln('${entry['method']} ${entry['url']} - ${entry['statusCode']} (${entry['responseTimeMs']}ms)');
    }

    return buffer.toString();
  }

  List<int> _toZip(Map<String, dynamic> data) {
    final archive = Archive();
    final jsonContent = const JsonEncoder.withIndent('  ').convert(data);
    archive.addFile(
      ArchiveFile('data.json', jsonContent.length, utf8.encode(jsonContent)),
    );

    final readme = '''
Arabic HTTP Studio Export
=========================
Export Date: ${DateTime.now()}
Version: 1.0.0

Contents:
- data.json: Full export data in JSON format

To import:
1. Open Arabic HTTP Studio
2. Go to Import/Export
3. Select this ZIP file
''';
    archive.addFile(
      ArchiveFile('README.txt', readme.length, utf8.encode(readme)),
    );

    return ZipEncoder().encode(archive)!;
  }

  Map<String, dynamic> _yamlToMap(dynamic yamlData) {
    if (yamlData is Map) {
      return Map<String, dynamic>.from(yamlData);
    }
    throw const AppError(message: 'صيغة YAML غير صالحة', code: 'INVALID_YAML');
  }

  Map<String, dynamic> _parseCsv(String content) {
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) return {};

    final headers = rows.first.map((e) => e.toString()).toList();
    final requests = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final request = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        request[headers[j]] = row[j];
      }
      requests.add(request);
    }

    return {'requests': requests};
  }

  Map<String, dynamic> _parseTxt(String content) {
    // Simple TXT parsing - returns basic structure
    final lines = content.split('\n');
    final requests = <Map<String, dynamic>>[];

    for (final line in lines) {
      if (line.contains(' - ') && (line.startsWith('GET') ||
          line.startsWith('POST') ||
          line.startsWith('PUT') ||
          line.startsWith('PATCH') ||
          line.startsWith('DELETE') ||
          line.startsWith('HEAD') ||
          line.startsWith('OPTIONS'))) {
        final parts = line.split(' ');
        if (parts.length >= 2) {
          requests.add({
            'method': parts[0],
            'url': parts[1],
            'name': line.substring(line.indexOf(' - ') + 3),
          });
        }
      }
    }

    return {'requests': requests};
  }

  /// Share exported file
  Future<String> getExportPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
