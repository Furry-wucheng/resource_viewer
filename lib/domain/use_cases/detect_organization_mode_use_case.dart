import '../../shared/file_source/file_source.dart';
import '../../shared/media/media_file_types.dart';
import '../models/file_entry.dart';
import '../models/resource.dart';

/// 自动检测文件夹的最佳组织模式
///
/// 按以下顺序从上到下匹配，命中即停止：
/// 1. 含子文件夹 + 子文件夹内含图片 + 顶层无散落文件 → chapter
/// 2. 含混合文件 / 仅单层文件 / 无法判定 → flatgrid
/// 3. 画廊模式不自动判定，仅用户手动选择
class DetectOrganizationModeUseCase {
  const DetectOrganizationModeUseCase();

  /// 检测指定路径的组织模式
  ///
  /// [source] 文件源
  /// [relativePath] 资源相对于源根目录的路径
  Future<OrganizationMode> call(FileSource source, String relativePath) async {
    try {
      final entries = await source.listDirectory(relativePath);
      if (entries.isEmpty) return OrganizationMode.flatgrid;

      // 分类条目
      final subDirs = <FileEntry>[];
      final looseFiles = <FileEntry>[];

      for (final entry in entries) {
        if (entry.isDirectory) {
          subDirs.add(entry);
        } else if (_isCompatibleFile(entry.name)) {
          looseFiles.add(entry);
        }
      }

      // 条件 1: 有子文件夹 且 顶层无散落兼容文件 且 至少一个子文件夹内含图片
      if (subDirs.isNotEmpty && looseFiles.isEmpty) {
        final hasImagesInSubDir = await _anySubDirHasImages(source, subDirs);
        if (hasImagesInSubDir) {
          return OrganizationMode.chapter;
        }
      }

      // 条件 2/3: 其他情况 → flatgrid（兜底）
      return OrganizationMode.flatgrid;
    } catch (_) {
      // 读取失败时兜底为 flatgrid
      return OrganizationMode.flatgrid;
    }
  }

  /// 检查是否有子文件夹内含图片
  Future<bool> _anySubDirHasImages(
    FileSource source,
    List<FileEntry> subDirs,
  ) async {
    for (final dir in subDirs) {
      try {
        final contents = await source.listDirectory(dir.path);
        if (contents.any((e) => !e.isDirectory && _isImageFile(e.name))) {
          return true;
        }
      } catch (_) {
        // 单个子目录读取失败不阻塞判定
        continue;
      }
    }
    return false;
  }

  /// 检查文件名是否为支持的图片格式
  bool _isImageFile(String name) {
    return MediaFileTypes.isImage(name);
  }

  /// 检查文件名是否为兼容文件格式
  bool _isCompatibleFile(String name) {
    return MediaFileTypes.isViewable(name);
  }
}
