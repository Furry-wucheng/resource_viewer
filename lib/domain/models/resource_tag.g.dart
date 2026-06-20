// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResourceTag _$ResourceTagFromJson(Map<String, dynamic> json) => _ResourceTag(
  resourceId: json['resourceId'] as String,
  tagId: json['tagId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ResourceTagToJson(_ResourceTag instance) =>
    <String, dynamic>{
      'resourceId': instance.resourceId,
      'tagId': instance.tagId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
