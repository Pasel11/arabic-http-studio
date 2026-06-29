import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_error.dart';
import '../models/workspace_models.dart';

/// Repository for managing workspaces.
///
/// This repository handles CRUD operations for workspaces,
/// which are the top-level organizational unit in the application.
class WorkspaceRepository {
  /// Creates a workspace repository.
  WorkspaceRepository(this._box);

  final Box<String> _box;

  /// Gets all workspaces.
  List<Workspace> getAll() {
    return _box.values
        .map((e) => Workspace.fromJsonString(e))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Gets the active workspace.
  Workspace? getActive() {
    final active = getAll().where((w) => w.isActive).toList();
    return active.isEmpty ? null : active.first;
  }

  /// Gets a workspace by ID.
  Workspace? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return Workspace.fromJsonString(jsonStr);
  }

  /// Searches workspaces by name or description.
  List<Workspace> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((w) {
      return w.name.toLowerCase().contains(lowerQuery) ||
          w.description?.toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }

  /// Saves a workspace.
  Future<void> save(Workspace workspace) async {
    try {
      if (workspace.isActive) {
        // Deactivate other workspaces
        for (final ws in getAll()) {
          if (ws.id != workspace.id && ws.isActive) {
            await _box.put(
              ws.id,
              ws.copyWith(isActive: false).toJsonString(),
            );
          }
        }
      }
      await _box.put(workspace.id, workspace.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ مساحة العمل',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sets a workspace as active.
  Future<void> setActive(String id) async {
    for (final ws in getAll()) {
      await _box.put(
        ws.id,
        ws.copyWith(isActive: ws.id == id).toJsonString(),
      );
    }
  }

  /// Deletes a workspace.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف مساحة العمل',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes all workspaces.
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع مساحات العمل',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Repository for managing projects.
class ProjectRepository {
  /// Creates a project repository.
  ProjectRepository(this._box);

  final Box<String> _box;

  /// Gets all projects.
  List<Project> getAll() {
    return _box.values
        .map((e) => Project.fromJsonString(e))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Gets projects by workspace ID.
  List<Project> getByWorkspace(String workspaceId) {
    return getAll().where((p) => p.workspaceId == workspaceId).toList();
  }

  /// Gets a project by ID.
  Project? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return Project.fromJsonString(jsonStr);
  }

  /// Searches projects.
  List<Project> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          p.description?.toLowerCase().contains(lowerQuery) == true ||
          p.baseUrl?.toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }

  /// Saves a project.
  Future<void> save(Project project) async {
    try {
      await _box.put(project.id, project.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ المشروع',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a project.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف المشروع',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes all projects.
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف جميع المشاريع',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Repository for managing tags.
class TagsRepository {
  /// Creates a tags repository.
  TagsRepository(this._box);

  final Box<String> _box;

  /// Gets all tags.
  List<Tag> getAll() {
    return _box.values
        .map((e) => Tag.fromJsonString(e))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Gets tags by project ID.
  List<Tag> getByProject(String projectId) {
    return getAll().where((t) => t.projectId == projectId || t.projectId == null).toList();
  }

  /// Gets a tag by ID.
  Tag? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return Tag.fromJsonString(jsonStr);
  }

  /// Saves a tag.
  Future<void> save(Tag tag) async {
    try {
      await _box.put(tag.id, tag.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ الوسم',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a tag.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف الوسم',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Repository for managing notes.
class NotesRepository {
  /// Creates a notes repository.
  NotesRepository(this._box);

  final Box<String> _box;

  /// Gets all notes.
  List<Note> getAll() {
    return _box.values
        .map((e) => Note.fromJsonString(e))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Gets notes by request ID.
  List<Note> getByRequest(String requestId) {
    return getAll().where((n) => n.requestId == requestId).toList();
  }

  /// Gets notes by collection ID.
  List<Note> getByCollection(String collectionId) {
    return getAll().where((n) => n.collectionId == collectionId).toList();
  }

  /// Gets notes by project ID.
  List<Note> getByProject(String projectId) {
    return getAll().where((n) => n.projectId == projectId).toList();
  }

  /// Gets a note by ID.
  Note? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    return Note.fromJsonString(jsonStr);
  }

  /// Saves a note.
  Future<void> save(Note note) async {
    try {
      await _box.put(note.id, note.toJsonString());
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حفظ الملاحظة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a note.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      throw StorageError(
        message: 'فشل حذف الملاحظة',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

// Hive box names for new entities
const String workspacesBox = 'workspaces';
const String projectsBox = 'projects';
const String tagsBox = 'tags';
const String notesBox = 'notes';

/// Provider for WorkspaceRepository.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final box = Hive.box<String>(workspacesBox);
  return WorkspaceRepository(box);
});

/// Provider for ProjectRepository.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final box = Hive.box<String>(projectsBox);
  return ProjectRepository(box);
});

/// Provider for TagsRepository.
final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  final box = Hive.box<String>(tagsBox);
  return TagsRepository(box);
});

/// Provider for NotesRepository.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final box = Hive.box<String>(notesBox);
  return NotesRepository(box);
});
