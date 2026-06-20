import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:resource_viewer/shared/file_source/local_file_source.dart';
import 'package:resource_viewer/shared/thumbnail/image_thumbnail_generator.dart';

void main() {
  late Directory tempDir;
  late LocalFileSource fileSource;
  late ImageThumbnailGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_thumbnail_test_');
    fileSource = LocalFileSource(
      sourceId: 'test-source',
      rootPath: tempDir.path,
    );
    generator = ImageThumbnailGenerator(outputDirectory: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 创建一个测试 JPEG 图片
  Future<void> createTestImage(String name, {int width = 400, int height = 300}) async {
    final image = img.Image(width: width, height: height);
    // 填充红色
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final bytes = img.encodeJpg(image);
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes(bytes);
  }

  group('ImageThumbnailGenerator', () {
    test('生成缩略图路径不为 null', () async {
      await createTestImage('test.jpg');

      final result = await generator.generate(fileSource, '', 'resource-1');

      expect(result, isNotNull);
    });

    test('生成的缩略图文件存在', () async {
      await createTestImage('test.jpg');

      final result = await generator.generate(fileSource, '', 'resource-1');

      expect(result, isNotNull);
      final file = File(result!);
      expect(await file.exists(), true);
    });

    test('缩略图比例约 2:3', () async {
      await createTestImage('test.jpg', width: 800, height: 600);

      final result = await generator.generate(fileSource, '', 'resource-1');
      expect(result, isNotNull);

      final thumbBytes = await File(result!).readAsBytes();
      final thumbImage = img.decodeImage(thumbBytes);
      expect(thumbImage, isNotNull);

      // 验证尺寸
      expect(thumbImage!.width, ImageThumbnailGenerator.thumbWidth);
      expect(thumbImage.height, ImageThumbnailGenerator.thumbHeight);

      // 验证比例约 2:3
      final ratio = thumbImage.width / thumbImage.height;
      expect(ratio, closeTo(2 / 3, 0.01));
    });

    test('空目录返回 null', () async {
      final result = await generator.generate(fileSource, '', 'resource-1');
      expect(result, isNull);
    });

    test('无图片文件返回 null', () async {
      // 创建非图片文件
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsString('hello');

      final result = await generator.generate(fileSource, '', 'resource-1');
      expect(result, isNull);
    });
  });
}
