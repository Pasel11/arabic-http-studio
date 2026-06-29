import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../../../core/services/encryption_service.dart';
import '../../variables/models/variable_model.dart';

/// Repository for managing variables
class VariablesRepository {
  VariablesRepository(this._box);

  final Box<String> _box;

  List<VariableModel> getAll() {
    return _box.values
        .map((e) => VariableModel.fromJsonString(e))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<VariableModel> getGlobal() {
    return getAll().where((v) => v.isGlobal).toList();
  }

  List<VariableModel> getByEnvironment(String environmentId) {
    return getAll().where((v) => v.environmentId == environmentId).toList();
  }

  List<VariableModel> getSecrets() {
    return getAll().where((v) => v.isEncrypted || v.type == 'secret').toList();
  }

  List<VariableModel> getDynamic() {
    return getAll().where((v) => v.isDynamic).toList();
  }

  VariableModel? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return VariableModel.fromJsonString(jsonStr);
  }

  VariableModel? getByKey(String key) {
    return getAll().firstWhere(
      (v) => v.key == key,
      orElse: () => throw StateError('Variable not found: $key'),
    );
  }

  List<VariableModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((v) {
      return v.key.toLowerCase().contains(lowerQuery) ||
          v.value.toLowerCase().contains(lowerQuery) ||
          v.description?.toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }

  Future<void> save(VariableModel variable) async {
    try {
      // Encrypt if it's a secret
      if (variable.isEncrypted || variable.type == 'secret') {
        final encryptedValue = EncryptionService.instance.encrypt(variable.value);
        await _box.put(
          variable.id,
          VariableModel(
            id: variable.id,
            key: variable.key,
            value: encryptedValue,
            type: variable.type,
            description: variable.description,
            isGlobal: variable.isGlobal,
            isEncrypted: true,
            isDynamic: variable.isDynamic,
            dynamicType: variable.dynamicType,
            environmentId: variable.environmentId,
            createdAt: variable.createdAt,
            updatedAt: DateTime.now(),
          ).toJsonString(),
        );
      } else {
        await _box.put(variable.id, variable.toJsonString());
      }
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ المتغير',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get decrypted value
  String getValue(VariableModel variable) {
    if (variable.isEncrypted || variable.type == 'secret') {
      try {
        return EncryptionService.instance.decrypt(variable.value);
      } catch (_) {
        return variable.value;
      }
    }

    if (variable.isDynamic) {
      return _generateDynamicValue(variable.dynamicType);
    }

    return variable.value;
  }

  String _generateDynamicValue(String? type) {
    switch (type) {
      case 'timestamp':
        return DateTime.now().millisecondsSinceEpoch.toString();
      case 'uuid':
        return DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      case 'random_number':
        return (100000 + DateTime.now().microsecond * 7 % 900000).toString();
      case 'date':
        return DateTime.now().toIso8601String().split('T')[0];
      case 'time':
        return DateTime.now().toIso8601String().split('T')[1].split('.')[0];
      default:
        return '';
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف المتغير',
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
        message: 'فشل حذف جميع المتغيرات',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all variables as a map (key -> value) for substitution
  Map<String, String> toMap({String? environmentId}) {
    final result = <String, String>{};

    for (final v in getAll()) {
      if (environmentId == null || v.isGlobal || v.environmentId == environmentId) {
        result[v.key] = getValue(v);
      }
    }

    return result;
  }
}

/// Provider for VariablesRepository
final variablesRepositoryProvider = Provider<VariablesRepository>((ref) {
  final box = Hive.box<String>(AppConstants.variablesBox);
  return VariablesRepository(box);
});
