import 'dart:convert';

/// Authentication configuration model
class AuthConfig {
  final String type;
  final String? token;
  final String? username;
  final String? password;
  final String? apiKey;
  final String? apiKeyHeader;
  final String? apiKeyLocation;
  final Map<String, String>? customHeaders;
  final Map<String, String>? customQueryParams;
  final String? jwtPayload;
  final String? jwtSecret;
  final String? realm;
  final String? nonce;
  final String? qop;

  const AuthConfig({
    required this.type,
    this.token,
    this.username,
    this.password,
    this.apiKey,
    this.apiKeyHeader,
    this.apiKeyLocation = 'header',
    this.customHeaders,
    this.customQueryParams,
    this.jwtPayload,
    this.jwtSecret,
    this.realm,
    this.nonce,
    this.qop,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'token': token,
        'username': username,
        'password': password,
        'apiKey': apiKey,
        'apiKeyHeader': apiKeyHeader,
        'apiKeyLocation': apiKeyLocation,
        'customHeaders': customHeaders,
        'customQueryParams': customQueryParams,
        'jwtPayload': jwtPayload,
        'jwtSecret': jwtSecret,
        'realm': realm,
        'nonce': nonce,
        'qop': qop,
      };

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      type: json['type'] as String,
      token: json['token'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      apiKey: json['apiKey'] as String?,
      apiKeyHeader: json['apiKeyHeader'] as String?,
      apiKeyLocation: json['apiKeyLocation'] as String? ?? 'header',
      customHeaders: (json['customHeaders'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      customQueryParams: (json['customQueryParams'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      jwtPayload: json['jwtPayload'] as String?,
      jwtSecret: json['jwtSecret'] as String?,
      realm: json['realm'] as String?,
      nonce: json['nonce'] as String?,
      qop: json['qop'] as String?,
    );
  }

  AuthConfig copyWith({
    String? type,
    String? token,
    String? username,
    String? password,
    String? apiKey,
    String? apiKeyHeader,
    String? apiKeyLocation,
    Map<String, String>? customHeaders,
    Map<String, String>? customQueryParams,
    String? jwtPayload,
    String? jwtSecret,
    String? realm,
    String? nonce,
    String? qop,
  }) {
    return AuthConfig(
      type: type ?? this.type,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
      customHeaders: customHeaders ?? this.customHeaders,
      customQueryParams: customQueryParams ?? this.customQueryParams,
      jwtPayload: jwtPayload ?? this.jwtPayload,
      jwtSecret: jwtSecret ?? this.jwtSecret,
      realm: realm ?? this.realm,
      nonce: nonce ?? this.nonce,
      qop: qop ?? this.qop,
    );
  }

  /// Generate Authorization header value based on auth type
  String? getAuthorizationHeader() {
    switch (type) {
      case 'bearer':
        return token != null ? 'Bearer $token' : null;
      case 'basic':
        if (username != null && password != null) {
          final credentials = '$username:$password';
          final encoded = base64.encode(utf8.encode(credentials));
          return 'Basic $encoded';
        }
        return null;
      case 'jwt':
        return token;
      case 'apiKey':
        return null;
      case 'custom':
        return null;
      default:
        return null;
    }
  }

  /// Get additional headers for this auth config
  Map<String, String> getAdditionalHeaders() {
    final headers = <String, String>{};
    final authHeader = getAuthorizationHeader();
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }

    if (type == 'apiKey' && apiKeyLocation == 'header' && apiKey != null) {
      headers[apiKeyHeader ?? 'X-API-Key'] = apiKey!;
    }

    if (type == 'custom' && customHeaders != null) {
      headers.addAll(customHeaders!);
    }

    return headers;
  }

  /// Get additional query params for this auth config
  Map<String, String> getAdditionalQueryParams() {
    final params = <String, String>{};

    if (type == 'apiKey' && apiKeyLocation == 'query' && apiKey != null) {
      params[apiKeyHeader ?? 'api_key'] = apiKey!;
    }

    if (type == 'custom' && customQueryParams != null) {
      params.addAll(customQueryParams!);
    }

    return params;
  }
}
