import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/tag_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/tag.dart';

/// 标签选择弹窗
///
/// 显示所有标签列表，支持勾选/取消勾选，支持创建新标签。
/// 返回最终选中的标签 ID 列表。
class TagPickerDialog extends StatefulWidget {
  const TagPickerDialog({super.key, required this.selectedTagIds});

  final Set<String> selectedTagIds;

  /// 显示标签选择弹窗，返回选中的标签 ID 集合（null 表示取消）
  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> selectedTagIds,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (_) => TagPickerDialog(selectedTagIds: selectedTagIds),
    );
  }

  @override
  State<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<TagPickerDialog> {
  late TagRepository _tagRepo;
  List<Tag> _allTags = [];
  late Set<String> _selectedIds;
  bool _loading = true;
  bool _showCreateForm = false;
  final _nameController = TextEditingController();
  String _newTagColor = '#4CAF50'; // 默认绿色

  @override
  void initState() {
    super.initState();
    _tagRepo = context.read<TagRepository>();
    _selectedIds = Set.from(widget.selectedTagIds);
    _loadTags();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final result = await _tagRepo.getAllTags();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _allTags = value;
          _loading = false;
        });
      case Err():
        setState(() => _loading = false);
    }
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
  }

  Future<void> _createTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = const Uuid().v4();
    final result = await _tagRepo.createTag(
      id: id,
      name: name,
      color: _newTagColor,
    );

    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        setState(() {
          _allTags.add(value);
          _selectedIds.add(value.id);
          _showCreateForm = false;
          _nameController.clear();
        });
      case Err(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择标签'),
      content: SizedBox(
        width: 360,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 标签列表
                  Expanded(
                    child: _allTags.isEmpty
                        ? const Center(child: Text('暂无标签，请创建'))
                        : ListView.builder(
                            itemCount: _allTags.length,
                            itemBuilder: (context, index) {
                              final tag = _allTags[index];
                              final isSelected = _selectedIds.contains(tag.id);
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: _parseColor(tag.color),
                                ),
                                title: Text(tag.name),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                onTap: () => _toggleTag(tag.id),
                              );
                            },
                          ),
                  ),
                  // 创建新标签区域
                  const Divider(),
                  if (_showCreateForm) ...[
                    Row(
                      children: [
                        // 颜色选择
                        GestureDetector(
                          onTap: _showColorPicker,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: _parseColor(_newTagColor),
                            child: const Icon(
                              Icons.palette,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 名称输入
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: '标签名称',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            autofocus: true,
                            onSubmitted: (_) => _createTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: _createTag,
                          tooltip: '确认',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _showCreateForm = false),
                          tooltip: '取消',
                        ),
                      ],
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: () => setState(() => _showCreateForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('创建新标签'),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('确定'),
        ),
      ],
    );
  }

  void _showColorPicker() {
    final colors = [
      '#F44336',
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#2196F3',
      '#03A9F4',
      '#00BCD4',
      '#009688',
      '#4CAF50',
      '#8BC34A',
      '#CDDC39',
      '#FFC107',
      '#FF9800',
      '#FF5722',
      '#795548',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () {
                setState(() => _newTagColor = c);
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _parseColor(c),
                child: _newTagColor == c
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexClean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexClean', radix: 16));
  }
}
