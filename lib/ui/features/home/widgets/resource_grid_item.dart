import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/resource.dart';
import '../../../core/theme/app_colors.dart';

/// 资源网格项
///
/// 显示缩略图 + 名称 + 类型角标 + 收藏星标。
class ResourceGridItem extends StatelessWidget {
  const ResourceGridItem({
    super.key,
    required this.resource,
    this.thumbnailPath,
    this.onTap,
    this.isFavorited = false,
    this.onFavoriteTap,
  });

  final Resource resource;
  final String? thumbnailPath;
  final VoidCallback? onTap;

  /// 是否已收藏
  final bool isFavorited;

  /// 收藏按钮点击回调
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildThumbnail()),
            _buildInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      final file = File(thumbnailPath!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              cacheWidth: 180,
              cacheHeight: 270,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(),
            ),
            if (_showsTypeBadge)
              Positioned(right: 4, bottom: 4, child: _buildTypeBadge()),
            // 收藏星标
            Positioned(right: 4, top: 4, child: _buildFavoriteButton()),
          ],
        );
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPlaceholder(),
        if (_showsTypeBadge)
          Positioned(right: 4, bottom: 4, child: _buildTypeBadge()),
        // 收藏星标
        Positioned(right: 4, top: 4, child: _buildFavoriteButton()),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            _typeIcon,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _typeLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorited ? Icons.star : Icons.star_border,
          color: isFavorited ? AppColors.star : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  bool get _showsTypeBadge =>
      resource.type == ResourceType.pdf ||
      resource.type == ResourceType.archive;

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          if (resource.fileCount != null) ...[
            const SizedBox(height: 2),
            Text(
              '${resource.fileCount} 个文件',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _typeIcon {
    return switch (resource.type) {
      ResourceType.folder => Icons.folder,
      ResourceType.pdf => Icons.picture_as_pdf,
      ResourceType.archive => Icons.archive,
      ResourceType.video => Icons.movie,
    };
  }

  String get _typeLabel {
    return switch (resource.type) {
      ResourceType.folder => '图片',
      ResourceType.pdf => 'PDF',
      ResourceType.archive => '压缩包',
      ResourceType.video => '视频',
    };
  }
}
