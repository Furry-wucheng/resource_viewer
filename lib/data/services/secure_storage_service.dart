import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储服务
///
/// 封装 flutter_secure_storage，提供 SMB 密码的安全存取接口。
/// Key 命名规范：smb_pwd_{sourceId}
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Key 前缀
  static const _prefix = 'smb_pwd_';

  /// 保存密码
  ///
  /// [sourceId] 数据源 ID
  /// [password] 明文密码（加密存储由 flutter_secure_storage 处理）
  Future<void> savePassword(String sourceId, String password) async {
    await _storage.write(key: '$_prefix$sourceId', value: password);
  }

  /// 获取密码
  ///
  /// 返回明文密码，用于 SMB 连接。
  /// 如果未存储，返回 null。
  Future<String?> getPassword(String sourceId) async {
    return await _storage.read(key: '$_prefix$sourceId');
  }

  /// 删除密码
  ///
  /// 源删除时调用。
  Future<void> deletePassword(String sourceId) async {
    await _storage.delete(key: '$_prefix$sourceId');
  }

  /// 检查是否已存储密码
  Future<bool> hasPassword(String sourceId) async {
    return await _storage.containsKey(key: '$_prefix$sourceId');
  }

  /// 删除所有 SMB 密码（慎用，仅用于数据迁移或重置）
  Future<void> deleteAllPasswords() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_prefix)) {
        await _storage.delete(key: key);
      }
    }
  }
}
