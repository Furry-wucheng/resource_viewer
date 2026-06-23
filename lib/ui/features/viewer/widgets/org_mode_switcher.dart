import 'package:flutter/material.dart';

import '../../../../domain/models/resource.dart';

/// 组织模式切换器 — 与 design/chapter-list.html / flat-grid.html 的 .mode-switcher 一致
///
/// 三个并排按钮（章节/平铺/画廊），选中项白色凸起，未选中项灰色扁平。
class OrgModeSwitcher extends StatelessWidget {
  const OrgModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.chapterEnabled = true,
  });

  final OrganizationMode? currentMode;
  final ValueChanged<OrganizationMode> onModeChanged;
  final bool chapterEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            OrganizationMode.chapter,
            '章节',
            Icons.menu_book_outlined,
            enabled: chapterEnabled,
          ),
          _buildOption(
            context,
            OrganizationMode.flatgrid,
            '平铺',
            Icons.grid_view_outlined,
          ),
          _buildOption(
            context,
            OrganizationMode.gallery,
            '画廊',
            Icons.dashboard_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    OrganizationMode mode,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isActive = currentMode == mode;
    final foreground = !enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.28)
        : isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final option = GestureDetector(
      onTap: enabled ? () => onModeChanged(mode) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (enabled) return option;
    return Tooltip(message: '资源根目录没有子文件夹', child: option);
  }
}
