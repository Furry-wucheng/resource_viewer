import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../domain/models/file_entry.dart';
import '../../../../shared/file_source/file_source.dart';

/// ResourcePicker 模式
enum ResourcePickerMode {
  /// 批量添加
  batchAdd,

  /// 拆分资源 - 保留原资源
  splitKeep,

  /// 拆分资源 - 删除原资源
  splitDelete,
}

class ResourcePickerResult {
  const ResourcePickerResult({
    required this.paths,
    required this.deleteOriginal,
  });

  final List<String> paths;
  final bool deleteOriginal;
}

/// ResourcePicker 树节点
class PickerNode {
  PickerNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
    this.isLeaf = false,
    this.isChecked = false,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final List<PickerNode> children;
  final bool isLeaf;
  bool isChecked;
  bool isExpanded = false;
}

/// ResourcePicker 弹窗组件
///
/// 可复用的树形扫描选择弹窗。
/// 纯树形结构、节点勾选（不级联）、全选子项、智能识别规则。
class ResourcePickerDialog extends StatefulWidget {
  const ResourcePickerDialog({
    super.key,
    required this.title,
    required this.fileSource,
    required this.rootPath,
    this.mode = ResourcePickerMode.batchAdd,
  });

  final String title;
  final FileSource fileSource;
  final String rootPath;
  final ResourcePickerMode mode;

  /// 显示 ResourcePicker 弹窗
  ///
  /// 返回用户选中的路径列表，取消返回 null。
  static Future<ResourcePickerResult?> show({
    required BuildContext context,
    required String title,
    required FileSource fileSource,
    required String rootPath,
    ResourcePickerMode mode = ResourcePickerMode.batchAdd,
  }) {
    return showDialog<ResourcePickerResult>(
      context: context,
      builder: (context) => ResourcePickerDialog(
        title: title,
        fileSource: fileSource,
        rootPath: rootPath,
        mode: mode,
      ),
    );
  }

  @override
  State<ResourcePickerDialog> createState() => _ResourcePickerDialogState();
}

class _ResourcePickerDialogState extends State<ResourcePickerDialog> {
  List<PickerNode> _roots = [];
  bool _loading = true;
  String? _error;

  /// 已选中的路径集合
  final Set<String> _checkedPaths = {};

  int get _checkedCount => _checkedPaths.length;

  /// 支持的兼容文件扩展名
  static const _compatibleExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.pdf',
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.zip',
    '.rar',
    '.7z',
  };

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    try {
      final entries = await widget.fileSource.listDirectory(widget.rootPath);

      final nodes = <PickerNode>[];
      for (final entry in entries) {
        final node = await _buildNode(entry);
        if (node != null) {
          nodes.add(node);
        }
      }

      // 文件夹在前，文件在后
      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _roots = nodes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载目录失败: $e';
        _loading = false;
      });
    }
  }

  /// 构建树节点
  Future<PickerNode?> _buildNode(FileEntry entry) async {
    if (entry.isDirectory) {
      // 检查子目录内容来判断是否为叶子节点
      try {
        final children = await widget.fileSource.listDirectory(entry.path);
        final hasFiles = children.any(
          (e) => !e.isDirectory && _isCompatibleFile(e.name),
        );
        final hasSubDirs = children.any((e) => e.isDirectory);

        if (!hasFiles && !hasSubDirs) return null; // 空文件夹不显示

        // 智能识别：文件夹下一层全是兼容文件（无子文件夹）→ 叶子节点
        final isLeaf = !hasSubDirs && hasFiles;

        if (isLeaf) {
          return PickerNode(
            name: entry.name,
            path: entry.path,
            isDirectory: true,
            isLeaf: true,
          );
        }

        // 有子文件夹 → 可展开，但只构建一层（懒加载）
        // 先不加载子节点，用占位表示
        final childNodes = <PickerNode>[];
        for (final child in children) {
          final childNode = await _buildNode(child);
          if (childNode != null) childNodes.add(childNode);
        }

        return PickerNode(
          name: entry.name,
          path: entry.path,
          isDirectory: true,
          children: childNodes,
        );
      } catch (_) {
        return null;
      }
    }

    // 文件：只有兼容文件才显示
    if (_isCompatibleFile(entry.name)) {
      return PickerNode(
        name: entry.name,
        path: entry.path,
        isDirectory: false,
        isLeaf: true,
      );
    }

    return null;
  }

  void _toggleCheck(PickerNode node) {
    setState(() {
      if (_checkedPaths.contains(node.path)) {
        _checkedPaths.remove(node.path);
        node.isChecked = false;
      } else {
        _checkedPaths.add(node.path);
        node.isChecked = true;
      }
    });
  }

  void _toggleExpand(PickerNode node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
    });
  }

  /// 全选子项（仅一层）
  void _selectAllChildren(PickerNode node) {
    setState(() {
      for (final child in node.children) {
        if (!_checkedPaths.contains(child.path)) {
          _checkedPaths.add(child.path);
          child.isChecked = true;
        }
      }
    });
  }

  void _onConfirm({required bool deleteOriginal}) {
    Navigator.of(context).pop(
      ResourcePickerResult(
        paths: _checkedPaths.toList(),
        deleteOriginal: deleteOriginal,
      ),
    );
  }

  bool _isCompatibleFile(String name) {
    final ext = p.extension(name).toLowerCase();
    return _compatibleExtensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomButtons = _buildBottomButtons();

    return Dialog(
      child: Container(
        width: 440,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部栏
            _buildTopBar(theme),
            // 树形内容
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _buildTreeNodes(_roots, 0),
                    ),
            ),
            // 底部按钮
            bottomButtons ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            '已选 $_checkedCount 项',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTreeNodes(List<PickerNode> nodes, int depth) {
    final widgets = <Widget>[];
    for (final node in nodes) {
      widgets.add(_buildTreeNode(node, depth));
      if (node.isDirectory && node.isExpanded && node.children.isNotEmpty) {
        widgets.addAll(_buildTreeNodes(node.children, depth + 1));
      }
    }
    return widgets;
  }

  Widget _buildTreeNode(PickerNode node, int depth) {
    final theme = Theme.of(context);
    final padding = EdgeInsets.only(left: 16.0 + depth * 24.0, right: 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: node.isDirectory && !node.isLeaf
              ? () => _toggleExpand(node)
              : () => _toggleCheck(node),
          child: Padding(
            padding: padding,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  // 复选框（仅可作资源单元的节点显示）
                  if (!node.isDirectory || node.isLeaf)
                    GestureDetector(
                      onTap: () => _toggleCheck(node),
                      child: Icon(
                        node.isChecked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: node.isChecked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // 展开/折叠箭头
                  if (node.isDirectory && !node.isLeaf)
                    GestureDetector(
                      onTap: () => _toggleExpand(node),
                      child: Icon(
                        node.isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  // 图标
                  Icon(_nodeIcon(node), size: 20, color: _nodeColor(node)),
                  const SizedBox(width: 8),
                  // 名称
                  Expanded(
                    child: Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  // 全选子项按钮
                  if (node.isDirectory &&
                      !node.isLeaf &&
                      node.isExpanded &&
                      node.children.isNotEmpty)
                    TextButton(
                      onPressed: () => _selectAllChildren(node),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '全选子项',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomButtons() {
    switch (widget.mode) {
      case ResourcePickerMode.batchAdd:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checkedCount > 0
                      ? () => _onConfirm(deleteOriginal: false)
                      : null,
                  child: Text('批量添加资源 ($_checkedCount)'),
                ),
              ),
            ],
          ),
        );
      case ResourcePickerMode.splitKeep:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checkedCount > 0
                      ? () => _onConfirm(deleteOriginal: false)
                      : null,
                  child: Text('拆分并保留原资源 ($_checkedCount)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _checkedCount > 0
                      ? () => _onConfirm(deleteOriginal: true)
                      : null,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('拆分并删除原资源'),
                ),
              ),
            ],
          ),
        );
      case ResourcePickerMode.splitDelete:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checkedCount > 0
                      ? () => _onConfirm(deleteOriginal: true)
                      : null,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('拆分并删除原资源 ($_checkedCount)'),
                ),
              ),
            ],
          ),
        );
    }
  }

  IconData _nodeIcon(PickerNode node) {
    if (!node.isDirectory) {
      final ext = p.extension(node.name).toLowerCase();
      if (ext == '.pdf') return Icons.picture_as_pdf;
      if (ext == '.mp4' || ext == '.mkv') return Icons.movie;
      if (ext == '.zip' || ext == '.rar' || ext == '.7z') return Icons.archive;
      return Icons.image;
    }
    return Icons.folder;
  }

  Color _nodeColor(PickerNode node) {
    if (!node.isDirectory) {
      final ext = p.extension(node.name).toLowerCase();
      if (ext == '.pdf') return Colors.red;
      if (ext == '.mp4' || ext == '.mkv') return Colors.blue;
      return Colors.green;
    }
    return Colors.orange;
  }
}
