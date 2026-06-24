import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/tag.dart';
import '../../../../shared/media/media_file_types.dart';

/// 文件网格视图组件
///
/// 以网格形式显示文件和文件夹。
/// 已入库项目显示入库角标，长按可打开条目操作菜单。
class FileGridView extends StatefulWidget {
  const FileGridView({
    super.key,
    required this.entries,
    this.onTap,
    this.selectedEntries,
    this.onToggleSelect,
    this.importedPaths,
    this.resourceTags,
    this.onLongPressEntry,
    this.thumbnailLoader,
    this.hasMore = false,
    this.onLoadMore,
  });

  final List<FileEntry> entries;
  final ValueChanged<FileEntry>? onTap;
  final Set<String>? selectedEntries;
  final ValueChanged<FileEntry>? onToggleSelect;

  /// 已入库路径集合
  final Set<String>? importedPaths;

  /// 路径 → 标签列表
  final Map<String, List<Tag>>? resourceTags;

  /// 长按/右键条目的回调
  final ValueChanged<FileEntry>? onLongPressEntry;
  final Future<Uint8List?> Function(FileEntry)? thumbnailLoader;

  /// 是否还有更多条目可展示
  final bool hasMore;

  /// 滚动到底部时加载更多
  final VoidCallback? onLoadMore;

  @override
  State<FileGridView> createState() => _FileGridViewState();
}

class _FileGridViewState extends State<FileGridView> {
  final _scrollController = ScrollController();
  bool _throttled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FileGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasMore || widget.entries.length != oldWidget.entries.length) {
      _throttled = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_throttled) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && widget.onLoadMore != null) {
        _throttled = true;
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
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

    final showLoadMore = widget.hasMore;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.entries.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.entries.length) {
          return const SizedBox(height: 60);
        }
        final entry = widget.entries[index];
        final isSelected =
            widget.selectedEntries?.contains(entry.path) ?? false;
        final isImported = widget.importedPaths?.contains(entry.path) ?? false;
        final tags = isImported
            ? (widget.resourceTags?[entry.path] ?? [])
            : <Tag>[];

        return _FileGridItem(
          entry: entry,
          isSelected: isSelected,
          isImported: isImported,
          tags: tags,
          onTap: widget.onTap != null ? () => widget.onTap?.call(entry) : null,
          onLongPress: widget.onLongPressEntry != null
              ? () => widget.onLongPressEntry?.call(entry)
              : widget.onToggleSelect != null
              ? () => widget.onToggleSelect?.call(entry)
              : null,
          onToggleSelect: widget.onToggleSelect != null
              ? () => widget.onToggleSelect?.call(entry)
              : null,
          thumbnailLoader: widget.thumbnailLoader,
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
      onSecondaryTap: onLongPress,
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
            // 文件类型角标（非文件夹文件）
            if (!entry.isDirectory)
              Positioned(
                bottom: 4,
                right: 4,
                child: _buildFileTypeBadge(entry.name),
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
  static Widget _buildFileTypeBadge(String fileName) {
    IconData icon;
    Color color;
    if (MediaFileTypes.isPdf(fileName)) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (MediaFileTypes.isVideo(fileName)) {
      icon = Icons.movie;
      color = Colors.blue;
    } else if (MediaFileTypes.isArchive(fileName)) {
      icon = Icons.archive;
      color = Colors.orange;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

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

    final IconData iconData;
    final Color color;

    if (MediaFileTypes.isImage(entry.name)) {
      iconData = Icons.image;
      color = Colors.green;
    } else if (MediaFileTypes.isPdf(entry.name)) {
      iconData = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (MediaFileTypes.isVideo(entry.name)) {
      iconData = Icons.video_file;
      color = Colors.blue;
    } else if (MediaFileTypes.isArchive(entry.name)) {
      iconData = Icons.archive;
      color = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 48);
  }
}
