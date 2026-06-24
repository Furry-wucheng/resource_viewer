import 'package:path/path.dart' as p;

import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../content_provider/content_provider.dart';
import '../content_provider/image_folder_provider.dart';
import '../file_source/file_source.dart';
import '../media/media_file_types.dart';
import 'organization_strategy.dart';

/// 画廊模式策略
///
/// 递归展开所有子文件夹的全部兼容文件到一个大网格。
/// 不保留文件夹层级信息——所有文件视为平面列表。
class GalleryStrategy implements OrganizationStrategy {
  @override
  OrganizationMode get mode => OrganizationMode.gallery;

  @override
  Future<List<Chapter>> getChapters(Resource r, FileSource source) async {
    return [];
  }

  @override
  Future<List<FileEntry>> getContents(Resource r, FileSource source) async {
    final allFiles = <FileEntry>[];
    final visited = <String>{};
    await _collectRecursive(source, r.relativePath, allFiles, visited);

    // 按文件夹名 → 文件名字母升序
    allFiles.sort((a, b) {
      final dirA = p.dirname(a.path);
      final dirB = p.dirname(b.path);
      final dirCmp = dirA.compareTo(dirB);
      if (dirCmp != 0) return dirCmp;
      return a.name.compareTo(b.name);
    });

    return allFiles;
  }

  @override
  ContentProvider createProvider(
    Resource r,
    FileSource source, {
    Chapter? chapter,
  }) {
    return ImageFolderProvider(fileSource: source, folderPath: r.relativePath);
  }

  /// 递归收集所有兼容文件
  Future<void> _collectRecursive(
    FileSource source,
    String path,
    List<FileEntry> result,
    Set<String> visited,
  ) async {
    if (!visited.add(path)) return; // 防止目录环

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
      // 单个目录读取失败不阻塞整体收集
    }
  }

  bool _isCompatibleFile(String name) {
    return MediaFileTypes.isViewable(name);
  }
}
