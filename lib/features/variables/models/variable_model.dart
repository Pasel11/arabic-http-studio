import 'dart:convert';

/// Variable model
class VariableModel {
  final String id;
  String key;
  String value;
  String type;
  String? description;
  bool isGlobal;
  bool isEncrypted;
  bool isDynamic;
  String? dynamicType;
  String? environmentId;
  DateTime createdAt;
  DateTime updatedAt;

  VariableModel({
    required this.id,
    required this.key,
    required this.value,
    this.type = 'string',
    this.description,
    this.isGlobal = false,
    this.isEncrypted = false,
    this.isDynamic = false,
    this.dynamicType,
    this.environmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'type': type,
        'description': description,
        'isGlobal': isGlobal,
        'isEncrypted': isEncrypted,
        'isDynamic': isDynamic,
        'dynamicType': dynamicType,
        'environmentId': environmentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory VariableModel.fromJson(Map<String, dynamic> json) {
    return VariableModel(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      type: json['type'] as String? ?? 'string',
      description: json['description'] as String?,
      isGlobal: json['isGlobal'] as bool? ?? false,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      isDynamic: json['isDynamic'] as bool? ?? false,
      dynamicType: json['dynamicType'] as String?,
      environmentId: json['environmentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory VariableModel.fromJsonString(String jsonString) {
    return VariableModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
