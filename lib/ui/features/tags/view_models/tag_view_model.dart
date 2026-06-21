import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../data/repositories/tag_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/tag.dart';
import '../../../core/view_models/base_view_model.dart';

/// 标签管理 ViewModel
///
/// 处理标签 CRUD 操作和状态管理
class TagViewModel extends BaseViewModel {
  TagViewModel({required this.tagRepository});

  final TagRepository tagRepository;
  final Uuid _uuid = const Uuid();

  List<Tag> _tags = [];
  List<Tag> _builtInTags = [];
  List<Tag> _customTags = [];

  List<Tag> get tags => _tags;
  List<Tag> get builtInTags => _builtInTags;
  List<Tag> get customTags => _customTags;

  /// 加载所有标签
  Future<void> loadTags() async {
    startLoading();

    final result = await tagRepository.getAllTags();
    switch (result) {
      case Ok(:final value):
        _tags = value;
        _splitTags();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 创建标签
  ///
  /// 返回创建的标签，失败返回 null
  Future<Tag?> createTag({required String name, required String color}) async {
    // 校验标签名
    final validation = validateTagName(name);
    if (validation != null) {
      return null;
    }

    final id = _uuid.v4();
    final result = await tagRepository.createTag(
      id: id,
      name: name.trim(),
      color: color,
    );

    switch (result) {
      case Ok(:final value):
        await loadTags();
        return value;
      case Err():
        return null;
    }
  }

  /// 重命名标签
  ///
  /// 返回更新后的标签，失败返回 null
  Future<Tag?> renameTag(String id, String newName) async {
    // 校验新名称
    final validation = validateTagName(newName, excludeId: id);
    if (validation != null) {
      return null;
    }

    final result = await tagRepository.renameTag(id, newName.trim());

    switch (result) {
      case Ok(:final value):
        await loadTags();
        return value;
      case Err():
        return null;
    }
  }

  /// 修改标签颜色
  ///
  /// 返回更新后的标签，失败返回 null
  Future<Tag?> updateColor(String id, String color) async {
    final result = await tagRepository.updateColor(id, color);

    switch (result) {
      case Ok(:final value):
        await loadTags();
        return value;
      case Err():
        return null;
    }
  }

  /// 删除标签
  ///
  /// 返回是否删除成功
  Future<bool> deleteTag(String id) async {
    final result = await tagRepository.deleteTag(id);

    switch (result) {
      case Ok():
        await loadTags();
        return true;
      case Err():
        return false;
    }
  }

  /// 校验标签名
  ///
  /// 返回错误信息，校验通过返回 null
  String? validateTagName(String name, {String? excludeId}) {
    if (name.trim().isEmpty) {
      return '标签名不能为空';
    }

    if (name.trim() == '收藏') {
      return "'收藏'是系统内置标签，请换一个名称";
    }

    if (name.trim().length > 20) {
      return '标签名不能超过 20 个字符';
    }

    // 检查是否重名
    final existing = _tags.where(
      (t) => t.name == name.trim() && t.id != excludeId,
    );
    if (existing.isNotEmpty) {
      return "标签'${name.trim()}'已存在";
    }

    return null;
  }

  /// 获取标签（按颜色分组，用于颜色选择器）
  List<String> getUsedColors() {
    return _tags.map((t) => t.color).toList();
  }

  /// 获取第一个未使用的颜色
  String getFirstUnusedColor(List<String> presetColors) {
    final usedColors = getUsedColors().toSet();
    return presetColors.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => presetColors.first,
    );
  }

  @override
  Future<void> retry() async {
    await loadTags();
  }

  // ============================================================================
  // 内部方法
  // ============================================================================

  /// 将标签分为内置和自定义两组
  void _splitTags() {
    _builtInTags = _tags.where((t) => t.isBuiltIn).toList();
    _customTags = _tags.where((t) => !t.isBuiltIn).toList();
  }
}
