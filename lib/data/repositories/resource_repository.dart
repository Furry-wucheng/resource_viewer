import 'package:drift/drift.dart';

import '../services/database_service.dart';
import '../models/resources.dart' as drift;
import '../../domain/core/paged_result.dart';
import '../../domain/core/result.dart';
import '../../domain/models/resource.dart' as domain;
import '../../domain/models/resource_query.dart';

/// 资源 Repository
///
/// 负责 drift Resource 到 domain Resource 的转换，处理错误包装为 Result
class ResourceRepository {
  ResourceRepository(this._db);

  final AppDatabase _db;

  /// 获取所有资源
  Future<Result<List<domain.Resource>>> getAllResources() async {
    try {
      final rows = await _db.getAllResources();
      final resources = rows.map(_toDomain).toList();
      return Ok(resources);
    } catch (e) {
      return Err(DatabaseError('获取资源列表失败', cause: e));
    }
  }

  /// 根据 ID 获取资源
  Future<Result<domain.Resource?>> getResourceById(String id) async {
    try {
      final row = await _db.getResourceById(id);
      return Ok(row != null ? _toDomain(row) : null);
    } catch (e) {
      return Err(DatabaseError('获取资源失败', cause: e));
    }
  }

  /// 根据数据源 ID 获取资源列表
  Future<Result<List<domain.Resource>>> getResourcesBySourceId(
    String sourceId,
  ) async {
    try {
      final rows = await _db.getResourcesBySourceId(sourceId);
      final resources = rows.map(_toDomain).toList();
      return Ok(resources);
    } catch (e) {
      return Err(DatabaseError('获取数据源资源失败', cause: e));
    }
  }

  /// 按 sourceId + paths 批量查询资源（用于当前目录入库状态）
  Future<Result<List<domain.Resource>>> getResourcesBySourceIdAndPaths(
    String sourceId,
    List<String> paths,
  ) async {
    try {
      final rows = await _db.getResourcesBySourceIdAndPaths(sourceId, paths);
      return Ok(rows.map(_toDomain).toList());
    } catch (e) {
      return Err(DatabaseError('批量查询资源失败', cause: e));
    }
  }

  /// 监听可用资源变化（仅 enabled + isAvailable 的源下的资源）
  ///
  /// 返回 Stream，当资源或源状态变化时自动更新。
  Stream<Result<List<domain.Resource>>> watchAvailableResources() async* {
    try {
      await for (final rows in _db.watchAvailableResources()) {
        yield Ok(rows.map(_toDomain).toList());
      }
    } catch (error) {
      yield Err(DatabaseError('监听可用资源失败', cause: error));
    }
  }

  /// 创建资源
  Future<Result<domain.Resource>> createResource({
    required String id,
    required String sourceId,
    required String name,
    required domain.ResourceType type,
    required String relativePath,
    domain.OrganizationMode? organizationMode,
    String? thumbnailPath,
    int? fileCount,
    BigInt? fileSize,
  }) async {
    try {
      final companion = ResourcesCompanion(
        id: Value(id),
        sourceId: Value(sourceId),
        name: Value(name),
        type: Value(_toDriftResourceType(type)),
        relativePath: Value(relativePath),
        organizationMode: Value(
          organizationMode != null
              ? _toDriftOrganizationMode(organizationMode)
              : null,
        ),
        thumbnailPath: Value(thumbnailPath),
        fileCount: Value(fileCount),
        fileSize: Value(fileSize),
      );
      await _db.createResource(companion);
      final created = await _db.getResourceById(id);
      if (created == null) {
        return Err(DatabaseError('创建资源后未找到记录'));
      }
      return Ok(_toDomain(created));
    } catch (e) {
      return Err(DatabaseError('创建资源失败', cause: e));
    }
  }

  /// 原子创建资源并绑定初始标签。
  Future<Result<domain.Resource>> createResourceWithTags({
    required String id,
    required String sourceId,
    required String name,
    required domain.ResourceType type,
    required String relativePath,
    required List<String> tagIds,
    domain.OrganizationMode? organizationMode,
    int? fileCount,
    BigInt? fileSize,
  }) async {
    try {
      final companion = ResourcesCompanion(
        id: Value(id),
        sourceId: Value(sourceId),
        name: Value(name),
        type: Value(_toDriftResourceType(type)),
        relativePath: Value(relativePath),
        organizationMode: Value(
          organizationMode != null
              ? _toDriftOrganizationMode(organizationMode)
              : null,
        ),
        fileCount: Value(fileCount),
        fileSize: Value(fileSize),
      );
      await _db.createResourceWithTags(companion, tagIds);
      final created = await _db.getResourceById(id);
      if (created == null) {
        return Err(DatabaseError('创建资源后未找到记录'));
      }
      return Ok(_toDomain(created));
    } catch (e) {
      return Err(DatabaseError('创建资源并设置标签失败', cause: e));
    }
  }

  /// 扫描去重 / Upsert（冲突时更新元数据）
  Future<Result<void>> upsertResource({
    required String id,
    required String sourceId,
    required String name,
    required domain.ResourceType type,
    required String relativePath,
    domain.OrganizationMode? organizationMode,
    String? thumbnailPath,
    int? fileCount,
    BigInt? fileSize,
  }) async {
    try {
      final companion = ResourcesCompanion(
        id: Value(id),
        sourceId: Value(sourceId),
        name: Value(name),
        type: Value(_toDriftResourceType(type)),
        relativePath: Value(relativePath),
        organizationMode: Value(
          organizationMode != null
              ? _toDriftOrganizationMode(organizationMode)
              : null,
        ),
        thumbnailPath: Value(thumbnailPath),
        fileCount: Value(fileCount),
        fileSize: Value(fileSize),
      );
      await _db.upsertResource(companion);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('更新资源失败', cause: e));
    }
  }

  /// 更新资源
  Future<Result<domain.Resource>> updateResource(
    domain.Resource resource,
  ) async {
    try {
      final companion = ResourcesCompanion(
        id: Value(resource.id),
        sourceId: Value(resource.sourceId),
        name: Value(resource.name),
        type: Value(_toDriftResourceType(resource.type)),
        relativePath: Value(resource.relativePath),
        organizationMode: Value(
          resource.organizationMode != null
              ? _toDriftOrganizationMode(resource.organizationMode!)
              : null,
        ),
        thumbnailPath: Value(resource.thumbnailPath),
        fileCount: Value(resource.fileCount),
        fileSize: Value(resource.fileSize),
        isAvailable: Value(resource.isAvailable),
        lastScannedAt: Value(resource.lastScannedAt),
      );
      final success = await _db.updateResource(companion);
      if (!success) {
        return Err(DatabaseError('更新资源失败，记录不存在'));
      }
      final updated = await _db.getResourceById(resource.id);
      if (updated == null) {
        return Err(DatabaseError('更新资源后未找到记录'));
      }
      return Ok(_toDomain(updated));
    } catch (e) {
      return Err(DatabaseError('更新资源失败', cause: e));
    }
  }

  /// 删除资源（级联删除关联的 ResourceTags）
  Future<Result<void>> deleteResource(String id) async {
    try {
      await _db.deleteResource(id);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('删除资源失败', cause: e));
    }
  }

  /// Atomically creates split children and optionally removes the original.
  Future<Result<void>> commitResourceSplit({
    required List<domain.Resource> children,
    required String originalId,
    required bool deleteOriginal,
  }) async {
    try {
      await _db.transaction(() async {
        for (final child in children) {
          await _db.createResource(
            ResourcesCompanion(
              id: Value(child.id),
              sourceId: Value(child.sourceId),
              name: Value(child.name),
              type: Value(_toDriftResourceType(child.type)),
              relativePath: Value(child.relativePath),
              organizationMode: Value(
                child.organizationMode == null
                    ? null
                    : _toDriftOrganizationMode(child.organizationMode!),
              ),
            ),
          );
        }
        if (deleteOriginal) {
          final deleted = await _db.deleteResource(originalId);
          if (deleted != 1) throw StateError('原资源不存在');
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('拆分资源失败', cause: e));
    }
  }

  /// 键集分页查询资源
  Future<Result<List<domain.Resource>>> pageResources({
    String? lastCreatedAt,
    String? lastId,
    required int pageSize,
  }) async {
    try {
      final rows = await _db.pageResources(
        lastCreatedAt: lastCreatedAt,
        lastId: lastId,
        pageSize: pageSize,
      );
      final resources = rows.map(_toDomain).toList();
      return Ok(resources);
    } catch (e) {
      return Err(DatabaseError('分页查询资源失败', cause: e));
    }
  }

  /// 获取可用资源（仅 enabled + isAvailable 的源下的资源）
  Future<Result<List<domain.Resource>>> getAvailableResources({
    String? lastCreatedAt,
    String? lastId,
    required int pageSize,
  }) async {
    try {
      final rows = await _db.getAvailableResources(
        lastCreatedAt: lastCreatedAt,
        lastId: lastId,
        pageSize: pageSize,
      );
      final resources = rows.map(_toDomain).toList();
      return Ok(resources);
    } catch (e) {
      return Err(DatabaseError('获取可用资源失败', cause: e));
    }
  }

  /// 统一资源查询（可用源过滤 + 搜索 + 标签交集 + 收藏 + 键集分页）
  Future<Result<PagedResult<domain.Resource>>> queryResources(
    ResourceQuery query,
  ) async {
    try {
      final rows = await _db.queryResources(
        searchQuery: query.searchQuery,
        tagIds: query.tagIds,
        favoriteOnly: query.favoriteOnly,
        lastCreatedAt: query.cursor?.lastCreatedAt,
        lastId: query.cursor?.lastId,
        pageSize: query.pageSize,
      );

      final hasMore = rows.length > query.pageSize;
      final items = rows.take(query.pageSize).map(_toDomain).toList();

      ResourceCursor? nextCursor;
      if (hasMore && items.isNotEmpty) {
        final last = rows[query.pageSize - 1];
        nextCursor = ResourceCursor(
          lastCreatedAt: last.createdAt.toIso8601String(),
          lastId: last.id,
        );
      }

      return Ok(PagedResult(
        items: items,
        nextCursor: nextCursor?.encode(),
        hasMore: hasMore,
      ));
    } catch (e) {
      return Err(DatabaseError('查询资源失败', cause: e));
    }
  }

  /// 统一计数查询
  Future<Result<int>> countQueryResources(ResourceQuery query) async {
    try {
      final count = await _db.countQueryResources(
        searchQuery: query.searchQuery,
        tagIds: query.tagIds,
        favoriteOnly: query.favoriteOnly,
      );
      return Ok(count);
    } catch (e) {
      return Err(DatabaseError('统计资源数量失败', cause: e));
    }
  }

  /// 按标签筛选资源
  Future<Result<List<domain.Resource>>> filterByTags(
    List<String> tagIds,
  ) async {
    try {
      final rows = await _db.filterByTags(tagIds);
      final resources = rows.map(_toDomain).toList();
      return Ok(resources);
    } catch (e) {
      return Err(DatabaseError('按标签筛选资源失败', cause: e));
    }
  }

  /// 统计筛选结果数量
  Future<Result<int>> countFiltered(List<String> tagIds) async {
    try {
      final count = await _db.countFiltered(tagIds);
      return Ok(count);
    } catch (e) {
      return Err(DatabaseError('统计筛选结果失败', cause: e));
    }
  }

  // ============================================================================
  // 转换方法
  // ============================================================================

  /// drift Resource → domain Resource
  domain.Resource _toDomain(Resource row) {
    return domain.Resource(
      id: row.id,
      sourceId: row.sourceId,
      name: row.name,
      type: _toDomainResourceType(row.type),
      organizationMode: row.organizationMode != null
          ? _toDomainOrganizationMode(row.organizationMode!)
          : null,
      relativePath: row.relativePath,
      thumbnailPath: row.thumbnailPath,
      fileCount: row.fileCount,
      fileSize: row.fileSize,
      isAvailable: row.isAvailable,
      lastScannedAt: row.lastScannedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// drift ResourceType → domain ResourceType
  domain.ResourceType _toDomainResourceType(drift.ResourceType type) {
    return switch (type) {
      drift.ResourceType.folder => domain.ResourceType.folder,
      drift.ResourceType.pdf => domain.ResourceType.pdf,
      drift.ResourceType.archive => domain.ResourceType.archive,
      drift.ResourceType.video => domain.ResourceType.video,
    };
  }

  /// domain ResourceType → drift ResourceType
  drift.ResourceType _toDriftResourceType(domain.ResourceType type) {
    return switch (type) {
      domain.ResourceType.folder => drift.ResourceType.folder,
      domain.ResourceType.pdf => drift.ResourceType.pdf,
      domain.ResourceType.archive => drift.ResourceType.archive,
      domain.ResourceType.video => drift.ResourceType.video,
    };
  }

  /// drift OrganizationMode → domain OrganizationMode
  domain.OrganizationMode _toDomainOrganizationMode(
    drift.OrganizationMode mode,
  ) {
    return switch (mode) {
      drift.OrganizationMode.direct => domain.OrganizationMode.direct,
      drift.OrganizationMode.chapter => domain.OrganizationMode.chapter,
      drift.OrganizationMode.flatgrid => domain.OrganizationMode.flatgrid,
      drift.OrganizationMode.gallery => domain.OrganizationMode.gallery,
    };
  }

  /// domain OrganizationMode → drift OrganizationMode
  drift.OrganizationMode _toDriftOrganizationMode(
    domain.OrganizationMode mode,
  ) {
    return switch (mode) {
      domain.OrganizationMode.direct => drift.OrganizationMode.direct,
      domain.OrganizationMode.chapter => drift.OrganizationMode.chapter,
      domain.OrganizationMode.flatgrid => drift.OrganizationMode.flatgrid,
      domain.OrganizationMode.gallery => drift.OrganizationMode.gallery,
    };
  }
}
