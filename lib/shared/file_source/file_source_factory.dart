import '../../domain/models/source.dart';
import 'file_source.dart';
import 'local_file_source.dart';
import 'smb_file_source.dart';

/// FileSource 工厂类
///
/// 按 Source 类型创建对应 FileSource 实现，缓存活跃连接。
/// 新增数据源类型只需在此注册。
class FileSourceFactory {
  final Map<String, FileSource> _cache = {};

  /// SMB 密码提供函数（由外部注入，用于获取已存储的密码）
  ///
  /// 签名：(sourceId) => password
  Future<String?> Function(String sourceId)? passwordProvider;

  /// 创建或获取已缓存的 FileSource
  ///
  /// 同一 sourceId 重复调用返回同一实例（缓存）。
  ///
  /// 注意：SMB 源需要 [passwordProvider] 来获取密码。
  /// 如果未设置 [passwordProvider]，SMB 源将使用空密码。
  FileSource create(Source source) {
    final existing = _cache[source.id];
    if (existing != null) return existing;

    final fileSource = switch (source.type) {
      SourceType.local => LocalFileSource(
        sourceId: source.id,
        rootPath: source.rootPath,
      ),
      SourceType.smb => throw UnimplementedError('请使用 createAsync() 创建 SMB 源'),
      SourceType.ftp => throw UnimplementedError('FTP 源尚未实现'),
      SourceType.webdav => throw UnimplementedError('WebDAV 源尚未实现'),
    };

    _cache[source.id] = fileSource;
    return fileSource;
  }

  /// 异步创建或获取已缓存的 FileSource
  ///
  /// 支持 SMB 源（需要从 SecureStorage 获取密码）。
  Future<FileSource> createAsync(Source source, {String? password}) async {
    final existing = _cache[source.id];
    if (existing != null) return existing;

    final FileSource fileSource;

    switch (source.type) {
      case SourceType.local:
        fileSource = LocalFileSource(
          sourceId: source.id,
          rootPath: source.rootPath,
        );

      case SourceType.smb:
        // 从参数或 passwordProvider 获取密码
        String? smbPassword = password;
        if (smbPassword == null && passwordProvider != null) {
          smbPassword = await passwordProvider!(source.id);
        }

        // 解析 rootPath 获取 share 名称
        // rootPath 格式：\\host\share 或 smb://host/share
        final share = extractShare(source.rootPath);

        fileSource = SmbFileSource(
          sourceId: source.id,
          host: source.host ?? '',
          share: share,
          port: source.port ?? 445,
          username: source.username,
          password: smbPassword,
          domain: source.domain,
        );

      case SourceType.ftp:
        throw UnimplementedError('FTP 源尚未实现');

      case SourceType.webdav:
        throw UnimplementedError('WebDAV 源尚未实现');
    }

    _cache[source.id] = fileSource;
    return fileSource;
  }

  /// 从 rootPath 提取共享名称
  ///
  /// 支持格式：
  /// - \\host\share → share
  /// - smb://host/share → share
  /// - share → share
  static String extractShare(String rootPath) {
    // 处理 \\host\share 格式
    if (rootPath.startsWith('\\\\')) {
      final parts = rootPath.substring(2).split('\\');
      if (parts.length >= 2) return parts[1];
      if (parts.length == 1) return parts[0];
    }

    // 处理 smb://host/share 格式
    if (rootPath.startsWith('smb://')) {
      final uri = rootPath.substring(6);
      final parts = uri.split('/');
      if (parts.length >= 2) return parts[1];
      if (parts.length == 1) return parts[0];
    }

    // 直接返回
    return rootPath;
  }

  /// 断开指定源的连接并清理缓存
  Future<void> disconnect(String sourceId) async {
    final fileSource = _cache.remove(sourceId);
    if (fileSource != null) {
      await fileSource.disconnect();
    }
  }

  /// 断开所有连接并清理缓存
  Future<void> disconnectAll() async {
    for (final fileSource in _cache.values) {
      await fileSource.disconnect();
    }
    _cache.clear();
  }

  /// 获取指定源的 FileSource（如果已缓存）
  FileSource? get(String sourceId) => _cache[sourceId];

  /// 是否已缓存指定源
  bool has(String sourceId) => _cache.containsKey(sourceId);
}
