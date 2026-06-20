import 'package:drift/drift.dart';

import 'resources.dart';
import 'tags.dart';

/// 资源-标签关联表定义
///
/// 使用联合主键 (resourceId, tagId) 确保唯一性
/// 手动添加 (tagId, resourceId) 索引以优化标签筛选查询
@TableIndex.sql(
  'CREATE INDEX idx_rt_tag_resource ON resource_tags (tag_id, resource_id)',
)
class ResourceTags extends Table {
  /// 资源 ID（外键，联合主键之一）
  TextColumn get resourceId =>
      text().references(Resources, #id, onDelete: KeyAction.cascade)();

  /// 标签 ID（外键，联合主键之一）
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {resourceId, tagId};
}
