import 'package:drift/drift.dart';

import '../services/database_service.dart';
import '../services/thumbnail_cache_service.dart';
import '../models/sources.dart' as drift;
import '../../domain/models/source.dart' as domain;
import '../../domain/core/result.dart';
import '../../shared/file_source/file_source_factory.dart';

/// 数据源 Repository
///
/// 负责 drift Source 到 domain Source 的转换，处理错误包装为 Result
class SourceRepository {
  SourceRepository(
    this._db, {
    this.fileSourceFactory,
    this.thumbnailCacheService,
  });

  final AppDatabase _db;
  final FileSourceFactory? fileSourceFactory;
  final ThumbnailCacheService? thumbnailCacheService;

  /// 获取所有数据源
  Future<Result<List<domain.Source>>> getAllSources() async {
    try {
      final rows = await _db.getAllSources();
      final sources = rows.map(_toDomain).toList();
      return Ok(sources);
    } catch (e) {
      return Err(DatabaseError('获取数据源列表失败', cause: e));
    }
  }

  /// 监听所有数据源变化
  Stream<Result<List<domain.Source>>> watchAllSources() async* {
    try {
      await for (final rows in _db.watchAllSources()) {
        yield Ok(rows.map(_toDomain).toList());
      }
    } catch (error) {
      yield Err(DatabaseError('监听数据源失败', cause: error));
    }
  }

  /// 根据 ID 获取数据源
  Future<Result<domain.Source?>> getSourceById(String id) async {
    try {
      final row = await _db.getSourceById(id);
      return Ok(row != null ? _toDomain(row) : null);
    } catch (e) {
      return Err(DatabaseError('获取数据源失败', cause: e));
    }
  }

  /// 创建数据源
  Future<Result<domain.Source>> createSource({
    required String id,
    required String name,
    required domain.SourceType type,
    required String rootPath,
    String? host,
    int? port,
    String? username,
    bool passwordStored = false,
    String? domainName,
    bool enabled = true,
    bool isAvailable = false,
  }) async {
    try {
      final companion = SourcesCompanion(
        id: Value(id),
        name: Value(name),
        type: Value(_toDriftSourceType(type)),
        rootPath: Value(rootPath),
        host: Value(host),
        port: Value(port),
        username: Value(username),
        passwordStored: Value(passwordStored),
        domain: Value(domainName),
        enabled: Value(enabled),
        isAvailable: Value(isAvailable),
      );
      await _db.createSource(companion);
      final created = await _db.getSourceById(id);
      if (created == null) {
        return Err(DatabaseError('创建数据源后未找到记录'));
      }
      return Ok(_toDomain(created));
    } catch (e) {
      return Err(DatabaseError('创建数据源失败', cause: e));
    }
  }

  /// 更新数据源
  Future<Result<domain.Source>> updateSource(domain.Source source) async {
    try {
      final companion = SourcesCompanion(
        id: Value(source.id),
        name: Value(source.name),
        type: Value(_toDriftSourceType(source.type)),
        rootPath: Value(source.rootPath),
        host: Value(source.host),
        port: Value(source.port),
        username: Value(source.username),
        passwordStored: Value(source.passwordStored),
        domain: Value(source.domain),
        enabled: Value(source.enabled),
        isAvailable: Value(source.isAvailable),
        lastCheckAt: Value(source.lastCheckAt),
      );
      final success = await _db.updateSource(companion);
      if (!success) {
        return Err(DatabaseError('更新数据源失败，记录不存在'));
      }
      final updated = await _db.getSourceById(source.id);
      if (updated == null) {
        return Err(DatabaseError('更新数据源后未找到记录'));
      }
      return Ok(_toDomain(updated));
    } catch (e) {
      return Err(DatabaseError('更新数据源失败', cause: e));
    }
  }

  /// 删除数据源（级联删除关联的 Resources、ResourceTags、缩略图缓存 + disconnect）
  Future<Result<void>> deleteSource(String id) async {
    try {
      final resources = await _db.getResourcesBySourceId(id);

      // 断开 FileSource 连接
      await fileSourceFactory?.disconnect(id);

      // 缩略图不在数据库事务中；逐项删除可避免误清其他源的缓存。
      if (thumbnailCacheService != null) {
        for (final resource in resources) {
          await thumbnailCacheService!.delete(resource.id);
        }
      }

      // 删除数据库记录（级联删除 Resources 和 ResourceTags）
      await _db.deleteSource(id);

      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('删除数据源失败', cause: e));
    }
  }

  /// 切换数据源启用/禁用状态
  Future<Result<void>> toggleSource(String id) async {
    try {
      final source = await _db.getSourceById(id);
      if (source == null) {
        return Err(DatabaseError('数据源不存在'));
      }

      // 使用 updateSource 方法来更新 enabled 状态
      final domainSource = _toDomain(source).copyWith(enabled: !source.enabled);
      final companion = SourcesCompanion(
        id: Value(id),
        name: Value(domainSource.name),
        type: Value(_toDriftSourceType(domainSource.type)),
        rootPath: Value(domainSource.rootPath),
        host: Value(domainSource.host),
        port: Value(domainSource.port),
        username: Value(domainSource.username),
        passwordStored: Value(domainSource.passwordStored),
        domain: Value(domainSource.domain),
        enabled: Value(domainSource.enabled),
        isAvailable: Value(domainSource.isAvailable),
        lastCheckAt: Value(domainSource.lastCheckAt),
      );
      await _db.updateSource(companion);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('切换数据源状态失败', cause: e));
    }
  }

  /// 标记数据源为不可达
  Future<Result<void>> markSourceUnavailable(String id) async {
    try {
      await _db.markSourceUnavailable(id);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('标记数据源不可达失败', cause: e));
    }
  }

  /// 标记数据源为可达
  Future<Result<void>> markSourceAvailable(String id) async {
    try {
      await _db.markSourceAvailable(id);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('标记数据源可达失败', cause: e));
    }
  }

  // ============================================================================
  // 转换方法
  // ============================================================================

  /// drift Source → domain Source
  domain.Source _toDomain(Source row) {
    return domain.Source(
      id: row.id,
      name: row.name,
      type: _toDomainSourceType(row.type),
      rootPath: row.rootPath,
      host: row.host,
      port: row.port,
      username: row.username,
      passwordStored: row.passwordStored,
      domain: row.domain,
      enabled: row.enabled,
      isAvailable: row.isAvailable,
      lastCheckAt: row.lastCheckAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// drift SourceType → domain SourceType
  domain.SourceType _toDomainSourceType(drift.SourceType type) {
    return switch (type) {
      drift.SourceType.local => domain.SourceType.local,
      drift.SourceType.smb => domain.SourceType.smb,
      drift.SourceType.ftp => domain.SourceType.ftp,
      drift.SourceType.webdav => domain.SourceType.webdav,
    };
  }

  /// domain SourceType → drift SourceType
  drift.SourceType _toDriftSourceType(domain.SourceType type) {
    return switch (type) {
      domain.SourceType.local => drift.SourceType.local,
      domain.SourceType.smb => drift.SourceType.smb,
      domain.SourceType.ftp => drift.SourceType.ftp,
      domain.SourceType.webdav => drift.SourceType.webdav,
    };
  }
}
