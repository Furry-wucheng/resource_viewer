import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:resource_viewer/shared/file_source/local_file_source.dart';

void main() {
  late Directory tempDir;
  late LocalFileSource source;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('local_file_source_test_');
    source = LocalFileSource(
      sourceId: 'test-source',
      rootPath: tempDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 创建测试文件
  Future<void> createTestFile(String relativePath, {List<int>? bytes}) async {
    final file = File(p.join(tempDir.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes ?? [0, 1, 2, 3]);
  }

  /// 创建测试目录
  Future<void> createTestDir(String relativePath) async {
    await Directory(p.join(tempDir.path, relativePath)).create(recursive: true);
  }

  group('LocalFileSource', () {
    group('listDirectory', () {
      test('空目录返回空列表', () async {
        final result = await source.listDirectory('');
        expect(result, isEmpty);
      });

      test('文件夹在前，文件在后', () async {
        await createTestDir('subfolder');
        await createTestFile('image.jpg');
        await createTestFile('document.pdf');

        final result = await source.listDirectory('');

        expect(result.length, 3);
        expect(result[0].isDirectory, true);
        expect(result[0].name, 'subfolder');
        expect(result[1].isDirectory, false);
        expect(result[2].isDirectory, false);
      });

      test('按名称字母升序排列', () async {
        await createTestDir('zebra');
        await createTestDir('apple');
        await createTestDir('banana');

        final result = await source.listDirectory('');

        expect(result.length, 3);
        expect(result[0].name, 'apple');
        expect(result[1].name, 'banana');
        expect(result[2].name, 'zebra');
      });

      test('自然排序（2 排在 10 前面）', () async {
        await createTestFile('chapter2.jpg');
        await createTestFile('chapter10.jpg');
        await createTestFile('chapter1.jpg');

        final result = await source.listDirectory('');

        expect(result.length, 3);
        expect(result[0].name, 'chapter1.jpg');
        expect(result[1].name, 'chapter2.jpg');
        expect(result[2].name, 'chapter10.jpg');
      });

      test('过滤隐藏文件', () async {
        await createTestFile('.hidden');
        await createTestFile('visible.jpg');

        final result = await source.listDirectory('');

        expect(result.length, 1);
        expect(result[0].name, 'visible.jpg');
      });

      test('仅显示支持的文件类型', () async {
        await createTestFile('image.jpg');
        await createTestFile('image.png');
        await createTestFile('document.pdf');
        await createTestFile('video.mp4');
        await createTestFile('archive.zip');
        await createTestFile('unsupported.txt');
        await createTestFile('unsupported.doc');

        final result = await source.listDirectory('');

        expect(result.length, 5);
        final names = result.map((e) => e.name).toSet();
        expect(names.contains('unsupported.txt'), false);
        expect(names.contains('unsupported.doc'), false);
      });

      test('FileEntry 包含正确的属性', () async {
        await createTestFile('test.jpg', bytes: List.filled(100, 0));

        final result = await source.listDirectory('');

        expect(result.length, 1);
        final entry = result[0];
        expect(entry.name, 'test.jpg');
        expect(entry.isDirectory, false);
        expect(entry.size, BigInt.from(100));
        expect(entry.modifiedAt, isNotNull);
      });

      test('支持的图片格式', () async {
        for (final ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']) {
          await createTestFile('image$ext');
        }

        final result = await source.listDirectory('');
        expect(result.length, 6);
      });

      test('支持的视频格式', () async {
        for (final ext in ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm']) {
          await createTestFile('video$ext');
        }

        final result = await source.listDirectory('');
        expect(result.length, 6);
      });
    });

    group('stat', () {
      test('返回文件信息', () async {
        await createTestFile('test.jpg', bytes: List.filled(42, 0));

        final entry = await source.stat('test.jpg');

        expect(entry, isNotNull);
        expect(entry!.name, 'test.jpg');
        expect(entry.isDirectory, false);
        expect(entry.size, BigInt.from(42));
      });

      test('返回文件夹信息', () async {
        await createTestDir('mydir');

        final entry = await source.stat('mydir');

        expect(entry, isNotNull);
        expect(entry!.name, 'mydir');
        expect(entry.isDirectory, true);
      });

      test('不存在的路径返回 null', () async {
        final entry = await source.stat('nonexistent');
        expect(entry, isNull);
      });
    });

    group('readFile', () {
      test('读取文件内容', () async {
        final bytes = [1, 2, 3, 4, 5];
        await createTestFile('data.bin', bytes: bytes);

        final result = await source.readFile('data.bin');
        expect(result, bytes);
      });

      test('不存在的文件抛出异常', () async {
        expect(
          () => source.readFile('nonexistent.jpg'),
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('testConnection', () {
      test('存在的目录返回 true', () async {
        final result = await source.testConnection();
        expect(result, true);
      });

      test('不存在的目录返回 false', () async {
        final badSource = LocalFileSource(
          sourceId: 'bad',
          rootPath: '/nonexistent/path/that/does/not/exist',
        );
        final result = await badSource.testConnection();
        expect(result, false);
      });
    });

    group('disconnect', () {
      test('空操作不抛异常', () async {
        expect(() => source.disconnect(), returnsNormally);
      });
    });
  });
}
