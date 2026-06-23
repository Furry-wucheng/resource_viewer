import 'package:drift/drift.dart';

import 'enums.dart';

/// 应用级设置单例表；唯一合法记录的 id 为 1。
@DataClassName('AppConfigRow')
class AppConfig extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get themeMode => textEnum<AppThemeMode>().withDefault(
    Constant(AppThemeMode.system.name),
  )();

  TextColumn get pageDirection => textEnum<PageDirection>().withDefault(
    Constant(PageDirection.rightToLeft.name),
  )();

  TextColumn get doublePageMode => textEnum<DoublePageMode>().withDefault(
    Constant(DoublePageMode.auto.name),
  )();

  BoolColumn get crossChapter => boolean().withDefault(const Constant(true))();

  IntColumn get cacheLimitMB => integer().withDefault(const Constant(500))();

  IntColumn get thumbnailConcurrency => integer().withDefault(const Constant(4))();

  TextColumn get autoSyncInterval => textEnum<AutoSyncInterval>().withDefault(
    Constant(AutoSyncInterval.off.name),
  )();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
