import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../domain/core/result.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/file_entry.dart';
import '../../shared/file_source/file_source.dart';
import '../../shared/thumbnail/thumbnail_generator.dart';
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

  /// 文件浏览器预览。
  ///
  /// 缩略图按“数据源 + 路径 + 修改时间 + 大小”写入磁盘 LRU 缓存。
  /// 同一文件再次预览只读取已压缩字节，文件变更后缓存键自动变化。
  Future<Result<Uint8List?>> preview(FileSource source, FileEntry entry) async {
    try {
      final cacheKey = _previewCacheKey(source.sourceId, entry);
      final cachedPath = await _cacheService.get(cacheKey);
      if (cachedPath != null) {
        return Ok(await File(cachedPath).readAsBytes());
      }

      final Uint8List? bytes;
      if (entry.isDirectory) {
        bytes = await _previewDirectory(source, entry.path);
      } else {
        final extension = p.extension(entry.name).toLowerCase();
        if (_imageExtensions.contains(extension)) {
          bytes = await _previewImage(source, entry.path);
        } else if (_videoExtensions.contains(extension)) {
          bytes = await _videoGenerator.generatePreview(source, entry.path);
        } else {
          bytes = null;
        }
      }
      if (bytes != null) await _cacheService.put(cacheKey, bytes);
      return Ok(bytes);
    } catch (error) {
      return Err(
        MediaLoadError('生成文件预览失败', cause: error, mediaType: MediaType.image),
      );
    }
  }

  static String _previewCacheKey(String sourceId, FileEntry entry) {
    final fingerprint = [
      sourceId,
      entry.path,
      entry.modifiedAt?.toUtc().microsecondsSinceEpoch ?? 0,
      entry.size ?? BigInt.zero,
    ].join('|');
    // 缓存版本变更时自动绕过旧的缩略图。
    return 'preview_v2_${sha256.convert(utf8.encode(fingerprint))}';
  }

  /// 读取原图 → Isolate 内压缩 → 返回小尺寸预览字节
  Future<Uint8List?> _previewImage(FileSource source, String path) async {
    final bytes = await source.readFile(path);
    final compressed = await Isolate.run(() => _compressPreview(bytes));
    return compressed;
  }

  /// 在 Isolate 中压缩图片到统一缩略图尺寸
  static Uint8List? _compressPreview(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    // GIF/WebP 可能包含多帧。缩略图只取已合成的第一帧，
    // noAnimation 防止 resize/crop 继续处理整个动画帧列表。
    final image = img.Image.from(decoded.getFrame(0), noAnimation: true);
    final scale = max(
      ThumbnailGenerator.thumbWidth / image.width,
      ThumbnailGenerator.thumbHeight / image.height,
    );
    final scaledWidth = (image.width * scale).round();
    final scaledHeight = (image.height * scale).round();
    var scaled = img.copyResize(
      image,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );
    // 居中裁剪
    final cropX = (scaledWidth - ThumbnailGenerator.thumbWidth) ~/ 2;
    final cropY = (scaledHeight - ThumbnailGenerator.thumbHeight) ~/ 2;
    scaled = img.copyCrop(
      scaled,
      x: cropX,
      y: cropY,
      width: ThumbnailGenerator.thumbWidth,
      height: ThumbnailGenerator.thumbHeight,
    );
    return Uint8List.fromList(
      img.encodeJpg(scaled, quality: ThumbnailGenerator.jpegQuality),
    );
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
        return _previewImage(source, entry.path);
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
