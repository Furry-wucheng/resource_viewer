// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  id: (json['id'] as num?)?.toInt() ?? 1,
  themeMode:
      $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
      AppThemeMode.system,
  pageDirection:
      $enumDecodeNullable(_$PageDirectionEnumMap, json['pageDirection']) ??
      PageDirection.rightToLeft,
  doublePageMode:
      $enumDecodeNullable(_$DoublePageModeEnumMap, json['doublePageMode']) ??
      DoublePageMode.auto,
  crossChapter: json['crossChapter'] as bool? ?? true,
  cacheLimitMB: (json['cacheLimitMB'] as num?)?.toInt() ?? 500,
  thumbnailConcurrency: (json['thumbnailConcurrency'] as num?)?.toInt() ?? 4,
  autoSyncInterval:
      $enumDecodeNullable(
        _$AutoSyncIntervalEnumMap,
        json['autoSyncInterval'],
      ) ??
      AutoSyncInterval.off,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'pageDirection': _$PageDirectionEnumMap[instance.pageDirection]!,
      'doublePageMode': _$DoublePageModeEnumMap[instance.doublePageMode]!,
      'crossChapter': instance.crossChapter,
      'cacheLimitMB': instance.cacheLimitMB,
      'thumbnailConcurrency': instance.thumbnailConcurrency,
      'autoSyncInterval': _$AutoSyncIntervalEnumMap[instance.autoSyncInterval]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$PageDirectionEnumMap = {
  PageDirection.rightToLeft: 'rightToLeft',
  PageDirection.leftToRight: 'leftToRight',
  PageDirection.vertical: 'vertical',
};

const _$DoublePageModeEnumMap = {
  DoublePageMode.auto: 'auto',
  DoublePageMode.single: 'single',
  DoublePageMode.double: 'double',
};

const _$AutoSyncIntervalEnumMap = {
  AutoSyncInterval.off: 'off',
  AutoSyncInterval.minutes15: 'minutes15',
  AutoSyncInterval.minutes30: 'minutes30',
  AutoSyncInterval.hour1: 'hour1',
};
