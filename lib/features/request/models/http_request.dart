import 'dart:convert';

import '../../authentication/models/auth_config.dart';

export '../../authentication/models/auth_config.dart';

/// HTTP Request Model
class HttpRequestModel {
  final String id;
  String name;
  String method;
  String url;
  List<HeaderItem> headers;
  List<QueryParam> queryParams;
  BodyItem? body;
  List<CookieItem> cookies;
  AuthConfig? auth;
  String? description;
  List<String> tags;
  String? collectionId;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;
  int? timeout;
  bool followRedirects;
  int maxRedirects;
  String httpVersion;
  bool verifyTls;
  String? proxyType;
  String? proxyHost;
  int? proxyPort;
  String? proxyUsername;
  String? proxyPassword;
  String? preRequestScript;
  String? postResponseScript;

  HttpRequestModel({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const [],
    this.queryParams = const [],
    this.body,
    this.cookies = const [],
    this.auth,
    this.description,
    this.tags = const [],
    this.collectionId,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.timeout,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.httpVersion = 'HTTP/1.1',
    this.verifyTls = true,
    this.proxyType,
    this.proxyHost,
    this.proxyPort,
    this.proxyUsername,
    this.proxyPassword,
    this.preRequestScript,
    this.postResponseScript,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  HttpRequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<HeaderItem>? headers,
    List<QueryParam>? queryParams,
    BodyItem? body,
    List<CookieItem>? cookies,
    AuthConfig? auth,
    String? description,
    List<String>? tags,
    String? collectionId,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? timeout,
    bool? followRedirects,
    int? maxRedirects,
    String? httpVersion,
    bool? verifyTls,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    String? proxyUsername,
    String? proxyPassword,
    String? preRequestScript,
    String? postResponseScript,
  }) {
    return HttpRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
      cookies: cookies ?? this.cookies,
      auth: auth ?? this.auth,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      collectionId: collectionId ?? this.collectionId,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      timeout: timeout ?? this.timeout,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      httpVersion: httpVersion ?? this.httpVersion,
      verifyTls: verifyTls ?? this.verifyTls,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      proxyUsername: proxyUsername ?? this.proxyUsername,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      preRequestScript: preRequestScript ?? this.preRequestScript,
      postResponseScript: postResponseScript ?? this.postResponseScript,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'headers': headers.map((h) => h.toJson()).toList(),
      'queryParams': queryParams.map((q) => q.toJson()).toList(),
      'body': body?.toJson(),
      'cookies': cookies.map((c) => c.toJson()).toList(),
      'auth': auth?.toJson(),
      'description': description,
      'tags': tags,
      'collectionId': collectionId,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timeout': timeout,
      'followRedirects': followRedirects,
      'maxRedirects': maxRedirects,
      'httpVersion': httpVersion,
      'verifyTls': verifyTls,
      'proxyType': proxyType,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
      'proxyUsername': proxyUsername,
      'proxyPassword': proxyPassword,
      'preRequestScript': preRequestScript,
      'postResponseScript': postResponseScript,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory HttpRequestModel.fromJson(Map<String, dynamic> json) {
    return HttpRequestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      headers: (json['headers'] as List<dynamic>?)
              ?.map((e) => HeaderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      queryParams: (json['queryParams'] as List<dynamic>?)
              ?.map((e) => QueryParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      body: json['body'] != null
          ? BodyItem.fromJson(json['body'] as Map<String, dynamic>)
          : null,
      cookies: (json['cookies'] as List<dynamic>?)
              ?.map((e) => CookieItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      auth: json['auth'] != null
          ? AuthConfig.fromJson(json['auth'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      collectionId: json['collectionId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      timeout: json['timeout'] as int?,
      followRedirects: json['followRedirects'] as bool? ?? true,
      maxRedirects: json['maxRedirects'] as int? ?? 5,
      httpVersion: json['httpVersion'] as String? ?? 'HTTP/1.1',
      verifyTls: json['verifyTls'] as bool? ?? true,
      proxyType: json['proxyType'] as String?,
      proxyHost: json['proxyHost'] as String?,
      proxyPort: json['proxyPort'] as int?,
      proxyUsername: json['proxyUsername'] as String?,
      proxyPassword: json['proxyPassword'] as String?,
      preRequestScript: json['preRequestScript'] as String?,
      postResponseScript: json['postResponseScript'] as String?,
    );
  }

  factory HttpRequestModel.fromJsonString(String jsonString) {
    return HttpRequestModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Build full URL with query parameters
  String get fullUrl {
    if (queryParams.isEmpty) return url;
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    for (final q in queryParams.where((e) => e.enabled)) {
      params[q.key] = q.value;
    }
    return uri.replace(queryParameters: params).toString();
  }

  /// Get enabled headers as map
  Map<String, String> get enabledHeaders {
    return {
      for (final h in headers.where((e) => e.enabled)) h.key: h.value,
    };
  }

  /// Get enabled cookies as map
  Map<String, String> get enabledCookies {
    return {
      for (final c in cookies.where((e) => e.enabled)) c.key: c.value,
    };
  }

  /// Get enabled query params as map
  Map<String, String> get enabledQueryParams {
    return {
      for (final q in queryParams.where((e) => e.enabled)) q.key: q.value,
    };
  }
}

class HeaderItem {
  String key;
  String value;
  bool enabled;
  String? description;

  HeaderItem({
    required this.key,
    required this.value,
    this.enabled = true,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
        'description': description,
      };

  factory HeaderItem.fromJson(Map<String, dynamic> json) {
    return HeaderItem(
      key: json['key'] as String,
      value: json['value'] as String,
      enabled: json['enabled'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  HeaderItem copyWith({
    String? key,
    String? value,
    bool? enabled,
    String? description,
  }) {
    return HeaderItem(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
    );
  }
}

class QueryParam {
  String key;
  String value;
  bool enabled;
  String? description;

  QueryParam({
    required this.key,
    required this.value,
    this.enabled = true,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
        'description': description,
      };

  factory QueryParam.fromJson(Map<String, dynamic> json) {
    return QueryParam(
      key: json['key'] as String,
      value: json['value'] as String,
      enabled: json['enabled'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  QueryParam copyWith({
    String? key,
    String? value,
    bool? enabled,
    String? description,
  }) {
    return QueryParam(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
    );
  }
}

class BodyItem {
  String type;
  String? rawContent;
  List<FormFieldItem>? formFields;
  List<FileFieldItem>? fileFields;
  String? contentType;
  String? filePath;
  String? fileName;

  BodyItem({
    required this.type,
    this.rawContent,
    this.formFields,
    this.fileFields,
    this.contentType,
    this.filePath,
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'rawContent': rawContent,
        'formFields': formFields?.map((f) => f.toJson()).toList(),
        'fileFields': fileFields?.map((f) => f.toJson()).toList(),
        'contentType': contentType,
        'filePath': filePath,
        'fileName': fileName,
      };

  factory BodyItem.fromJson(Map<String, dynamic> json) {
    return BodyItem(
      type: json['type'] as String,
      rawContent: json['rawContent'] as String?,
      formFields: (json['formFields'] as List<dynamic>?)
          ?.map((e) => FormFieldItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      fileFields: (json['fileFields'] as List<dynamic>?)
          ?.map((e) => FileFieldItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentType: json['contentType'] as String?,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  BodyItem copyWith({
    String? type,
    String? rawContent,
    List<FormFieldItem>? formFields,
    List<FileFieldItem>? fileFields,
    String? contentType,
    String? filePath,
    String? fileName,
  }) {
    return BodyItem(
      type: type ?? this.type,
      rawContent: rawContent ?? this.rawContent,
      formFields: formFields ?? this.formFields,
      fileFields: fileFields ?? this.fileFields,
      contentType: contentType ?? this.contentType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
    );
  }
}

class FormFieldItem {
  String key;
  String value;
  bool enabled;

  FormFieldItem({
    required this.key,
    required this.value,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
      };

  factory FormFieldItem.fromJson(Map<String, dynamic> json) {
    return FormFieldItem(
      key: json['key'] as String,
      value: json['value'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class FileFieldItem {
  String key;
  String filePath;
  String fileName;
  String? contentType;
  bool enabled;

  FileFieldItem({
    required this.key,
    required this.filePath,
    required this.fileName,
    this.contentType,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'filePath': filePath,
        'fileName': fileName,
        'contentType': contentType,
        'enabled': enabled,
      };

  factory FileFieldItem.fromJson(Map<String, dynamic> json) {
    return FileFieldItem(
      key: json['key'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class CookieItem {
  String key;
  String value;
  bool enabled;
  String? domain;
  String? path;
  DateTime? expires;
  bool? secure;
  bool? httpOnly;

  CookieItem({
    required this.key,
    required this.value,
    this.enabled = true,
    this.domain,
    this.path,
    this.expires,
    this.secure,
    this.httpOnly,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
        'domain': domain,
        'path': path,
        'expires': expires?.toIso8601String(),
        'secure': secure,
        'httpOnly': httpOnly,
      };

  factory CookieItem.fromJson(Map<String, dynamic> json) {
    return CookieItem(
      key: json['key'] as String,
      value: json['value'] as String,
      enabled: json['enabled'] as bool? ?? true,
      domain: json['domain'] as String?,
      path: json['path'] as String?,
      expires: json['expires'] != null
          ? DateTime.parse(json['expires'] as String)
          : null,
      secure: json['secure'] as bool?,
      httpOnly: json['httpOnly'] as bool?,
    );
  }

  CookieItem copyWith({
    String? key,
    String? value,
    bool? enabled,
    String? domain,
    String? path,
    DateTime? expires,
    bool? secure,
    bool? httpOnly,
  }) {
    return CookieItem(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      domain: domain ?? this.domain,
      path: path ?? this.path,
      expires: expires ?? this.expires,
      secure: secure ?? this.secure,
      httpOnly: httpOnly ?? this.httpOnly,
    );
  }
}

// AuthConfig is imported from authentication/models/auth_config.dart

