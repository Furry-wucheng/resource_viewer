import 'package:freezed_annotation/freezed_annotation.dart';

part 'source.freezed.dart';
part 'source.g.dart';

/// 数据源类型枚举
enum SourceType {
  local, // 本地文件系统
  smb, // SMB 网络共享
  ftp, // FTP（架构预留）
  webdav, // WebDAV（架构预留）
}

/// 数据源领域模型（不可变）
@freezed
abstract class Source with _$Source {
  const factory Source({
    required String id,
    required String name,
    required SourceType type,
    required String rootPath,
    String? host,
    int? port,
    String? username,
    @Default(false) bool passwordStored,
    String? domain,
    @Default(true) bool enabled,
    @Default(false) bool isAvailable,
    DateTime? lastCheckAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}
