import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/tag_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/tag.dart';
import '../../../core/theme/app_colors.dart';
import '../../tags/widgets/tag_multi_select_sheet.dart';

/// 资源详情弹窗
///
/// 元信息展示 + 标签编辑 + 组织模式切换。
class ResourceDetailSheet extends StatefulWidget {
  const ResourceDetailSheet({
    super.key,
    required this.resource,
    this.onResourceUpdated,
  });

  final Resource resource;
  final VoidCallback? onResourceUpdated;

  /// 显示资源详情弹窗（居中 Dialog）
  static Future<void> show({
    required BuildContext context,
    required Resource resource,
    VoidCallback? onResourceUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ResourceDetailSheet(
        resource: resource,
        onResourceUpdated: onResourceUpdated,
      ),
    );
  }

  @override
  State<ResourceDetailSheet> createState() => _ResourceDetailSheetState();
}

class _ResourceDetailSheetState extends State<ResourceDetailSheet> {
  late Resource _resource;
  late TextEditingController _nameController;
  OrganizationMode? _organizationMode;
  Set<String> _selectedTagIds = {};
  List<Tag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
    _nameController = TextEditingController(text: _resource.name);
    _organizationMode = _resource.organizationMode;
    _loadTags();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final tagRepo = context.read<TagRepository>();
    final result = await tagRepo.getTagsForResource(_resource.id);
    switch (result) {
      case Ok(:final value):
        _selectedTagIds = value.map((t) => t.id).toSet();
      case Err():
        break;
    }

    final allResult = await tagRepo.getAllTags();
    switch (allResult) {
      case Ok(:final value):
        _tags = value;
      case Err():
        break;
    }

    setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _resource.name) return;

    final repo = context.read<ResourceRepository>();
    final updated = _resource.copyWith(name: newName);
    final result = await repo.updateResource(updated);
    switch (result) {
      case Ok(:final value):
        setState(() => _resource = value);
        widget.onResourceUpdated?.call();
      case Err(:final error):
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
    }
  }

  Future<void> _setOrganizationMode(OrganizationMode mode) async {
    setState(() => _organizationMode = mode);
    final repo = context.read<ResourceRepository>();
    final updated = _resource.copyWith(organizationMode: mode);
    final result = await repo.updateResource(updated);
    switch (result) {
      case Ok(:final value):
        setState(() => _resource = value);
        widget.onResourceUpdated?.call();
      case Err(:final error):
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _loading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                        child: Text(
                          '资源详情',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // 名称编辑
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '资源名称',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: _saveName,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 信息区域
                      _buildInfoRows(theme),
                      const Divider(),
                      // 组织模式
                      _buildOrgModeSelector(theme),
                      const Divider(),
                      // 标签编辑
                      _buildTagsSection(theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRows(ThemeData theme) {
    final typeLabel = switch (_resource.type) {
      ResourceType.folder => '文件夹',
      ResourceType.pdf => 'PDF',
      ResourceType.archive => '压缩包',
      ResourceType.video => '视频',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _infoRow(theme, '类型', typeLabel),
          _infoRow(theme, '路径', _resource.relativePath),
          if (_resource.fileCount != null)
            _infoRow(theme, '文件数', '${_resource.fileCount}'),
          _infoRow(
            theme,
            '添加时间',
            '${_resource.createdAt.year}-${_resource.createdAt.month.toString().padLeft(2, '0')}-${_resource.createdAt.day.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgModeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('组织模式', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _orgModeChip(theme, OrganizationMode.chapter, '章节'),
              _orgModeChip(theme, OrganizationMode.chapterGallery, '章节画廊'),
              _orgModeChip(theme, OrganizationMode.flatgrid, '平铺网格'),
              _orgModeChip(theme, OrganizationMode.gallery, '画廊'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orgModeChip(ThemeData theme, OrganizationMode mode, String label) {
    final isSelected = _organizationMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setOrganizationMode(mode),
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('标签', style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton(onPressed: _editTags, child: const Text('编辑标签')),
            ],
          ),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .where((t) => _selectedTagIds.contains(t.id))
                  .map(
                    (tag) => Chip(
                      label: Text(tag.name),
                      backgroundColor: _hexToColor(
                        tag.color,
                      ).withValues(alpha: 0.2),
                      side: BorderSide(color: _hexToColor(tag.color)),
                    ),
                  )
                  .toList(),
            )
          else
            Text('暂无标签', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _editTags() async {
    final result = await TagMultiSelectSheet.show(
      context: context,
      selectedTagIds: _selectedTagIds,
      title: '编辑标签',
    );

    if (result != null && mounted) {
      final tagRepo = context.read<TagRepository>();
      final updateResult = await tagRepo.setTagsForResource(
        _resource.id,
        result.toList(),
      );
      switch (updateResult) {
        case Ok():
          setState(() => _selectedTagIds = result);
          widget.onResourceUpdated?.call();
        case Err(:final error):
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message)));
          }
      }
    }
  }

  Color _hexToColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
