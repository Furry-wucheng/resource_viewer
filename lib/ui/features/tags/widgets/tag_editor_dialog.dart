import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 标签编辑弹窗
///
/// 可用于创建和编辑标签：输入名称 + 12 色选择器
class TagEditorDialog extends StatefulWidget {
  /// 创建模式
  const TagEditorDialog.create({
    super.key,
    this.initialColor,
    this.usedColors = const [],
  }) : initialName = null,
       title = '新建标签',
       isEdit = false;

  /// 编辑模式
  const TagEditorDialog.edit({
    super.key,
    required this.initialName,
    required this.initialColor,
  }) : title = '编辑标签',
       isEdit = true,
       usedColors = const [];

  final String? initialName;
  final String? initialColor;
  final String title;
  final bool isEdit;
  final List<String> usedColors;

  /// 显示标签创建/编辑弹窗
  ///
  /// 返回 `TagEditorResult`，取消返回 null
  static Future<TagEditorResult?> show({
    required BuildContext context,
    String? initialName,
    String? initialColor,
    String title = '新建标签',
    bool isEdit = false,
    List<String> usedColors = const [],
  }) {
    return showDialog<TagEditorResult>(
      context: context,
      builder: (context) => isEdit
          ? TagEditorDialog.edit(
              initialName: initialName!,
              initialColor: initialColor!,
            )
          : TagEditorDialog.create(
              initialColor: initialColor,
              usedColors: usedColors,
            ),
    );
  }

  @override
  State<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<TagEditorDialog> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  late String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? _getDefaultColor();
    _errorText = _validateName(_nameController.text);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text;
    setState(() {
      _errorText = _validateName(name);
    });
  }

  String? _validateName(String name) {
    if (name.trim().isEmpty) {
      return '标签名不能为空';
    }
    if (name.trim() == '收藏') {
      return "'收藏'是系统内置标签";
    }
    if (name.trim().length > 20) {
      return '标签名不能超过 20 个字符';
    }
    return null;
  }

  String _getDefaultColor() {
    final usedSet = widget.usedColors.toSet();
    for (final color in AppColors.tagPresets) {
      final hex = _colorToHex(color);
      if (!usedSet.contains(hex)) {
        return hex;
      }
    }
    return _colorToHex(AppColors.tagPresets.last);
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _onSave() {
    if (_errorText != null) return;

    Navigator.of(context).pop(
      TagEditorResult(name: _nameController.text.trim(), color: _selectedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名称输入框
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: '标签名称',
                hintText: '输入标签名称',
                errorText: _errorText,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // 颜色选择器标题
            Text(
              '选择颜色',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // 12 色选择器
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.tagPresets.map((color) {
                final hex = _colorToHex(color);
                final isSelected = hex == _selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _errorText == null ? _onSave : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 标签编辑结果
class TagEditorResult {
  const TagEditorResult({required this.name, required this.color});

  final String name;
  final String color;
}
