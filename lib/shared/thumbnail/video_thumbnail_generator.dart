import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../file_source/file_source.dart';
import 'thumbnail_generator.dart';

/// 视频缩略图生成器
///
/// 使用 media_kit 截取视频首帧作为缩略图。
class VideoThumbnailGenerator implements ThumbnailGenerator {
  /// 缩略图宽度
  static const thumbWidth = 180;

  /// 缩略图高度
  static const thumbHeight = 270;

  /// 自定义输出目录（为 null 时使用系统缓存目录）
  final String? outputDirectory;

  VideoThumbnailGenerator({this.outputDirectory});

  @override
  Future<String?> generate(
    FileSource source,
    String relativePath,
    String resourceId,
  ) async {
    Player? player;
    try {
      // 对于本地文件，直接使用绝对路径
      // 对于远程源，需要先获取可访问的路径
      final absolutePath = _resolveAbsolutePath(source, relativePath);
      if (absolutePath == null) return null;

      // 创建 Player
      player = Player();

      // 打开视频文件
      await player.open(Media(absolutePath));

      // 等待视频加载完成
      await Future.delayed(const Duration(seconds: 2));

      // 截取当前帧（首帧）
      final screenshotBytes = await player.screenshot();

      if (screenshotBytes == null || screenshotBytes.isEmpty) return null;

      // 解码截取的图片
      final screenshotImage = img.decodeImage(screenshotBytes);
      if (screenshotImage == null) return null;

      // 缩放至缩略图尺寸
      final thumbnail = _resizeAndCrop(screenshotImage, thumbWidth, thumbHeight);

      // 编码为 JPEG
      final thumbBytes = img.encodeJpg(thumbnail, quality: 85);

      // 确定输出目录
      String thumbPath;
      if (outputDirectory != null) {
        thumbPath = p.join(outputDirectory!, 'thumbs');
      } else {
        final cacheDir = await getApplicationCacheDirectory();
        thumbPath = p.join(cacheDir.path, 'thumbs');
      }
      await Directory(thumbPath).create(recursive: true);

      // 写入缩略图文件
      final thumbFile = File(p.join(thumbPath, 'thumb_$resourceId.jpg'));
      await thumbFile.writeAsBytes(thumbBytes);

      return thumbFile.path;
    } catch (_) {
      return null;
    } finally {
      await player?.dispose();
    }
  }

  /// 解析绝对路径
  String? _resolveAbsolutePath(FileSource source, String relativePath) {
    // 对于 LocalFileSource，我们可以尝试直接构造路径
    // 这里使用一个简单的方法：如果 source 有 rootPath 属性就用它
    // 否则返回 null（远程源需要其他方式）
    try {
      // 使用 dynamic 调用以避免类型依赖
      final rootPath = (source as dynamic).rootPath as String?;
      if (rootPath != null) {
        return p.join(rootPath, relativePath);
      }
    } catch (_) {
      // 不是 LocalFileSource，无法直接获取路径
    }
    return null;
  }

  /// 缩放并裁剪图片到目标尺寸（居中裁剪）
  img.Image _resizeAndCrop(img.Image source, int targetWidth, int targetHeight) {
    final sourceWidth = source.width;
    final sourceHeight = source.height;

    final scaleX = targetWidth / sourceWidth;
    final scaleY = targetHeight / sourceHeight;
    final scale = max(scaleX, scaleY);

    final scaledWidth = (sourceWidth * scale).round();
    final scaledHeight = (sourceHeight * scale).round();

    final scaled = img.copyResize(
      source,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );

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
