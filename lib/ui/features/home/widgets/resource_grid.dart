import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/source_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/use_cases/split_resource_use_case.dart';
import '../../../../shared/file_source/file_source_factory.dart';
import '../../sources/widgets/resource_picker_dialog.dart';
import 'resource_detail_sheet.dart';
import 'resource_grid_item.dart';

/// 资源响应式网格
///
/// 根据屏幕宽度自动调整列数（≥6列）。
/// 支持滚动到底部加载更多（键集分页）。
class ResourceGrid extends StatefulWidget {
  const ResourceGrid({
    super.key,
    required this.resources,
    this.thumbnailPaths = const {},
    this.favoriteResourceIds = const {},
    this.onAddSource,
    this.onFavoriteTap,
    this.isMultiSelectMode = false,
    this.selectedResourceIds = const {},
    this.onToggleSelection,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.onLoadMore,
  });

  final List<Resource> resources;
  final Map<String, String?> thumbnailPaths;

  /// 已收藏的资源 ID 集合
  final Set<String> favoriteResourceIds;

  final VoidCallback? onAddSource;

  /// 收藏按钮点击回调
  final void Function(String resourceId)? onFavoriteTap;

  /// 是否处于多选模式
  final bool isMultiSelectMode;

  /// 多选模式下被选中的资源 ID
  final Set<String> selectedResourceIds;

  /// 多选模式下切换选中状态
  final void Function(String id)? onToggleSelection;

  /// 是否有更多数据可加载
  final bool hasMore;

  /// 是否正在加载更多
  final bool isLoadingMore;

  /// 加载更多错误信息
  final String? loadMoreError;

  /// 加载更多回调
  final VoidCallback? onLoadMore;

  @override
  State<ResourceGrid> createState() => _ResourceGridState();
}

class _ResourceGridState extends State<ResourceGrid> {
  bool _navigationInProgress = false;
  final _scrollController = ScrollController();
  bool _loadMoreThrottled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ResourceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 加载完成或错误后重置节流，允许再次触发
    if (!widget.isLoadingMore && widget.loadMoreError == null) {
      _loadMoreThrottled = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadMoreThrottled) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoadingMore && widget.onLoadMore != null) {
        _loadMoreThrottled = true;
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('还没有资源'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.onAddSource,
              child: const Text('去添加数据源'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          key: const PageStorageKey<String>('home-resource-grid'),
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          // 底部加载指示器占一个额外位置
          itemCount: widget.resources.length + (_hasBottomWidget ? 1 : 0),
          itemBuilder: (context, index) {
            // 最后一项是底部状态
            if (index >= widget.resources.length) {
              return _buildBottomWidget();
            }
            final resource = widget.resources[index];
            return ResourceGridItem(
              resource: resource,
              thumbnailPath: widget.thumbnailPaths[resource.id],
              onTap: () {
                if (widget.isMultiSelectMode) {
                  widget.onToggleSelection?.call(resource.id);
                } else {
                  _openResource(context, resource);
                }
              },
              onLongPress: () {
                if (!widget.isMultiSelectMode) {
                  _showResourceMenu(context, resource);
                }
              },
              isFavorited: widget.favoriteResourceIds.contains(resource.id),
              onFavoriteTap: widget.isMultiSelectMode
                  ? null
                  : widget.onFavoriteTap != null
                      ? () => widget.onFavoriteTap!(resource.id)
                      : null,
              isMultiSelectMode: widget.isMultiSelectMode,
              isSelected: widget.selectedResourceIds.contains(resource.id),
            );
          },
        );
      },
    );
  }

  bool get _hasBottomWidget =>
      widget.isLoadingMore ||
      widget.loadMoreError != null ||
      (!widget.hasMore && widget.resources.isNotEmpty);

  Widget _buildBottomWidget() {
    if (widget.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.loadMoreError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onLoadMore,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    // 已无更多
    if (!widget.hasMore && widget.resources.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '— 已加载全部 —',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showResourceMenu(BuildContext context, Resource resource) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.of(ctx).pop();
                ResourceDetailSheet.show(context: context, resource: resource);
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('拆分资源'),
              onTap: () {
                Navigator.of(ctx).pop();
                _splitResource(context, resource);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除资源', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteResource(context, resource);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteResource(BuildContext context, Resource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除资源"${resource.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final resourceRepo = context.read<ResourceRepository>();
    final result = await resourceRepo.deleteResource(resource.id);
    if (context.mounted) {
      switch (result) {
        case Ok():
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已删除"${resource.name}"')));
        case Err(:final error):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _splitResource(BuildContext context, Resource resource) async {
    final fileSourceFactory = context.read<FileSourceFactory>();
    final resourceRepo = context.read<ResourceRepository>();
    final sourceRepo = context.read<SourceRepository>();
    final sourceResult = await sourceRepo.getSourceById(resource.sourceId);
    final source = switch (sourceResult) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (source == null || !context.mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据源不可用')));
      }
      return;
    }
    final fileSource = await fileSourceFactory.createAsync(source);
    if (!context.mounted) return;

    final pickerResult = await ResourcePickerDialog.show(
      context: context,
      title: '拆分资源：${resource.name}',
      fileSource: fileSource,
      rootPath: resource.relativePath,
      mode: ResourcePickerMode.splitKeep,
    );

    if (pickerResult == null || pickerResult.paths.isEmpty) return;
    if (!context.mounted) return;

    if (pickerResult.deleteOriginal) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认拆分并删除'),
          content: Text(
            '原资源“${resource.name}”将被删除，拆出 ${pickerResult.paths.length} 个子资源。确定？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认删除'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final splitUseCase = SplitResourceUseCase(resourceRepo);
    final result = await splitUseCase(
      originalResource: resource,
      selectedPaths: pickerResult.paths,
      deleteOriginal: pickerResult.deleteOriginal,
      fileSource: fileSource,
    );

    if (context.mounted) {
      switch (result) {
        case Ok(:final value):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已创建 ${value.createdIds.length} 个子资源')),
          );
        case Err(:final error):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openResource(BuildContext context, Resource resource) async {
    if (_navigationInProgress) return;
    _navigationInProgress = true;
    try {
      await context.push('/viewer/${resource.id}');
    } finally {
      _navigationInProgress = false;
    }
  }
}
