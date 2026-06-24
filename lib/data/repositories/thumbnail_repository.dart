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
import '../../shared/media/media_file_types.dart';
import '../../shared/thumbnail/thumbnail_generator.dart';
import '../../shared/thumbnail/image_thumbnail_generator.dart';
import '../../shared/thumbnail/video_thumbnail_generator.dart';
import '../../shared/thumbnail/pdf_thumbnail_generator.dart';
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
  late final PdfThumbnailGenerator _pdfGenerator = PdfThumbnailGenerator(
    outputDirectory: _imageGenerator.outputDirectory,
  );

  static const _smallImageByteLimit = 512 * 1024;

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
        if (MediaFileTypes.isImage(entry.name)) {
          bytes = await _previewImage(source, entry.path);
        } else if (MediaFileTypes.isVideo(entry.name)) {
          bytes = await _videoGenerator.generatePreview(source, entry.path);
        } else if (MediaFileTypes.isPdf(entry.name)) {
          bytes = await _pdfGenerator.generatePreview(source, entry.path);
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
    return 'preview_v3_${sha256.convert(utf8.encode(fingerprint))}';
  }

  /// 读取原图 → Isolate 内压缩 → 返回小尺寸预览字节
  Future<Uint8List?> _previewImage(FileSource source, String path) async {
    final bytes = await source.readFile(path);
    final extension = p.extension(path).toLowerCase();
    final compressed = await Isolate.run(
      () => _compressPreview(bytes, extension),
    );
    return compressed;
  }

  /// 在 Isolate 中压缩图片到统一缩略图尺寸
  static Uint8List? _compressPreview(Uint8List bytes, String extension) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return _canFallbackToOriginalBytes(bytes, extension) ? bytes : null;
    }
    if (decoded == null) {
      return _canFallbackToOriginalBytes(bytes, extension) ? bytes : null;
    }
    // GIF/WebP 可能包含多帧。缩略图只取已合成的第一帧，
    // noAnimation 防止 resize/crop 继续处理整个动画帧列表。
    final image = img.Image.from(decoded.getFrame(0), noAnimation: true);
    if (_canUseOriginalBytes(bytes, image, extension)) return bytes;
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

  static bool _canUseOriginalBytes(
    Uint8List bytes,
    img.Image image,
    String extension,
  ) {
    if (bytes.length > _smallImageByteLimit) return false;
    if (image.width > ThumbnailGenerator.thumbWidth) return false;
    if (image.height > ThumbnailGenerator.thumbHeight) return false;
    return MediaFileTypes.canReuseOriginalPreviewBytes(extension);
  }

  static bool _canFallbackToOriginalBytes(Uint8List bytes, String extension) {
    if (bytes.length > _smallImageByteLimit) return false;
    return MediaFileTypes.canFallbackToOriginalPreviewBytes(extension);
  }

  Future<Uint8List?> _previewDirectory(
    FileSource source,
    String rootPath,
  ) async {
    String? firstVideoPath;

    final rootEntries = await source.listDirectory(rootPath);
    for (final entry in rootEntries.where((entry) => !entry.isDirectory)) {
      if (MediaFileTypes.isImage(entry.name)) {
        return _previewImage(source, entry.path);
      }
      if (firstVideoPath == null && MediaFileTypes.isVideo(entry.name)) {
        firstVideoPath = entry.path;
      }
    }

    final videoPath = firstVideoPath;
    return videoPath == null
        ? null
        : _videoGenerator.generatePreview(source, videoPath);
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
          thumbPath = await _pdfGenerator.generate(
            source,
            relativePath,
            resourceId,
          );
          break;
        case ResourceType.archive:
          // TODO: 实现压缩包缩略图生成器
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
