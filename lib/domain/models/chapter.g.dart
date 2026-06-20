// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Chapter _$ChapterFromJson(Map<String, dynamic> json) => _Chapter(
  name: json['name'] as String,
  path: json['path'] as String,
  coverPath: json['coverPath'] as String?,
  pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
  isDisabled: json['isDisabled'] as bool? ?? false,
);

Map<String, dynamic> _$ChapterToJson(_Chapter instance) => <String, dynamic>{
  'name': instance.name,
  'path': instance.path,
  'coverPath': instance.coverPath,
  'pageCount': instance.pageCount,
  'isDisabled': instance.isDisabled,
};
