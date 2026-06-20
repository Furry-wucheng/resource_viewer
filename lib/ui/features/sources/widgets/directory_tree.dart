import 'package:flutter/material.dart';

import '../../../../data/repositories/filesystem_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/file_entry.dart';

/// 目录树组件
///
/// 树形展示目录层级，点击展开/收起，选中高亮。
/// 使用 FilesystemRepository 懒加载子目录。
class DirectoryTree extends StatefulWidget {
  const DirectoryTree({
    super.key,
    required this.sourceId,
    required this.sourceName,
    required this.filesystemRepository,
    this.currentPath = '',
    this.onDirectoryTap,
  });

  final String sourceId;
  final String sourceName;
  final FilesystemRepository filesystemRepository;
  final String currentPath;
  final ValueChanged<String>? onDirectoryTap;

  @override
  State<DirectoryTree> createState() => _DirectoryTreeState();
}

class _DirectoryTreeState extends State<DirectoryTree> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.folder, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.sourceName,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 树形目录
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _TreeNodeWidget(
                sourceId: widget.sourceId,
                filesystemRepository: widget.filesystemRepository,
                dirName: widget.sourceName,
                relativePath: '',
                depth: 0,
                currentPath: widget.currentPath,
                onDirectoryTap: widget.onDirectoryTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 单个目录树节点
class _TreeNodeWidget extends StatefulWidget {
  const _TreeNodeWidget({
    required this.sourceId,
    required this.filesystemRepository,
    required this.dirName,
    required this.relativePath,
    required this.depth,
    required this.currentPath,
    this.onDirectoryTap,
  });

  final String sourceId;
  final FilesystemRepository filesystemRepository;
  final String dirName;
  final String relativePath;
  final int depth;
  final String currentPath;
  final ValueChanged<String>? onDirectoryTap;

  @override
  State<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<_TreeNodeWidget> {
  bool _expanded = false;
  bool _loading = false;
  List<FileEntry> _subdirectories = [];
  bool _hasSubdirectories = true; // 假设有子目录，展开后才知道

  bool get _isSelected => widget.currentPath == widget.relativePath;
  bool get _isAncestor =>
      widget.currentPath.startsWith('${widget.relativePath}/');

  @override
  void initState() {
    super.initState();
    // 如果当前路径是此节点的祖先，自动展开
    if (_isAncestor || (widget.depth == 0)) {
      _expanded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSubdirectories();
      });
    }
  }

  @override
  void didUpdateWidget(_TreeNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 currentPath 变化时，检查是否需要自动展开
    if (!_expanded && _isAncestor) {
      _expanded = true;
      if (_subdirectories.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadSubdirectories();
        });
      }
    }
  }

  Future<void> _loadSubdirectories() async {
    if (_loading) return;
    _loading = true;

    final result = await widget.filesystemRepository.listDirectory(
      widget.sourceId,
      widget.relativePath,
    );

    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        final dirs = value.where((e) => e.isDirectory).toList();
        setState(() {
          _subdirectories = dirs;
          _hasSubdirectories = dirs.isNotEmpty;
          _loading = false;
        });
      case Err():
        setState(() {
          _hasSubdirectories = false;
          _loading = false;
        });
    }
  }

  void _toggleExpand() {
    final shouldLoad = !_expanded &&
        _subdirectories.isEmpty &&
        _hasSubdirectories;
    setState(() {
      _expanded = !_expanded;
    });
    if (shouldLoad) _loadSubdirectories();
  }

  @override
  Widget build(BuildContext context) {
    // 根节点不显示自身，只显示子目录
    if (widget.depth == 0) {
      return _buildChildren();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            widget.onDirectoryTap?.call(widget.relativePath);
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 12.0 + widget.depth * 16.0,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            color: _isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Row(
              children: [
                // 展开/收起箭头
                GestureDetector(
                  onTap: _hasSubdirectories ? _toggleExpand : null,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _hasSubdirectories
                            ? Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right,
                                size: 18,
                              )
                            : null,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isSelected ? Icons.folder_open : Icons.folder,
                  size: 18,
                  color: _isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.dirName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          _isSelected ? FontWeight.bold : FontWeight.normal,
                      color: _isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) _buildChildren(),
      ],
    );
  }

  Widget _buildChildren() {
    if (_loading && _subdirectories.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 12.0 + (widget.depth + 1) * 16.0),
        child: const SizedBox(
          height: 28,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (!_hasSubdirectories && widget.depth > 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _subdirectories.map((dir) {
        final childPath = widget.relativePath.isEmpty
            ? dir.name
            : '${widget.relativePath}/${dir.name}';
        return _TreeNodeWidget(
          sourceId: widget.sourceId,
          filesystemRepository: widget.filesystemRepository,
          dirName: dir.name,
          relativePath: childPath,
          depth: widget.depth + 1,
          currentPath: widget.currentPath,
          onDirectoryTap: widget.onDirectoryTap,
        );
      }).toList(),
    );
  }
}
