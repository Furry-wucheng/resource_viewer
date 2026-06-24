import 'dart:typed_data';

import 'video_media_source.dart';

enum ViewerMediaType { image, video }

/// 统一查看器的一页内容；入口只负责构建列表，查看器负责统一渲染。
class ViewerMediaItem {
  const ViewerMediaItem.image({required this.title, required this.loadImage})
    : type = ViewerMediaType.image,
      videoSource = null;

  const ViewerMediaItem.video({required this.title, required this.videoSource})
    : type = ViewerMediaType.video,
      loadImage = null;

  final String title;
  final ViewerMediaType type;
  final Future<Uint8List> Function()? loadImage;
  final VideoMediaSource? videoSource;
}
