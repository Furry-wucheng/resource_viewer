import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../media/media_file_types.dart';
import '../file_source/file_source.dart';
import 'content_provider.dart';

/// 图片文件夹 ContentProvider
///
/// 按文件名排序提供图片翻页，仅处理文件夹类型资源。
class ImageFolderProvider implements ContentProvider {
  ImageFolderProvider({required this.fileSource, required this.folderPath});

  final FileSource fileSource;
  final String folderPath;

  List<String>? _imagePaths;
  bool _disposed = false;

  @override
  int get pageCount {
    _ensureLoaded();
    return _imagePaths!.length;
  }

  @override
  Future<Uint8List> loadPage(int index) async {
    _ensureLoaded();
    if (index < 0 || index >= _imagePaths!.length) {
      throw RangeError.index(index, _imagePaths, 'index');
    }
    if (_disposed) {
      throw StateError('ImageFolderProvider 已释放');
    }

    final relativePath = _imagePaths![index];
    return fileSource.readFile(relativePath);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _imagePaths = null;
  }

  /// 确保图片路径列表已加载
  void _ensureLoaded() {
    if (_imagePaths != null) return;
    throw StateError('请先调用 load() 加载图片列表');
  }

  /// 加载文件夹内的图片列表
  ///
  /// 过滤仅保留支持的图片格式，按自然排序。
  /// 不支持的格式跳过，加载失败抛异常。
  Future<void> load() async {
    final entries = await fileSource.listDirectory(folderPath);

    final imagePaths = <String>[];
    for (final entry in entries) {
      if (entry.isDirectory) continue;
      if (!_isSupportedImage(entry.name)) continue;
      imagePaths.add(entry.path);
    }

    // 自然排序
    imagePaths.sort((a, b) => _naturalCompare(p.basename(a), p.basename(b)));

    _imagePaths = imagePaths;
  }

  int indexOfPath(String relativePath) {
    _ensureLoaded();
    final normalized = relativePath.replaceAll('\\', '/');
    return _imagePaths!.indexWhere(
      (path) => path.replaceAll('\\', '/') == normalized,
    );
  }

  /// 检查文件名是否为支持的图片格式
  bool _isSupportedImage(String name) {
    return MediaFileTypes.isImage(name);
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
