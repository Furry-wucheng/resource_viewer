import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../domain/core/result.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/file_entry.dart';
import '../../shared/file_source/file_source.dart';
import '../../shared/thumbnail/image_thumbnail_generator.dart';
import '../../shared/thumbnail/video_thumbnail_generator.dart';
import '../services/thumbnail_cache_service.dart';

/// 缩略图 Repository
///
/// 封装缩略图生成和缓存管理。
/// 委托 ThumbnailGenerator 和 ThumbnailCacheService。
class ThumbnailRepository {
  ThumbnailRepository(this._cacheService, {String? outputDirectory})
    : _imageGenerator = ImageThumbnailGenerator(
        outputDirectory: outputDirectory,
      ),
      _videoGenerator = VideoThumbnailGenerator(
        outputDirectory: outputDirectory,
      );

  final ThumbnailCacheService _cacheService;
  final ImageThumbnailGenerator _imageGenerator;
  final VideoThumbnailGenerator _videoGenerator;

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.tiff',
    '.tif',
  };
  static const _videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
  };

  /// 文件浏览器临时预览，不写数据库或资源缩略图缓存。
  Future<Result<Uint8List?>> preview(FileSource source, FileEntry entry) async {
    try {
      if (entry.isDirectory) {
        return Ok(await _previewDirectory(source, entry.path));
      }
      final extension = p.extension(entry.name).toLowerCase();
      if (_imageExtensions.contains(extension)) {
        return Ok(await source.readFile(entry.path));
      }
      if (_videoExtensions.contains(extension)) {
        return Ok(await _videoGenerator.generatePreview(source, entry.path));
      }
      return const Ok(null);
    } catch (error) {
      return Err(
        MediaLoadError('生成文件预览失败', cause: error, mediaType: MediaType.image),
      );
    }
  }

  Future<Uint8List?> _previewDirectory(
    FileSource source,
    String rootPath,
  ) async {
    final entries = await source.listDirectory(rootPath);
    String? firstVideoPath;
    for (final entry in entries.where((entry) => !entry.isDirectory)) {
      final extension = p.extension(entry.name).toLowerCase();
      if (_imageExtensions.contains(extension)) {
        return source.readFile(entry.path);
      }
      if (firstVideoPath == null && _videoExtensions.contains(extension)) {
        firstVideoPath = entry.path;
      }
    }
    return firstVideoPath == null
        ? null
        : _videoGenerator.generatePreview(source, firstVideoPath);
  }

  /// 生成缩略图
  ///
  /// 按资源类型路由到对应生成器。
  /// 返回生成的缩略图路径，失败时返回 null。
  Future<Result<String?>> generate(
    String resourceId,
    FileSource source,
    String relativePath,
    ResourceType resourceType,
  ) async {
    try {
      String? thumbPath;

      switch (resourceType) {
        case ResourceType.folder:
          thumbPath = await _imageGenerator.generate(
            source,
            relativePath,
            resourceId,
          );
          break;
        case ResourceType.video:
          thumbPath = await _videoGenerator.generate(
            source,
            relativePath,
            resourceId,
          );
          break;
        case ResourceType.pdf:
        case ResourceType.archive:
          // TODO: 实现 PDF 和压缩包缩略图生成器
          thumbPath = null;
          break;
      }

      if (thumbPath != null) {
        // 读取生成的缩略图字节并存入缓存
        final bytes = await File(thumbPath).readAsBytes();
        await _cacheService.put(resourceId, bytes);
        thumbPath = await _cacheService.get(resourceId);
      }

      return Ok(thumbPath);
    } catch (e) {
      return Err(DatabaseError('生成缩略图失败', cause: e));
    }
  }

  /// 获取缩略图路径
  ///
  /// 从缓存中获取，返回路径或 null。
  Future<Result<String?>> get(String resourceId) async {
    try {
      final path = await _cacheService.get(resourceId);
      return Ok(path);
    } catch (e) {
      return Err(DatabaseError('获取缩略图失败', cause: e));
    }
  }

  /// 删除指定缩略图
  Future<Result<void>> delete(String resourceId) async {
    try {
      await _cacheService.delete(resourceId);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('删除缩略图失败', cause: e));
    }
  }

  /// 获取缓存大小
  Future<Result<int>> getCacheSize() async {
    try {
      final size = await _cacheService.getSize();
      return Ok(size);
    } catch (e) {
      return Err(DatabaseError('获取缓存大小失败', cause: e));
    }
  }

  /// 清理所有缓存
  Future<Result<void>> clearCache() async {
    try {
      await _cacheService.clearCache();
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('清理缓存失败', cause: e));
    }
  }
}
