import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/reports/services/report_service.dart';
import 'package:arabic_http_studio/features/request/models/http_request.dart';
import 'package:arabic_http_studio/features/history/models/history_entry.dart';

void main() {
  group('ReportService', () {
    final service = ReportService.instance;

    test('should generate markdown report', () async {
      final request = HttpRequestModel(
        id: 'test-1',
        name: 'Test Request',
        method: 'GET',
        url: 'https://api.example.com/test',
        headers: [HeaderItem(key: 'Content-Type', value: 'application/json')],
      );

      final content = await service.generateReport(
        request: request,
        response: null,
        format: ReportFormat.markdown,
      );

      expect(content, contains('Test Request'));
      expect(content, contains('GET'));
      expect(content, contains('https://api.example.com/test'));
      expect(content, contains('Content-Type'));
    });

    test('should generate HTML report', () async {
      final request = HttpRequestModel(
        id: 'test-1',
        name: 'Test Request',
        method: 'POST',
        url: 'https://api.example.com/test',
      );

      final content = await service.generateReport(
        request: request,
        response: null,
        format: ReportFormat.html,
      );

      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('<html'));
      expect(content, contains('Test Request'));
      expect(content, contains('POST'));
    });

    test('should include response data in report', () async {
      final request = HttpRequestModel(
        id: 'test-1',
        name: 'Test Request',
        method: 'GET',
        url: 'https://api.example.com/test',
      );

      final response = HistoryEntry(
        id: 'resp-1',
        requestId: 'test-1',
        requestName: 'Test Request',
        method: 'GET',
        url: 'https://api.example.com/test',
        statusCode: 200,
        statusText: 'OK',
        responseTimeMs: 150,
        responseSizeBytes: 1024,
        requestSizeBytes: 0,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: '{"status": "success"}',
        requestHeaders: {},
        timestamp: DateTime.now(),
        isSuccess: true,
      );

      final content = await service.generateReport(
        request: request,
        response: response,
        format: ReportFormat.markdown,
      );

      expect(content, contains('200'));
      expect(content, contains('150ms'));
      expect(content, contains('success'));
    });

    test('should include user notes in report', () async {
      final request = HttpRequestModel(
        id: 'test-1',
        name: 'Test',
        method: 'GET',
        url: 'https://api.example.com',
      );

      final content = await service.generateReport(
        request: request,
        response: null,
        userNotes: 'This is a test note',
        format: ReportFormat.markdown,
      );

      expect(content, contains('This is a test note'));
    });

    test('should generate batch report', () async {
      final requests = [
        HttpRequestModel(
          id: '1',
          name: 'Request 1',
          method: 'GET',
          url: 'https://api.example.com/1',
        ),
        HttpRequestModel(
          id: '2',
          name: 'Request 2',
          method: 'POST',
          url: 'https://api.example.com/2',
        ),
      ];

      final content = await service.generateBatchReport(
        requests: requests,
        responses: [null, null],
        format: ReportFormat.markdown,
      );

      expect(content, contains('Request 1'));
      expect(content, contains('Request 2'));
      expect(content, contains('تقرير شامل'));
    });
  });

  group('ReportFormat', () {
    test('should have all expected formats', () {
      expect(ReportFormat.values, contains(ReportFormat.markdown));
      expect(ReportFormat.values, contains(ReportFormat.html));
      expect(ReportFormat.values, contains(ReportFormat.pdf));
    });
  });
}
