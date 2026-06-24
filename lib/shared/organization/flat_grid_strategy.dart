import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../content_provider/content_provider.dart';
import '../content_provider/image_folder_provider.dart';
import '../file_source/file_source.dart';
import '../media/media_file_types.dart';
import 'organization_strategy.dart';

/// 平铺网格模式策略
///
/// 当前层级网格展示，文件夹逐层进入，文件点击进入查看器。
/// 当资源仅含单层文件（无子文件夹）时，平铺网格自然退化为全文件缩略图网格。
class FlatGridStrategy implements OrganizationStrategy {
  @override
  OrganizationMode get mode => OrganizationMode.flatgrid;

  @override
  Future<List<Chapter>> getChapters(Resource r, FileSource source) async {
    return [];
  }

  @override
  Future<List<FileEntry>> getContents(Resource r, FileSource source) async {
    final entries = await source.listDirectory(r.relativePath);

    final subDirs = <FileEntry>[];
    final files = <FileEntry>[];

    for (final entry in entries) {
      if (entry.isDirectory) {
        subDirs.add(entry);
      } else if (_isCompatibleFile(entry.name)) {
        files.add(entry);
      }
    }

    // 文件夹优先，各自按名称自然排序
    subDirs.sort((a, b) => _naturalCompare(a.name, b.name));
    files.sort((a, b) => _naturalCompare(a.name, b.name));

    return [...subDirs, ...files];
  }

  @override
  ContentProvider createProvider(
    Resource r,
    FileSource source, {
    Chapter? chapter,
  }) {
    return ImageFolderProvider(fileSource: source, folderPath: r.relativePath);
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

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }
}
