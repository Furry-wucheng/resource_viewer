import 'package:drift/drift.dart';

import 'enums.dart';
import 'sources.dart';

export 'enums.dart' show OrganizationMode, ResourceType;

/// 资源表定义
@TableIndex(name: 'idx_resources_created_at_id', columns: {#createdAt, #id})
@TableIndex(name: 'idx_resources_name_id', columns: {#name, #id})
class Resources extends Table {
  /// 主键，UUIDv4
  TextColumn get id => text()();

  /// 所属数据源 ID（外键）
  TextColumn get sourceId =>
      text().references(Sources, #id, onDelete: KeyAction.cascade)();

  /// 资源名称（文件夹名或文件名）
  TextColumn get name => text().withLength(max: 255)();

  /// 资源类型
  TextColumn get type => textEnum<ResourceType>()();

  /// 组织模式（null = 未判定）
  TextColumn get organizationMode => textEnum<OrganizationMode>().nullable()();

  /// 相对于源根目录的路径
  TextColumn get relativePath => text().withLength(max: 1000)();

  /// 本地缓存缩略图路径
  TextColumn get thumbnailPath => text().withLength(max: 500).nullable()();

  /// 内部图片/页数
  IntColumn get fileCount => integer().nullable()();

  /// 文件大小（字节）
  Column<BigInt> get fileSize => int64().nullable()();

  /// 文件当前是否可访问
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  /// 最后扫描时间
  DateTimeColumn get lastScannedAt => dateTime().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, relativePath},
  ];
}
