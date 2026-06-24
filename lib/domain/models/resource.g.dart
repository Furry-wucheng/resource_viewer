// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Resource _$ResourceFromJson(Map<String, dynamic> json) => _Resource(
  id: json['id'] as String,
  sourceId: json['sourceId'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ResourceTypeEnumMap, json['type']),
  organizationMode: $enumDecodeNullable(
    _$OrganizationModeEnumMap,
    json['organizationMode'],
  ),
  relativePath: json['relativePath'] as String,
  thumbnailPath: json['thumbnailPath'] as String?,
  fileCount: (json['fileCount'] as num?)?.toInt(),
  fileSize: json['fileSize'] == null
      ? null
      : BigInt.parse(json['fileSize'] as String),
  isAvailable: json['isAvailable'] as bool? ?? true,
  lastScannedAt: json['lastScannedAt'] == null
      ? null
      : DateTime.parse(json['lastScannedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ResourceToJson(_Resource instance) => <String, dynamic>{
  'id': instance.id,
  'sourceId': instance.sourceId,
  'name': instance.name,
  'type': _$ResourceTypeEnumMap[instance.type]!,
  'organizationMode': _$OrganizationModeEnumMap[instance.organizationMode],
  'relativePath': instance.relativePath,
  'thumbnailPath': instance.thumbnailPath,
  'fileCount': instance.fileCount,
  'fileSize': instance.fileSize?.toString(),
  'isAvailable': instance.isAvailable,
  'lastScannedAt': instance.lastScannedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$ResourceTypeEnumMap = {
  ResourceType.folder: 'folder',
  ResourceType.pdf: 'pdf',
  ResourceType.archive: 'archive',
  ResourceType.video: 'video',
};

const _$OrganizationModeEnumMap = {
  OrganizationMode.direct: 'direct',
  OrganizationMode.chapter: 'chapter',
  OrganizationMode.chapterGallery: 'chapterGallery',
  OrganizationMode.flatgrid: 'flatgrid',
  OrganizationMode.gallery: 'gallery',
};
