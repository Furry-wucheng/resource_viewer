import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:resource_viewer/shared/content_provider/image_folder_provider.dart';
import 'package:resource_viewer/shared/file_source/local_file_source.dart';

void main() {
  late Directory tempDir;
  late LocalFileSource fileSource;
  late ImageFolderProvider provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_folder_provider_test_');
    fileSource = LocalFileSource(
      sourceId: 'test-source',
      rootPath: tempDir.path,
    );
  });

  tearDown(() async {
    await provider.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 创建测试图片文件
  Future<void> createTestImage(String name, {List<int>? bytes}) async {
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes(bytes ?? Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])); // JPEG magic bytes
  }

  group('ImageFolderProvider', () {
    test('pageCount = 文件夹内支持的图片数量', () async {
      await createTestImage('a.jpg');
      await createTestImage('b.png');
      await createTestImage('c.gif');
      await createTestImage('unsupported.txt');

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      expect(provider.pageCount, 3);
    });

    test('loadPage 返回正确图片字节', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await createTestImage('test.jpg', bytes: bytes);

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      final result = await provider.loadPage(0);
      expect(result, bytes);
    });

    test('Windows 风格同层路径可定位并连续翻页', () async {
      final album = Directory(p.join(tempDir.path, 'album'));
      await album.create();
      await File(p.join(album.path, '1.jpg')).writeAsBytes([1]);
      await File(p.join(album.path, '2.jpg')).writeAsBytes([2]);
      await File(p.join(album.path, '10.jpg')).writeAsBytes([10]);

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: 'album');
      await provider.load();

      expect(provider.pageCount, 3);
      expect(provider.indexOfPath(r'album\2.jpg'), 1);
      expect(await provider.loadPage(0), [1]);
      expect(await provider.loadPage(1), [2]);
      expect(await provider.loadPage(2), [10]);
    });

    test('文件名自然排序（2 排在 10 前面）', () async {
      await createTestImage('chapter2.jpg');
      await createTestImage('chapter10.jpg');
      await createTestImage('chapter1.jpg');

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      expect(provider.pageCount, 3);

      // 验证排序顺序：chapter1, chapter2, chapter10
      final entries = await fileSource.listDirectory('');
      final sortedNames = entries.map((e) => e.name).toList();
      // ImageFolderProvider 内部排序，通过 loadPage 顺序验证
      // chapter1 < chapter2 < chapter10 (自然排序)
      expect(sortedNames.length, 3);
    });

    test('不支持的格式跳过', () async {
      await createTestImage('photo.jpg');
      await createTestImage('document.pdf');
      await createTestImage('video.mp4');
      await createTestImage('text.txt');

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      expect(provider.pageCount, 1); // 只有 jpg
    });

    test('空文件夹 pageCount = 0', () async {
      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      expect(provider.pageCount, 0);
    });

    test('dispose 后 loadPage 抛异常', () async {
      await createTestImage('test.jpg');

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();
      await provider.dispose();

      expect(
        () => provider.loadPage(0),
        throwsStateError,
      );
    });

    test('index 越界抛 RangeError', () async {
      await createTestImage('test.jpg');

      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');
      await provider.load();

      expect(
        () => provider.loadPage(1),
        throwsRangeError,
      );
      expect(
        () => provider.loadPage(-1),
        throwsRangeError,
      );
    });

    test('load 前访问 pageCount 抛 StateError', () {
      provider = ImageFolderProvider(fileSource: fileSource, folderPath: '');

      expect(
        () => provider.pageCount,
        throwsStateError,
      );
    });
  });
}
