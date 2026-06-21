import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 查看器顶部工具栏
///
/// 显示返回按钮、资源名称、收藏按钮、当前页码/总页数。
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    this.isFavorited = false,
    this.onFavoriteTap,
  });

  final String title;
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  /// 是否已收藏
  final bool isFavorited;

  /// 收藏按钮点击回调
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 收藏按钮
          if (onFavoriteTap != null)
            IconButton(
              icon: Icon(
                isFavorited ? Icons.star : Icons.star_border,
                color: isFavorited ? AppColors.star : Colors.white,
              ),
              onPressed: onFavoriteTap,
            ),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
