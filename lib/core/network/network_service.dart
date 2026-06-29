import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/app_constants.dart';
import '../error/app_error.dart';
import '../../features/authentication/models/auth_config.dart';
import '../../features/history/models/history_entry.dart';
import '../../features/request/models/http_request.dart';

/// Response data from HTTP request
class HttpResponseData {
  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final String body;
  final List<int> bodyBytes;
  final int durationMs;
  final int sizeBytes;
  final TimelineData? timeline;
  final String? contentType;
  final Map<String, String> responseCookies;

  HttpResponseData({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    required this.bodyBytes,
    required this.durationMs,
    required this.sizeBytes,
    this.timeline,
    this.contentType,
    this.responseCookies = const {},
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Network service for HTTP requests using Dio
class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final CookieJar _cookieJar = CookieJar();
  late Dio _dio;

  /// Initialize Dio with default settings
  void initialize() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: AppConstants.defaultConnectTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.defaultSendTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.defaultReceiveTimeout),
        validateStatus: (_) => true, // Always return response
        followRedirects: true,
        maxRedirects: 5,
        receiveDataWhenStatusError: true,
        responseType: ResponseType.bytes,
      ),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Execute HTTP request
  Future<HttpResponseData> executeRequest(HttpRequestModel request) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      // Build full URL with query params
      final fullUrl = _buildFullUrl(request);
      final headers = _buildHeaders(request);
      final body = _buildBody(request);

      // Track timeline
      final dnsStart = DateTime.now();

      final response = await _dio.request<dynamic>(
        fullUrl,
        data: body,
        options: Options(
          method: request.method,
          headers: headers,
          followRedirects: request.followRedirects,
          maxRedirects: request.maxRedirects,
          validateStatus: (_) => true,
          receiveDataWhenStatusError: true,
          responseType: ResponseType.bytes,
          sendTimeout: request.timeout != null
              ? Duration(milliseconds: request.timeout!)
              : null,
          receiveTimeout: request.timeout != null
              ? Duration(milliseconds: request.timeout!)
              : null,
        ),
      );

      stopwatch.stop();
      final endTime = DateTime.now();

      // Build timeline (simplified - real timeline needs interceptor data)
      final timeline = TimelineData(
        dnsLookupMs: endTime.difference(dnsStart).inMilliseconds ~/ 4,
        connectionMs: endTime.difference(dnsStart).inMilliseconds ~/ 4,
        sslHandshakeMs: endTime.difference(dnsStart).inMilliseconds ~/ 4,
        sendingMs: endTime.difference(dnsStart).inMilliseconds ~/ 4,
        waitingMs: endTime.difference(dnsStart).inMilliseconds ~/ 2,
        downloadingMs: endTime.difference(dnsStart).inMilliseconds ~/ 4,
        totalMs: stopwatch.elapsedMilliseconds,
      );

      final bodyBytes = response.data as List<int>;
      final bodyString = _decodeBody(bodyBytes, response.headers);

      final responseHeaders = <String, String>{};
      response.headers.forEach((key, values) {
        responseHeaders[key] = values.join(', ');
      });

      final responseCookies = <String, String>{};
      final cookies = await _cookieJar.loadForRequest(Uri.parse(fullUrl));
      for (final cookie in cookies) {
        responseCookies[cookie.name] = cookie.value;
      }

      return HttpResponseData(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        headers: responseHeaders,
        body: bodyString,
        bodyBytes: bodyBytes,
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: bodyBytes.length,
        timeline: timeline,
        contentType: responseHeaders['content-type'],
        responseCookies: responseCookies,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      throw _handleDioError(e, stopwatch.elapsedMilliseconds);
    } catch (e, stackTrace) {
      stopwatch.stop();
      throw AppError(
        message: e.toString(),
        code: 'REQUEST_ERROR',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _buildFullUrl(HttpRequestModel request) {
    var url = request.url;
    final queryParams = <String, String>{};

    // Add request query params
    for (final q in request.queryParams.where((e) => e.enabled)) {
      queryParams[q.key] = q.value;
    }

    // Add auth query params
    if (request.auth != null) {
      queryParams.addAll(request.auth!.getAdditionalQueryParams());
    }

    if (queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final existingParams = Map<String, String>.from(uri.queryParameters);
      existingParams.addAll(queryParams);
      url = uri.replace(queryParameters: existingParams).toString();
    }

    return url;
  }

  Map<String, String> _buildHeaders(HttpRequestModel request) {
    final headers = <String, String>{};

    // Add request headers
    for (final h in request.headers.where((e) => e.enabled)) {
      headers[h.key] = h.value;
    }

    // Add auth headers
    if (request.auth != null) {
      headers.addAll(request.auth!.getAdditionalHeaders());
    }

    // Add cookie header
    if (request.cookies.isNotEmpty) {
      final cookieStr = request.cookies
          .where((c) => c.enabled)
          .map((c) => '${c.key}=${c.value}')
          .join('; ');
      if (cookieStr.isNotEmpty) {
        headers['Cookie'] = cookieStr;
      }
    }

    // Add content type based on body
    if (request.body != null && request.body!.type != 'none') {
      final contentType = _getContentType(request.body!);
      if (contentType != null && !headers.containsKey('Content-Type')) {
        headers['Content-Type'] = contentType;
      }
    }

    return headers;
  }

  dynamic _buildBody(HttpRequestModel request) {
    if (request.body == null || request.body!.type == 'none') {
      return null;
    }

    final body = request.body!;
    switch (body.type) {
      case 'json':
      case 'text':
      case 'xml':
      case 'html':
        return body.rawContent;
      case 'form':
        final formData = FormData();
        for (final field in body.formFields ?? <FormFieldItem>[]) {
          if (field.enabled) {
            formData.fields.add(MapEntry(field.key, field.value));
          }
        }
        return formData;
      case 'multipart':
        final formData = FormData();
        for (final field in body.formFields ?? <FormFieldItem>[]) {
          if (field.enabled) {
            formData.fields.add(MapEntry(field.key, field.value));
          }
        }
        for (final fileField in body.fileFields ?? <FileFieldItem>[]) {
          if (fileField.enabled) {
            final file = File(fileField.filePath);
            if (file.existsSync()) {
              final uploadFile = MultipartFile.fromBytes(
                file.readAsBytesSync(),
                filename: fileField.fileName,
                contentType: MediaType.parse(
                  fileField.contentType ?? 'application/octet-stream',
                ),
              );
              formData.files.add(MapEntry(fileField.key, uploadFile));
            }
          }
        }
        return formData;
      case 'binary':
        if (body.filePath != null) {
          final file = File(body.filePath!);
          if (file.existsSync()) {
            return file.readAsBytesSync();
          }
        }
        return null;
      default:
        return null;
    }
  }

  String? _getContentType(BodyItem body) {
    switch (body.type) {
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
        return 'text/html';
      case 'text':
        return 'text/plain';
      case 'form':
        return 'application/x-www-form-urlencoded';
      case 'multipart':
        return 'multipart/form-data';
      case 'binary':
        return 'application/octet-stream';
      default:
        return null;
    }
  }

  String _decodeBody(List<int> bytes, Headers headers) {
    final contentType = headers.value('content-type');
    String? charset;
    if (contentType != null) {
      final parts = contentType.split(';');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('charset=')) {
          charset = trimmed.substring(8).replaceAll('"', '');
        }
      }
    }

    final encoding = Encoding.getByName(charset ?? 'utf-8') ?? utf8;
    return encoding.decode(bytes);
  }

  AppError _handleDioError(DioException e, int elapsedMs) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError(
          originalError: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.connectionError:
        return ConnectionError(
          originalError: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.badCertificate:
        return AppError(
          message: 'شهادة SSL/TLS غير صالحة',
          code: 'CERT_ERROR',
          originalError: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.badResponse:
        return NetworkError(
          message: 'استجابة خاطئة من الخادم: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
          originalError: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.cancel:
        return AppError(
          message: 'تم إلغاء الطلب',
          code: 'CANCELLED',
          originalError: e,
          stackTrace: e.stackTrace,
        );
      default:
        return AppError(
          message: e.message ?? 'خطأ غير معروف',
          code: 'UNKNOWN_NETWORK_ERROR',
          originalError: e,
          stackTrace: e.stackTrace,
        );
    }
  }

  /// Cancel all ongoing requests
  void cancelAll() {
    _dio.close(force: true);
    initialize();
  }

  /// Clear all cookies
  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
}

/// Logging interceptor for Dio
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
