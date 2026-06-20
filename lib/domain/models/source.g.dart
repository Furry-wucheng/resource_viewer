// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Source _$SourceFromJson(Map<String, dynamic> json) => _Source(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$SourceTypeEnumMap, json['type']),
  rootPath: json['rootPath'] as String,
  host: json['host'] as String?,
  port: (json['port'] as num?)?.toInt(),
  username: json['username'] as String?,
  passwordStored: json['passwordStored'] as bool? ?? false,
  domain: json['domain'] as String?,
  enabled: json['enabled'] as bool? ?? true,
  isAvailable: json['isAvailable'] as bool? ?? false,
  lastCheckAt: json['lastCheckAt'] == null
      ? null
      : DateTime.parse(json['lastCheckAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SourceToJson(_Source instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$SourceTypeEnumMap[instance.type]!,
  'rootPath': instance.rootPath,
  'host': instance.host,
  'port': instance.port,
  'username': instance.username,
  'passwordStored': instance.passwordStored,
  'domain': instance.domain,
  'enabled': instance.enabled,
  'isAvailable': instance.isAvailable,
  'lastCheckAt': instance.lastCheckAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$SourceTypeEnumMap = {
  SourceType.local: 'local',
  SourceType.smb: 'smb',
  SourceType.ftp: 'ftp',
  SourceType.webdav: 'webdav',
};
