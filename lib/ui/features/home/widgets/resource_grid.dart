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
/// 点击资源跳转到查看器。
class ResourceGrid extends StatefulWidget {
  const ResourceGrid({
    super.key,
    required this.resources,
    this.thumbnailPaths = const {},
    this.favoriteResourceIds = const {},
    this.onAddSource,
    this.onFavoriteTap,
  });

  final List<Resource> resources;
  final Map<String, String?> thumbnailPaths;

  /// 已收藏的资源 ID 集合
  final Set<String> favoriteResourceIds;

  final VoidCallback? onAddSource;

  /// 收藏按钮点击回调
  final void Function(String resourceId)? onFavoriteTap;

  @override
  State<ResourceGrid> createState() => _ResourceGridState();
}

class _ResourceGridState extends State<ResourceGrid> {
  bool _navigationInProgress = false;

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
          padding: const EdgeInsets.all(12),
          scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.resources.length,
          itemBuilder: (context, index) {
            final resource = widget.resources[index];
            return ResourceGridItem(
              resource: resource,
              thumbnailPath: widget.thumbnailPaths[resource.id],
              onTap: () => _openResource(context, resource),
              onLongPress: () => _showResourceMenu(context, resource),
              isFavorited: widget.favoriteResourceIds.contains(resource.id),
              onFavoriteTap: widget.onFavoriteTap != null
                  ? () => widget.onFavoriteTap!(resource.id)
                  : null,
            );
          },
        );
      },
    );
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
            "原资源“${resource.name}”将被删除，拆出 ${pickerResult.paths.length} 个子资源。确定？",
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
