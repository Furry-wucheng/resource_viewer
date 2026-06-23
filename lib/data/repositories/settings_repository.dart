import 'package:drift/drift.dart';

import '../models/enums.dart';
import '../services/database_service.dart';
import '../../domain/models/app_config.dart' as domain;
import '../../domain/core/result.dart';

/// 设置 Repository
///
/// 负责 drift AppConfigRow 到 domain AppConfig 的转换，错误包装为 Result
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// 获取应用配置单例；缺失时数据库兜底补建
  Future<Result<domain.AppConfig>> getConfig() async {
    try {
      final row = await _db.getAppConfig();
      return Ok(_toDomain(row));
    } catch (e) {
      return Err(DatabaseError('读取应用设置失败', cause: e));
    }
  }

  /// 监听应用配置变化
  Stream<Result<domain.AppConfig>> watchConfig() async* {
    try {
      await for (final row in _db.watchAppConfig()) {
        yield Ok(_toDomain(row));
      }
    } catch (error) {
      yield Err(DatabaseError('监听应用设置失败', cause: error));
    }
  }

  /// 更新主题模式
  Future<Result<domain.AppConfig>> updateThemeMode(
    domain.AppThemeMode mode,
  ) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          themeMode: Value(_toDriftThemeMode(mode)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新主题设置失败', cause: e));
    }
  }

  /// 更新默认翻页方向
  Future<Result<domain.AppConfig>> updatePageDirection(
    domain.PageDirection direction,
  ) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          pageDirection: Value(_toDriftPageDirection(direction)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新翻页方向设置失败', cause: e));
    }
  }

  /// 更新默认双页显示模式
  Future<Result<domain.AppConfig>> updateDoublePageMode(
    domain.DoublePageMode mode,
  ) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          doublePageMode: Value(_toDriftDoublePageMode(mode)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新双页显示设置失败', cause: e));
    }
  }

  /// 更新跨章节连续阅读
  Future<Result<domain.AppConfig>> updateCrossChapter(bool enabled) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          crossChapter: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新跨章节设置失败', cause: e));
    }
  }

  /// 更新缓存容量上限（MB）
  Future<Result<domain.AppConfig>> updateCacheLimitMB(int limitMB) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          cacheLimitMB: Value(limitMB),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新缓存容量设置失败', cause: e));
    }
  }

  /// 更新缩略图加载并发数
  Future<Result<domain.AppConfig>> updateThumbnailConcurrency(int n) async {
    try {
      await _db.updateAppConfig(
        AppConfigCompanion(
          id: const Value(1),
          thumbnailConcurrency: Value(n),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('更新并发数设置失败', cause: e));
    }
  }

  /// 恢复默认设置
  Future<Result<domain.AppConfig>> resetDefaults() async {
    try {
      await _db.resetAppConfig();
      return getConfig();
    } catch (e) {
      return Err(DatabaseError('恢复默认设置失败', cause: e));
    }
  }

  // ============================================================================
  // 转换方法
  // ============================================================================

  /// drift AppConfigRow → domain AppConfig
  domain.AppConfig _toDomain(AppConfigRow row) {
    return domain.AppConfig(
      id: row.id,
      themeMode: _toDomainThemeMode(row.themeMode),
      pageDirection: _toDomainPageDirection(row.pageDirection),
      doublePageMode: _toDomainDoublePageMode(row.doublePageMode),
      crossChapter: row.crossChapter,
      cacheLimitMB: row.cacheLimitMB,
      thumbnailConcurrency: row.thumbnailConcurrency,
      autoSyncInterval: _toDomainAutoSyncInterval(row.autoSyncInterval),
      updatedAt: row.updatedAt,
    );
  }

  domain.AppThemeMode _toDomainThemeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => domain.AppThemeMode.system,
    AppThemeMode.light => domain.AppThemeMode.light,
    AppThemeMode.dark => domain.AppThemeMode.dark,
  };

  domain.PageDirection _toDomainPageDirection(PageDirection dir) =>
      switch (dir) {
        PageDirection.rightToLeft => domain.PageDirection.rightToLeft,
        PageDirection.leftToRight => domain.PageDirection.leftToRight,
        PageDirection.vertical => domain.PageDirection.vertical,
      };

  domain.DoublePageMode _toDomainDoublePageMode(DoublePageMode mode) =>
      switch (mode) {
        DoublePageMode.auto => domain.DoublePageMode.auto,
        DoublePageMode.single => domain.DoublePageMode.single,
        DoublePageMode.double => domain.DoublePageMode.double,
      };

  domain.AutoSyncInterval _toDomainAutoSyncInterval(AutoSyncInterval interval) =>
      switch (interval) {
        AutoSyncInterval.off => domain.AutoSyncInterval.off,
        AutoSyncInterval.minutes15 => domain.AutoSyncInterval.minutes15,
        AutoSyncInterval.minutes30 => domain.AutoSyncInterval.minutes30,
        AutoSyncInterval.hour1 => domain.AutoSyncInterval.hour1,
      };

  AppThemeMode _toDriftThemeMode(domain.AppThemeMode mode) => switch (mode) {
    domain.AppThemeMode.system => AppThemeMode.system,
    domain.AppThemeMode.light => AppThemeMode.light,
    domain.AppThemeMode.dark => AppThemeMode.dark,
  };

  PageDirection _toDriftPageDirection(domain.PageDirection dir) =>
      switch (dir) {
        domain.PageDirection.rightToLeft => PageDirection.rightToLeft,
        domain.PageDirection.leftToRight => PageDirection.leftToRight,
        domain.PageDirection.vertical => PageDirection.vertical,
      };

  DoublePageMode _toDriftDoublePageMode(domain.DoublePageMode mode) =>
      switch (mode) {
        domain.DoublePageMode.auto => DoublePageMode.auto,
        domain.DoublePageMode.single => DoublePageMode.single,
        domain.DoublePageMode.double => DoublePageMode.double,
      };
}
