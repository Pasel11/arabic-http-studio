import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/http_request.dart';
import '../repositories/request_repository.dart';

/// State notifier for current request being edited
class CurrentRequestNotifier extends StateNotifier<HttpRequestModel?> {
  CurrentRequestNotifier(this._repository) : super(null);

  final RequestRepository _repository;

  void setRequest(HttpRequestModel request) {
    state = request;
  }

  void updateName(String name) {
    if (state != null) {
      state = state!.copyWith(name: name);
    }
  }

  void updateMethod(String method) {
    if (state != null) {
      state = state!.copyWith(method: method);
    }
  }

  void updateUrl(String url) {
    if (state != null) {
      state = state!.copyWith(url: url);
    }
  }

  void updateDescription(String? description) {
    if (state != null) {
      state = state!.copyWith(description: description);
    }
  }

  void updateHeaders(List<HeaderItem> headers) {
    if (state != null) {
      state = state!.copyWith(headers: headers);
    }
  }

  void addHeader(HeaderItem header) {
    if (state != null) {
      state = state!.copyWith(headers: [...state!.headers, header]);
    }
  }

  void updateHeader(HeaderItem header) {
    if (state != null) {
      final headers = state!.headers.map((h) {
        return h.key == header.key ? header : h;
      }).toList();
      state = state!.copyWith(headers: headers);
    }
  }

  void removeHeader(String key) {
    if (state != null) {
      state = state!.copyWith(
        headers: state!.headers.where((h) => h.key != key).toList(),
      );
    }
  }

  void updateQueryParams(List<QueryParam> params) {
    if (state != null) {
      state = state!.copyWith(queryParams: params);
    }
  }

  void addQueryParam(QueryParam param) {
    if (state != null) {
      state = state!.copyWith(queryParams: [...state!.queryParams, param]);
    }
  }

  void updateQueryParam(QueryParam param) {
    if (state != null) {
      final params = state!.queryParams.map((p) {
        return p.key == param.key ? param : p;
      }).toList();
      state = state!.copyWith(queryParams: params);
    }
  }

  void removeQueryParam(String key) {
    if (state != null) {
      state = state!.copyWith(
        queryParams: state!.queryParams.where((p) => p.key != key).toList(),
      );
    }
  }

  void updateBody(BodyItem? body) {
    if (state != null) {
      state = state!.copyWith(body: body);
    }
  }

  void updateCookies(List<CookieItem> cookies) {
    if (state != null) {
      state = state!.copyWith(cookies: cookies);
    }
  }

  void addCookie(CookieItem cookie) {
    if (state != null) {
      state = state!.copyWith(cookies: [...state!.cookies, cookie]);
    }
  }

  void updateCookie(CookieItem cookie) {
    if (state != null) {
      final cookies = state!.cookies.map((c) {
        return c.key == cookie.key ? cookie : c;
      }).toList();
      state = state!.copyWith(cookies: cookies);
    }
  }

  void removeCookie(String key) {
    if (state != null) {
      state = state!.copyWith(
        cookies: state!.cookies.where((c) => c.key != key).toList(),
      );
    }
  }

  void updateAuth(AuthConfig? auth) {
    if (state != null) {
      state = state!.copyWith(auth: auth);
    }
  }

  void updateSettings({
    int? timeout,
    bool? followRedirects,
    int? maxRedirects,
    String? httpVersion,
    bool? verifyTls,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
  }) {
    if (state != null) {
      state = state!.copyWith(
        timeout: timeout,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        httpVersion: httpVersion,
        verifyTls: verifyTls,
        proxyType: proxyType,
        proxyHost: proxyHost,
        proxyPort: proxyPort,
      );
    }
  }

  void updateTags(List<String> tags) {
    if (state != null) {
      state = state!.copyWith(tags: tags);
    }
  }

  void updateCollectionId(String? collectionId) {
    if (state != null) {
      state = state!.copyWith(collectionId: collectionId);
    }
  }

  Future<void> save() async {
    if (state != null) {
      await _repository.save(state!);
    }
  }

  Future<void> delete() async {
    if (state != null) {
      await _repository.delete(state!.id);
    }
  }
}

/// Provider for current request
final currentRequestProvider =
    StateNotifierProvider<CurrentRequestNotifier, HttpRequestModel?>((ref) {
  final repository = ref.read(requestRepositoryProvider);
  return CurrentRequestNotifier(repository);
});

/// Provider for request by ID
final requestByIdProvider =
    FutureProvider.family<HttpRequestModel?, String>((ref, id) async {
  final repository = ref.read(requestRepositoryProvider);
  return repository.getById(id);
});
