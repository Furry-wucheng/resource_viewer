import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_entry.freezed.dart';
part 'file_entry.g.dart';

@freezed
abstract class FileEntry with _$FileEntry {
  const factory FileEntry({
    required String name,
    required String path,
    required bool isDirectory,
    BigInt? size,
    DateTime? modifiedAt,
  }) = _FileEntry;

  factory FileEntry.fromJson(Map<String, dynamic> json) =>
      _$FileEntryFromJson(json);
}
