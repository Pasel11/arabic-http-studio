import '../../request/models/http_request.dart';

/// Represents a collection/folder imported from external sources.
class CollectionFolder {
  /// Creates a collection folder.
  CollectionFolder({
    required this.id,
    required this.name,
    this.description,
    this.requestIds = const [],
    this.parentId,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// IDs of requests in this collection.
  final List<String> requestIds;

  /// Parent folder ID (null for root).
  final String? parentId;
}

/// Result of an import operation.
class ImportResult {
  /// Creates an import result.
  ImportResult({
    required this.requests,
    this.collections = const [],
    this.environments = const [],
    this.variables = const [],
    this.source = '',
    this.title,
    this.errors = const [],
  });

  /// Imported requests.
  final List<HttpRequestModel> requests;

  /// Imported collections/folders.
  final List<CollectionFolder> collections;

  /// Imported environments.
  final List<dynamic> environments;

  /// Imported variables.
  final List<dynamic> variables;

  /// Source format (e.g., 'OpenAPI 3.0', 'Postman Collection v2.1').
  final String source;

  /// Title of the imported collection.
  final String? title;

  /// Errors encountered during import.
  final List<String> errors;

  /// Whether the import had errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Number of items imported.
  int get totalCount => requests.length + collections.length;
}
