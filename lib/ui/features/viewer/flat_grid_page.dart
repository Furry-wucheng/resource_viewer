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
import 'view_models/flat_grid_view_model.dart';
import 'widgets/org_mode_switcher.dart';

/// 平铺网格页 — 与 design/flat-grid.html 一致
///
/// 仅网格视图，无列表模式。文件夹下钻仅靠返回键。
class FlatGridPage extends StatefulWidget {
  const FlatGridPage({
    super.key,
    required this.resource,
    required this.fileSource,
  });

  final Resource resource;
  final FileSource fileSource;

  @override
  State<FlatGridPage> createState() => _FlatGridPageState();
}

class _FlatGridPageState extends State<FlatGridPage> {
  late final FlatGridViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FlatGridViewModel(
      resource: widget.resource,
      fileSource: widget.fileSource,
      thumbnailRepository: context.read<ThumbnailRepository>(),
      organizationRepository: context.read<OrganizationRepository>(),
    );
    _viewModel.addListener(_onChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    final autoEnter = await FlatGridViewModel.loadAutoEnterLeafFolder();
    await _viewModel.init();
    if (!mounted || !autoEnter || !_viewModel.hasOnlyFiles) return;
    final first = _viewModel.entries.firstOrNull;
    if (first != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFile(first);
      });
    }
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

  Future<Uint8List?> _loadThumb(FileEntry entry) async {
    final result = await context.read<ThumbnailRepository>().preview(
      widget.fileSource,
      entry,
    );
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _viewModel.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _viewModel.goBack(),
              )
            : IconButton(
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
    if (_viewModel.entries.isEmpty) {
      return const Center(child: Text('此目录没有可查看的文件'));
    }
    return FileGridView(
      entries: _viewModel.entries,
      onTap: _onFileTap,
      thumbnailLoader: _loadThumb,
    );
  }

  void _onFileTap(FileEntry entry) {
    if (entry.isDirectory) {
      _viewModel.enterDirectory(entry.name);
      return;
    }
    _openFile(entry);
  }

  void _openFile(FileEntry entry) {
    final viewable = _viewModel.entries.where((e) => !e.isDirectory).toList();
    final idx = viewable.indexWhere((e) => e.path == entry.path);
    if (idx < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileSequenceViewerPage(
          fileSource: widget.fileSource,
          localRootPath: '',
          entries: viewable,
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
        if (_viewModel.canRetry)
          TextButton(onPressed: _viewModel.retry, child: const Text('重试')),
      ],
    ),
  );
}
