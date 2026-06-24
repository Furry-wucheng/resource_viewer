import 'package:freezed_annotation/freezed_annotation.dart';

part 'resource.freezed.dart';
part 'resource.g.dart';

/// 资源类型枚举
enum ResourceType {
  folder, // 文件夹（图片文件夹）
  pdf, // PDF 文件
  archive, // 压缩包
  video, // 视频文件
}

/// 组织模式枚举
enum OrganizationMode {
  direct, // 直接阅读
  chapter, // 章节模式
  chapterGallery, // 章节画廊模式
  flatgrid, // 平铺网格
  gallery, // 画廊模式
}

/// 资源领域模型（不可变）
@freezed
abstract class Resource with _$Resource {
  const factory Resource({
    required String id,
    required String sourceId,
    required String name,
    required ResourceType type,
    OrganizationMode? organizationMode,
    required String relativePath,
    String? thumbnailPath,
    int? fileCount,
    BigInt? fileSize,
    @Default(true) bool isAvailable,
    DateTime? lastScannedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Resource;

  factory Resource.fromJson(Map<String, dynamic> json) =>
      _$ResourceFromJson(json);
}
