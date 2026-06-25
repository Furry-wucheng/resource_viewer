import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';

import 'package:resource_viewer/shared/file_source/local_file_source.dart';
import 'package:resource_viewer/shared/thumbnail/video_thumbnail_generator.dart';

class _MockVideoThumbnailer extends Mock implements FcNativeVideoThumbnail {}

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
    test('原生解码结果直接返回为 JPEG', () async {
      final video = File('${tempDir.path}${Platform.pathSeparator}clip.mp4');
      await video.writeAsBytes(const [0]);
      final thumbnailer = _MockVideoThumbnailer();
      final frame = img.Image(width: 180, height: 270);
      img.fill(frame, color: img.ColorRgb8(20, 180, 80));
      when(
        () => thumbnailer.saveThumbnailToBytes(
          srcFile: video.path,
          width: 180,
          height: 270,
          quality: 85,
        ),
      ).thenAnswer((_) async => img.encodeJpg(frame));
      generator = VideoThumbnailGenerator(
        outputDirectory: tempDir.path,
        thumbnailer: thumbnailer,
      );

      final bytes = await generator.generatePreview(fileSource, 'clip.mp4');

      expect(bytes, isNotNull);
      final decoded = img.decodeJpg(bytes!);
      expect(decoded?.width, 180);
      expect(decoded?.height, 270);
      verify(
        () => thumbnailer.saveThumbnailToBytes(
          srcFile: video.path,
          width: 180,
          height: 270,
          quality: 85,
        ),
      ).called(1);
    });

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
