import 'package:path/path.dart' as p;

import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../content_provider/content_provider.dart';
import '../content_provider/image_folder_provider.dart';
import '../file_source/file_source.dart';
import '../media/media_file_types.dart';
import 'chapter_strategy.dart';
import 'organization_strategy.dart';

/// 章节画廊模式策略。
///
/// 根层保持章节模式：子文件夹作为章节。进入某一章节后，递归展开该
/// 章节下所有支持文件，形成一个扁平阅读序列。
class ChapterGalleryStrategy implements OrganizationStrategy {
  final ChapterStrategy _chapterStrategy = ChapterStrategy();

  @override
  OrganizationMode get mode => OrganizationMode.chapterGallery;

  @override
  Future<List<Chapter>> getChapters(Resource r, FileSource source) async {
    final entries = await source.listDirectory(r.relativePath);
    final chapters = <Chapter>[];

    for (final entry in entries) {
      if (!entry.isDirectory) continue;
      final files = <FileEntry>[];
      final visited = <String>{};
      await _collectRecursive(source, entry.path, files, visited);
      _sortFiles(files);
      String? coverPath;
      for (final file in files) {
        if (_isImageFile(file.name)) {
          coverPath = file.path;
          break;
        }
      }

      chapters.add(
        Chapter(
          name: entry.name,
          path: entry.path,
          coverPath: coverPath,
          pageCount: files.length,
          isDisabled: files.isEmpty,
        ),
      );
    }

    chapters.sort((a, b) => _naturalCompare(a.name, b.name));
    return chapters;
  }

  @override
  Future<List<FileEntry>> getContents(Resource r, FileSource source) {
    return _chapterStrategy.getContents(r, source);
  }

  Future<List<FileEntry>> getChapterContents(
    FileSource source,
    Chapter chapter,
  ) async {
    final files = <FileEntry>[];
    final visited = <String>{};
    await _collectRecursive(source, chapter.path, files, visited);
    _sortFiles(files);
    return files;
  }

  void _sortFiles(List<FileEntry> files) {
    files.sort((a, b) {
      final dirCmp = p.dirname(a.path).compareTo(p.dirname(b.path));
      if (dirCmp != 0) return dirCmp;
      return _naturalCompare(a.name, b.name);
    });
  }

  @override
  ContentProvider createProvider(
    Resource r,
    FileSource source, {
    Chapter? chapter,
  }) {
    return ImageFolderProvider(
      fileSource: source,
      folderPath: chapter?.path ?? r.relativePath,
    );
  }

  Future<void> _collectRecursive(
    FileSource source,
    String path,
    List<FileEntry> result,
    Set<String> visited,
  ) async {
    if (!visited.add(path)) return;

    try {
      final entries = await source.listDirectory(path);
      for (final entry in entries) {
        if (entry.isDirectory) {
          await _collectRecursive(source, entry.path, result, visited);
        } else if (_isCompatibleFile(entry.name)) {
          result.add(entry);
        }
      }
    } catch (_) {
      // 单个子目录读取失败不阻塞整个章节。
    }
  }

  bool _isImageFile(String name) {
    return MediaFileTypes.isImage(name);
  }

  bool _isCompatibleFile(String name) {
    return MediaFileTypes.isViewable(name);
  }

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

    if (buffer.isNotEmpty) parts.add(buffer.toString());
    return parts;
  }
}
