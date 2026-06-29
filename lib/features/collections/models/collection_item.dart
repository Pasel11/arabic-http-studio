import 'dart:convert';

/// Collection or folder item
class CollectionItem {
  final String id;
  String name;
  String? description;
  List<String> requestIds;
  List<String> folderIds;
  String? parentId;
  List<String> tags;
  bool isFolder;
  DateTime createdAt;
  DateTime updatedAt;
  String? color;
  String? icon;

  CollectionItem({
    required this.id,
    required this.name,
    this.description,
    List<String>? requestIds,
    List<String>? folderIds,
    this.parentId,
    List<String>? tags,
    this.isFolder = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.color,
    this.icon,
  })  : requestIds = requestIds ?? [],
        folderIds = folderIds ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requestIds': requestIds,
        'folderIds': folderIds,
        'parentId': parentId,
        'tags': tags,
        'isFolder': isFolder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'color': color,
        'icon': icon,
      };

  String toJsonString() => jsonEncode(toJson());

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      requestIds: (json['requestIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      folderIds: (json['folderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      parentId: json['parentId'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isFolder: json['isFolder'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }

  factory CollectionItem.fromJsonString(String jsonString) {
    return CollectionItem.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
