import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';

import '../../../../domain/models/resource.dart';
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
