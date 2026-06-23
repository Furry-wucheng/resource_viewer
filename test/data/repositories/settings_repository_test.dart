import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/repositories/settings_repository.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/app_config.dart';

void main() {
  group('SettingsRepository', () {
    late AppDatabase db;
    late SettingsRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = SettingsRepository(db);
    });

    tearDown(() => db.close());

    test('读取默认配置值', () async {
      final result = await repo.getConfig();
      final config = (result as Ok<AppConfig>).value;
      expect(config.themeMode, AppThemeMode.system);
      expect(config.pageDirection, PageDirection.rightToLeft);
      expect(config.doublePageMode, DoublePageMode.auto);
      expect(config.crossChapter, isTrue);
      expect(config.cacheLimitMB, 500);
      expect(config.autoSyncInterval, AutoSyncInterval.off);
    });

    test('更新主题模式', () async {
      final result = await repo.updateThemeMode(AppThemeMode.dark);
      final config = (result as Ok<AppConfig>).value;
      expect(config.themeMode, AppThemeMode.dark);
    });

    test('更新翻页方向', () async {
      final result = await repo.updatePageDirection(PageDirection.leftToRight);
      final config = (result as Ok<AppConfig>).value;
      expect(config.pageDirection, PageDirection.leftToRight);
    });

    test('更新双页显示模式', () async {
      final result = await repo.updateDoublePageMode(DoublePageMode.single);
      final config = (result as Ok<AppConfig>).value;
      expect(config.doublePageMode, DoublePageMode.single);
    });

    test('更新跨章节连续阅读', () async {
      final result = await repo.updateCrossChapter(false);
      final config = (result as Ok<AppConfig>).value;
      expect(config.crossChapter, isFalse);
    });

    test('更新缓存容量', () async {
      final result = await repo.updateCacheLimitMB(2000);
      final config = (result as Ok<AppConfig>).value;
      expect(config.cacheLimitMB, 2000);
    });

    test('恢复默认设置', () async {
      // 先修改多个设置
      await repo.updateThemeMode(AppThemeMode.dark);
      await repo.updatePageDirection(PageDirection.leftToRight);
      await repo.updateCacheLimitMB(2000);

      final result = await repo.resetDefaults();
      final config = (result as Ok<AppConfig>).value;
      expect(config.themeMode, AppThemeMode.system);
      expect(config.pageDirection, PageDirection.rightToLeft);
      expect(config.cacheLimitMB, 500);
    });

    test('监听配置变化', () async {
      // 修改后流应推送新值
      await repo.updateThemeMode(AppThemeMode.dark);

      final updated = await repo.watchConfig().first;
      expect(
        (updated as Ok<AppConfig>).value.themeMode,
        AppThemeMode.dark,
      );
    });

    test('AppConfig 缺失时兜底补建', () async {
      // 删除 appConfig 行
      await db.delete(db.appConfig).go();

      // 读取时自动补建
      final result = await repo.getConfig();
      final config = (result as Ok<AppConfig>).value;
      expect(config.themeMode, AppThemeMode.system);
      expect(config.cacheLimitMB, 500);
    });
  });
}
