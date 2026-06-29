import 'dart:convert';

/// Environment model
class EnvironmentModel {
  final String id;
  String name;
  String? description;
  Map<String, String> variables;
  Map<String, String> secrets;
  bool isActive;
  String? color;
  DateTime createdAt;
  DateTime updatedAt;

  EnvironmentModel({
    required this.id,
    required this.name,
    this.description,
    Map<String, String>? variables,
    Map<String, String>? secrets,
    this.isActive = false,
    this.color,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : variables = variables ?? {},
        secrets = secrets ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'variables': variables,
        'secrets': secrets,
        'isActive': isActive,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory EnvironmentModel.fromJson(Map<String, dynamic> json) {
    return EnvironmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      variables: Map<String, String>.from(json['variables'] as Map? ?? {}),
      secrets: Map<String, String>.from(json['secrets'] as Map? ?? {}),
      isActive: json['isActive'] as bool? ?? false,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory EnvironmentModel.fromJsonString(String jsonString) {
    return EnvironmentModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
