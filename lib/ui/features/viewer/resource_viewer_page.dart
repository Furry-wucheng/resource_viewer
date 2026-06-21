import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/resource.dart' as domain;
import '../../../shared/content_provider/image_folder_provider.dart';
import '../../../shared/file_source/file_source_factory.dart';
import '../../features/home/view_models/home_view_model.dart'
    show favoriteTagId;
import 'viewer_page.dart';
import 'video_viewer_page.dart';

/// 资源查看器页面
///
/// 根据 resourceId 查找资源和数据源，创建 ContentProvider，打开 ViewerPage。
class ResourceViewerPage extends StatefulWidget {
  const ResourceViewerPage({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<ResourceViewerPage> createState() => _ResourceViewerPageState();
}

class _ResourceViewerPageState extends State<ResourceViewerPage> {
  bool _loading = true;
  String? _error;
  Widget? _viewer;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final resourceRepo = context.read<ResourceRepository>();
    final sourceRepo = context.read<SourceRepository>();
    final fileSourceFactory = context.read<FileSourceFactory>();
    final tagRepo = context.read<TagRepository>();

    // 查找资源
    final resourceResult = await resourceRepo.getResourceById(
      widget.resourceId,
    );
    final resource = switch (resourceResult) {
      Ok(:final value) => value,
      Err(:final error) => _fail(error.message),
    };
    if (resource == null) return;

    // 查找数据源
    final sourceResult = await sourceRepo.getSourceById(resource.sourceId);
    final source = switch (sourceResult) {
      Ok(:final value) => value,
      Err(:final error) => _fail(error.message),
    };
    if (source == null) return;

    // 加载收藏状态
    final tagsResult = await tagRepo.getTagsForResource(widget.resourceId);
    _isFavorited = switch (tagsResult) {
      Ok(:final value) => value.any((t) => t.id == favoriteTagId),
      Err() => false,
    };

    // 创建 FileSource
    final fileSource = fileSourceFactory.create(source);

    // 根据资源类型创建 ContentProvider
    if (resource.type == domain.ResourceType.folder) {
      final provider = ImageFolderProvider(
        fileSource: fileSource,
        folderPath: resource.relativePath,
      );
      await provider.load();
      if (!mounted) {
        await provider.dispose();
        return;
      }
      if (provider.pageCount == 0) {
        await provider.dispose();
        _fail('资源内没有支持的图片');
        return;
      }
      _showViewer(
        ViewerPage(
          title: resource.name,
          contentProvider: provider,
          resourceId: widget.resourceId,
          isFavorited: _isFavorited,
          onFavoriteTap: _toggleFavorite,
        ),
      );
    } else if (resource.type == domain.ResourceType.video) {
      if (!mounted) return;
      _showViewer(
        VideoViewerPage(
          title: resource.name,
          filePath: p.join(source.rootPath, resource.relativePath),
          isFavorited: _isFavorited,
          onFavoriteTap: _toggleFavorite,
        ),
      );
    } else {
      _fail('暂不支持此资源类型');
    }
  }

  Future<void> _toggleFavorite() async {
    final tagRepo = context.read<TagRepository>();

    if (_isFavorited) {
      final result = await tagRepo.removeTagFromResource(
        widget.resourceId,
        favoriteTagId,
      );
      if (result is Ok) {
        setState(() => _isFavorited = false);
      }
    } else {
      final result = await tagRepo.addTagToResource(
        widget.resourceId,
        favoriteTagId,
      );
      if (result is Ok) {
        setState(() => _isFavorited = true);
      }
    }
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

  void _showViewer(Widget viewer) {
    if (!mounted) return;
    setState(() {
      _viewer = viewer;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewer = _viewer;
    if (viewer != null) return viewer;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('资源查看')),
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
