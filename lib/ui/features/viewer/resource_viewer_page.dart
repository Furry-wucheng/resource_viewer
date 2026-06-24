import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/organization_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/resource.dart' as domain;
import '../../../domain/use_cases/detect_organization_mode_use_case.dart';
import '../../../shared/content_provider/image_folder_provider.dart';
import '../../../shared/content_provider/pdf_provider.dart';
import '../../../shared/content_provider/video_media_source.dart';
import '../../../shared/file_source/file_source.dart';
import '../../../shared/file_source/file_source_factory.dart';
import '../../../shared/file_source/local_file_source.dart';
import '../../features/home/view_models/home_view_model.dart'
    show favoriteTagId;
import 'chapter_list_page.dart';
import 'flat_grid_page.dart';
import 'gallery_page.dart';
import 'viewer_page.dart';
import 'video_viewer_page.dart';

/// 资源查看器页面（路由分发中心）
class ResourceViewerPage extends StatefulWidget {
  const ResourceViewerPage({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<ResourceViewerPage> createState() => _ResourceViewerPageState();
}

class _ResourceViewerPageState extends State<ResourceViewerPage> {
  bool _loading = true;
  String? _error;
  bool _isFavorited = false;

  /// 缓存的数据源根路径
  String? _sourceRootPath;

  /// 防止递归重新分发
  bool _dispatching = false;

  /// 上次使用的组织模式（用于检测变化）
  domain.OrganizationMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    if (_dispatching) return; // 防止递归
    _dispatching = true;
    setState(() {
      _loading = true;
      _error = null;
    });

    final resourceRepo = context.read<ResourceRepository>();
    final sourceRepo = context.read<SourceRepository>();
    final fileSourceFactory = context.read<FileSourceFactory>();
    final tagRepo = context.read<TagRepository>();
    final organizationRepo = context.read<OrganizationRepository>();

    final resourceResult = await resourceRepo.getResourceById(
      widget.resourceId,
    );
    var resource = switch (resourceResult) {
      Ok(:final value) => value,
      Err(:final error) => _fail(error.message),
    };
    if (resource == null) return;

    final sourceResult = await sourceRepo.getSourceById(resource.sourceId);
    final source = switch (sourceResult) {
      Ok(:final value) => value,
      Err(:final error) => _fail(error.message),
    };
    if (source == null) return;

    final tagsResult = await tagRepo.getTagsForResource(widget.resourceId);
    _isFavorited = switch (tagsResult) {
      Ok(:final value) => value.any((t) => t.id == favoriteTagId),
      Err() => false,
    };

    final fileSource = await fileSourceFactory.createAsync(source);
    _sourceRootPath = source.rootPath;

    var organizationMode = resource.organizationMode;
    if (organizationMode == null) {
      final detectUseCase = DetectOrganizationModeUseCase();
      organizationMode = await detectUseCase(fileSource, resource.relativePath);
      final updated = resource.copyWith(organizationMode: organizationMode);
      await resourceRepo.updateResource(updated);
      resource = updated;
    }

    if (organizationMode == domain.OrganizationMode.chapter ||
        organizationMode == domain.OrganizationMode.chapterGallery) {
      final supportResult = await organizationRepo.hasSubdirectories(
        fileSource,
        resource.relativePath,
      );
      final supportsChapter = switch (supportResult) {
        Ok(:final value) => value,
        Err() => false,
      };
      if (!supportsChapter) {
        organizationMode = domain.OrganizationMode.flatgrid;
        resource = resource.copyWith(organizationMode: organizationMode);
        await resourceRepo.updateResource(resource);
      }
    }

    if (!mounted) {
      _dispatching = false;
      return;
    }

    _lastMode = organizationMode;

    switch (organizationMode) {
      case domain.OrganizationMode.chapter:
      case domain.OrganizationMode.chapterGallery:
        await _pushChapterList(resource, fileSource);
      case domain.OrganizationMode.flatgrid:
        await _pushFlatGrid(resource, fileSource);
      case domain.OrganizationMode.gallery:
        await _pushGallery(resource, fileSource);
      case domain.OrganizationMode.direct:
        await _showDirect(resource, fileSource);
    }

    _dispatching = false;

    // When sub-page pops, check if mode changed and re-dispatch
    if (!mounted) return;
    final updatedResult = await resourceRepo.getResourceById(widget.resourceId);
    final updated = switch (updatedResult) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (updated != null && updated.organizationMode != _lastMode) {
      await _loadAndNavigate();
      return;
    }

    // ResourceViewerPage is only a dispatcher. Once the selected mode page
    // closes, close the dispatcher as well instead of exposing its spinner.
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pushChapterList(domain.Resource resource, fileSource) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _buildChapterListPage(resource, fileSource),
      ),
    );
  }

  Widget _buildChapterListPage(domain.Resource resource, fileSource) {
    return ChapterListPage(resource: resource, fileSource: fileSource);
  }

  Future<void> _pushFlatGrid(domain.Resource resource, fileSource) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FlatGridPage(resource: resource, fileSource: fileSource),
      ),
    );
  }

  Future<void> _pushGallery(domain.Resource resource, fileSource) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryPage(resource: resource, fileSource: fileSource),
      ),
    );
  }

  Future<void> _showDirect(domain.Resource resource, fileSource) async {
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
      await _showViewerWidget(
        ViewerPage(
          title: resource.name,
          contentProvider: provider,
          resourceId: widget.resourceId,
          isFavorited: _isFavorited,
          onFavoriteTap: _toggleFavorite,
        ),
      );
    } else if (resource.type == domain.ResourceType.pdf) {
      final provider = PdfProvider(
        fileSource: fileSource,
        filePath: resource.relativePath,
      );
      try {
        await provider.init();
      } on MediaEncryptedError {
        if (mounted) _fail('此 PDF 已加密，暂不支持查看');
        await provider.dispose();
        return;
      } catch (e) {
        if (mounted) _fail('PDF 加载失败: $e');
        await provider.dispose();
        return;
      }
      if (!mounted) {
        await provider.dispose();
        return;
      }
      await _showViewerWidget(
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
      await _showViewerWidget(
        VideoViewerPage(
          title: resource.name,
          videoSource: await _videoSource(resource, fileSource),
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
      if (result is Ok && mounted) setState(() => _isFavorited = false);
    } else {
      final result = await tagRepo.addTagToResource(
        widget.resourceId,
        favoriteTagId,
      );
      if (result is Ok && mounted) setState(() => _isFavorited = true);
    }
  }

  Future<VideoMediaSource> _videoSource(
    domain.Resource resource,
    FileSource fileSource,
  ) async {
    if (fileSource is LocalFileSource) {
      final rootPath = _sourceRootPath ?? fileSource.rootPath;
      return VideoMediaSource.localFile(
        p.join(rootPath, resource.relativePath),
      );
    }

    final size =
        resource.fileSize?.toInt() ??
        await _statSize(fileSource, resource.relativePath);
    return VideoMediaSource.proxiedFile(
      fileSource: fileSource,
      relativePath: resource.relativePath,
      fileSize: size,
    );
  }

  Future<int> _statSize(FileSource fileSource, String relativePath) async {
    final entry = await fileSource.stat(relativePath);
    return entry?.size?.toInt() ?? 0;
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

  Future<void> _showViewerWidget(Widget viewer) async {
    if (!mounted) return;
    setState(() => _loading = false);
    // Push viewer and wait for it to pop
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => viewer));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('资源查看')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
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
    // Loading indicator while dispatching
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
