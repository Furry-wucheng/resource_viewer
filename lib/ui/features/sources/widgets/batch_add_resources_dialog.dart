import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/tag_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/tag.dart';
import '../../../core/theme/app_colors.dart';
import '../../tags/widgets/tag_editor_dialog.dart';
import '../../viewer/widgets/org_mode_switcher.dart';

/// 批量添加资源弹窗的返回结果
class BatchAddDialogResult {
  const BatchAddDialogResult({
    this.organizationMode, // null = 智能判定
    required this.tagIds,
  });

  final OrganizationMode? organizationMode;
  final Set<String> tagIds;
}

/// 统一批量添加资源弹窗
///
/// 合并了原有的确认弹窗 + TagMultiSelectSheet 两步流程，
/// 并增加了组织模式选择（含智能判定开关）。
class BatchAddResourcesDialog extends StatefulWidget {
  const BatchAddResourcesDialog({super.key, required this.itemCount});

  final int itemCount;

  /// 显示统一批量添加资源弹窗
  ///
  /// 返回 [BatchAddDialogResult]，取消返回 null。
  static Future<BatchAddDialogResult?> show({
    required BuildContext context,
    required int itemCount,
  }) {
    return showDialog<BatchAddDialogResult>(
      context: context,
      builder: (_) => BatchAddResourcesDialog(itemCount: itemCount),
    );
  }

  @override
  State<BatchAddResourcesDialog> createState() =>
      _BatchAddResourcesDialogState();
}

class _BatchAddResourcesDialogState extends State<BatchAddResourcesDialog> {
  late final TagRepository _tagRepo;

  /// null = 智能判定
  OrganizationMode? _selectedMode;
  bool _useSmartDetection = true;

  List<Tag> _tags = [];
  final Set<String> _selectedTagIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tagRepo = context.read<TagRepository>();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final result = await _tagRepo.getAllTags();
    if (!mounted) return;
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
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _onModeChanged(OrganizationMode mode) {
    setState(() => _selectedMode = mode);
  }

  void _onSmartDetectionChanged(bool value) {
    setState(() {
      _useSmartDetection = value;
      if (value) {
        _selectedMode = null;
      } else {
        _selectedMode = OrganizationMode.chapter;
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
            _selectedTagIds.add(value.id);
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
    Navigator.of(context).pop(
      BatchAddDialogResult(
        organizationMode: _selectedMode,
        tagIds: Set.from(_selectedTagIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            _buildHeader(theme),

            // 摘要
            _buildSummary(theme),

            // 组织模式区域
            _buildOrgModeSection(theme),

            const Divider(height: 1),

            // 标签区域
            _buildTagSection(theme),

            // 底部按钮
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Text(
        '批量添加资源',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        '将检查并添加 ${widget.itemCount} 个所选项目，空文件夹和已入库项目会被跳过。',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOrgModeSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 智能判定开关
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: _useSmartDetection
                    ? theme.colorScheme.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '打开时自动判定',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                child: Switch(
                  value: _useSmartDetection,
                  onChanged: _onSmartDetectionChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          // 手动模式选择器
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _useSmartDetection
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrgModeSwitcher(
                          currentMode: _selectedMode,
                          onModeChanged: _onModeChanged,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '关闭后将统一使用所选模式',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签区域标题
          Row(
            children: [
              Text(
                '标签',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '（可选）',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!_isLoading)
                Text(
                  '已选 ${_selectedTagIds.length} 个',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 标签列表
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(height: 200, child: _buildTagList(theme)),

          // 新建标签按钮
          TextButton.icon(
            onPressed: _onCreateTag,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建标签'),
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
      children: [
        // 内置标签
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
    final isSelected = _selectedTagIds.contains(tag.id);
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
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _onConfirm,
            child: Text('添加 ${widget.itemCount} 项资源'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
