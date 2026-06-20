import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../file_source/file_source.dart';
import 'thumbnail_generator.dart';

/// 图片缩略图生成器
///
/// 取资源文件夹内第一张图片，缩放至 2:3 竖版缩略图（180×270）。
class ImageThumbnailGenerator implements ThumbnailGenerator {
  /// 缩略图宽度
  static const thumbWidth = 180;

  /// 缩略图高度
  static const thumbHeight = 270;

  /// 支持的图片扩展名
  static const _supportedExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp',
  };

  /// 自定义输出目录（为 null 时使用系统缓存目录）
  final String? outputDirectory;

  ImageThumbnailGenerator({this.outputDirectory});

  @override
  Future<String?> generate(
    FileSource source,
    String relativePath,
    String resourceId,
  ) async {
    try {
      // 列出目录中的文件
      final entries = await source.listDirectory(relativePath);

      // 找到第一张支持的图片
      String? firstImagePath;
      for (final entry in entries) {
        if (entry.isDirectory) continue;
        final ext = p.extension(entry.name).toLowerCase();
        if (_supportedExtensions.contains(ext)) {
          firstImagePath = entry.path;
          break;
        }
      }

      if (firstImagePath == null) return null;

      // 读取图片字节
      final imageBytes = await source.readFile(firstImagePath);

      // 解码图片
      final thumbBytes = await Isolate.run(() => _encodeThumbnail(imageBytes));
      if (thumbBytes == null) return null;

      // 确定输出目录
      String thumbPath;
      if (outputDirectory != null) {
        thumbPath = p.join(outputDirectory!, 'thumbs');
      } else {
        final cacheDir = await getApplicationCacheDirectory();
        thumbPath = p.join(cacheDir.path, 'thumbs');
      }
      await Directory(thumbPath).create(recursive: true);

      final thumbFile = File(p.join(thumbPath, 'thumb_$resourceId.jpg'));
      await thumbFile.writeAsBytes(thumbBytes);

      return thumbFile.path;
    } catch (_) {
      return null;
    }
  }

  static List<int>? _encodeThumbnail(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final thumbnail = _resizeAndCrop(image, thumbWidth, thumbHeight);
    return img.encodeJpg(thumbnail, quality: 85);
  }

  /// 缩放并裁剪图片到目标尺寸（居中裁剪）
  static img.Image _resizeAndCrop(
    img.Image source,
    int targetWidth,
    int targetHeight,
  ) {
    final sourceWidth = source.width;
    final sourceHeight = source.height;

    // 计算缩放比例，确保覆盖目标区域
    final scaleX = targetWidth / sourceWidth;
    final scaleY = targetHeight / sourceHeight;
    final scale = max(scaleX, scaleY);

    final scaledWidth = (sourceWidth * scale).round();
    final scaledHeight = (sourceHeight * scale).round();

    // 缩放
    final scaled = img.copyResize(
      source,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );

    // 居中裁剪
    final offsetX = (scaledWidth - targetWidth) ~/ 2;
    final offsetY = (scaledHeight - targetHeight) ~/ 2;

    return img.copyCrop(
      scaled,
      x: offsetX,
      y: offsetY,
      width: targetWidth,
      height: targetHeight,
    );
  }
}
