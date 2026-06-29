import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../environment/models/environment_model.dart';

/// Repository for managing environments
class EnvironmentRepository {
  EnvironmentRepository(this._box);

  final Box<String> _box;

  List<EnvironmentModel> getAll() {
    return _box.values
        .map((e) => EnvironmentModel.fromJsonString(e))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  EnvironmentModel? getActive() {
    final active = getAll().where((e) => e.isActive).toList();
    return active.isEmpty ? null : active.first;
  }

  EnvironmentModel? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return EnvironmentModel.fromJsonString(jsonStr);
  }

  List<EnvironmentModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((e) {
      return e.name.toLowerCase().contains(lowerQuery) ||
          e.description?.toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }

  Future<void> save(EnvironmentModel environment) async {
    try {
      // If marking as active, deactivate others
      if (environment.isActive) {
        for (final env in getAll()) {
          if (env.id != environment.id && env.isActive) {
            await _box.put(
              env.id,
              EnvironmentModel(
                id: env.id,
                name: env.name,
                description: env.description,
                variables: env.variables,
                secrets: env.secrets,
                isActive: false,
                color: env.color,
                createdAt: env.createdAt,
                updatedAt: DateTime.now(),
              ).toJsonString(),
            );
          }
        }
      }
      await _box.put(environment.id, environment.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ البيئة',
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
        message: 'فشل حذف البيئة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setActive(String id) async {
    for (final env in getAll()) {
      final isActive = env.id == id;
      await _box.put(
        env.id,
        EnvironmentModel(
          id: env.id,
          name: env.name,
          description: env.description,
          variables: env.variables,
          secrets: env.secrets,
          isActive: isActive,
          color: env.color,
          createdAt: env.createdAt,
          updatedAt: DateTime.now(),
        ).toJsonString(),
      );
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع البيئات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all variables for active environment (merged with global)
  Map<String, String> getActiveVariables() {
    final result = <String, String>{};

    for (final env in getAll()) {
      if (env.isActive) {
        result.addAll(env.variables);
      }
    }

    return result;
  }
}

/// Provider for EnvironmentRepository
final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  final box = Hive.box<String>(AppConstants.environmentsBox);
  return EnvironmentRepository(box);
});
