import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/models/enums.dart';
import 'package:resource_viewer/data/services/database_service.dart';

void main() {
  test('启用 foreign_keys 并创建资源复合索引', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(pragma.read<int>('foreign_keys'), 1);

    final indexes = await db
        .customSelect("PRAGMA index_list('resources')")
        .map((row) => row.read<String>('name'))
        .get();
    expect(indexes, contains('idx_resources_created_at_id'));
    expect(indexes, contains('idx_resources_name_id'));
  });

  test('首次创建时写入 AppConfig 默认值', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final config = await db.select(db.appConfig).getSingle();
    expect(config.id, 1);
    expect(config.themeMode, AppThemeMode.system);
    expect(config.pageDirection, PageDirection.rightToLeft);
    expect(config.doublePageMode, DoublePageMode.auto);
    expect(config.crossChapter, isTrue);
    expect(config.cacheLimitMB, 500);
    expect(config.autoSyncInterval, AutoSyncInterval.off);
  });

  test('重开数据库时补建被删除的内置标签和 AppConfig', () async {
    final directory = await Directory.systemTemp.createTemp('resource_viewer_');
    final file = File('${directory.path}${Platform.pathSeparator}test.sqlite');
    addTearDown(() => directory.delete(recursive: true));

    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.delete(db.tags).go();
    await db.delete(db.appConfig).go();
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    final tags = await db.select(db.tags).get();
    final configs = await db.select(db.appConfig).get();
    expect(tags.single.id, '00000000-0000-0000-0000-000000000001');
    expect(configs.single.id, 1);
    await db.close();
  });
}
