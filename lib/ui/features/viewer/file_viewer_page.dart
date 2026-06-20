import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../domain/models/file_entry.dart';
import '../../../shared/file_source/file_source_factory.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../data/repositories/filesystem_repository.dart';
import '../../../domain/core/result.dart';
import 'file_sequence_viewer_page.dart';

/// 文件查看器页面
///
/// 从文件浏览器打开，根据文件类型创建对应的 ContentProvider。
class FileViewerPage extends StatefulWidget {
  const FileViewerPage({
    super.key,
    required this.sourceId,
    required this.entry,
    required this.sourceName,
  });

  final String sourceId;
  final FileEntry entry;
  final String sourceName;

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class FileViewerRequest {
  const FileViewerRequest({required this.entry, required this.sourceName});

  final FileEntry entry;
  final String sourceName;
}

class _FileViewerPageState extends State<FileViewerPage> {
  bool _loading = true;
  String? _error;
  Widget? _viewer;

  @override
  void initState() {
    super.initState();
    _openViewer();
  }

  Future<void> _openViewer() async {
    final fileSourceFactory = context.read<FileSourceFactory>();
    final sourceRepository = context.read<SourceRepository>();
    final filesystemRepository = context.read<FilesystemRepository>();
    final sourceResult = await sourceRepository.getSourceById(widget.sourceId);
    final source = switch (sourceResult) {
      Ok(:final value) => value,
      Err(:final error) => _fail(error.message),
    };
    if (source == null) return;
    final fileSource = fileSourceFactory.create(source);

    // 文件浏览器查看始终以当前目录的同层级兼容媒体为上下文。
    final normalizedPath = widget.entry.path.replaceAll('\\', '/');
    final directoryPath = widget.entry.isDirectory
        ? normalizedPath
        : (p.posix.dirname(normalizedPath) == '.'
              ? ''
              : p.posix.dirname(normalizedPath));
    final listResult = await filesystemRepository.listDirectory(
      widget.sourceId,
      directoryPath,
    );
    final entries = switch (listResult) {
      Ok(:final value) => value.where(_isViewableMedia).toList(),
      Err(:final error) => _fail(error.message),
    };
    if (entries == null || !mounted) return;
    if (entries.isEmpty) {
      _fail('当前目录没有可查看的图片或视频');
      return;
    }
    final requestedPath = widget.entry.isDirectory
        ? entries.first.path
        : normalizedPath;
    final initialIndex = entries.indexWhere(
      (entry) => entry.path == requestedPath,
    );
    _showViewer(
      FileSequenceViewerPage(
        fileSource: fileSource,
        localRootPath: source.rootPath,
        entries: entries,
        initialIndex: initialIndex < 0 ? 0 : initialIndex,
      ),
    );
  }

  void _showViewer(Widget viewer) {
    if (!mounted) return;
    setState(() {
      _viewer = viewer;
      _loading = false;
      _error = null;
    });
  }

  dynamic _fail(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _loading = false;
      });
    }
    return null;
  }

  bool _isViewableMedia(FileEntry entry) {
    if (entry.isDirectory) return false;
    return const {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.tiff',
      '.tif',
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

  @override
  Widget build(BuildContext context) {
    final viewer = _viewer;
    if (viewer != null) return viewer;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('文件查看')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? '未知错误'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
