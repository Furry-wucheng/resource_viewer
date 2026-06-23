import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/sources.dart';
import '../models/resources.dart';
import '../models/tags.dart';
import '../models/resource_tags.dart';
import '../models/app_config.dart';
import '../models/enums.dart';
import '../../domain/models/resource_query.dart';

part 'database_service.g.dart';

@DriftDatabase(tables: [Sources, Resources, Tags, ResourceTags, AppConfig])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造函数，允许注入自定义 QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedBuiltInTags();
      await _seedAppConfig();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(appConfig, appConfig.thumbnailConcurrency);
      }
    },
    beforeOpen: (details) async {
      // 每连接必须执行的 PRAGMA（SQLite 默认关闭 foreign_keys）
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = NORMAL;');

      // 补建内置标签（对升级用户兜底，idempotent）
      await _ensureBuiltInTags();
      await _ensureAppConfig();
    },
  );

  /// 播种内置标签（首次安装）
  Future<void> _seedBuiltInTags() async {
    await into(tags).insert(
      TagsCompanion.insert(
        id: '00000000-0000-0000-0000-000000000001',
        name: '收藏',
        color: '#FFC107',
        isBuiltIn: const Value(true),
      ),
    );
  }

  /// 补建内置标签（idempotent，对升级用户兜底）
  Future<void> _ensureBuiltInTags() async {
    final count = await (select(
      tags,
    )..where((t) => t.isBuiltIn.equals(true))).get();
    if (count.isEmpty) {
      await _seedBuiltInTags();
    }
  }

  Future<void> _seedAppConfig() => into(appConfig).insert(
    const AppConfigCompanion(id: Value(1)),
    mode: InsertMode.insertOrIgnore,
  );

  Future<void> _ensureAppConfig() => _seedAppConfig();

  // ===== AppConfig DAO =====

  /// 获取应用配置单例（id = 1）；缺失时兜底补建并返回默认值
  Future<AppConfigRow> getAppConfig() async {
    final row = await (select(
      appConfig,
    )..where((c) => c.id.equals(1))).getSingleOrNull();
    if (row != null) return row;
    await _ensureAppConfig();
    return (select(appConfig)..where((c) => c.id.equals(1))).getSingle();
  }

  /// 监听应用配置变化
  Stream<AppConfigRow> watchAppConfig() =>
      (select(appConfig)..where((c) => c.id.equals(1))).watchSingle();

  /// 更新应用配置
  Future<void> updateAppConfig(AppConfigCompanion entry) =>
      update(appConfig).replace(entry);

  /// 恢复应用配置为默认值
  Future<void> resetAppConfig() async {
    await (update(appConfig)..where((c) => c.id.equals(1))).write(
      AppConfigCompanion(
        themeMode: const Value(AppThemeMode.system),
        pageDirection: const Value(PageDirection.rightToLeft),
        doublePageMode: const Value(DoublePageMode.auto),
        crossChapter: const Value(true),
        cacheLimitMB: const Value(500),
        thumbnailConcurrency: const Value(4),
        autoSyncInterval: const Value(AutoSyncInterval.off),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ===== Source DAO =====

  /// 获取所有数据源
  Future<List<Source>> getAllSources() => select(sources).get();

  /// 监听所有数据源变化
  Stream<List<Source>> watchAllSources() => select(sources).watch();

  /// 根据 ID 获取数据源
  Future<Source?> getSourceById(String id) =>
      (select(sources)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// 创建数据源
  Future<int> createSource(SourcesCompanion entry) =>
      into(sources).insert(entry);

  /// 更新数据源
  Future<bool> updateSource(SourcesCompanion entry) =>
      update(sources).replace(entry);

  /// 删除数据源（级联删除关联的 Resources 和 ResourceTags）
  Future<int> deleteSource(String id) =>
      (delete(sources)..where((s) => s.id.equals(id))).go();

  /// 标记数据源为不可达
  Future<void> markSourceUnavailable(String id) async {
    await (update(sources)..where((s) => s.id.equals(id))).write(
      SourcesCompanion(
        isAvailable: const Value(false),
        lastCheckAt: Value(DateTime.now()),
      ),
    );
  }

  /// 标记数据源为可达
  Future<void> markSourceAvailable(String id) async {
    await (update(sources)..where((s) => s.id.equals(id))).write(
      SourcesCompanion(
        isAvailable: const Value(true),
        lastCheckAt: Value(DateTime.now()),
      ),
    );
  }

  /// 标记数据源下的所有资源为不可达
  Future<void> markResourcesUnavailableBySource(String sourceId) async {
    await (update(resources)..where((r) => r.sourceId.equals(sourceId))).write(
      ResourcesCompanion(isAvailable: const Value(false)),
    );
  }

  /// 标记数据源下的所有资源为可达
  Future<void> markResourcesAvailableBySource(String sourceId) async {
    await (update(resources)..where((r) => r.sourceId.equals(sourceId))).write(
      ResourcesCompanion(isAvailable: const Value(true)),
    );
  }

  // ===== Resource DAO =====

  /// 获取所有资源
  Future<List<Resource>> getAllResources() => select(resources).get();

  /// 根据 ID 获取资源
  Future<Resource?> getResourceById(String id) =>
      (select(resources)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// 根据数据源 ID 获取资源列表
  Future<List<Resource>> getResourcesBySourceId(String sourceId) =>
      (select(resources)..where((r) => r.sourceId.equals(sourceId))).get();

  /// 按 sourceId + paths 批量查询资源（用于当前目录入库状态）
  Future<List<Resource>> getResourcesBySourceIdAndPaths(
    String sourceId,
    List<String> paths,
  ) async {
    if (paths.isEmpty) return [];
    final result = <Resource>[];
    // 分批查询避免 SQL 参数爆炸
    const chunkSize = 100;
    for (var start = 0; start < paths.length; start += chunkSize) {
      final end = min(start + chunkSize, paths.length);
      final chunk = paths.sublist(start, end);
      final query = select(
        resources,
      )..where((r) => r.sourceId.equals(sourceId) & r.relativePath.isIn(chunk));
      result.addAll(await query.get());
    }
    return result;
  }

  /// 创建资源
  Future<int> createResource(ResourcesCompanion entry) =>
      into(resources).insert(entry);

  /// 扫描去重 / Upsert（冲突时更新元数据）
  Future<void> upsertResource(ResourcesCompanion entry) =>
      into(resources).insertOnConflictUpdate(entry);

  /// 更新资源
  Future<bool> updateResource(ResourcesCompanion entry) =>
      update(resources).replace(entry);

  /// 删除资源（级联删除关联的 ResourceTags）
  Future<int> deleteResource(String id) =>
      (delete(resources)..where((r) => r.id.equals(id))).go();

  /// 键集分页查询资源
  Future<List<Resource>> pageResources({
    required String? lastCreatedAt,
    required String? lastId,
    required int pageSize,
  }) {
    final query = select(resources)
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(pageSize);

    if (lastCreatedAt != null && lastId != null) {
      final cursorDt = DateTime.parse(lastCreatedAt);
      query.where(
        (r) =>
            r.createdAt.isSmallerThanValue(cursorDt) |
            (r.createdAt.equals(cursorDt) & r.id.isBiggerThanValue(lastId)),
      );
    }
    return query.get();
  }

  /// 获取可用资源（仅 enabled + isAvailable 的源下的资源）
  Future<List<Resource>> getAvailableResources({
    required String? lastCreatedAt,
    required String? lastId,
    required int pageSize,
  }) async {
    // 先获取可用的源 ID
    final availableSourceIds =
        await (selectOnly(sources)
              ..addColumns([sources.id])
              ..where(
                sources.enabled.equals(true) & sources.isAvailable.equals(true),
              ))
            .map((row) => row.read(sources.id)!)
            .get();

    if (availableSourceIds.isEmpty) return [];

    final query = select(resources)
      ..where(
        (r) => r.sourceId.isIn(availableSourceIds) & r.isAvailable.equals(true),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(pageSize);

    if (lastCreatedAt != null && lastId != null) {
      final cursorDt = DateTime.parse(lastCreatedAt);
      query.where(
        (r) =>
            r.createdAt.isSmallerThanValue(cursorDt) |
            (r.createdAt.equals(cursorDt) & r.id.isBiggerThanValue(lastId)),
      );
    }
    return query.get();
  }

  /// 监听可用资源变化（仅 enabled + isAvailable 的源下的资源）
  Stream<List<Resource>> watchAvailableResources() {
    // 使用 join 查询，监听 sources 和 resources 两个表的变化
    final query =
        select(
            resources,
          ).join([innerJoin(sources, sources.id.equalsExp(resources.sourceId))])
          ..where(
            sources.enabled.equals(true) &
                sources.isAvailable.equals(true) &
                resources.isAvailable.equals(true),
          )
          ..orderBy([
            OrderingTerm.desc(resources.createdAt),
            OrderingTerm.asc(resources.id),
          ]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(resources)).toList(),
    );
  }

  /// 按标签筛选资源（交集筛选）
  ///
  /// 使用 GROUP BY HAVING COUNT(*) = N 替代 INTERSECT
  Future<List<Resource>> filterByTags(List<String> tagIds) {
    if (tagIds.isEmpty) return select(resources).get();

    final ids = tagIds.toSet().toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    return customSelect(
      '''
        SELECT r.*
        FROM resources AS r
        INNER JOIN resource_tags AS rt ON rt.resource_id = r.id
        WHERE rt.tag_id IN ($placeholders)
        GROUP BY r.id
        HAVING COUNT(DISTINCT rt.tag_id) = ?
      ''',
      variables: [
        ...ids.map(Variable.withString),
        Variable.withInt(ids.length),
      ],
      readsFrom: {resources, resourceTags},
    ).map((row) => resources.map(row.data)).get();
  }

  /// 统计筛选结果数量
  Future<int> countFiltered(List<String> tagIds) async {
    if (tagIds.isEmpty) {
      return (selectOnly(
        resources,
      )..addColumns([countAll()])).map((r) => r.read(countAll())!).getSingle();
    }

    final ids = tagIds.toSet().toList();

    final placeholders = List.filled(ids.length, '?').join(', ');
    final row = await customSelect(
      '''
        SELECT COUNT(*) AS result
        FROM (
          SELECT rt.resource_id
          FROM resource_tags AS rt
          WHERE rt.tag_id IN ($placeholders)
          GROUP BY rt.resource_id
          HAVING COUNT(DISTINCT rt.tag_id) = ?
        )
      ''',
      variables: [
        ...ids.map(Variable.withString),
        Variable.withInt(ids.length),
      ],
      readsFrom: {resourceTags},
    ).getSingle();
    return row.read<int>('result');
  }

  /// 构建筛选条件（可用源过滤 + 搜索 + 标签交集 + 收藏），供 query 和 count 共用
  ({List<String> conditions, List<Variable<Object>> variables})
  _buildFilterConditions({
    String? searchQuery,
    List<String>? tagIds,
    bool favoriteOnly = false,
  }) {
    final conditions = <String>[];
    final variables = <Variable<Object>>[];

    // 可用源过滤
    conditions.add('''
      r.source_id IN (
        SELECT s.id FROM sources AS s
        WHERE s.enabled = 1 AND s.is_available = 1
      )
      AND r.is_available = 1
    ''');

    // 搜索（LIKE 通配符 % 和 _ 需转义避免误匹配）
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add(r"r.name LIKE ? ESCAPE '\'");
      final escaped = searchQuery
          .trim()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      variables.add(Variable.withString('%$escaped%'));
    }

    // 收藏筛选
    if (favoriteOnly) {
      conditions.add('''
        r.id IN (
          SELECT rt.resource_id FROM resource_tags AS rt
          WHERE rt.tag_id = '00000000-0000-0000-0000-000000000001'
        )
      ''');
    }

    // 标签交集筛选
    final effectiveTagIds = tagIds ?? <String>[];
    if (effectiveTagIds.isNotEmpty) {
      final placeholders = List.filled(effectiveTagIds.length, '?').join(', ');
      conditions.add('''
        r.id IN (
          SELECT rt.resource_id
          FROM resource_tags AS rt
          WHERE rt.tag_id IN ($placeholders)
          GROUP BY rt.resource_id
          HAVING COUNT(DISTINCT rt.tag_id) = ?
        )
      ''');
      variables.addAll(effectiveTagIds.map(Variable.withString));
      variables.add(Variable.withInt(effectiveTagIds.length));
    }

    return (conditions: conditions, variables: variables);
  }

  /// 统一资源查询（可用源过滤 + 搜索 + 标签交集 + 收藏 + 键集分页）
  ///
  /// 返回 limit+1 条以便判断 hasMore。
  Future<List<Resource>> queryResources({
    String? searchQuery,
    List<String>? tagIds,
    bool favoriteOnly = false,
    ResourceSort sort = ResourceSort.createdDesc,
    String? lastCreatedAt,
    String? lastName,
    String? lastId,
    int pageSize = 50,
  }) async {
    final (:conditions, :variables) = _buildFilterConditions(
      searchQuery: searchQuery,
      tagIds: tagIds,
      favoriteOnly: favoriteOnly,
    );

    // 键集分页
    if (lastCreatedAt != null && lastId != null) {
      final cursorDt = DateTime.parse(lastCreatedAt);
      switch (sort) {
        case ResourceSort.createdDesc:
          conditions.add(
            '(r.created_at < ? OR (r.created_at = ? AND r.id > ?))',
          );
          variables
            ..add(Variable.withDateTime(cursorDt))
            ..add(Variable.withDateTime(cursorDt))
            ..add(Variable.withString(lastId));
        case ResourceSort.createdAsc:
          conditions.add(
            '(r.created_at > ? OR (r.created_at = ? AND r.id > ?))',
          );
          variables
            ..add(Variable.withDateTime(cursorDt))
            ..add(Variable.withDateTime(cursorDt))
            ..add(Variable.withString(lastId));
        case ResourceSort.nameAsc:
        case ResourceSort.nameDesc:
          break;
      }
    } else if (lastName != null && lastId != null) {
      switch (sort) {
        case ResourceSort.nameAsc:
          conditions.add('(r.name > ? OR (r.name = ? AND r.id > ?))');
          variables
            ..add(Variable.withString(lastName))
            ..add(Variable.withString(lastName))
            ..add(Variable.withString(lastId));
        case ResourceSort.nameDesc:
          conditions.add('(r.name < ? OR (r.name = ? AND r.id > ?))');
          variables
            ..add(Variable.withString(lastName))
            ..add(Variable.withString(lastName))
            ..add(Variable.withString(lastId));
        case ResourceSort.createdDesc:
        case ResourceSort.createdAsc:
          break;
      }
    }

    final where = conditions.join(' AND ');
    final orderBy = switch (sort) {
      ResourceSort.createdDesc => 'r.created_at DESC, r.id ASC',
      ResourceSort.createdAsc => 'r.created_at ASC, r.id ASC',
      ResourceSort.nameAsc => 'r.name ASC, r.id ASC',
      ResourceSort.nameDesc => 'r.name DESC, r.id ASC',
    };
    final sql =
        '''
      SELECT r.* FROM resources AS r
      WHERE $where
      ORDER BY $orderBy
      LIMIT ${pageSize + 1}
    ''';

    return customSelect(
      sql,
      variables: variables,
      readsFrom: {resources},
    ).map((row) => resources.map(row.data)).get();
  }

  /// 统一计数查询（条件同上，无分页）
  Future<int> countQueryResources({
    String? searchQuery,
    List<String>? tagIds,
    bool favoriteOnly = false,
  }) async {
    final (:conditions, :variables) = _buildFilterConditions(
      searchQuery: searchQuery,
      tagIds: tagIds,
      favoriteOnly: favoriteOnly,
    );

    final where = conditions.join(' AND ');
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt FROM resources AS r WHERE $where',
      variables: variables,
      readsFrom: {resources},
    ).getSingle();
    return row.read<int>('cnt');
  }

  // ===== Tag DAO =====

  /// 获取所有标签
  Future<List<Tag>> getAllTags() => select(tags).get();

  /// 监听所有标签变化
  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  /// 根据 ID 获取标签
  Future<Tag?> getTagById(String id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 根据名称获取标签
  Future<Tag?> getTagByName(String name) =>
      (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  /// 创建标签
  Future<int> createTag(TagsCompanion entry) => into(tags).insert(entry);

  /// 更新标签
  Future<bool> updateTag(TagsCompanion entry) => update(tags).replace(entry);

  /// 删除标签（级联删除关联的 ResourceTags）
  Future<int> deleteTag(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  /// 获取每个标签关联的资源数量
  Future<Map<String, int>> tagResourceCounts() async {
    final rows =
        await (selectOnly(resourceTags)
              ..addColumns([resourceTags.tagId, countAll()])
              ..groupBy([resourceTags.tagId]))
            .get();
    return {
      for (final r in rows) r.read(resourceTags.tagId)!: r.read(countAll())!,
    };
  }

  // ===== ResourceTag DAO =====

  /// 为资源添加标签
  Future<void> addTagToResource(String resourceId, String tagId) async {
    await into(resourceTags).insert(
      ResourceTagsCompanion.insert(resourceId: resourceId, tagId: tagId),
    );
  }

  /// 移除资源的标签
  Future<void> removeTagFromResource(String resourceId, String tagId) async {
    await (delete(resourceTags)..where(
          (rt) => rt.resourceId.equals(resourceId) & rt.tagId.equals(tagId),
        ))
        .go();
  }

  /// 获取资源的所有标签
  Future<List<Tag>> getTagsForResource(String resourceId) async {
    final query = select(tags).join([
      innerJoin(
        resourceTags,
        resourceTags.tagId.equalsExp(tags.id),
        useColumns: false,
      ),
    ])..where(resourceTags.resourceId.equals(resourceId));
    return query.map((row) => row.readTable(tags)).get();
  }

  /// 批量获取多个资源的标签
  Future<Map<String, List<Tag>>> getTagsForResources(
    List<String> resourceIds,
  ) async {
    if (resourceIds.isEmpty) return {};

    final result = <String, List<Tag>>{
      for (final resourceId in resourceIds) resourceId: [],
    };
    final uniqueIds = resourceIds.toSet().toList();
    const chunkSize = 500;

    for (var start = 0; start < uniqueIds.length; start += chunkSize) {
      final end = start + chunkSize > uniqueIds.length
          ? uniqueIds.length
          : start + chunkSize;
      final query = select(tags).join([
        innerJoin(resourceTags, resourceTags.tagId.equalsExp(tags.id)),
      ])..where(resourceTags.resourceId.isIn(uniqueIds.sublist(start, end)));

      final rows = await query.get();
      for (final row in rows) {
        final relation = row.readTable(resourceTags);
        result
            .putIfAbsent(relation.resourceId, () => [])
            .add(row.readTable(tags));
      }
    }
    return result;
  }

  /// 获取标签下的所有资源
  Future<List<Resource>> getResourcesForTag(String tagId) async {
    final query = select(resources).join([
      innerJoin(
        resourceTags,
        resourceTags.resourceId.equalsExp(resources.id),
        useColumns: false,
      ),
    ])..where(resourceTags.tagId.equals(tagId));
    return query.map((row) => row.readTable(resources)).get();
  }

  /// 批量为资源设置标签（先删后增）
  Future<void> setTagsForResource(
    String resourceId,
    List<String> tagIds,
  ) async {
    await transaction(() async {
      await (delete(
        resourceTags,
      )..where((rt) => rt.resourceId.equals(resourceId))).go();
      for (final tagId in tagIds.toSet()) {
        await addTagToResource(resourceId, tagId);
      }
    });
  }

  /// 原子创建资源并绑定初始标签。
  Future<void> createResourceWithTags(
    ResourcesCompanion resource,
    List<String> tagIds,
  ) async {
    await transaction(() async {
      await createResource(resource);
      final resourceId = resource.id.value;
      for (final tagId in tagIds.toSet()) {
        await addTagToResource(resourceId, tagId);
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'resource_viewer.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('PRAGMA synchronous = NORMAL;');
      },
      readPool: 3,
    );
  });
}
