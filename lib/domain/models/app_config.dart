import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

enum AppThemeMode { system, light, dark }

enum PageDirection { rightToLeft, leftToRight, vertical }

enum DoublePageMode { auto, single, double }

enum AutoSyncInterval { off, minutes15, minutes30, hour1 }

@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    @Default(1) int id,
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(PageDirection.rightToLeft) PageDirection pageDirection,
    @Default(DoublePageMode.auto) DoublePageMode doublePageMode,
    @Default(true) bool crossChapter,
    @Default(500) int cacheLimitMB,
    @Default(AutoSyncInterval.off) AutoSyncInterval autoSyncInterval,
    required DateTime updatedAt,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
