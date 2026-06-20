import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:resource_viewer/domain/models/source.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source_factory.dart';

class MockFileSource extends Mock implements FileSource {}

void main() {
  late FileSourceFactory factory;

  setUp(() {
    factory = FileSourceFactory();
  });

  Source makeSource({
    String id = 'src-1',
    String name = 'Test Source',
    SourceType type = SourceType.local,
    String rootPath = '/tmp/test',
  }) {
    return Source(
      id: id,
      name: name,
      type: type,
      rootPath: rootPath,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('FileSourceFactory', () {
    group('create', () {
      test('local 类型创建 LocalFileSource', () {
        final source = makeSource();
        final fileSource = factory.create(source);
        expect(fileSource.sourceId, 'src-1');
      });

      test('同一 sourceId 重复调用返回同一实例', () {
        final source = makeSource();
        final first = factory.create(source);
        final second = factory.create(source);
        expect(identical(first, second), true);
      });

      test('不同 sourceId 返回不同实例', () {
        final source1 = makeSource(id: 'src-1');
        final source2 = makeSource(id: 'src-2');
        final first = factory.create(source1);
        final second = factory.create(source2);
        expect(identical(first, second), false);
      });

      test('SMB 类型抛出 UnimplementedError', () {
        final source = makeSource(type: SourceType.smb);
        expect(() => factory.create(source), throwsUnimplementedError);
      });
    });

    group('disconnect', () {
      test('断开后清理缓存', () async {
        final source = makeSource();
        factory.create(source);
        expect(factory.has('src-1'), true);

        await factory.disconnect('src-1');
        expect(factory.has('src-1'), false);
      });

      test('断开不存在的源不抛异常', () async {
        expect(() => factory.disconnect('nonexistent'), returnsNormally);
      });
    });

    group('disconnectAll', () {
      test('清理所有缓存', () async {
        final source1 = makeSource(id: 'src-1');
        final source2 = makeSource(id: 'src-2');
        factory.create(source1);
        factory.create(source2);
        expect(factory.has('src-1'), true);
        expect(factory.has('src-2'), true);

        await factory.disconnectAll();
        expect(factory.has('src-1'), false);
        expect(factory.has('src-2'), false);
      });
    });

    group('get / has', () {
      test('未缓存时返回 null', () {
        expect(factory.get('nonexistent'), isNull);
        expect(factory.has('nonexistent'), false);
      });

      test('缓存后可获取', () {
        final source = makeSource();
        factory.create(source);
        expect(factory.get('src-1'), isNotNull);
        expect(factory.has('src-1'), true);
      });
    });
  });
}
