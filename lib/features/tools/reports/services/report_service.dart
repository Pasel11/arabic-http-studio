import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../request/models/http_request.dart';
import '../../history/models/history_entry.dart';
import '../../../core/utils/app_utils.dart';

/// Service for generating professional reports.
///
/// Creates comprehensive reports containing:
/// - Request summary
/// - Response summary
/// - Performance metrics
/// - Timing data
/// - Data sizes
/// - Errors
/// - User notes
///
/// Reports can be exported to:
/// - Markdown
/// - HTML
/// - PDF (via HTML)
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  /// Generates a report for a single request/response pair.
  Future<String> generateReport({
    required HttpRequestModel request,
    required HistoryEntry? response,
    String? userNotes,
    ReportFormat format = ReportFormat.markdown,
    String? fileName,
  }) async {
    final report = _buildReport(request, response, userNotes);
    final content = _formatReport(report, format);

    if (fileName != null) {
      final directory = await getApplicationDocumentsDirectory();
      final ext = format == ReportFormat.html ? 'html' : 'md';
      final file = File('${directory.path}/$fileName.$ext');
      await file.writeAsString(content);
      return file.path;
    }

    return content;
  }

  /// Generates a batch report for multiple requests.
  Future<String> generateBatchReport({
    required List<HttpRequestModel> requests,
    required List<HistoryEntry?> responses,
    String? userNotes,
    ReportFormat format = ReportFormat.markdown,
    String? fileName,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('# تقرير شامل');
    buffer.writeln();
    buffer.writeln('> تم إنشاؤه بواسطة Arabic HTTP Studio في ${DateTime.now()}');
    buffer.writeln();
    buffer.writeln('## نظرة عامة');
    buffer.writeln();
    buffer.writeln('- عدد الطلبات: ${requests.length}');
    buffer.writeln();

    final stats = _calculateBatchStats(responses);
    buffer.writeln('## الإحصائيات');
    buffer.writeln();
    buffer.writeln('| المؤشر | القيمة |');
    buffer.writeln('|---------|--------|');
    buffer.writeln('| النجاح | ${stats.successCount} |');
    buffer.writeln('| الفشل | ${stats.failureCount} |');
    buffer.writeln('| متوسط زمن الاستجابة | ${stats.avgResponseTime}ms |');
    buffer.writeln('| إجمالي البيانات | ${AppUtils.formatBytes(stats.totalSize)} |');
    buffer.writeln();

    if (userNotes != null && userNotes.isNotEmpty) {
      buffer.writeln('## ملاحظات');
      buffer.writeln();
      buffer.writeln(userNotes);
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    for (var i = 0; i < requests.length; i++) {
      buffer.writeln('## الطلب ${i + 1}: ${requests[i].name}');
      buffer.writeln();
      final report = _buildReport(
        requests[i],
        i < responses.length ? responses[i] : null,
        null,
      );
      buffer.writeln(_formatReport(report, format));
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    final content = buffer.toString();
    if (fileName != null) {
      final directory = await getApplicationDocumentsDirectory();
      final ext = format == ReportFormat.html ? 'html' : 'md';
      final file = File('${directory.path}/$fileName.$ext');
      await file.writeAsString(content);
      return file.path;
    }

    return content;
  }

  ReportData _buildReport(
    HttpRequestModel request,
    HistoryEntry? response,
    String? userNotes,
  ) {
    return ReportData(
      request: request,
      response: response,
      userNotes: userNotes,
      generatedAt: DateTime.now(),
    );
  }

  String _formatReport(ReportData report, ReportFormat format) {
    switch (format) {
      case ReportFormat.markdown:
        return _toMarkdown(report);
      case ReportFormat.html:
        return _toHtml(report);
      case ReportFormat.pdf:
        return _toHtml(report); // PDF is generated from HTML
    }
  }

  String _toMarkdown(ReportData report) {
    final buffer = StringBuffer();
    final request = report.request;
    final response = report.response;

    // Request section
    buffer.writeln('### ملخص الطلب');
    buffer.writeln();
    buffer.writeln('| الحقل | القيمة |');
    buffer.writeln('|-------|--------|');
    buffer.writeln('| الاسم | ${request.name} |');
    buffer.writeln('| الطريقة | `${request.method}` |');
    buffer.writeln('| الرابط | `${request.url}` |');
    buffer.writeln('| التاريخ | ${AppUtils.formatDateTime(report.generatedAt)} |');
    if (request.description != null) {
      buffer.writeln('| الوصف | ${request.description} |');
    }
    buffer.writeln();

    // Headers
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

    // Query params
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

    // Body
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

    // Response section
    if (response != null) {
      buffer.writeln('### ملخص الاستجابة');
      buffer.writeln();
      buffer.writeln('| الحقل | القيمة |');
      buffer.writeln('|-------|--------|');
      buffer.writeln('| رمز الحالة | ${response.statusCode} ${response.statusText} |');
      buffer.writeln('| زمن الاستجابة | ${response.responseTimeMs}ms |');
      buffer.writeln('| حجم الاستجابة | ${AppUtils.formatBytes(response.responseSizeBytes)} |');
      buffer.writeln('| النجاح | ${response.isSuccess ? "نعم ✓" : "لا ✗"} |');
      buffer.writeln('| نوع المحتوى | ${response.contentType ?? "غير معروف"} |');
      buffer.writeln();

      // Timeline
      if (response.timeline != null) {
        buffer.writeln('#### الخط الزمني');
        buffer.writeln();
        buffer.writeln('| المرحلة | الزمن |');
        buffer.writeln('|---------|-------|');
        buffer.writeln('| بحث DNS | ${response.timeline!.dnsLookupMs}ms |');
        buffer.writeln('| الاتصال | ${response.timeline!.connectionMs}ms |');
        buffer.writeln('| SSL | ${response.timeline!.sslHandshakeMs}ms |');
        buffer.writeln('| الإرسال | ${response.timeline!.sendingMs}ms |');
        buffer.writeln('| الانتظار | ${response.timeline!.waitingMs}ms |');
        buffer.writeln('| التنزيل | ${response.timeline!.downloadingMs}ms |');
        buffer.writeln('| **الإجمالي** | **${response.timeline!.totalMs}ms** |');
        buffer.writeln();
      }

      // Response headers
      if (response.responseHeaders.isNotEmpty) {
        buffer.writeln('#### رؤوس الاستجابة');
        buffer.writeln();
        buffer.writeln('| المفتاح | القيمة |');
        buffer.writeln('|---------|--------|');
        for (final entry in response.responseHeaders.entries.take(10)) {
          buffer.writeln('| `${entry.key}` | `${entry.value}` |');
        }
        buffer.writeln();
      }

      // Response body (truncated)
      if (response.responseBody != null) {
        buffer.writeln('#### متن الاستجابة');
        buffer.writeln();
        final body = response.responseBody!;
        if (body.length > 1000) {
          buffer.writeln('```json');
          buffer.writeln(body.substring(0, 1000));
          buffer.writeln('... (مقتطف - ${body.length} حرف إجمالاً)');
          buffer.writeln('```');
        } else {
          buffer.writeln('```json');
          buffer.writeln(body);
          buffer.writeln('```');
        }
        buffer.writeln();
      }

      // Error
      if (!response.isSuccess && response.errorMessage != null) {
        buffer.writeln('### الأخطاء');
        buffer.writeln();
        buffer.writeln('```${response.errorMessage}```');
        buffer.writeln();
      }
    }

    // User notes
    if (report.userNotes != null && report.userNotes!.isNotEmpty) {
      buffer.writeln('### ملاحظات المستخدم');
      buffer.writeln();
      buffer.writeln(report.userNotes);
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _toHtml(ReportData report) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="ar" dir="rtl">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>تقرير HTTP</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: "Cairo", sans-serif; margin: 40px; background: #f5f5f5; }');
    buffer.writeln('    .report { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }');
    buffer.writeln('    h1, h2, h3 { color: #1a73e8; }');
    buffer.writeln('    table { width: 100%; border-collapse: collapse; margin: 16px 0; }');
    buffer.writeln('    th, td { padding: 12px; text-align: right; border-bottom: 1px solid #ddd; }');
    buffer.writeln('    th { background: #f8f9fa; font-weight: bold; }');
    buffer.writeln('    code { background: #f1f3f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }');
    buffer.writeln('    pre { background: #1e1e1e; color: #d4d4d4; padding: 16px; border-radius: 8px; overflow-x: auto; }');
    buffer.writeln('    .success { color: #34a853; }');
    buffer.writeln('    .failure { color: #ea4335; }');
    buffer.writeln('    .timestamp { color: #5f6368; font-size: 14px; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="report">');

    // Convert markdown to HTML (simplified)
    final markdown = _toMarkdown(report);
    buffer.writeln(_markdownToHtml(markdown));

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _markdownToHtml(String markdown) {
    return markdown
        .replaceAllMapped(
          RegExp(r'^### (.+)$', multiLine: true),
          (m) => '<h3>${m[1]}</h3>',
        )
        .replaceAllMapped(
          RegExp(r'^#### (.+)$', multiLine: true),
          (m) => '<h4>${m[1]}</h4>',
        )
        .replaceAllMapped(
          RegExp(r'^\| (.+?) \|$', multiLine: true),
          (m) => '<tr><td>${m[1]?.replaceAll(' | ', '</td><td>')}</td></tr>',
        )
        .replaceAll('```json', '<pre><code>')
        .replaceAll('```', '</code></pre>')
        .replaceAll('`', '<code>').replaceAll('</code></code>', '</code>')
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (m) => '<strong>${m[1]}</strong>',
        );
  }

  _BatchStats _calculateBatchStats(List<HistoryEntry?> responses) {
    var success = 0;
    var failure = 0;
    var totalTime = 0;
    var totalSize = 0;
    var count = 0;

    for (final response in responses) {
      if (response == null) continue;
      count++;
      if (response.isSuccess) {
        success++;
      } else {
        failure++;
      }
      totalTime += response.responseTimeMs;
      totalSize += response.responseSizeBytes;
    }

    return _BatchStats(
      successCount: success,
      failureCount: failure,
      avgResponseTime: count > 0 ? totalTime ~/ count : 0,
      totalSize: totalSize,
    );
  }
}

/// Report format options.
enum ReportFormat {
  markdown,
  html,
  pdf,
}

/// Internal report data structure.
class ReportData {
  const ReportData({
    required this.request,
    required this.response,
    required this.userNotes,
    required this.generatedAt,
  });

  final HttpRequestModel request;
  final HistoryEntry? response;
  final String? userNotes;
  final DateTime generatedAt;
}

/// Internal batch statistics.
class _BatchStats {
  const _BatchStats({
    required this.successCount,
    required this.failureCount,
    required this.avgResponseTime,
    required this.totalSize,
  });

  final int successCount;
  final int failureCount;
  final int avgResponseTime;
  final int totalSize;
}
