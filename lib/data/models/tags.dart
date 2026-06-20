import 'package:drift/drift.dart';

/// 标签表定义
class Tags extends Table {
  /// 主键，UUIDv4（内置标签使用固定 UUID）
  TextColumn get id => text()();

  /// 标签名称（唯一）
  TextColumn get name => text().withLength(max: 20)();

  /// HEX 颜色值 #RRGGBB
  TextColumn get color => text().withLength(max: 7)();

  /// 是否为内置标签（内置标签不可删除/重命名）
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}
