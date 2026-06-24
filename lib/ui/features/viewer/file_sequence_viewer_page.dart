import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../domain/models/file_entry.dart';
import '../../../shared/content_provider/video_media_source.dart';
import '../../../shared/content_provider/viewer_media_item.dart';
import '../../../shared/file_source/file_source.dart';
import '../../../shared/file_source/local_file_source.dart';
import '../../../shared/media/media_file_types.dart';
import 'viewer_page.dart';

/// 文件浏览器上下文适配器；实际 UI 与资源库共用 [ViewerPage]。
class FileSequenceViewerPage extends StatelessWidget {
  const FileSequenceViewerPage({
    super.key,
    required this.fileSource,
    required this.localRootPath,
    required this.entries,
    required this.initialIndex,
  });

  final FileSource fileSource;
  final String localRootPath;
  final List<FileEntry> entries;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final items = entries.map((entry) {
      if (_isVideo(entry)) {
        return ViewerMediaItem.video(
          title: entry.name,
          videoSource: _videoSource(entry),
        );
      }
      return ViewerMediaItem.image(
        title: entry.name,
        loadImage: () => fileSource.readFile(entry.path),
      );
    }).toList();
    return ViewerPage.media(
      title: entries[initialIndex].name,
      items: items,
      initialPage: initialIndex,
    );
  }

  VideoMediaSource _videoSource(FileEntry entry) {
    final source = fileSource;
    if (source is LocalFileSource) {
      final rootPath = localRootPath.isEmpty ? source.rootPath : localRootPath;
      return VideoMediaSource.localFile(p.join(rootPath, entry.path));
    }
    return VideoMediaSource.proxiedFile(
      fileSource: fileSource,
      relativePath: entry.path,
      fileSize: entry.size?.toInt() ?? 0,
    );
  }

  bool _isVideo(FileEntry entry) => MediaFileTypes.isVideo(entry.name);
}
