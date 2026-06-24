import 'dart:typed_data';

import '../../domain/models/file_entry.dart';

/// 统一文件访问接口（策略模式）
///
/// 本地文件系统 / SMB / FTP / WebDAV 均实现此接口。
/// 新增数据源类型只需实现此接口 + 在 [FileSourceFactory] 注册。
abstract class FileSource {
  /// 数据源 ID（对应 Source.id）
  String get sourceId;

  /// 列出目录下的文件和文件夹
  ///
  /// [relativePath] 相对于源根目录的路径。
  /// 返回结果：文件夹在前，文件在后，按名称字母升序。
  Future<List<FileEntry>> listDirectory(String relativePath);

  /// 获取单个文件/文件夹的元信息
  Future<FileEntry?> stat(String relativePath);

  /// 读取整个文件内容（适用于小文件）
  Future<Uint8List> readFile(String relativePath);

  /// 流式读取文件（适用于大文件，如视频）
  Stream<Uint8List> streamFile(String relativePath);

  /// 随机读取文件的一段字节（适用于视频 seek / HTTP Range）
  ///
  /// [offset] 为从文件开头起算的字节偏移， [length] 为期望读取长度。
  /// 如果请求越过文件末尾，具体实现可返回短读。
  Future<Uint8List> readRange(
    String relativePath, {
    required int offset,
    required int length,
  });

  /// 流式读取文件的一段字节（适用于视频 HTTP Range 代理）。
  ///
  /// 与 [readRange] 不同，本方法以 chunk 流形式产出数据，调用方可在
  /// 每个 chunk 后立即转发，形成自然背压：当下游（如 mpv demuxer）
  /// 消费变慢时 socket 缓冲堆积，`await for` 循环自动暂停读取，从而
  /// 让推送速率匹配消费速率、避免突发模式。
  ///
  /// 默认实现用 [readRange] 按 1MB 循环模拟；持久句柄实现（SMB 等）
  /// 应覆盖此方法以避免每 MB 重新打开/关闭文件句柄。
  Stream<Uint8List> streamRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async* {
    const chunkSize = 1024 * 1024;
    var pos = offset;
    var remaining = length;
    while (remaining > 0) {
      final toRead = remaining < chunkSize ? remaining : chunkSize;
      final bytes = await readRange(relativePath, offset: pos, length: toRead);
      if (bytes.isEmpty) break;
      yield bytes;
      pos += bytes.length;
      remaining -= bytes.length;
    }
  }

  /// 测试连接是否可达
  ///
  /// 本地源：检查路径是否存在。
  /// SMB：检查网络连通性和认证。
  Future<bool> testConnection();

  /// 断开连接，释放资源
  ///
  /// 本地源：空操作。
  /// SMB：断开网络连接。
  Future<void> disconnect();
}
