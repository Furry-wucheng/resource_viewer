import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

/// PDF 渲染服务
///
/// 封装 pdfrx，提供 PDF 文档的逐页渲染能力。
/// 每页渲染为 PNG 字节数据，供 PdfProvider 使用。
class PdfRenderService {
  /// 打开 PDF 文档（从字节数据）
  ///
  /// [bytes] PDF 文件原始字节。
  /// [sourceName] 用于标识文档来源的唯一名称。
  ///
  /// 如果 PDF 已加密，可通过 [PdfDocument.isEncrypted] 检测。
  Future<PdfDocument> openFromBytes(
    Uint8List bytes, {
    String sourceName = '',
  }) async {
    return PdfDocument.openData(bytes, sourceName: sourceName);
  }

  /// 获取 PDF 页数
  int pageCount(PdfDocument document) {
    return document.pages.length;
  }

  /// 检测 PDF 是否加密
  bool isEncrypted(PdfDocument document) {
    return document.isEncrypted;
  }

  /// 渲染指定页为 PNG 图片
  ///
  /// [document] 已打开的 PDF 文档
  /// [pageIndex] 页码索引（从 0 开始）
  /// [displayWidth] 显示宽度（逻辑像素），用于控制渲染分辨率
  /// [displayHeight] 显示高度（逻辑像素）
  ///
  /// 返回 PNG 格式的图片字节。
  Future<Uint8List> renderPage(
    PdfDocument document,
    int pageIndex, {
    int? displayWidth,
    int? displayHeight,
  }) async {
    final page = document.pages[pageIndex];

    // 按显示尺寸渲染，避免全分辨率浪费内存
    final width = displayWidth ?? page.width.toInt();
    final height = displayHeight ?? page.height.toInt();

    final rendered = await page.render(
      width: width,
      height: height,
      backgroundColor: 0xFFFFFFFF,
    );

    if (rendered == null) {
      throw StateError('PDF 页面渲染失败：page $pageIndex');
    }

    try {
      return _bgraToPng(rendered.pixels, rendered.width, rendered.height);
    } finally {
      rendered.dispose();
    }
  }

  /// 渲染缩略图
  ///
  /// 使用固定尺寸渲染 PDF 首页为 PNG 缩略图。
  Future<Uint8List?> renderThumbnail(
    PdfDocument document,
    int targetWidth,
    int targetHeight,
  ) async {
    if (document.pages.isEmpty) return null;

    final page = document.pages[0];
    final pageWidth = page.width.toInt();
    final pageHeight = page.height.toInt();

    if (pageWidth <= 0 || pageHeight <= 0) return null;

    // 缩放以覆盖目标尺寸
    final scaleX = targetWidth / pageWidth;
    final scaleY = targetHeight / pageHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    final rendered = await page.render(
      width: (pageWidth * scale).toInt(),
      height: (pageHeight * scale).toInt(),
      backgroundColor: 0xFFFFFFFF,
    );

    if (rendered == null) return null;

    try {
      return _bgraToPng(rendered.pixels, rendered.width, rendered.height);
    } finally {
      rendered.dispose();
    }
  }

  /// 将 BGRA8888 像素数据转换为 PNG 字节
  ///
  /// PdfImage.pixels 是 BGRA 格式，需要转换为 RGBA 再编码为 PNG。
  Uint8List _bgraToPng(Uint8List bgra, int width, int height) {
    // 转换为 RGBA
    final rgba = Uint8List(bgra.length);
    for (var i = 0; i < bgra.length; i += 4) {
      rgba[i] = bgra[i + 2]; // R
      rgba[i + 1] = bgra[i + 1]; // G
      rgba[i + 2] = bgra[i]; // B
      rgba[i + 3] = bgra[i + 3]; // A
    }

    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    return Uint8List.fromList(img.encodePng(image));
  }
}
