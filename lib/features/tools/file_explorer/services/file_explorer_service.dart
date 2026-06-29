import 'dart:io';
import 'package:path/path.dart' as p;

/// Model representing a file in the file explorer.
class FileItem {
  /// Creates a file item.
  FileItem({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    required this.modified,
    this.isPinned = false,
    this.isRecent = false,
  });

  /// Full path to the file.
  final String path;

  /// File name.
  final String name;

  /// File type (file or directory).
  final FileItemType type;

  /// Size in bytes (0 for directories).
  final int size;

  /// Last modified date.
  final DateTime modified;

  /// Whether this file is pinned.
  final bool isPinned;

  /// Whether this file is recent.
  final bool isRecent;

  /// File extension.
  String get extension {
    if (type == FileItemType.directory) return '';
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Whether this is an image file.
  bool get isImage {
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(extension);
  }

  /// Whether this is a JSON file.
  bool get isJson => extension == 'json';

  /// Whether this is a text file.
  bool get isText {
    return ['txt', 'md', 'json', 'xml', 'yaml', 'yml', 'csv', 'html', 'css', 'js', 'ts', 'dart'].contains(extension);
  }
}

/// Types of file items.
enum FileItemType {
  file,
  directory,
}

/// Service for managing files in the file explorer.
///
/// Provides functionality for:
/// - Listing files in directories
/// - File operations (create, delete, rename, duplicate)
/// - File preview
/// - Import/Export
/// - Recent and pinned files tracking
class FileExplorerService {
  FileExplorerService._();
  static final FileExplorerService instance = FileExplorerService._();

  final List<String> _recentFiles = [];
  final Set<String> _pinnedFiles = {};

  /// Lists files in the specified directory.
  Future<List<FileItem>> listDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return [];
    }

    final items = <FileItem>[];
    final entities = await directory.list().toList();

    for (final entity in entities) {
      final name = p.basename(entity.path);
      final stat = await entity.stat();

      items.add(FileItem(
        path: entity.path,
        name: name,
        type: entity is Directory ? FileItemType.directory : FileItemType.file,
        size: stat.size,
        modified: stat.modified,
        isPinned: _pinnedFiles.contains(entity.path),
        isRecent: _recentFiles.contains(entity.path),
      ));
    }

    // Sort: directories first, then by name
    items.sort((a, b) {
      if (a.type != b.type) {
        return a.type == FileItemType.directory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  /// Reads a file's content as string.
  Future<String> readFile(String path) async {
    final file = File(path);
    return file.readAsString();
  }

  /// Reads a file's content as bytes.
  Future<List<int>> readFileBytes(String path) async {
    final file = File(path);
    return file.readAsBytes();
  }

  /// Writes content to a file.
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    _addToRecent(path);
  }

  /// Creates a new directory.
  Future<void> createDirectory(String path) async {
    final directory = Directory(path);
    await directory.create(recursive: true);
  }

  /// Deletes a file or directory.
  Future<void> delete(String path) async {
    final file = File(path);
    final dir = Directory(path);

    if (await file.exists()) {
      await file.delete();
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    _recentFiles.remove(path);
    _pinnedFiles.remove(path);
  }

  /// Renames a file or directory.
  Future<String> rename(String oldPath, String newName) async {
    final file = File(oldPath);
    final dir = Directory(oldPath);

    String newPath;
    if (await file.exists()) {
      newPath = p.join(p.dirname(oldPath), newName);
      await file.rename(newPath);
    } else if (await dir.exists()) {
      newPath = p.join(p.dirname(oldPath), newName);
      await dir.rename(newPath);
    } else {
      throw FileSystemException('الملف غير موجود', oldPath);
    }

    return newPath;
  }

  /// Duplicates a file.
  Future<String> duplicate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('الملف غير موجود', path);
    }

    final dir = p.dirname(path);
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    final newPath = p.join(dir, '$name_copy$ext');

    await file.copy(newPath);
    return newPath;
  }

  /// Pins a file.
  void pinFile(String path) {
    _pinnedFiles.add(path);
  }

  /// Unpins a file.
  void unpinFile(String path) {
    _pinnedFiles.remove(path);
  }

  /// Whether a file is pinned.
  bool isPinned(String path) => _pinnedFiles.contains(path);

  /// Gets all pinned files.
  List<String> get pinnedFiles => _pinnedFiles.toList();

  /// Adds a file to recent files.
  void _addToRecent(String path) {
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    // Keep only last 20 recent files
    if (_recentFiles.length > 20) {
      _recentFiles.removeRange(20, _recentFiles.length);
    }
  }

  /// Gets all recent files.
  List<String> get recentFiles => List.unmodifiable(_recentFiles);

  /// Gets the default working directory.
  Future<String> getDefaultDirectory() async {
    // This would use path_provider in a real app
    return Directory.current.path;
  }

  /// Gets the file size as a human-readable string.
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
