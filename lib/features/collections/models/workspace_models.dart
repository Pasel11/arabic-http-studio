import 'dart:convert';

/// Represents a workspace that contains multiple projects.
///
/// A workspace is the top-level organizational unit in the application.
/// It can contain multiple projects, each with their own collections,
/// environments, and requests.
///
/// Example:
/// ```dart
/// final workspace = Workspace(
///   id: 'ws-1',
///   name: 'My Workspace',
///   description: 'Personal API testing workspace',
/// );
/// ```
class Workspace {
  /// Creates a workspace.
  Workspace({
    required this.id,
    required this.name,
    this.description,
    List<String>? projectIds,
    this.color,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = false,
  })  : projectIds = projectIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for the workspace.
  final String id;

  /// Display name of the workspace.
  final String name;

  /// Optional description of the workspace.
  final String? description;

  /// IDs of projects belonging to this workspace.
  final List<String> projectIds;

  /// Custom color for the workspace (hex string).
  final String? color;

  /// Custom icon name for the workspace.
  final String? icon;

  /// When the workspace was created.
  final DateTime createdAt;

  /// When the workspace was last updated.
  final DateTime updatedAt;

  /// Whether this is the currently active workspace.
  final bool isActive;

  /// Converts the workspace to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'projectIds': projectIds,
        'color': color,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isActive': isActive,
      };

  /// Creates a workspace from a JSON map.
  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      projectIds: (json['projectIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from JSON string.
  factory Workspace.fromJsonString(String jsonString) {
    return Workspace.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Creates a copy with updated fields.
  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? projectIds,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectIds: projectIds ?? this.projectIds,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Represents a project within a workspace.
///
/// A project is a collection of API endpoints, environments,
/// and related resources for a specific API or service.
///
/// Example:
/// ```dart
/// final project = Project(
///   id: 'proj-1',
///   workspaceId: 'ws-1',
///   name: 'User API',
///   baseUrl: 'https://api.example.com',
/// );
/// ```
class Project {
  /// Creates a project.
  Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.baseUrl,
    List<String>? collectionIds,
    List<String>? environmentIds,
    List<String>? tagIds,
    this.color,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : collectionIds = collectionIds ?? [],
        environmentIds = environmentIds ?? [],
        tagIds = tagIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for the project.
  final String id;

  /// ID of the workspace this project belongs to.
  final String workspaceId;

  /// Display name of the project.
  final String name;

  /// Optional description of the project.
  final String? description;

  /// Base URL for all requests in this project.
  final String? baseUrl;

  /// IDs of collections in this project.
  final List<String> collectionIds;

  /// IDs of environments in this project.
  final List<String> environmentIds;

  /// IDs of tags in this project.
  final List<String> tagIds;

  /// Custom color for the project.
  final String? color;

  /// Custom icon name for the project.
  final String? icon;

  /// When the project was created.
  final DateTime createdAt;

  /// When the project was last updated.
  final DateTime updatedAt;

  /// Converts the project to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'name': name,
        'description': description,
        'baseUrl': baseUrl,
        'collectionIds': collectionIds,
        'environmentIds': environmentIds,
        'tagIds': tagIds,
        'color': color,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Creates a project from a JSON map.
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      baseUrl: json['baseUrl'] as String?,
      collectionIds: (json['collectionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      environmentIds: (json['environmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tagIds: (json['tagIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from JSON string.
  factory Project.fromJsonString(String jsonString) {
    return Project.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Creates a copy with updated fields.
  Project copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? description,
    String? baseUrl,
    List<String>? collectionIds,
    List<String>? environmentIds,
    List<String>? tagIds,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      baseUrl: baseUrl ?? this.baseUrl,
      collectionIds: collectionIds ?? this.collectionIds,
      environmentIds: environmentIds ?? this.environmentIds,
      tagIds: tagIds ?? this.tagIds,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Represents a tag for organizing requests.
class Tag {
  /// Creates a tag.
  Tag({
    required this.id,
    required this.name,
    this.color,
    this.description,
    this.projectId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Unique identifier for the tag.
  final String id;

  /// Display name of the tag.
  final String name;

  /// Color for the tag (hex string).
  final String? color;

  /// Optional description.
  final String? description;

  /// ID of the project this tag belongs to (null for global tags).
  final String? projectId;

  /// When the tag was created.
  final DateTime createdAt;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'description': description,
        'projectId': projectId,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Creates from JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      description: json['description'] as String?,
      projectId: json['projectId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from JSON string.
  factory Tag.fromJsonString(String jsonString) {
    return Tag.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

/// Represents a note attached to a request or collection.
class Note {
  /// Creates a note.
  Note({
    required this.id,
    required this.title,
    required this.content,
    this.requestId,
    this.collectionId,
    this.projectId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for the note.
  final String id;

  /// Title of the note.
  final String title;

  /// Content of the note (supports markdown).
  final String content;

  /// ID of the request this note is attached to.
  final String? requestId;

  /// ID of the collection this note is attached to.
  final String? collectionId;

  /// ID of the project this note belongs to.
  final String? projectId;

  /// Tags associated with the note.
  final List<String> tags;

  /// When the note was created.
  final DateTime createdAt;

  /// When the note was last updated.
  final DateTime updatedAt;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'requestId': requestId,
        'collectionId': collectionId,
        'projectId': projectId,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Creates from JSON map.
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      requestId: json['requestId'] as String?,
      collectionId: json['collectionId'] as String?,
      projectId: json['projectId'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serializes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from JSON string.
  factory Note.fromJsonString(String jsonString) {
    return Note.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
