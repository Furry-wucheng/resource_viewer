import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../view_models/viewer_view_model.dart';

/// 查看器顶部工具栏
///
/// 显示返回按钮、资源名称、收藏按钮、当前页码/总页数、设置菜单。
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    this.isFavorited = false,
    this.onFavoriteTap,
    this.pageDirection,
    this.doublePageMode,
    this.onPageDirectionChanged,
    this.onDoublePageModeChanged,
    this.onViewDetailTap,
  });

  final String title;
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  /// 是否已收藏
  final bool isFavorited;

  /// 收藏按钮点击回调
  final VoidCallback? onFavoriteTap;

  /// 当前翻页方向
  final PageDirection? pageDirection;

  /// 当前双页模式
  final DoublePageMode? doublePageMode;

  /// 翻页方向变更回调
  final ValueChanged<PageDirection>? onPageDirectionChanged;

  /// 双页模式变更回调
  final ValueChanged<DoublePageMode>? onDoublePageModeChanged;

  /// 查看详情回调
  final VoidCallback? onViewDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 8,
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
          // 设置按钮
          if (onPageDirectionChanged != null || onDoublePageModeChanged != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
              color: Colors.grey[900],
              onSelected: (value) {
                switch (value) {
                  case 'detail':
                    onViewDetailTap?.call();
                  case 'dir_rtl':
                    onPageDirectionChanged?.call(PageDirection.rightToLeft);
                  case 'dir_ltr':
                    onPageDirectionChanged?.call(PageDirection.leftToRight);
                  case 'double_auto':
                    onDoublePageModeChanged?.call(DoublePageMode.auto);
                  case 'double_single':
                    onDoublePageModeChanged?.call(DoublePageMode.single);
                  case 'double_double':
                    onDoublePageModeChanged?.call(DoublePageMode.double);
                }
              },
              itemBuilder: (context) => [
                if (onViewDetailTap != null)
                  const PopupMenuItem(
                    value: 'detail',
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: Colors.white),
                      title: Text(
                        '查看详情',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
                if (pageDirection != null && onPageDirectionChanged != null)
                  const PopupMenuItem(
                    enabled: false,
                    child: Text(
                      '翻页方向',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                if (pageDirection != null && onPageDirectionChanged != null)
                  PopupMenuItem(
                    value: 'dir_rtl',
                    child: ListTile(
                      leading: Icon(
                        pageDirection == PageDirection.rightToLeft
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        '右→左（日漫）',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
                if (pageDirection != null && onPageDirectionChanged != null)
                  PopupMenuItem(
                    value: 'dir_ltr',
                    child: ListTile(
                      leading: Icon(
                        pageDirection == PageDirection.leftToRight
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        '左→右',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
                if (doublePageMode != null && onDoublePageModeChanged != null)
                  const PopupMenuItem(
                    enabled: false,
                    child: Text(
                      '双页显示',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                if (doublePageMode != null && onDoublePageModeChanged != null)
                  PopupMenuItem(
                    value: 'double_auto',
                    child: ListTile(
                      leading: Icon(
                        doublePageMode == DoublePageMode.auto
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        '自动（宽屏时双页）',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
                if (doublePageMode != null && onDoublePageModeChanged != null)
                  PopupMenuItem(
                    value: 'double_single',
                    child: ListTile(
                      leading: Icon(
                        doublePageMode == DoublePageMode.single
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        '始终单页',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
                if (doublePageMode != null && onDoublePageModeChanged != null)
                  PopupMenuItem(
                    value: 'double_double',
                    child: ListTile(
                      leading: Icon(
                        doublePageMode == DoublePageMode.double
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        '始终双页',
                        style: TextStyle(color: Colors.white),
                      ),
                      dense: true,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
