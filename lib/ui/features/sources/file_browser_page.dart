import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/filesystem_repository.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/thumbnail_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/file_entry.dart';
import '../../../shared/file_source/file_source_factory.dart';
import '../../core/view_models/base_view_model.dart';
import '../viewer/file_viewer_page.dart';
import 'view_models/file_browser_view_model.dart';
import 'widgets/directory_tree.dart';
import 'widgets/file_grid_view.dart';
import 'widgets/file_list_view.dart';
import 'widgets/tag_picker_dialog.dart';

/// 文件浏览器页面
///
/// 支持目录导航、面包屑导航、列表/网格视图切换。
/// ≥900dp 时显示左树右内容的双栏布局。
class FileBrowserPage extends StatelessWidget {
  const FileBrowserPage({
    super.key,
    required this.sourceId,
    required this.sourceName,
  });

  final String sourceId;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FileBrowserViewModel(
        sourceId: sourceId,
        sourceName: sourceName,
        filesystemRepository: context.read<FilesystemRepository>(),
        resourceRepository: context.read<ResourceRepository>(),
        tagRepository: context.read<TagRepository>(),
        thumbnailRepository: context.read<ThumbnailRepository>(),
        fileSourceFactory: context.read<FileSourceFactory>(),
      )..loadDirectory(''),
      child: const _FileBrowserView(),
    );
  }
}

class _FileBrowserView extends StatelessWidget {
  const _FileBrowserView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FileBrowserViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final useDualPane = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: vm.isMultiSelectMode
            ? Text('已选 ${vm.selectedPaths.length} 项')
            : Text(vm.sourceName),
        leading: vm.isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: vm.exitMultiSelectMode,
              )
            : null,
        actions: [
          if (vm.isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: vm.selectAll,
              tooltip: '全选',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: vm.enterMultiSelectMode,
              tooltip: '多选',
            ),
            IconButton(
              icon: Icon(
                vm.viewMode == ViewMode.list
                    ? Icons.grid_view
                    : Icons.view_list,
              ),
              onPressed: vm.toggleViewMode,
              tooltip:
                  vm.viewMode == ViewMode.list ? '网格视图' : '列表视图',
            ),
          ],
        ],
      ),
      body: useDualPane
          ? _buildDualPane(context, vm)
          : _buildSinglePane(context, vm),
      bottomNavigationBar:
          vm.isMultiSelectMode ? _buildMultiSelectBar(context, vm) : null,
    );
  }

  /// 双栏布局：左树 + 右内容
  Widget _buildDualPane(BuildContext context, FileBrowserViewModel vm) {
    return Row(
      children: [
        // 左侧目录树
        SizedBox(
          width: 240,
          child: Card(
            margin: const EdgeInsets.all(8),
            clipBehavior: Clip.antiAlias,
            child: DirectoryTree(
              sourceId: vm.sourceId,
              sourceName: vm.sourceName,
              filesystemRepository: context.read<FilesystemRepository>(),
              currentPath: vm.currentPath,
              onDirectoryTap: (path) => vm.loadDirectory(path),
            ),
          ),
        ),
        // 右侧内容
        Expanded(
          child: Column(
            children: [
              _buildBreadcrumbs(context, vm),
              Expanded(child: _buildBody(context, vm)),
            ],
          ),
        ),
      ],
    );
  }

  /// 单栏布局
  Widget _buildSinglePane(BuildContext context, FileBrowserViewModel vm) {
    return Column(
      children: [
        _buildBreadcrumbs(context, vm),
        Expanded(child: _buildBody(context, vm)),
      ],
    );
  }

  /// 构建面包屑导航
  Widget _buildBreadcrumbs(BuildContext context, FileBrowserViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < vm.breadcrumbs.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              InkWell(
                onTap: () => vm.navigateToBreadcrumb(i),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    vm.breadcrumbs[i].label,
                    style: TextStyle(
                      color: i == vm.breadcrumbs.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: i == vm.breadcrumbs.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody(BuildContext context, FileBrowserViewModel vm) {
    switch (vm.state) {
      case UiState.loading:
        return _buildLoadingSkeleton(context);
      case UiState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(vm.errorMessage ?? '加载失败'),
              if (vm.canRetry) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: vm.retry,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        );
      case UiState.idle:
      case UiState.success:
        return vm.viewMode == ViewMode.list
            ? FileListView(
                entries: vm.entries,
                onTap: (entry) => _handleTap(context, vm, entry),
                selectedEntries:
                    vm.isMultiSelectMode ? vm.selectedPaths : null,
                onToggleSelect: vm.isMultiSelectMode
                    ? (entry) => vm.toggleSelection(entry.path)
                    : null,
                importedPaths: vm.importedPaths,
                resourceTags: vm.resourceTags,
                onLongPressImported: (entry) =>
                    _showTagPicker(context, vm, entry),
              )
            : FileGridView(
                entries: vm.entries,
                onTap: (entry) => _handleTap(context, vm, entry),
                selectedEntries:
                    vm.isMultiSelectMode ? vm.selectedPaths : null,
                onToggleSelect: vm.isMultiSelectMode
                    ? (entry) => vm.toggleSelection(entry.path)
                    : null,
                importedPaths: vm.importedPaths,
                resourceTags: vm.resourceTags,
                onLongPressImported: (entry) =>
                    _showTagPicker(context, vm, entry),
              );
    }
  }

  /// 构建加载骨架屏
  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 12,
            width: 100,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  /// 显示标签选择弹窗
  Future<void> _showTagPicker(
    BuildContext context,
    FileBrowserViewModel vm,
    FileEntry entry,
  ) async {
    final currentTags = vm.getTagsForPath(entry.path);
    final currentTagIds = currentTags.map((t) => t.id).toSet();

    final selectedIds = await TagPickerDialog.show(
      context,
      selectedTagIds: currentTagIds,
    );

    if (selectedIds != null) {
      await vm.updateResourceTags(entry.path, selectedIds);
    }
  }

  /// 处理点击事件
  Future<void> _handleTap(
    BuildContext context,
    FileBrowserViewModel vm,
    FileEntry entry,
  ) async {
    if (vm.isMultiSelectMode) {
      vm.toggleSelection(entry.path);
      return;
    }
    if (!vm.tryBeginEntryAction()) return;

    try {
      if (entry.isDirectory) {
        await vm.enterDirectory(entry.name);
      } else {
        await context.push(
          '/viewer/file/${vm.sourceId}',
          extra: FileViewerRequest(
            entry: entry,
            sourceName: vm.sourceName,
          ),
        );
      }
    } finally {
      vm.endEntryAction();
    }
  }

  /// 构建多选模式底部操作栏
  Widget _buildMultiSelectBar(BuildContext context, FileBrowserViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: vm.selectedPaths.isEmpty
                    ? null
                    : () => _batchAddResources(context, vm),
                icon: const Icon(Icons.add),
                label: const Text('批量添加资源'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.label),
                label: const Text('批量打标签'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 批量添加资源
  Future<void> _batchAddResources(
    BuildContext context,
    FileBrowserViewModel vm,
  ) async {
    final selected = vm.getSelectedEntries();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一项')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加资源'),
        content: Text('将检查并添加 ${selected.length} 个所选项目，空文件夹和已入库项目会被跳过。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await vm.addSelectedResources();
    if (!context.mounted) return;
    final message = switch (result) {
      Ok(:final value) => '已添加 ${value.added} 项，跳过 ${value.skipped} 项',
      Err(:final error) => '添加失败：${error.message}',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
