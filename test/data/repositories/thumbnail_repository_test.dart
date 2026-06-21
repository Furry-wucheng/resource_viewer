import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:resource_viewer/data/repositories/thumbnail_repository.dart';
import 'package:resource_viewer/data/services/thumbnail_cache_service.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/shared/file_source/local_file_source.dart';

void main() {
  test('重建 Repository 后文件预览仍命中磁盘缓存', () async {
    final temp = await Directory.systemTemp.createTemp('thumbnail_preview_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceDir = Directory(p.join(temp.path, 'source'))..createSync();
    final imageFile = File(p.join(sourceDir.path, 'cover.jpg'));
    final image = img.Image(width: 400, height: 600);
    img.fill(image, color: img.ColorRgb8(200, 20, 20));
    await imageFile.writeAsBytes(img.encodeJpg(image));
    final modifiedAt = (await imageFile.stat()).modified;
    final entry = FileEntry(
      name: 'cover.jpg',
      path: 'cover.jpg',
      isDirectory: false,
      size: BigInt.from(await imageFile.length()),
      modifiedAt: modifiedAt,
    );
    final source = LocalFileSource(
      sourceId: 'source',
      rootPath: sourceDir.path,
    );
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);

    final firstRepository = ThumbnailRepository(cache);
    final first = await firstRepository.preview(source, entry);
    expect(first, isA<Ok<Uint8List?>>());

    await imageFile.delete();
    final secondRepository = ThumbnailRepository(cache);
    final second = await secondRepository.preview(source, entry);

    expect(second, isA<Ok<Uint8List?>>());
    expect((second as Ok<Uint8List?>).value, isNotEmpty);
  });
}
