import 'package:freezed_annotation/freezed_annotation.dart';

part 'resource_tag.freezed.dart';
part 'resource_tag.g.dart';

@freezed
abstract class ResourceTag with _$ResourceTag {
  const factory ResourceTag({
    required String resourceId,
    required String tagId,
    required DateTime createdAt,
  }) = _ResourceTag;

  factory ResourceTag.fromJson(Map<String, dynamic> json) =>
      _$ResourceTagFromJson(json);
}
