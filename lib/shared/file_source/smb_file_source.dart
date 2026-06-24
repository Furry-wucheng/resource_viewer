import 'dart:typed_data';

import 'package:dart_smb2/dart_smb2.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/file_entry.dart';
import '../media/media_file_types.dart';
import 'file_source.dart';

/// SMB 文件系统 FileSource 实现
///
/// 使用 `dart_smb2` 访问 SMB 网络共享。
class SmbFileSource implements FileSource {
  SmbFileSource({
    required this.sourceId,
    required this.host,
    required this.share,
    this.port = 445,
    this.username,
    this.password,
    this.domain,
    this.timeoutSeconds = 30,
    SmbPoolConnector? poolConnector,
  }) : _poolConnector = poolConnector ?? _connectPool;

  @override
  final String sourceId;

  /// SMB 服务器地址
  final String host;

  /// 共享名称
  final String share;

  /// 端口（默认 445）
  final int port;

  /// 用户名（可选，空则使用当前用户）
  final String? username;

  /// 密码（可选）
  final String? password;

  /// 域/工作组（可选）
  final String? domain;

  final int timeoutSeconds;

  final SmbPoolConnector _poolConnector;

  /// SMB 连接池
  SmbPoolClient? _pool;

  /// 确保连接池已创建
  Future<SmbPoolClient> _ensurePool() async {
    if (_pool != null) return _pool!;

    if (port != 445) {
      throw ArgumentError.value(
        port,
        'port',
        'dart_smb2 0.1.0 仅支持默认 SMB 端口 445',
      );
    }

    _pool = await _poolConnector(
      host: host,
      share: share,
      username: username,
      password: password,
      domain: domain,
      timeoutSeconds: timeoutSeconds,
    );

    return _pool!;
  }

  @override
  Future<List<FileEntry>> listDirectory(String relativePath) async {
    final pool = await _ensurePool();

    // SMB 路径使用正斜杠，空字符串表示根目录
    final smbPath = _toSmbPath(relativePath);

    final entries = await pool.listDirectory(smbPath);

    // 过滤并转换为 FileEntry
    final result = <FileEntry>[];
    for (final entry in entries) {
      // 过滤隐藏文件
      if (entry.name.startsWith('.')) continue;

      // 非目录且不在支持列表中的文件跳过
      if (!entry.isDirectory && !_isSupported(entry.name)) continue;

      result.add(
        FileEntry(
          name: entry.name,
          path: _toDomainPath(smbPath, entry.name),
          isDirectory: entry.isDirectory,
          size: entry.isDirectory ? null : BigInt.from(entry.size),
          modifiedAt: entry.stat.modified,
        ),
      );
    }

    // 文件夹在前，文件在后，按名称字母升序
    result.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return _naturalCompare(a.name, b.name);
    });

    return result;
  }

  @override
  Future<FileEntry?> stat(String relativePath) async {
    final pool = await _ensurePool();
    final smbPath = _toSmbPath(relativePath);

    try {
      final stat = await pool.stat(smbPath);
      final name = p.basename(relativePath);

      return FileEntry(
        name: name,
        path: relativePath,
        isDirectory: stat.isDirectory,
        size: stat.isDirectory ? null : BigInt.from(stat.size),
        modifiedAt: stat.modified,
      );
    } on Smb2Exception catch (e) {
      if (e.type == Smb2ErrorType.fileNotFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> readFile(String relativePath) async {
    final pool = await _ensurePool();
    final smbPath = _toSmbPath(relativePath);
    return await pool.readFile(smbPath);
  }

  @override
  Stream<Uint8List> streamFile(String relativePath) async* {
    final pool = await _ensurePool();
    final smbPath = _toSmbPath(relativePath);
    yield* pool.streamFile(smbPath);
  }

  @override
  Future<Uint8List> readRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async {
    final pool = await _ensurePool();
    final smbPath = _toSmbPath(relativePath);
    return pool.readFileRange(smbPath, offset: offset, length: length);
  }

  @override
  Future<bool> testConnection() async {
    final pool = await _ensurePool();
    await pool.echo();
    return true;
  }

  @override
  Future<void> disconnect() async {
    await _pool?.disconnect();
    _pool = null;
  }

  /// 将相对路径转换为 SMB 路径
  ///
  /// SMB 路径使用正斜杠，空字符串表示根目录。
  String _toSmbPath(String relativePath) {
    if (relativePath.isEmpty) return '';
    // 确保使用正斜杠
    return relativePath.replaceAll('\\', '/');
  }

  /// 将 SMB 目录路径和文件名组合为 Domain 路径
  String _toDomainPath(String dirPath, String name) {
    if (dirPath.isEmpty) return name;
    return '$dirPath/$name';
  }

  /// 检查文件是否在支持列表中
  bool _isSupported(String name) {
    return MediaFileTypes.isSupported(name);
  }

  /// 自然排序（2 排在 10 前面）
  static int _naturalCompare(String a, String b) {
    final aParts = _splitNatural(a);
    final bParts = _splitNatural(b);

    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      final aIsNum =
          aParts[i].codeUnitAt(0) >= 48 && aParts[i].codeUnitAt(0) <= 57;
      final bIsNum =
          bParts[i].codeUnitAt(0) >= 48 && bParts[i].codeUnitAt(0) <= 57;

      if (aIsNum && bIsNum) {
        final cmp = int.parse(aParts[i]).compareTo(int.parse(bParts[i]));
        if (cmp != 0) return cmp;
      } else {
        final cmp = aParts[i].compareTo(bParts[i]);
        if (cmp != 0) return cmp;
      }
    }

    return aParts.length.compareTo(bParts.length);
  }

  /// 将字符串拆分为文本和数字部分
  static List<String> _splitNatural(String s) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool? isDigit;

    for (var i = 0; i < s.length; i++) {
      final char = s[i];
      final charIsDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

      if (isDigit == null) {
        isDigit = charIsDigit;
      } else if (charIsDigit != isDigit) {
        parts.add(buffer.toString());
        buffer.clear();
        isDigit = charIsDigit;
      }
      buffer.write(char);
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }
}

typedef SmbPoolConnector =
    Future<SmbPoolClient> Function({
      required String host,
      required String share,
      String? username,
      String? password,
      String? domain,
      required int timeoutSeconds,
    });

abstract class SmbPoolClient {
  Future<List<Smb2DirEntry>> listDirectory(String path);
  Future<Smb2Stat> stat(String path);
  Future<Uint8List> readFile(String path);
  Stream<Uint8List> streamFile(String path);
  Future<Uint8List> readFileRange(
    String path, {
    required int offset,
    required int length,
  });
  Future<void> echo();
  Future<void> disconnect();
}

class _DartSmbPoolClient implements SmbPoolClient {
  const _DartSmbPoolClient(this.pool);

  final Smb2Pool pool;

  @override
  Future<List<Smb2DirEntry>> listDirectory(String path) =>
      pool.listDirectory(path);

  @override
  Future<Smb2Stat> stat(String path) => pool.stat(path);

  @override
  Future<Uint8List> readFile(String path) => pool.readFile(path);

  @override
  Stream<Uint8List> streamFile(String path) => pool.streamFile(path);

  @override
  Future<Uint8List> readFileRange(
    String path, {
    required int offset,
    required int length,
  }) => pool.readFileRange(path, offset: offset, length: length);

  @override
  Future<void> echo() => pool.echo();

  @override
  Future<void> disconnect() => pool.disconnect();
}

Future<SmbPoolClient> _connectPool({
  required String host,
  required String share,
  String? username,
  String? password,
  String? domain,
  required int timeoutSeconds,
}) async {
  final pool = await Smb2Pool.connect(
    host: host,
    share: share,
    user: username,
    password: password,
    domain: domain,
    workers: 2,
    timeoutSeconds: timeoutSeconds,
  );
  return _DartSmbPoolClient(pool);
}
