import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/tag_repository.dart';
import '../../../domain/core/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/view_models/base_view_model.dart';
import 'view_models/tag_view_model.dart';
import 'widgets/tag_editor_dialog.dart';

/// 标签管理页
///
/// 全屏路由 `/tags/manager`，使用 `parentNavigatorKey`
class TagManagerPage extends StatefulWidget {
  const TagManagerPage({super.key});

  @override
  State<TagManagerPage> createState() => _TagManagerPageState();
}

class _TagManagerPageState extends State<TagManagerPage> {
  late final TagViewModel _viewModel;
  Map<String, int> _resourceCounts = {};

  @override
  void initState() {
    super.initState();
    _viewModel = TagViewModel(tagRepository: context.read<TagRepository>());
    _viewModel.addListener(_onStateChanged);
    _viewModel.loadTags();
    _loadResourceCounts();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Future<void> _loadResourceCounts() async {
    final tagRepo = context.read<TagRepository>();
    final result = await tagRepo.tagResourceCounts();
    switch (result) {
      case Ok(:final value):
        setState(() => _resourceCounts = value);
      case Err():
        break;
    }
  }

  Future<void> _onCreateTag() async {
    final usedColors = _viewModel.getUsedColors();
    final result = await TagEditorDialog.show(
      context: context,
      usedColors: usedColors,
    );

    if (result != null && mounted) {
      final created = await _viewModel.createTag(
        name: result.name,
        color: result.color,
      );
      if (created == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('创建标签失败')));
      }
      await _loadResourceCounts();
    }
  }

  Future<void> _onRenameTag(dynamic tag) async {
    final result = await TagEditorDialog.show(
      context: context,
      initialName: tag.name,
      initialColor: tag.color,
      title: '重命名标签',
      isEdit: true,
    );

    if (result != null && mounted) {
      final updated = await _viewModel.renameTag(tag.id, result.name);
      if (updated == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('重命名失败')));
      }
      await _loadResourceCounts();
    }
  }

  Future<void> _onChangeColor(dynamic tag) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ColorPickerDialog(currentColor: tag.color),
    );

    if (result != null && mounted) {
      final updated = await _viewModel.updateColor(tag.id, result);
      if (updated == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('修改颜色失败')));
      }
      await _loadResourceCounts();
    }
  }

  Future<void> _onDeleteTag(dynamic tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('删除标签"${tag.name}"将解除所有资源的关联，确定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deleteTag(tag.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除标签失败')));
      }
      await _loadResourceCounts();
    }
  }

  void _onTagTap(dynamic tag) {
    // 跳转首页并预置筛选条件
    context.go('/home?filterTag=${tag.id}');
  }

  void _showTagMenu(dynamic tag, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('重命名'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'color',
          child: const Row(
            children: [
              Icon(Icons.palette, size: 16),
              SizedBox(width: 8),
              Text('修改颜色'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text('删除', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'rename':
          _onRenameTag(tag);
          break;
        case 'color':
          _onChangeColor(tag);
          break;
        case 'delete':
          _onDeleteTag(tag);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('标签管理'),
        actions: [
          TextButton.icon(
            onPressed: _onCreateTag,
            icon: const Icon(Icons.add),
            label: const Text('新建标签'),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_viewModel.state) {
      case UiState.idle:
      case UiState.loading:
        return const Center(child: CircularProgressIndicator());

      case UiState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_viewModel.errorMessage ?? '加载失败'),
              if (_viewModel.canRetry) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _viewModel.retry,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        );

      case UiState.success:
        return _buildTagList(theme);
    }
  }

  Widget _buildTagList(ThemeData theme) {
    final builtInTags = _viewModel.builtInTags;
    final customTags = _viewModel.customTags;

    if (builtInTags.isEmpty && customTags.isEmpty) {
      return const Center(child: Text('暂无标签'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 内置标签区域
        if (builtInTags.isNotEmpty) ...[
          _buildSectionTitle('内置标签', theme),
          const SizedBox(height: 8),
          _buildTagCard(builtInTags, isBuiltIn: true, theme: theme),
        ],

        // 自定义标签区域
        if (customTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('自定义标签', theme),
          const SizedBox(height: 8),
          _buildTagCard(customTags, isBuiltIn: false, theme: theme),
        ],

        // 空状态
        if (customTags.isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.label_off,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  '创建第一个标签吧',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _onCreateTag,
                  icon: const Icon(Icons.add),
                  label: const Text('新建标签'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTagCard(
    List<dynamic> tags, {
    required bool isBuiltIn,
    required ThemeData theme,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tags.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final count = _resourceCounts[tag.id] ?? 0;

          return _buildTagItem(
            tag: tag,
            count: count,
            isBuiltIn: isBuiltIn,
            theme: theme,
          );
        },
      ),
    );
  }

  Widget _buildTagItem({
    required dynamic tag,
    required int count,
    required bool isBuiltIn,
    required ThemeData theme,
  }) {
    final color = _hexToColor(tag.color);

    return InkWell(
      onTap: () => _onTagTap(tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 颜色圆点
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),

            // 标签信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tag.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isBuiltIn) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '内置',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '共 $count 个资源',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 操作菜单（仅自定义标签）
            if (!isBuiltIn)
              GestureDetector(
                onTapDown: (details) {
                  _showTagMenu(tag, details.globalPosition);
                },
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}

/// 颜色选择器弹窗
class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({required this.currentColor});

  final String currentColor;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppColors.tagPresets.map((color) {
            final hex =
                '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            final isSelected = hex == currentColor;

            return GestureDetector(
              onTap: () => Navigator.of(context).pop(hex),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.onSurface, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
