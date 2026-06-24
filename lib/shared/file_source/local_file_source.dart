import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../domain/models/file_entry.dart';
import '../media/media_file_types.dart';
import 'file_source.dart';

/// 本地文件系统 FileSource 实现
///
/// 使用 `dart:io` 访问本地文件系统。
class LocalFileSource implements FileSource {
  LocalFileSource({required this.sourceId, required this.rootPath});

  @override
  final String sourceId;

  /// 源根目录的绝对路径
  final String rootPath;

  @override
  Future<List<FileEntry>> listDirectory(String relativePath) async {
    final dir = Directory(_resolvePath(relativePath));
    if (!await dir.exists()) {
      return [];
    }

    final entries = <FileEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final isDirectory = entity is Directory;

      // 过滤隐藏文件
      if (name.startsWith('.')) continue;

      // 非目录且不在支持列表中的文件跳过
      if (!isDirectory && !_isSupported(name)) continue;

      DateTime? modifiedAt;
      BigInt? size;
      try {
        final stat = await entity.stat();
        modifiedAt = stat.modified;
        size = BigInt.from(stat.size);
      } catch (_) {
        // stat 失败不影响列表
      }

      entries.add(
        FileEntry(
          name: name,
          path: _toRelative(entity.path),
          isDirectory: isDirectory,
          size: size,
          modifiedAt: modifiedAt,
        ),
      );
    }

    // 文件夹在前，文件在后，按名称字母升序
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return _naturalCompare(a.name, b.name);
    });

    return entries;
  }

  @override
  Future<FileEntry?> stat(String relativePath) async {
    final file = File(_resolvePath(relativePath));
    final dir = Directory(_resolvePath(relativePath));

    FileSystemEntity entity;
    if (await dir.exists()) {
      entity = dir;
    } else if (await file.exists()) {
      entity = file;
    } else {
      return null;
    }

    try {
      final stat = await entity.stat();
      return FileEntry(
        name: p.basename(entity.path),
        path: relativePath,
        isDirectory: entity is Directory,
        size: BigInt.from(stat.size),
        modifiedAt: stat.modified,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List> readFile(String relativePath) async {
    final file = File(_resolvePath(relativePath));
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', file.path);
    }
    return file.readAsBytes();
  }

  @override
  Stream<Uint8List> streamFile(String relativePath) async* {
    final file = File(_resolvePath(relativePath));
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', file.path);
    }

    const chunkSize = 64 * 1024; // 64KB per chunk
    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      while (true) {
        final chunk = await randomAccessFile.read(chunkSize);
        if (chunk.isEmpty) break;
        yield Uint8List.fromList(chunk);
      }
    } finally {
      await randomAccessFile.close();
    }
  }

  @override
  Future<Uint8List> readRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async {
    if (offset < 0 || length < 0) {
      throw ArgumentError('offset and length must be non-negative');
    }
    if (length == 0) return Uint8List(0);

    final file = File(_resolvePath(relativePath));
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', file.path);
    }

    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      await randomAccessFile.setPosition(offset);
      return randomAccessFile.read(length);
    } finally {
      await randomAccessFile.close();
    }
  }

  @override
  Stream<Uint8List> streamRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async* {
    if (offset < 0 || length < 0) {
      throw ArgumentError('offset and length must be non-negative');
    }
    if (length == 0) return;

    final file = File(_resolvePath(relativePath));
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', file.path);
    }

    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      await randomAccessFile.setPosition(offset);
      var remaining = length;
      const chunkSize = 1024 * 1024;
      while (remaining > 0) {
        final toRead = remaining < chunkSize ? remaining : chunkSize;
        final chunk = await randomAccessFile.read(toRead);
        if (chunk.isEmpty) break;
        yield Uint8List.fromList(chunk);
        remaining -= chunk.length;
      }
    } finally {
      await randomAccessFile.close();
    }
  }

  @override
  Future<bool> testConnection() async {
    final dir = Directory(rootPath);
    return dir.exists();
  }

  @override
  Future<void> disconnect() async {
    // 本地文件系统无连接需要关闭
  }

  /// 将相对路径解析为绝对路径
  String _resolvePath(String relativePath) {
    if (relativePath.isEmpty) return rootPath;
    final segments = relativePath.split(RegExp(r'[/\\]'));
    return p.normalize(p.joinAll([rootPath, ...segments]));
  }

  /// 将绝对路径转换为相对于根目录的路径
  String _toRelative(String absolutePath) {
    // Domain 路径统一使用正斜杠，避免 UI/ViewModel 依赖宿主平台分隔符。
    return p.relative(absolutePath, from: rootPath).replaceAll('\\', '/');
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
