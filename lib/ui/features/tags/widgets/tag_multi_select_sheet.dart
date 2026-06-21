import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/tag_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/tag.dart';
import '../../../core/theme/app_colors.dart';
import 'tag_editor_dialog.dart';

/// 标签多选弹窗
///
/// 可复用于：资源详情弹窗、批量打标签、添加资源附带打标签
class TagMultiSelectSheet extends StatefulWidget {
  const TagMultiSelectSheet({
    super.key,
    required this.selectedTagIds,
    this.title = '选择标签',
  });

  /// 当前已选中的标签 ID 集合
  final Set<String> selectedTagIds;

  /// 弹窗标题
  final String title;

  /// 显示标签多选弹窗
  ///
  /// 返回最终选中的标签 ID 集合，取消返回 null
  static Future<Set<String>?> show({
    required BuildContext context,
    required Set<String> selectedTagIds,
    String title = '选择标签',
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          TagMultiSelectSheet(selectedTagIds: selectedTagIds, title: title),
    );
  }

  @override
  State<TagMultiSelectSheet> createState() => _TagMultiSelectSheetState();
}

class _TagMultiSelectSheetState extends State<TagMultiSelectSheet> {
  late final TagRepository _tagRepo;
  List<Tag> _tags = [];
  late Set<String> _selectedIds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tagRepo = context.read<TagRepository>();
    _selectedIds = Set.from(widget.selectedTagIds);
    _loadTags();
  }

  Future<void> _loadTags() async {
    final result = await _tagRepo.getAllTags();
    switch (result) {
      case Ok(:final value):
        setState(() {
          _tags = value;
          _isLoading = false;
        });
      case Err():
        setState(() => _isLoading = false);
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

  Future<void> _onCreateTag() async {
    final result = await TagEditorDialog.show(context: context, title: '新建标签');

    if (result != null && mounted) {
      final id = const Uuid().v4();
      final createResult = await _tagRepo.createTag(
        id: id,
        name: result.name,
        color: result.color,
      );

      switch (createResult) {
        case Ok(:final value):
          setState(() {
            _selectedIds.add(value.id);
          });
          await _loadTags();
        case Err():
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('创建标签失败')));
          }
      }
    }
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          _buildHeader(theme),

          // 标签列表
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(child: _buildTagList(theme)),

          // 底部按钮
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '已选 ${_selectedIds.length} 个',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagList(ThemeData theme) {
    final builtInTags = _tags.where((t) => t.isBuiltIn).toList();
    final customTags = _tags.where((t) => !t.isBuiltIn).toList();

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 内置标签（收藏）
        if (builtInTags.isNotEmpty) ...[
          ...builtInTags.map(
            (tag) => _buildTagItem(tag: tag, isBuiltIn: true, theme: theme),
          ),
          if (customTags.isNotEmpty) const Divider(height: 1),
        ],

        // 自定义标签
        ...customTags.map(
          (tag) => _buildTagItem(tag: tag, isBuiltIn: false, theme: theme),
        ),

        // 空状态
        if (customTags.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              '暂无自定义标签',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagItem({
    required Tag tag,
    required bool isBuiltIn,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIds.contains(tag.id);
    final color = _hexToColor(tag.color);

    return InkWell(
      onTap: () => _toggleTag(tag.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // 图标
            if (isBuiltIn)
              Icon(Icons.star, color: AppColors.star, size: 20)
            else
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 12),

            // 标签名
            Expanded(child: Text(tag.name, style: theme.textTheme.bodyMedium)),

            // 勾选状态
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleTag(tag.id),
              activeColor: isBuiltIn ? AppColors.star : color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 新建标签按钮
          TextButton.icon(
            onPressed: _onCreateTag,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建标签'),
          ),
          const Spacer(),

          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),

          // 确认按钮
          FilledButton(onPressed: _onConfirm, child: const Text('确认')),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
