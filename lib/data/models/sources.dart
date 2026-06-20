import 'package:drift/drift.dart';
import 'enums.dart';

export 'enums.dart' show SourceType;

/// 数据源表定义
class Sources extends Table {
  /// 主键，UUIDv4
  TextColumn get id => text()();

  /// 用户自定义名称
  TextColumn get name => text().withLength(max: 100)();

  /// 数据源类型
  TextColumn get type => textEnum<SourceType>()();

  /// 根路径，如 D:\Comics 或 smb://192.168.1.100/share
  TextColumn get rootPath => text().withLength(max: 500)();

  /// 网络源主机地址
  TextColumn get host => text().withLength(max: 255).nullable()();

  /// 端口，默认 445
  IntColumn get port => integer().nullable()();

  /// 用户名
  TextColumn get username => text().withLength(max: 100).nullable()();

  /// 密码是否已存储（实际密码存 flutter_secure_storage）
  BoolColumn get passwordStored =>
      boolean().withDefault(const Constant(false))();

  /// 域/工作组
  TextColumn get domain => text().withLength(max: 100).nullable()();

  /// 是否启用（关闭后该源资源不在首页显示）
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// 当前是否可达
  BoolColumn get isAvailable => boolean().withDefault(const Constant(false))();

  /// 上次连接检查时间
  DateTimeColumn get lastCheckAt => dateTime().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
