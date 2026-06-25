import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../data/services/pdf_render_service.dart';
import '../file_source/file_source.dart';
import 'isolate_pool.dart';
import 'thumbnail_generator.dart';

/// PDF 缩略图生成器
///
/// 渲染 PDF 第一页为 2:3 竖版缩略图（180×270）。
/// 加密 PDF 返回 null（使用占位图）。
class PdfThumbnailGenerator implements ThumbnailGenerator {
  PdfThumbnailGenerator({PdfRenderService? renderService, this.outputDirectory})
    : _renderService = renderService ?? PdfRenderService();

  final PdfRenderService _renderService;
  final String? outputDirectory;

  Future<Uint8List?> generatePreview(
    FileSource source,
    String relativePath,
  ) async {
    try {
      final bytes = await source.readFile(relativePath);
      final document = await PdfDocument.openData(bytes);

      try {
        if (document.isEncrypted || document.pages.isEmpty) {
          return null;
        }

        final pngBytes = await _renderService.renderThumbnail(
          document,
          ThumbnailGenerator.thumbWidth * 2,
          ThumbnailGenerator.thumbHeight * 2,
        );
        if (pngBytes == null) return null;

        return IsolatePool.instance.run(_resizeAndCropToJpg, pngBytes);
      } finally {
        await document.dispose();
      }
    } on PdfException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> generate(
    FileSource source,
    String relativePath,
    String resourceId,
  ) async {
    try {
      final thumbBytes = await generatePreview(source, relativePath);
      if (thumbBytes == null) return null;

      final outDir = outputDirectory;
      final thumbDir = outDir != null
          ? p.join(outDir, 'thumbs')
          : p.join((await getApplicationCacheDirectory()).path, 'thumbs');
      await Directory(thumbDir).create(recursive: true);

      final thumbFile = File(p.join(thumbDir, 'thumb_$resourceId.jpg'));
      await thumbFile.writeAsBytes(thumbBytes);

      return thumbFile.path;
    } catch (_) {
      return null;
    }
  }

  /// 在 Isolate 中将 PNG 字节缩放裁剪为 JPEG 缩略图
  static Uint8List? _resizeAndCropToJpg(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) return null;

    final thumbnail = _resizeAndCrop(
      decoded,
      ThumbnailGenerator.thumbWidth,
      ThumbnailGenerator.thumbHeight,
    );

    return Uint8List.fromList(
      img.encodeJpg(thumbnail, quality: ThumbnailGenerator.jpegQuality),
    );
  }

  /// 缩放并裁剪图片到目标尺寸（居中裁剪）
  static img.Image _resizeAndCrop(
    img.Image source,
    int targetWidth,
    int targetHeight,
  ) {
    final sourceWidth = source.width;
    final sourceHeight = source.height;

    final scaleX = targetWidth / sourceWidth;
    final scaleY = targetHeight / sourceHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;

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
