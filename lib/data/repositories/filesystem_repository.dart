import 'dart:async';

import '../../domain/models/file_entry.dart';
import '../../domain/models/source.dart' as domain;
import '../../domain/core/result.dart';
import '../../shared/file_source/file_source_factory.dart';
import '../services/database_service.dart';
import '../models/enums.dart' as drift;

/// 文件系统 Repository
///
/// 封装文件浏览的委托逻辑，统一通过 FileSourceFactory 访问文件。
/// 支持 TTL 缓存和请求去重。
class FilesystemRepository {
  FilesystemRepository(this._db, this._fileSourceFactory);

  final AppDatabase _db;
  final FileSourceFactory _fileSourceFactory;

  /// 目录缓存（key = "sourceId:path"）
  final Map<String, _CacheEntry> _cache = {};

  /// 请求去重（key = "sourceId:path"）
  final Map<String, Future<Result<List<FileEntry>>>> _pendingRequests = {};

  /// 本地源缓存 TTL
  static const _localTtl = Duration(seconds: 30);

  /// SMB 源缓存 TTL
  static const _smbTtl = Duration(minutes: 2);

  /// 列出目录内容
  ///
  /// 通过 FileSourceFactory 委托，返回 `Result<List<FileEntry>>`。
  /// 支持 TTL 缓存和请求去重。
  Future<Result<List<FileEntry>>> listDirectory(
    String sourceId,
    String path,
  ) async {
    final cacheKey = '$sourceId:$path';

    // 检查缓存
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return Ok(cached.entries);
    }

    // 请求去重：同一路径并发请求共享一个 Future
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!;
    }

    final completer = Completer<Result<List<FileEntry>>>();
    _pendingRequests[cacheKey] = completer.future;

    try {
      // 获取源信息
      final sourceResult = await _getSource(sourceId);
      final domain.Source source;
      switch (sourceResult) {
        case Err(:final error):
          completer.complete(Err(error));
          return completer.future;
        case Ok(:final value):
          if (value == null) {
            completer.complete(const Err(DatabaseError('数据源不存在')));
            return completer.future;
          }
          source = value;
      }

      // 获取 FileSource
      final fileSource = _fileSourceFactory.create(source);

      // 列出目录
      final entries = await fileSource.listDirectory(path);

      // 更新缓存
      final ttl = source.type == domain.SourceType.local ? _localTtl : _smbTtl;
      _cache[cacheKey] = _CacheEntry(entries, ttl);

      completer.complete(Ok(entries));
      return completer.future;
    } catch (e) {
      completer.complete(Err(DatabaseError('列出目录失败', cause: e)));
      return completer.future;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// 清理指定源的全部缓存
  void invalidateCache(String sourceId) {
    _cache.removeWhere((key, _) => key.startsWith('$sourceId:'));
  }

  /// 清理所有缓存
  void invalidateAllCache() {
    _cache.clear();
  }

  /// 获取源信息
  Future<Result<domain.Source?>> _getSource(String sourceId) async {
    try {
      final row = await _db.getSourceById(sourceId);
      if (row == null) return const Ok(null);

      return Ok(domain.Source(
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
      ));
    } catch (e) {
      return Err(DatabaseError('获取数据源失败', cause: e));
    }
  }

  domain.SourceType _toDomainSourceType(drift.SourceType type) {
    return switch (type) {
      drift.SourceType.local => domain.SourceType.local,
      drift.SourceType.smb => domain.SourceType.smb,
      drift.SourceType.ftp => domain.SourceType.ftp,
      drift.SourceType.webdav => domain.SourceType.webdav,
    };
  }
}

/// 缓存条目
class _CacheEntry {
  _CacheEntry(this.entries, this.ttl);

  final List<FileEntry> entries;
  final Duration ttl;
  final DateTime createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}
