import 'package:drift/native.dart';
import 'package:resource_viewer/data/services/database_service.dart';

/// 创建内存数据库用于测试
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
