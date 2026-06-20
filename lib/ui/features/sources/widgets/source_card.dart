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
  });

  final Source source;
  final int resourceCount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildIcon(theme),
        title: Text(
          source.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${source.typeLabel} · $resourceCount 个资源',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态指示
            if (!source.isAvailable)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: '不可用',
                  child: Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            // 启用/禁用开关
            Switch(
              value: source.enabled,
              onChanged: onToggle,
            ),
            // 更多菜单
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    onRename();
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
        onTap: onTap,
      ),
    );
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
