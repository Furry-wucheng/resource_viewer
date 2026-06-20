import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../domain/models/file_entry.dart';
import '../../../shared/content_provider/viewer_media_item.dart';
import '../../../shared/file_source/file_source.dart';
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
          videoPath: p.join(localRootPath, entry.path),
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

  bool _isVideo(FileEntry entry) => const {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
  }.contains(p.extension(entry.name).toLowerCase());
}
