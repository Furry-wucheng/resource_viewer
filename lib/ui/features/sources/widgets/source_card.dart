import 'package:flutter/material.dart';

import '../../../../domain/models/source.dart';

/// 数据源卡片组件
///
/// 显示类型图标、源名称、资源数量、状态指示。
class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.source,
    required this.resourceCount,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onTap,
    this.isScanning = false,
    this.onEditSmbCredentials,
  });

  final Source source;
  final int resourceCount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  /// 是否正在扫描
  final bool isScanning;

  /// 编辑 SMB 凭据回调（仅 SMB 源有效）
  final VoidCallback? onEditSmbCredentials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = source.enabled;
    final isAvailable = source.isAvailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildIcon(theme),
        title: Text(
          source.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: !isEnabled || !isAvailable
              ? TextStyle(color: theme.colorScheme.outline)
              : null,
        ),
        subtitle: _buildSubtitle(theme, isEnabled, isAvailable),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态指示
            _buildStatusIndicator(theme, isEnabled, isAvailable),
            // 启用/禁用开关
            Switch(
              value: isEnabled,
              onChanged: onToggle,
            ),
            // 更多菜单
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    onRename();
                  case 'edit_smb':
                    onEditSmbCredentials?.call();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('重命名'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (source.type == SourceType.smb && onEditSmbCredentials != null)
                  const PopupMenuItem(
                    value: 'edit_smb',
                    child: ListTile(
                      leading: Icon(Icons.key),
                      title: Text('编辑 SMB 凭据'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: isEnabled ? onTap : null,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, bool isEnabled, bool isAvailable) {
    if (isScanning) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '扫描中...',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (!isEnabled) {
      return Text(
        '${source.typeLabel} · 已禁用',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    if (!isAvailable) {
      return Text(
        '${source.typeLabel} · 不可用',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return Text(
      '${source.typeLabel} · $resourceCount 个资源',
      style: theme.textTheme.bodySmall,
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, bool isEnabled, bool isAvailable) {
    if (isScanning) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (!isEnabled) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: '已禁用',
          child: Icon(
            Icons.pause_circle_outline,
            size: 16,
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    if (!isAvailable) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: '不可用',
          child: Icon(
            Icons.cloud_off,
            size: 16,
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIcon(ThemeData theme) {
    final IconData iconData;
    final Color color;

    switch (source.type) {
      case SourceType.local:
        iconData = Icons.folder;
        color = Colors.amber;
      case SourceType.smb:
        iconData = Icons.computer;
        color = Colors.blue;
      case SourceType.ftp:
        iconData = Icons.cloud;
        color = Colors.teal;
      case SourceType.webdav:
        iconData = Icons.cloud_sync;
        color = Colors.purple;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(iconData, color: color),
    );
  }
}

/// Source 扩展
extension _SourceLabel on Source {
  String get typeLabel => switch (type) {
        SourceType.local => '本地',
        SourceType.smb => 'SMB',
        SourceType.ftp => 'FTP',
        SourceType.webdav => 'WebDAV',
      };
}
