import '../file_source/file_source.dart';

/// 缩略图生成器抽象接口
///
/// 按资源类型路由到不同缩略图生成器：
/// - [ImageThumbnailGenerator] — 图片文件夹取第一张图
/// - [PdfThumbnailGenerator] — PDF 渲染第一页
/// - [ArchiveThumbnailGenerator] — 压缩包读取首图
/// - [VideoThumbnailGenerator] — media_kit 截图
abstract class ThumbnailGenerator {
  /// 缩略图宽度（统一常量，所有生成器和预览共用）
  static const thumbWidth = 180;

  /// 缩略图高度
  static const thumbHeight = 270;

  /// JPEG 编码质量
  static const jpegQuality = 85;

  /// 生成缩略图
  ///
  /// [source] 文件源
  /// [relativePath] 资源相对于源根目录的路径
  /// [resourceId] 用作稳定的磁盘缓存键
  ///
  /// 返回生成的缩略图文件路径，失败时返回 null（使用占位图）。
  Future<String?> generate(
    FileSource source,
    String relativePath,
    String resourceId,
  );
}
