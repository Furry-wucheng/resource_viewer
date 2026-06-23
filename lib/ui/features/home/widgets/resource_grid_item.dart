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
    this.onLongPress,
  });

  final Resource resource;
  final String? thumbnailPath;
  final VoidCallback? onTap;

  /// 是否已收藏
  final bool isFavorited;

  /// 收藏按钮点击回调
  final VoidCallback? onFavoriteTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 缩略图 / 占位
            _buildThumbnail(),
            // 底部渐变 + 名称
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 40, 6, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Text(
                  resource.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 类型角标
            if (_showsTypeBadge)
              Positioned(right: 4, bottom: 4, child: _buildTypeBadge()),
            // 收藏按钮
            Positioned(left: 4, top: 4, child: _buildFavoriteButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      final file = File(thumbnailPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          cacheWidth: 180,
          cacheHeight: 270,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
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
      child: Icon(
        isFavorited ? Icons.star : Icons.star_border,
        color: isFavorited ? AppColors.star : Colors.white,
        size: 22,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }

  bool get _showsTypeBadge =>
      resource.type == ResourceType.pdf ||
      resource.type == ResourceType.archive ||
      resource.type == ResourceType.video;

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
