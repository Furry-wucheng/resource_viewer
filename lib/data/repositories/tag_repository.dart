import 'package:drift/drift.dart';

import '../services/database_service.dart';
import '../../domain/models/tag.dart' as domain;
import '../../domain/core/result.dart';

/// 标签 Repository
///
/// 负责 drift Tag 到 domain Tag 的转换，处理错误包装为 Result
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  /// 获取所有标签（内置在前，自定义按创建时间倒序）
  Future<Result<List<domain.Tag>>> getAllTags() async {
    try {
      final rows = await _db.getAllTags();
      final tags = rows.map(_toDomain).toList();
      // 排序：内置标签在前，自定义标签按创建时间倒序
      tags.sort((a, b) {
        if (a.isBuiltIn && !b.isBuiltIn) return -1;
        if (!a.isBuiltIn && b.isBuiltIn) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return Ok(tags);
    } catch (e) {
      return Err(DatabaseError('获取标签列表失败', cause: e));
    }
  }

  /// 监听所有标签变化
  Stream<Result<List<domain.Tag>>> watchAllTags() async* {
    try {
      await for (final rows in _db.watchAllTags()) {
        yield Ok(rows.map(_toDomain).toList());
      }
    } catch (error) {
      yield Err(DatabaseError('监听标签失败', cause: error));
    }
  }

  /// 根据 ID 获取标签
  Future<Result<domain.Tag?>> getTagById(String id) async {
    try {
      final row = await _db.getTagById(id);
      return Ok(row != null ? _toDomain(row) : null);
    } catch (e) {
      return Err(DatabaseError('获取标签失败', cause: e));
    }
  }

  /// 根据名称获取标签
  Future<Result<domain.Tag?>> getTagByName(String name) async {
    try {
      final row = await _db.getTagByName(name);
      return Ok(row != null ? _toDomain(row) : null);
    } catch (e) {
      return Err(DatabaseError('获取标签失败', cause: e));
    }
  }

  /// 创建标签
  Future<Result<domain.Tag>> createTag({
    required String id,
    required String name,
    required String color,
    bool isBuiltIn = false,
  }) async {
    try {
      // 校验标签名
      final validation = await _validateTagName(name);
      if (validation != null) {
        return Err(ValidationError(validation));
      }

      final companion = TagsCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(color),
        isBuiltIn: Value(isBuiltIn),
      );
      await _db.createTag(companion);
      final created = await _db.getTagById(id);
      if (created == null) {
        return Err(DatabaseError('创建标签后未找到记录'));
      }
      return Ok(_toDomain(created));
    } catch (e) {
      return Err(DatabaseError('创建标签失败', cause: e));
    }
  }

  /// 更新标签
  Future<Result<domain.Tag>> updateTag(domain.Tag tag) async {
    try {
      // 检查是否为内置标签
      if (tag.isBuiltIn) {
        return Err(ValidationError('内置标签不可修改'));
      }

      // 校验标签名（排除当前标签）
      final existing = await _db.getTagByName(tag.name);
      if (existing != null && existing.id != tag.id) {
        return Err(ValidationError("标签'${tag.name}'已存在"));
      }

      final companion = TagsCompanion(
        id: Value(tag.id),
        name: Value(tag.name),
        color: Value(tag.color),
        isBuiltIn: Value(tag.isBuiltIn),
      );
      final success = await _db.updateTag(companion);
      if (!success) {
        return Err(DatabaseError('更新标签失败，记录不存在'));
      }
      final updated = await _db.getTagById(tag.id);
      if (updated == null) {
        return Err(DatabaseError('更新标签后未找到记录'));
      }
      return Ok(_toDomain(updated));
    } catch (e) {
      return Err(DatabaseError('更新标签失败', cause: e));
    }
  }

  /// 重命名标签
  Future<Result<domain.Tag>> renameTag(String id, String newName) async {
    try {
      // 获取现有标签
      final existing = await _db.getTagById(id);
      if (existing == null) {
        return Err(DatabaseError('标签不存在'));
      }

      // 检查是否为内置标签
      if (existing.isBuiltIn) {
        return Err(ValidationError('内置标签不可重命名'));
      }

      // 校验新名称（排除自身）
      final validation = await _validateTagName(newName, excludeId: id);
      if (validation != null) {
        return Err(ValidationError(validation));
      }

      final companion = TagsCompanion(
        id: Value(id),
        name: Value(newName),
        color: Value(existing.color),
        isBuiltIn: Value(existing.isBuiltIn),
      );
      await _db.updateTag(companion);
      final updated = await _db.getTagById(id);
      if (updated == null) {
        return Err(DatabaseError('重命名标签后未找到记录'));
      }
      return Ok(_toDomain(updated));
    } catch (e) {
      return Err(DatabaseError('重命名标签失败', cause: e));
    }
  }

  /// 修改标签颜色
  Future<Result<domain.Tag>> updateColor(String id, String color) async {
    try {
      // 获取现有标签
      final existing = await _db.getTagById(id);
      if (existing == null) {
        return Err(DatabaseError('标签不存在'));
      }

      if (existing.isBuiltIn) {
        return Err(ValidationError('内置标签不可修改颜色'));
      }

      // 颜色格式校验
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
        return Err(ValidationError('颜色格式不正确，应为 #RRGGBB'));
      }

      final companion = TagsCompanion(
        id: Value(id),
        name: Value(existing.name),
        color: Value(color),
        isBuiltIn: Value(existing.isBuiltIn),
      );
      await _db.updateTag(companion);
      final updated = await _db.getTagById(id);
      if (updated == null) {
        return Err(DatabaseError('修改颜色后未找到记录'));
      }
      return Ok(_toDomain(updated));
    } catch (e) {
      return Err(DatabaseError('修改标签颜色失败', cause: e));
    }
  }

  /// 删除标签（级联删除关联的 ResourceTags）
  Future<Result<void>> deleteTag(String id) async {
    try {
      // 检查是否为内置标签
      final tag = await _db.getTagById(id);
      if (tag != null && tag.isBuiltIn) {
        return Err(ValidationError('内置标签不可删除'));
      }

      await _db.deleteTag(id);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('删除标签失败', cause: e));
    }
  }

  /// 为资源添加标签
  Future<Result<void>> addTagToResource(String resourceId, String tagId) async {
    try {
      await _db.addTagToResource(resourceId, tagId);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('为资源添加标签失败', cause: e));
    }
  }

  /// 移除资源的标签
  Future<Result<void>> removeTagFromResource(
    String resourceId,
    String tagId,
  ) async {
    try {
      await _db.removeTagFromResource(resourceId, tagId);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('移除资源标签失败', cause: e));
    }
  }

  /// 获取资源的所有标签
  Future<Result<List<domain.Tag>>> getTagsForResource(String resourceId) async {
    try {
      final rows = await _db.getTagsForResource(resourceId);
      final tags = rows.map(_toDomain).toList();
      return Ok(tags);
    } catch (e) {
      return Err(DatabaseError('获取资源标签失败', cause: e));
    }
  }

  /// 批量获取多个资源的标签。
  Future<Result<Map<String, List<domain.Tag>>>> getTagsForResources(
    List<String> resourceIds,
  ) async {
    try {
      final rows = await _db.getTagsForResources(resourceIds);
      return Ok({
        for (final entry in rows.entries)
          entry.key: entry.value.map(_toDomain).toList(),
      });
    } catch (e) {
      return Err(DatabaseError('批量获取资源标签失败', cause: e));
    }
  }

  /// 获取标签下的所有资源 ID
  Future<Result<List<String>>> getResourceIdsForTag(String tagId) async {
    try {
      final rows = await _db.getResourcesForTag(tagId);
      final ids = rows.map((r) => r.id).toList();
      return Ok(ids);
    } catch (e) {
      return Err(DatabaseError('获取标签资源失败', cause: e));
    }
  }

  /// 批量为资源设置标签
  Future<Result<void>> setTagsForResource(
    String resourceId,
    List<String> tagIds,
  ) async {
    try {
      await _db.setTagsForResource(resourceId, tagIds);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseError('设置资源标签失败', cause: e));
    }
  }

  /// 获取每个标签关联的资源数量
  Future<Result<Map<String, int>>> tagResourceCounts() async {
    try {
      final counts = await _db.tagResourceCounts();
      return Ok(counts);
    } catch (e) {
      return Err(DatabaseError('获取标签资源统计失败', cause: e));
    }
  }

  /// 按标签筛选资源（交集筛选）
  ///
  /// 使用 GROUP BY HAVING COUNT(*) = N 替代 INTERSECT
  Future<Result<List<Resource>>> filterByTags(List<String> tagIds) async {
    try {
      return Ok(await _db.filterByTags(tagIds));
    } catch (e) {
      return Err(DatabaseError('筛选资源失败', cause: e));
    }
  }

  /// 统计筛选结果数量
  Future<Result<int>> countFiltered(List<String> tagIds) async {
    try {
      final count = await _db.countFiltered(tagIds);
      return Ok(count);
    } catch (e) {
      return Err(DatabaseError('统计筛选结果失败', cause: e));
    }
  }

  // ============================================================================
  // 内部方法
  // ============================================================================

  /// 校验标签名（ViewModel 层操作前校验）
  ///
  /// [excludeId] 排除的标签 ID（用于重命名时排除自身）
  Future<String?> _validateTagName(String name, {String? excludeId}) async {
    if (name.trim().isEmpty) return '标签名不能为空';
    if (name == '收藏') return "'收藏'是系统内置标签，请换一个名称";
    final trimmedName = name.trim();
    if (trimmedName.length > 20) return '标签名不能超过 20 个字符';

    final existing = await _db.getTagByName(trimmedName);
    if (existing != null && existing.id != excludeId) {
      return "标签'$name'已存在";
    }

    return null; // 通过
  }

  // ============================================================================
  // 转换方法
  // ============================================================================

  /// drift Tag → domain Tag
  domain.Tag _toDomain(Tag row) {
    return domain.Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      isBuiltIn: row.isBuiltIn,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
