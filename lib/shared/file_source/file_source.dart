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
