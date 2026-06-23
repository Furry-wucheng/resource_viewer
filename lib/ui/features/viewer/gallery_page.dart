import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/organization_repository.dart';
import '../../../data/repositories/thumbnail_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/file_entry.dart';
import '../../../domain/models/resource.dart';
import '../../../shared/file_source/file_source.dart';
import '../../core/view_models/base_view_model.dart' show UiState;
import '../../features/sources/widgets/file_grid_view.dart';
import 'file_sequence_viewer_page.dart';
import 'view_models/gallery_view_model.dart';
import 'widgets/org_mode_switcher.dart';

/// 画廊模式页面 — 与 design/flat-grid.html 布局一致
///
/// 递归展开所有子文件夹的全部兼容文件到一个大网格。
class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.resource,
    required this.fileSource,
  });

  final Resource resource;
  final FileSource fileSource;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final GalleryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GalleryViewModel(
      resource: widget.resource,
      fileSource: widget.fileSource,
      thumbnailRepository: context.read<ThumbnailRepository>(),
      organizationRepository: context.read<OrganizationRepository>(),
    );
    _viewModel.addListener(_onChanged);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _switchOrgMode(OrganizationMode mode) async {
    if (mode == widget.resource.organizationMode) return;
    final repo = context.read<ResourceRepository>();
    await repo.updateResource(widget.resource.copyWith(organizationMode: mode));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.resource.name),
        actions: [
          OrgModeSwitcher(
            currentMode: widget.resource.organizationMode,
            onModeChanged: _switchOrgMode,
            chapterEnabled: _viewModel.supportsChapterMode,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_viewModel.totalFileCount} 个文件',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: _viewModel.state == UiState.loading
          ? const Center(child: CircularProgressIndicator())
          : _viewModel.state == UiState.error
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_viewModel.allFiles.isEmpty) {
      return const Center(child: Text('画廊中没有可查看的文件'));
    }

    Future<Uint8List?> loadThumb(FileEntry entry) async {
      final result = await context.read<ThumbnailRepository>().preview(
        widget.fileSource,
        entry,
      );
      return switch (result) {
        Ok(:final value) => value,
        Err() => null,
      };
    }

    return FileGridView(
      entries: _viewModel.allFiles,
      onTap: _onFileTap,
      thumbnailLoader: loadThumb,
    );
  }

  void _onFileTap(FileEntry entry) {
    final idx = _viewModel.allFiles.indexWhere((e) => e.path == entry.path);
    if (idx < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileSequenceViewerPage(
          fileSource: widget.fileSource,
          localRootPath: '',
          entries: _viewModel.allFiles,
          initialIndex: idx,
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_viewModel.errorMessage ?? '加载失败'),
        if (_viewModel.canRetry) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _viewModel.retry, child: const Text('重试')),
        ],
      ],
    ),
  );
}
