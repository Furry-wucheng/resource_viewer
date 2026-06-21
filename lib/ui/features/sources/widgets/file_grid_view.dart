import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/tag.dart';

/// 文件网格视图组件
///
/// 以网格形式显示文件和文件夹。
/// 已入库项目显示入库角标，长按可编辑标签。
class FileGridView extends StatelessWidget {
  const FileGridView({
    super.key,
    required this.entries,
    this.onTap,
    this.selectedEntries,
    this.onToggleSelect,
    this.importedPaths,
    this.resourceTags,
    this.onLongPressImported,
    this.thumbnailLoader,
  });

  final List<FileEntry> entries;
  final ValueChanged<FileEntry>? onTap;
  final Set<String>? selectedEntries;
  final ValueChanged<FileEntry>? onToggleSelect;

  /// 已入库路径集合
  final Set<String>? importedPaths;

  /// 路径 → 标签列表
  final Map<String, List<Tag>>? resourceTags;

  /// 长按已入库项目的回调
  final ValueChanged<FileEntry>? onLongPressImported;
  final Future<Uint8List?> Function(FileEntry)? thumbnailLoader;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('此文件夹为空', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selectedEntries?.contains(entry.path) ?? false;
        final isImported = importedPaths?.contains(entry.path) ?? false;
        final tags = isImported ? (resourceTags?[entry.path] ?? []) : <Tag>[];

        return _FileGridItem(
          entry: entry,
          isSelected: isSelected,
          isImported: isImported,
          tags: tags,
          onTap: onTap != null ? () => onTap?.call(entry) : null,
          onLongPress: isImported && onLongPressImported != null
              ? () => onLongPressImported?.call(entry)
              : onToggleSelect != null
              ? () => onToggleSelect?.call(entry)
              : null,
          onToggleSelect: onToggleSelect != null
              ? () => onToggleSelect?.call(entry)
              : null,
          thumbnailLoader: thumbnailLoader,
        );
      },
    );
  }
}

class _FileGridItem extends StatelessWidget {
  const _FileGridItem({
    required this.entry,
    required this.isSelected,
    required this.isImported,
    required this.tags,
    this.onTap,
    this.onLongPress,
    this.onToggleSelect,
    this.thumbnailLoader,
  });

  final FileEntry entry;
  final bool isSelected;
  final bool isImported;
  final List<Tag> tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelect;
  final Future<Uint8List?> Function(FileEntry)? thumbnailLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片/图标
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(child: _buildPreview(theme)),
            ),
            // 底部渐变 + 文件名
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        alignment: WrapAlignment.center,
                        children: tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag.name,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 文件夹标识（右下角小图标）
            if (entry.isDirectory)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.folder,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            // 已入库角标
            if (isImported)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            // 多选指示器
            if (onToggleSelect != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onToggleSelect,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle_outlined,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建文件图标
  Widget _buildPreview(ThemeData theme) {
    final loader = thumbnailLoader;
    if (loader == null) return _buildIcon(theme);
    return FutureBuilder<Uint8List?>(
      future: loader(entry),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return _buildIcon(theme);
        return Image.memory(
          bytes,
          key: ValueKey('file-thumbnail-${entry.path}'),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          cacheWidth: 300,
          errorBuilder: (_, _, _) => _buildIcon(theme),
        );
      },
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (entry.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber, size: 48);
    }

    final ext = p.extension(entry.name).toLowerCase();
    final IconData iconData;
    final Color color;

    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
        iconData = Icons.image;
        color = Colors.green;
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
      case '.mp4':
      case '.mkv':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.webm':
        iconData = Icons.video_file;
        color = Colors.blue;
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        color = Colors.orange;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 48);
  }

}
