import 'package:dart_smb2/dart_smb2.dart';

import '../../domain/models/file_entry.dart';
import '../../domain/models/source.dart' as domain;
import '../../domain/core/result.dart';
import '../../shared/file_source/file_source_factory.dart';
import '../../shared/file_source/smb_file_source.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../models/enums.dart' as drift;

/// 文件系统 Repository
///
/// 封装文件浏览的委托逻辑，统一通过 FileSourceFactory 访问文件。
/// 支持 TTL 缓存和请求去重。
class FilesystemRepository {
  FilesystemRepository(
    this._db,
    this._fileSourceFactory, {
    this.secureStorageService,
    this.localTtl = const Duration(seconds: 30),
    this.remoteTtl = const Duration(minutes: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final FileSourceFactory _fileSourceFactory;
  final SecureStorageService? secureStorageService;
  final Duration localTtl;
  final Duration remoteTtl;
  final DateTime Function() _clock;

  /// 目录缓存（key = "sourceId:path"）
  final Map<String, _CacheEntry> _cache = {};

  /// 请求去重（key = "sourceId:path"）
  final Map<String, Future<Result<List<FileEntry>>>> _pendingRequests = {};

  /// 源缓存代次。失效时递增，防止旧的在途请求重新填充缓存。
  final Map<String, int> _sourceGenerations = {};

  /// 列出目录内容
  ///
  /// 通过 FileSourceFactory 委托，返回 `Result<List<FileEntry>>`。
  /// 支持 TTL 缓存和请求去重。
  Future<Result<List<FileEntry>>> listDirectory(String sourceId, String path) {
    final cacheKey = '$sourceId:$path';

    // 检查缓存
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_clock())) {
      return Future.value(Ok(cached.entries));
    }
    if (cached != null) _cache.remove(cacheKey);

    // 请求去重：同一路径并发请求共享一个 Future
    final pending = _pendingRequests[cacheKey];
    if (pending != null) return pending;

    final generation = _sourceGenerations[sourceId] ?? 0;
    final request = _loadDirectory(sourceId, path, cacheKey, generation);
    _pendingRequests[cacheKey] = request;
    request.whenComplete(() {
      if (identical(_pendingRequests[cacheKey], request)) {
        _pendingRequests.remove(cacheKey);
      }
    });
    return request;
  }

  /// 使用临时连接测试 SMB 配置，不写入缓存或数据库。
  Future<Result<bool>> testSmbConnection({
    required String host,
    required String share,
    int port = 445,
    String? username,
    String? password,
    String? domain,
    SmbPoolConnector? poolConnector,
  }) async {
    final source = SmbFileSource(
      sourceId: 'smb-connection-test',
      host: host,
      share: share,
      port: port,
      username: username,
      password: password,
      domain: domain,
      timeoutSeconds: 15,
      poolConnector: poolConnector,
    );
    try {
      await source.testConnection();
      return const Ok(true);
    } on Smb2Exception catch (error) {
      return Err(_mapSmbError(error));
    } on ArgumentError catch (error) {
      return Err(ValidationError(error.message?.toString() ?? 'SMB 配置无效'));
    } catch (error) {
      return Err(SourceUnreachableError('无法连接到服务器', cause: error));
    } finally {
      await source.disconnect();
    }
  }

  Future<Result<List<FileEntry>>> _loadDirectory(
    String sourceId,
    String path,
    String cacheKey,
    int generation,
  ) async {
    try {
      // 获取源信息
      final sourceResult = await _getSource(sourceId);
      final domain.Source source;
      switch (sourceResult) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (value == null) {
            return const Err(DatabaseError('数据源不存在'));
          }
          source = value;
      }

      // 获取密码（如果是 SMB 源）
      String? password;
      if (source.type == domain.SourceType.smb &&
          source.passwordStored &&
          secureStorageService != null) {
        password = await secureStorageService!.getPassword(sourceId);
      }

      // 获取 FileSource（异步创建，支持 SMB）
      final fileSource = await _fileSourceFactory.createAsync(
        source,
        password: password,
      );

      // 列出目录
      final entries = await fileSource.listDirectory(path);

      // 更新缓存
      if ((_sourceGenerations[sourceId] ?? 0) == generation) {
        final ttl = source.type == domain.SourceType.local
            ? localTtl
            : remoteTtl;
        _cache[cacheKey] = _CacheEntry(entries, ttl, _clock());
      }

      return Ok(entries);
    } on Smb2Exception catch (e) {
      // 映射 SMB 异常到 DomainError
      return Err(_mapSmbError(e));
    } catch (e) {
      return Err(DatabaseError('列出目录失败', cause: e));
    }
  }

  /// 映射 SMB 异常到 DomainError
  DomainError _mapSmbError(Smb2Exception e) {
    switch (e.type) {
      case Smb2ErrorType.auth:
        return SourceAuthError('SMB 认证失败', cause: e);
      case Smb2ErrorType.connection:
        return SourceUnreachableError('SMB 源不可达', cause: e);
      case Smb2ErrorType.timeout:
        return NetworkTimeoutError('连接超时', cause: e);
      case Smb2ErrorType.fileNotFound:
        return FileNotFoundError('路径不存在', cause: e);
      case Smb2ErrorType.accessDenied:
        return FileAccessDeniedError('权限不足', cause: e);
      default:
        return SourceUnreachableError('SMB 错误: ${e.message}', cause: e);
    }
  }

  /// 清理指定源的全部缓存
  void invalidateCache(String sourceId) {
    _cache.removeWhere((key, _) => key.startsWith('$sourceId:'));
    _pendingRequests.removeWhere((key, _) => key.startsWith('$sourceId:'));
    _sourceGenerations[sourceId] = (_sourceGenerations[sourceId] ?? 0) + 1;
  }

  /// 清理所有缓存
  void invalidateAllCache() {
    final sourceIds = <String>{
      ..._cache.keys.map((key) => key.substring(0, key.indexOf(':'))),
      ..._pendingRequests.keys.map((key) => key.substring(0, key.indexOf(':'))),
    };
    _cache.clear();
    _pendingRequests.clear();
    for (final sourceId in sourceIds) {
      _sourceGenerations[sourceId] = (_sourceGenerations[sourceId] ?? 0) + 1;
    }
  }

  /// 获取源信息
  Future<Result<domain.Source?>> _getSource(String sourceId) async {
    try {
      final row = await _db.getSourceById(sourceId);
      if (row == null) return const Ok(null);

      return Ok(
        domain.Source(
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
        ),
      );
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
  _CacheEntry(this.entries, this.ttl, this.createdAt);

  final List<FileEntry> entries;
  final Duration ttl;
  final DateTime createdAt;

  bool isExpired(DateTime now) => now.difference(createdAt) > ttl;
}
