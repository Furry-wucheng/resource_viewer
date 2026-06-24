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

  test('支持图片预览压缩解码失败时小文件回退到原始字节', () async {
    final temp = await Directory.systemTemp.createTemp('thumbnail_image_raw_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceDir = Directory(p.join(temp.path, 'source'))..createSync();
    final imageFile = File(p.join(sourceDir.path, 'special.webp'));
    final originalBytes = Uint8List.fromList([1, 2, 3, 4]);
    await imageFile.writeAsBytes(originalBytes);
    final source = LocalFileSource(
      sourceId: 'source',
      rootPath: sourceDir.path,
    );
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);
    final repository = ThumbnailRepository(cache);

    final result = await repository.preview(
      source,
      FileEntry(
        name: 'special.webp',
        path: 'special.webp',
        isDirectory: false,
        size: BigInt.from(originalBytes.length),
        modifiedAt: DateTime(2026),
      ),
    );

    expect(result, isA<Ok<Uint8List?>>());
    expect((result as Ok<Uint8List?>).value, originalBytes);
  });

  test('支持图片预览压缩解码失败时大文件不回退原始字节', () async {
    final temp = await Directory.systemTemp.createTemp('thumbnail_image_big_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceDir = Directory(p.join(temp.path, 'source'))..createSync();
    final imageFile = File(p.join(sourceDir.path, 'large.jpg'));
    final originalBytes = Uint8List(513 * 1024);
    await imageFile.writeAsBytes(originalBytes);
    final source = LocalFileSource(
      sourceId: 'source',
      rootPath: sourceDir.path,
    );
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);
    final repository = ThumbnailRepository(cache);

    final result = await repository.preview(
      source,
      FileEntry(
        name: 'large.jpg',
        path: 'large.jpg',
        isDirectory: false,
        size: BigInt.from(originalBytes.length),
        modifiedAt: DateTime(2026),
      ),
    );

    expect(result, isA<Ok<Uint8List?>>());
    expect((result as Ok<Uint8List?>).value, isNull);
  });

  test('文件夹预览会使用直属图片文件', () async {
    final temp = await Directory.systemTemp.createTemp('thumbnail_direct_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceDir = Directory(p.join(temp.path, 'source'))..createSync();
    final imageFile = File(p.join(sourceDir.path, '001.jpg'));
    final image = img.Image(width: 400, height: 600);
    img.fill(image, color: img.ColorRgb8(20, 200, 20));
    await imageFile.writeAsBytes(img.encodeJpg(image));
    final source = LocalFileSource(
      sourceId: 'source',
      rootPath: sourceDir.path,
    );
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);
    final repository = ThumbnailRepository(cache);

    final result = await repository.preview(
      source,
      FileEntry(
        name: 'book',
        path: '',
        isDirectory: true,
        modifiedAt: DateTime(2026),
      ),
    );

    expect(result, isA<Ok<Uint8List?>>());
    expect((result as Ok<Uint8List?>).value, isNotEmpty);
  });

  test('文件夹预览不会扫描直属子目录', () async {
    final temp = await Directory.systemTemp.createTemp('thumbnail_shallow_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceDir = Directory(p.join(temp.path, 'source'))..createSync();
    final nestedDir = Directory(p.join(sourceDir.path, 'chapter-1'))
      ..createSync();
    final imageFile = File(p.join(nestedDir.path, '001.jpg'));
    final image = img.Image(width: 400, height: 600);
    img.fill(image, color: img.ColorRgb8(20, 200, 20));
    await imageFile.writeAsBytes(img.encodeJpg(image));
    final source = LocalFileSource(
      sourceId: 'source',
      rootPath: sourceDir.path,
    );
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);
    final repository = ThumbnailRepository(cache);

    final result = await repository.preview(
      source,
      FileEntry(
        name: 'book',
        path: '',
        isDirectory: true,
        modifiedAt: DateTime(2026),
      ),
    );

    expect(result, isA<Ok<Uint8List?>>());
    expect((result as Ok<Uint8List?>).value, isNull);
  });
}
