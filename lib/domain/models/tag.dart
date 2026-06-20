import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// 标签领域模型（不可变）
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    required String color,
    @Default(false) bool isBuiltIn,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
