import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../request/models/http_request.dart';

/// Repository for managing HTTP requests
class RequestRepository {
  RequestRepository(this._box);

  final Box<String> _box;

  List<HttpRequestModel> getAll() {
    return _box.values
        .map((e) => HttpRequestModel.fromJsonString(e))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<HttpRequestModel> getRecent({int limit = 20}) {
    final all = getAll();
    return all.take(limit).toList();
  }

  List<HttpRequestModel> getPinned() {
    return getAll().where((r) => r.isPinned).toList();
  }

  List<HttpRequestModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((r) {
      return r.name.toLowerCase().contains(lowerQuery) ||
          r.url.toLowerCase().contains(lowerQuery) ||
          r.method.toLowerCase().contains(lowerQuery) ||
          r.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<HttpRequestModel> getByCollection(String collectionId) {
    return getAll().where((r) => r.collectionId == collectionId).toList();
  }

  HttpRequestModel? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return HttpRequestModel.fromJsonString(jsonStr);
  }

  Future<void> save(HttpRequestModel request) async {
    try {
      await _box.put(request.id, request.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ الطلب',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف الطلب',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع الطلبات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> togglePin(String id) async {
    final request = getById(id);
    if (request != null) {
      await save(request.copyWith(isPinned: !request.isPinned));
    }
  }
}

/// Provider for RequestRepository
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final box = Hive.box<String>(AppConstants.requestsBox);
  return RequestRepository(box);
});
