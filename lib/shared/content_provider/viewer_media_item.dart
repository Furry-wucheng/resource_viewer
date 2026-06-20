import 'dart:typed_data';

enum ViewerMediaType { image, video }

/// 统一查看器的一页内容；入口只负责构建列表，查看器负责统一渲染。
class ViewerMediaItem {
  const ViewerMediaItem.image({required this.title, required this.loadImage})
    : type = ViewerMediaType.image,
      videoPath = null;

  const ViewerMediaItem.video({required this.title, required this.videoPath})
    : type = ViewerMediaType.video,
      loadImage = null;

  final String title;
  final ViewerMediaType type;
  final Future<Uint8List> Function()? loadImage;
  final String? videoPath;
}
