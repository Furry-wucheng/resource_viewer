import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:resource_viewer/shared/file_source/local_file_source.dart';
import 'package:resource_viewer/shared/thumbnail/video_thumbnail_generator.dart';

void main() {
  late Directory tempDir;
  late LocalFileSource fileSource;
  late VideoThumbnailGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('video_thumbnail_test_');
    fileSource = LocalFileSource(
      sourceId: 'test-source',
      rootPath: tempDir.path,
    );
    generator = VideoThumbnailGenerator(outputDirectory: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VideoThumbnailGenerator', () {
    test('不存在的视频返回 null', () async {
      final result = await generator.generate(
        fileSource,
        'nonexistent.mp4',
        'resource-1',
      );
      expect(result, isNull);
    });

    test('空路径返回 null', () async {
      final result = await generator.generate(fileSource, '', 'resource-1');
      expect(result, isNull);
    });
  });
}
