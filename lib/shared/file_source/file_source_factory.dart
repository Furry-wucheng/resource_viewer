import '../../domain/models/source.dart';
import 'file_source.dart';
import 'local_file_source.dart';

/// FileSource 工厂类
///
/// 按 Source 类型创建对应 FileSource 实现，缓存活跃连接。
/// 新增数据源类型只需在此注册。
class FileSourceFactory {
  final Map<String, FileSource> _cache = {};

  /// 创建或获取已缓存的 FileSource
  ///
  /// 同一 sourceId 重复调用返回同一实例（缓存）。
  FileSource create(Source source) {
    final existing = _cache[source.id];
    if (existing != null) return existing;

    final fileSource = switch (source.type) {
      SourceType.local => LocalFileSource(
          sourceId: source.id,
          rootPath: source.rootPath,
        ),
      SourceType.smb => throw UnimplementedError('SMB 源尚未实现'),
      SourceType.ftp => throw UnimplementedError('FTP 源尚未实现'),
      SourceType.webdav => throw UnimplementedError('WebDAV 源尚未实现'),
    };

    _cache[source.id] = fileSource;
    return fileSource;
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
