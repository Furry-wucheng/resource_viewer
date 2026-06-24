import 'package:flutter/material.dart';

import '../../../shared/content_provider/video_media_source.dart';
import '../../../shared/content_provider/viewer_media_item.dart';
import 'viewer_page.dart';

/// 单视频资源入口适配器；实际 UI 与图片、文件浏览器共用 [ViewerPage]。
class VideoViewerPage extends StatelessWidget {
  const VideoViewerPage({
    super.key,
    required this.title,
    required this.videoSource,
    this.isFavorited = false,
    this.onFavoriteTap,
  });

  final String title;
  final VideoMediaSource videoSource;
  final bool isFavorited;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return ViewerPage.media(
      title: title,
      items: [ViewerMediaItem.video(title: title, videoSource: videoSource)],
      isFavorited: isFavorited,
      onFavoriteTap: onFavoriteTap,
    );
  }
}
