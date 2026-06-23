import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/tag.dart';

/// 文件列表视图组件
///
/// 以列表形式显示文件和文件夹。
/// 已入库项目显示标签芯片，长按可编辑标签。
class FileListView extends StatefulWidget {
  const FileListView({
    super.key,
    required this.entries,
    this.onTap,
    this.selectedEntries,
    this.onToggleSelect,
    this.importedPaths,
    this.resourceTags,
    this.onLongPressImported,
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

  /// 长按已入库项目的回调
  final ValueChanged<FileEntry>? onLongPressImported;
  final Future<Uint8List?> Function(FileEntry)? thumbnailLoader;

  /// 是否还有更多条目可展示
  final bool hasMore;

  /// 滚动到底部时加载更多
  final VoidCallback? onLoadMore;

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final _scrollController = ScrollController();
  bool _throttled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FileListView oldWidget) {
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.entries.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.entries.length) {
          return _buildBottomWidget();
        }
        final entry = widget.entries[index];
        final isSelected =
            widget.selectedEntries?.contains(entry.path) ?? false;
        final isImported = widget.importedPaths?.contains(entry.path) ?? false;
        final tags = isImported
            ? (widget.resourceTags?[entry.path] ?? [])
            : <Tag>[];

        return GestureDetector(
          onSecondaryTap: isImported && widget.onLongPressImported != null
              ? () => widget.onLongPressImported?.call(entry)
              : null,
          child: ListTile(
            leading: _buildIcon(entry, isImported),
            title: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _buildSubtitle(context, entry, tags),
            trailing: widget.onToggleSelect != null
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => widget.onToggleSelect?.call(entry),
                  )
                : null,
            onTap: widget.onTap != null
                ? () => widget.onTap?.call(entry)
                : null,
            onLongPress: isImported && widget.onLongPressImported != null
                ? () => widget.onLongPressImported?.call(entry)
                : widget.onToggleSelect != null
                ? () => widget.onToggleSelect?.call(entry)
                : null,
          ),
        );
      },
    );
  }

  /// 构建文件图标（已入库时加角标）
  Widget _buildIcon(FileEntry entry, bool isImported) {
    final icon = _buildPreview(entry);

    if (!isImported) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// 构建预览（有缩略图加载器时尝试加载，否则显示图标）
  Widget _buildPreview(FileEntry entry) {
    final loader = widget.thumbnailLoader;
    if (loader == null) return _getIcon(entry);
    return FutureBuilder<Uint8List?>(
      future: loader(entry),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return _getIcon(entry);
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.memory(
                  bytes,
                  key: ValueKey('list-thumbnail-${entry.path}'),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 80,
                  errorBuilder: (_, _, _) => _getIcon(entry),
                ),
              ),
              // 文件夹标识
              if (entry.isDirectory)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.folder,
                      size: 10,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _getIcon(FileEntry entry) {
    if (entry.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber, size: 36);
    }
    return Icon(_getFileIcon(entry), color: _getFileIconColor(entry), size: 36);
  }

  IconData _getFileIcon(FileEntry entry) {
    return switch (p.extension(entry.name).toLowerCase()) {
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' || '.bmp' => Icons.image,
      '.pdf' => Icons.picture_as_pdf,
      '.mp4' ||
      '.mkv' ||
      '.avi' ||
      '.mov' ||
      '.wmv' ||
      '.webm' => Icons.video_file,
      '.zip' || '.rar' || '.7z' || '.tar' || '.gz' => Icons.archive,
      _ => Icons.insert_drive_file,
    };
  }

  Color _getFileIconColor(FileEntry entry) {
    return switch (p.extension(entry.name).toLowerCase()) {
      '.jpg' ||
      '.jpeg' ||
      '.png' ||
      '.gif' ||
      '.webp' ||
      '.bmp' => Colors.green,
      '.pdf' => Colors.red,
      '.mp4' || '.mkv' || '.avi' || '.mov' || '.wmv' || '.webm' => Colors.blue,
      '.zip' || '.rar' || '.7z' || '.tar' || '.gz' => Colors.orange,
      _ => Colors.grey,
    };
  }

  /// 构建副标题（文件大小 + 标签芯片）
  Widget? _buildSubtitle(
    BuildContext context,
    FileEntry entry,
    List<Tag> tags,
  ) {
    final sizeText = _buildSizeText(entry);

    if (tags.isEmpty && sizeText == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sizeText != null) Text(sizeText),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag.name, style: const TextStyle(fontSize: 10)),
                backgroundColor: _parseColor(tag.color).withValues(alpha: 0.2),
                labelStyle: TextStyle(color: _parseColor(tag.color)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String? _buildSizeText(FileEntry entry) {
    if (entry.isDirectory) return null;
    final size = entry.size;
    if (size == null) return null;
    return _formatFileSize(size);
  }

  String _formatFileSize(BigInt bytes) {
    if (bytes < BigInt.from(1024)) return '$bytes B';
    if (bytes < BigInt.from(1024 * 1024)) {
      return '${(bytes / BigInt.from(1024)).toStringAsFixed(1)} KB';
    }
    if (bytes < BigInt.from(1024 * 1024 * 1024)) {
      return '${(bytes / BigInt.from(1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / BigInt.from(1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Color _parseColor(String hex) {
    final hexClean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexClean', radix: 16));
  }

  Widget _buildBottomWidget() {
    return const SizedBox(height: 60);
  }
}
