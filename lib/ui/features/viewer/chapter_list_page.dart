import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/thumbnail_repository.dart';
import '../../../data/repositories/organization_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/file_entry.dart';
import '../../../domain/models/resource.dart';
import '../../../shared/file_source/file_source.dart';
import '../../../shared/content_provider/image_folder_provider.dart';
import '../../../shared/organization/chapter_strategy.dart';
import '../../core/view_models/base_view_model.dart' show UiState;
import '../../core/theme/app_colors.dart';
import 'view_models/chapter_list_view_model.dart';
import 'widgets/org_mode_switcher.dart';
import 'viewer_page.dart';
import 'file_sequence_viewer_page.dart';

/// 章节列表页
///
/// 响应式双栏布局：
/// - 宽屏（≥900dp）：左侧封面面板 + 右侧章节列表
/// - 窄屏（<900dp）：封面上方，章节下方
/// 支持 grid/list 视图切换。
class ChapterListPage extends StatefulWidget {
  const ChapterListPage({
    super.key,
    required this.resource,
    required this.fileSource,
    this.onNavigateToViewer,
  });

  final Resource resource;
  final FileSource fileSource;

  /// 导航到查看器的回调（用于跨章节连续阅读）
  final void Function(Widget viewer)? onNavigateToViewer;

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  late final ChapterListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChapterListViewModel(
      resource: widget.resource,
      fileSource: widget.fileSource,
      thumbnailRepository: context.read<ThumbnailRepository>(),
      organizationRepository: context.read<OrganizationRepository>(),
    );
    _viewModel.addListener(_onChanged);
    _init();
  }

  Future<void> _init() async {
    final mode = await ChapterListViewModel.loadViewMode();
    _viewModel.applyViewMode(mode);
    await _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resource.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          OrgModeSwitcher(
            currentMode: widget.resource.organizationMode,
            onModeChanged: _switchOrgMode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _viewModel.state == UiState.loading
          ? const Center(child: CircularProgressIndicator())
          : _viewModel.state == UiState.error
          ? _buildError()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return isWide
                    ? _buildWideLayout(constraints)
                    : _buildNarrowLayout();
              },
            ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧封面面板
        SizedBox(width: 280, child: _buildCoverPanel()),
        const VerticalDivider(width: 1),
        // 右侧章节列表
        Expanded(child: _buildChapterContent()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCoverPanelCompact(),
          const Divider(height: 1),
          _buildChapterContent(),
        ],
      ),
    );
  }

  /// 宽屏封面面板
  Widget _buildCoverPanel() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 封面占位图
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.book, size: 64, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.resource.name,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '共 ${_viewModel.chapters.length} 章 · ${_viewModel.chapters.fold<int>(0, (sum, c) => sum + c.pageCount)} 页',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildViewModeToggle(theme),
        ],
      ),
    );
  }

  /// 窄屏封面区域
  Widget _buildCoverPanelCompact() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.resource.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '共 ${_viewModel.chapters.length} 章 · ${_viewModel.chapters.fold<int>(0, (sum, c) => sum + c.pageCount)} 页',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 章节内容区（章节列表 + 散落文件）
  Widget _buildChapterContent() {
    return Column(
      children: [
        Expanded(
          child: _viewModel.chapters.isEmpty && _viewModel.looseFiles.isEmpty
              ? const Center(child: Text('暂无章节'))
              : _viewModel.viewMode == ChapterViewMode.grid
              ? _buildChapterGrid()
              : _buildChapterList(),
        ),
      ],
    );
  }

  /// 网格视图
  Widget _buildChapterGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _viewModel.chapters.length + _viewModel.looseFiles.length,
      itemBuilder: (context, index) {
        if (index < _viewModel.chapters.length) {
          return _buildChapterCard(_viewModel.chapters[index]);
        }
        final fileIndex = index - _viewModel.chapters.length;
        return _buildLooseFileCard(_viewModel.looseFiles[fileIndex]);
      },
    );
  }

  /// 列表视图
  Widget _buildChapterList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount:
          _viewModel.chapters.length +
          _viewModel.looseFiles.length +
          (_viewModel.looseFiles.isNotEmpty ? 1 : 0), // +1 for separator
      itemBuilder: (context, index) {
        // 散落文件分隔线
        if (_viewModel.looseFiles.isNotEmpty &&
            index == _viewModel.chapters.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '散落文件',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          );
        }

        if (index < _viewModel.chapters.length) {
          return _buildChapterListItem(_viewModel.chapters[index]);
        }
        final fileIndex =
            index -
            _viewModel.chapters.length -
            (_viewModel.looseFiles.isNotEmpty ? 1 : 0);
        return _buildLooseFileListItem(_viewModel.looseFiles[fileIndex]);
      },
    );
  }

  /// 加载章节封面缩略图
  Future<Uint8List?> _loadChapterThumbnail(Chapter chapter) async {
    if (chapter.coverPath == null) return null;
    final thumbnailRepo = context.read<ThumbnailRepository>();
    final entry = FileEntry(
      name: chapter.coverPath!.split('/').last,
      path: chapter.coverPath!,
      isDirectory: false,
    );
    final result = await thumbnailRepo.preview(widget.fileSource, entry);
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  /// 章节网格卡片
  Widget _buildChapterCard(Chapter chapter) {
    final theme = Theme.of(context);
    final isDisabled = chapter.isDisabled;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDisabled ? null : () => _openChapter(chapter),
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 缩略图区
              Expanded(
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: _loadChapterThumbnail(chapter),
                        builder: (context, snapshot) {
                          final bytes = snapshot.data;
                          if (bytes != null) {
                            return Image.memory(bytes, fit: BoxFit.cover);
                          }
                          return const Center(
                            child: Icon(
                              Icons.photo_library,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      if (isDisabled)
                        const Center(
                          child: Text(
                            '空章节',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 章节名 + 页数
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${chapter.pageCount} 页',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 章节列表行
  Widget _buildChapterListItem(Chapter chapter) {
    final theme = Theme.of(context);
    final isDisabled = chapter.isDisabled;

    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: ListTile(
        leading: FutureBuilder<Uint8List?>(
          future: _loadChapterThumbnail(chapter),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : const Icon(
                      Icons.photo_library,
                      size: 24,
                      color: Colors.grey,
                    ),
            );
          },
        ),
        title: Text(chapter.name, style: theme.textTheme.bodyMedium),
        subtitle: Text(
          isDisabled ? '空章节' : '${chapter.pageCount} 页',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: isDisabled ? null : () => _openChapter(chapter),
      ),
    );
  }

  /// 散落文件网格卡片
  Widget _buildLooseFileCard(FileEntry file) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLooseFile(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    _fileIcon(file.name),
                    size: 48,
                    color: _fileColor(file.name),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 散落文件列表行
  Widget _buildLooseFileListItem(FileEntry file) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            _fileIcon(file.name),
            size: 24,
            color: _fileColor(file.name),
          ),
        ),
      ),
      title: Text(file.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openLooseFile(file),
    );
  }

  Future<void> _openChapter(Chapter chapter) async {
    final strategy = ChapterStrategy();
    final provider =
        strategy.createProvider(
              widget.resource,
              widget.fileSource,
              chapter: chapter,
            )
            as ImageFolderProvider;
    await provider.load();

    if (!mounted) {
      await provider.dispose();
      return;
    }

    if (provider.pageCount == 0) {
      await provider.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${chapter.name}" 中没有支持的图片')));
      return;
    }

    final viewer = ViewerPage(title: chapter.name, contentProvider: provider);

    if (widget.onNavigateToViewer != null) {
      widget.onNavigateToViewer!(viewer);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => viewer));
    }
  }

  void _openLooseFile(FileEntry file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileSequenceViewerPage(
          fileSource: widget.fileSource,
          localRootPath: '',
          entries: [file],
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _buildViewModeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewModeBtn(theme, ChapterViewMode.grid, Icons.grid_view),
          _viewModeBtn(theme, ChapterViewMode.list, Icons.view_list),
        ],
      ),
    );
  }

  Widget _viewModeBtn(ThemeData theme, ChapterViewMode mode, IconData icon) {
    final isActive = _viewModel.viewMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isActive) _viewModel.toggleViewMode();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _switchOrgMode(OrganizationMode mode) async {
    if (mode == widget.resource.organizationMode) return;
    final repo = context.read<ResourceRepository>();
    final updated = widget.resource.copyWith(organizationMode: mode);
    await repo.updateResource(updated);
    if (mounted) Navigator.of(context).pop();
  }

  IconData _fileIcon(String name) {
    final ext = name.toLowerCase();
    if (ext.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (ext.endsWith('.mp4') || ext.endsWith('.mkv')) return Icons.movie;
    if (ext.endsWith('.zip') || ext.endsWith('.rar') || ext.endsWith('.7z')) {
      return Icons.archive;
    }
    return Icons.image;
  }

  Color _fileColor(String name) {
    final ext = name.toLowerCase();
    if (ext.endsWith('.pdf')) return Colors.red;
    if (ext.endsWith('.mp4') || ext.endsWith('.mkv')) return Colors.blue;
    if (ext.endsWith('.zip') || ext.endsWith('.rar') || ext.endsWith('.7z')) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Widget _buildError() {
    return Center(
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
}
