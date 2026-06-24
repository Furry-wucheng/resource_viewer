import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../content_provider/content_provider.dart';
import '../content_provider/image_folder_provider.dart';
import '../file_source/file_source.dart';
import '../media/media_file_types.dart';
import 'organization_strategy.dart';

/// 章节模式策略
///
/// 子文件夹作为章节，每个章节作为独立阅读单元。
/// 顶层散落文件显示在章节列表末尾。
class ChapterStrategy implements OrganizationStrategy {
  @override
  OrganizationMode get mode => OrganizationMode.chapter;

  @override
  Future<List<Chapter>> getChapters(Resource r, FileSource source) async {
    final entries = await source.listDirectory(r.relativePath);

    final chapters = <Chapter>[];
    for (final entry in entries) {
      if (!entry.isDirectory) continue;
      final chapter = await _buildChapter(source, entry);
      chapters.add(chapter);
    }

    // 按名称自然排序
    chapters.sort((a, b) => _naturalCompare(a.name, b.name));
    return chapters;
  }

  @override
  Future<List<FileEntry>> getContents(Resource r, FileSource source) async {
    final entries = await source.listDirectory(r.relativePath);

    final subDirs = <FileEntry>[];
    final looseFiles = <FileEntry>[];

    for (final entry in entries) {
      if (entry.isDirectory) {
        subDirs.add(entry);
      } else if (_isCompatibleFile(entry.name)) {
        looseFiles.add(entry);
      }
    }

    // 排序：子文件夹在前，文件在后，各自按名称自然排序
    subDirs.sort((a, b) => _naturalCompare(a.name, b.name));
    looseFiles.sort((a, b) => _naturalCompare(a.name, b.name));

    return [...subDirs, ...looseFiles];
  }

  @override
  ContentProvider createProvider(
    Resource r,
    FileSource source, {
    Chapter? chapter,
  }) {
    final folderPath = chapter?.path ?? r.relativePath;

    return ImageFolderProvider(fileSource: source, folderPath: folderPath);
  }

  /// 构建单个章节信息
  Future<Chapter> _buildChapter(FileSource source, FileEntry dirEntry) async {
    try {
      final contents = await source.listDirectory(dirEntry.path);

      // 查找封面图片
      String? coverPath;
      int imageCount = 0;

      for (final file in contents) {
        if (file.isDirectory) continue;
        if (_isImageFile(file.name)) {
          imageCount++;
          coverPath ??= file.path;
        }
      }

      return Chapter(
        name: dirEntry.name,
        path: dirEntry.path,
        coverPath: coverPath,
        pageCount: imageCount,
        isDisabled: imageCount == 0,
      );
    } catch (_) {
      // 子目录读取失败，标记为空章节
      return Chapter(
        name: dirEntry.name,
        path: dirEntry.path,
        isDisabled: true,
      );
    }
  }

  bool _isImageFile(String name) {
    return MediaFileTypes.isImage(name);
  }

  bool _isCompatibleFile(String name) {
    return MediaFileTypes.isViewable(name);
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
