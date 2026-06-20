// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileEntry _$FileEntryFromJson(Map<String, dynamic> json) => _FileEntry(
  name: json['name'] as String,
  path: json['path'] as String,
  isDirectory: json['isDirectory'] as bool,
  size: json['size'] == null ? null : BigInt.parse(json['size'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
);

Map<String, dynamic> _$FileEntryToJson(_FileEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'isDirectory': instance.isDirectory,
      'size': instance.size?.toString(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
    };
