import 'dart:convert';

/// Favorite item model
class FavoriteItem {
  final String id;
  final String requestId;
  final String name;
  final String method;
  final String url;
  final DateTime addedAt;
  final String? collectionId;
  final List<String> tags;
  final String? description;
  final bool isPinned;

  FavoriteItem({
    required this.id,
    required this.requestId,
    required this.name,
    required this.method,
    required this.url,
    required this.addedAt,
    this.collectionId,
    this.tags = const [],
    this.description,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'name': name,
        'method': method,
        'url': url,
        'addedAt': addedAt.toIso8601String(),
        'collectionId': collectionId,
        'tags': tags,
        'description': description,
        'isPinned': isPinned,
      };

  String toJsonString() => jsonEncode(toJson());

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      name: json['name'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      collectionId: json['collectionId'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  factory FavoriteItem.fromJsonString(String jsonString) {
    return FavoriteItem.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  FavoriteItem copyWith({
    String? id,
    String? requestId,
    String? name,
    String? method,
    String? url,
    DateTime? addedAt,
    String? collectionId,
    List<String>? tags,
    String? description,
    bool? isPinned,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      addedAt: addedAt ?? this.addedAt,
      collectionId: collectionId ?? this.collectionId,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
