import 'package:flutter/material.dart';

import '../../../../domain/models/tag.dart';
import '../../../core/theme/app_colors.dart';

/// 首页筛选栏组件
///
/// "全部"和"收藏"固定在左侧，自定义标签横向滚动。
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.customTags,
    this.selectedTagIds = const {},
    this.isAllSelected = true,
    this.isFavoriteSelected = false,
    this.filteredCount,
    this.totalCount,
    this.hasActiveFilter = false,
    this.onSearchChanged,
    this.onAllTap,
    this.onFavoriteTap,
    this.onTagTap,
  });

  /// 自定义标签列表
  final List<Tag> customTags;

  /// 当前选中的标签 ID 集合
  final Set<String> selectedTagIds;

  /// 是否选中"全部"
  final bool isAllSelected;

  /// 是否选中"收藏"
  final bool isFavoriteSelected;

  /// 筛选后的资源数量
  final int? filteredCount;

  /// 总资源数量
  final int? totalCount;
  final bool hasActiveFilter;
  final ValueChanged<String>? onSearchChanged;

  /// 点击"全部"回调
  final VoidCallback? onAllTap;

  /// 点击"收藏"回调
  final VoidCallback? onFavoriteTap;

  /// 点击标签回调
  final void Function(String tagId)? onTagTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            key: const Key('resource-search-field'),
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: '搜索资源...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // 筛选栏
        SizedBox(
          height: 44,
          child: Row(
            children: [
              // 固定左侧：全部 + 收藏
              _buildFixedFilters(theme),

              // 可滚动区域：自定义标签
              if (customTags.isNotEmpty)
                Expanded(child: _buildScrollableTags(theme)),
            ],
          ),
        ),

        // 筛选结果计数
        if (_showCount) _buildCountBadge(theme),
      ],
    );
  }

  bool get _showCount =>
      filteredCount != null &&
      totalCount != null &&
      (hasActiveFilter || !isAllSelected);

  Widget _buildFixedFilters(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12),
        _buildFilterChip(
          label: '全部',
          isSelected: isAllSelected,
          selectedColor: AppColors.primary,
          onTap: onAllTap,
          theme: theme,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: '收藏',
          icon: Icons.star,
          isSelected: isFavoriteSelected,
          selectedColor: AppColors.star,
          onTap: onFavoriteTap,
          theme: theme,
        ),
        if (customTags.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: AppColors.outline),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildScrollableTags(ThemeData theme) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 12),
      itemCount: customTags.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final tag = customTags[index];
        final isSelected = selectedTagIds.contains(tag.id);
        final color = _hexToColor(tag.color);

        return _buildFilterChip(
          label: tag.name,
          isSelected: isSelected,
          selectedColor: color,
          onTap: () => onTagTap?.call(tag.id),
          theme: theme,
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color selectedColor,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final backgroundColor = isSelected ? selectedColor : Colors.transparent;
    final foregroundColor = isSelected
        ? Colors.white
        : theme.colorScheme.onSurface;
    final borderColor = isSelected ? selectedColor : theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            '筛选出 $filteredCount / $totalCount 个资源',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (filteredCount == 0) ...[
            const SizedBox(width: 8),
            Text(
              '试试调整筛选条件',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
