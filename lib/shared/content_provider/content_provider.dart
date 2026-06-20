import 'dart:typed_data';

/// 查看器内容提供器抽象接口
///
/// 统一图片/PDF/压缩包的翻页体验，使 ViewerPage 不感知底层格式。
/// 视频不走此接口，由 ViewerViewModel 直接管理 media_kit Player。
abstract class ContentProvider {
  /// 总页数
  int get pageCount;

  /// 加载指定页的内容
  ///
  /// [index] 页码索引（从 0 开始）。
  /// 返回图片字节数据，供 Image.memory() 显示。
  Future<Uint8List> loadPage(int index);

  /// 释放资源（文件句柄、内存缓存等）
  Future<void> dispose();
}
