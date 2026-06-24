import 'dart:typed_data';

import 'package:dart_smb2/dart_smb2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:resource_viewer/shared/file_source/file_source_factory.dart';
import 'package:resource_viewer/shared/file_source/smb_file_source.dart';
import 'package:resource_viewer/shared/file_source/local_file_source.dart';
import 'package:resource_viewer/domain/models/source.dart';
import '../../helpers/mock_factories.dart';

void main() {
  group('SmbFileSource', () {
    late MockSmbPoolClient pool;
    late SmbFileSource source;

    setUp(() {
      pool = MockSmbPoolClient();
      source = SmbFileSource(
        sourceId: 'test-smb',
        host: 'server',
        share: 'share',
        poolConnector:
            ({
              required host,
              required share,
              username,
              password,
              domain,
              required timeoutSeconds,
            }) async => pool,
      );
    });

    test('constructor sets properties correctly', () {
      final source = SmbFileSource(
        sourceId: 'test-smb',
        host: '192.168.1.100',
        share: 'Documents',
        port: 445,
        username: 'user',
        password: 'pass',
        domain: 'WORKGROUP',
      );

      expect(source.sourceId, 'test-smb');
      expect(source.host, '192.168.1.100');
      expect(source.share, 'Documents');
      expect(source.port, 445);
      expect(source.username, 'user');
      expect(source.password, 'pass');
      expect(source.domain, 'WORKGROUP');
    });

    test('port defaults to 445', () {
      final source = SmbFileSource(
        sourceId: 'test',
        host: 'host',
        share: 'share',
      );

      expect(source.port, 445);
    });

    test('listDirectory maps entries and filters unsupported files', () async {
      final modified = DateTime.utc(2026, 6, 22);
      when(() => pool.listDirectory('books')).thenAnswer(
        (_) async => [
          Smb2DirEntry(
            name: 'chapter',
            stat: Smb2Stat(
              type: Smb2FileType.directory,
              size: 0,
              modified: modified,
              created: modified,
            ),
          ),
          Smb2DirEntry(
            name: 'cover.jpg',
            stat: Smb2Stat(
              type: Smb2FileType.file,
              size: 42,
              modified: modified,
              created: modified,
            ),
          ),
          Smb2DirEntry(
            name: 'notes.txt',
            stat: Smb2Stat(
              type: Smb2FileType.file,
              size: 5,
              modified: modified,
              created: modified,
            ),
          ),
        ],
      );

      final entries = await source.listDirectory('books');

      expect(entries.map((entry) => entry.name), ['chapter', 'cover.jpg']);
      expect(entries.last.path, 'books/cover.jpg');
      expect(entries.last.size, BigInt.from(42));
      verify(() => pool.listDirectory('books')).called(1);
    });

    test('delegates stat, read, stream, echo and disconnect', () async {
      final timestamp = DateTime.utc(2026, 6, 22);
      final stat = Smb2Stat(
        type: Smb2FileType.file,
        size: 3,
        modified: timestamp,
        created: timestamp,
      );
      when(() => pool.stat('cover.jpg')).thenAnswer((_) async => stat);
      when(
        () => pool.readFile('cover.jpg'),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
      when(
        () => pool.streamFile('cover.jpg'),
      ).thenAnswer((_) => Stream.value(Uint8List.fromList([1, 2, 3])));
      when(
        () => pool.readFileRange('cover.jpg', offset: 1, length: 2),
      ).thenAnswer((_) async => Uint8List.fromList([2, 3]));
      when(() => pool.echo()).thenAnswer((_) async {});
      when(() => pool.disconnect()).thenAnswer((_) async {});

      expect((await source.stat('cover.jpg'))?.size, BigInt.from(3));
      expect(await source.readFile('cover.jpg'), [1, 2, 3]);
      expect(await source.streamFile('cover.jpg').single, [1, 2, 3]);
      expect(await source.readRange('cover.jpg', offset: 1, length: 2), [2, 3]);
      expect(await source.testConnection(), isTrue);
      await source.disconnect();

      verify(() => pool.stat('cover.jpg')).called(1);
      verify(() => pool.readFile('cover.jpg')).called(1);
      verify(() => pool.streamFile('cover.jpg')).called(1);
      verify(
        () => pool.readFileRange('cover.jpg', offset: 1, length: 2),
      ).called(1);
      verify(() => pool.echo()).called(1);
      verify(() => pool.disconnect()).called(1);
    });

    test('testConnection rethrows typed SMB errors', () async {
      const error = Smb2Exception('bad credentials', 13, Smb2ErrorType.auth);
      when(() => pool.echo()).thenThrow(error);

      await expectLater(source.testConnection(), throwsA(same(error)));
    });

    test('rejects unsupported custom ports before connecting', () async {
      var connected = false;
      final customPortSource = SmbFileSource(
        sourceId: 'custom-port',
        host: 'server',
        share: 'share',
        port: 1445,
        poolConnector:
            ({
              required host,
              required share,
              username,
              password,
              domain,
              required timeoutSeconds,
            }) async {
              connected = true;
              return pool;
            },
      );

      await expectLater(customPortSource.testConnection(), throwsArgumentError);
      expect(connected, isFalse);
    });
  });

  group('FileSourceFactory.extractShare', () {
    test('parses UNC paths correctly', () {
      expect(
        FileSourceFactory.extractShare('\\\\192.168.1.100\\Documents'),
        'Documents',
      );
      expect(FileSourceFactory.extractShare('\\\\NAS\\Media'), 'Media');
      expect(
        FileSourceFactory.extractShare('\\\\server\\share\\subfolder'),
        'share',
      );
    });

    test('parses SMB URL paths correctly', () {
      expect(
        FileSourceFactory.extractShare('smb://192.168.1.100/Documents'),
        'Documents',
      );
      expect(FileSourceFactory.extractShare('smb://NAS/Media'), 'Media');
    });

    test('returns raw value for simple share names', () {
      expect(FileSourceFactory.extractShare('MyShare'), 'MyShare');
      expect(FileSourceFactory.extractShare('Documents'), 'Documents');
    });
  });

  group('FileSourceFactory.createAsync', () {
    test('creates local source', () async {
      final factory = FileSourceFactory();
      final source = Source(
        id: 'local-1',
        name: 'Test Local',
        type: SourceType.local,
        rootPath: '/tmp/test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final fileSource = await factory.createAsync(source);

      expect(fileSource, isA<LocalFileSource>());
      expect(fileSource.sourceId, 'local-1');
    });

    test('caches source instances', () async {
      final factory = FileSourceFactory();
      final source = Source(
        id: 'local-1',
        name: 'Test Local',
        type: SourceType.local,
        rootPath: '/tmp/test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final first = await factory.createAsync(source);
      final second = await factory.createAsync(source);

      expect(identical(first, second), true);
    });

    test('throws for SMB source without password provider', () async {
      final factory = FileSourceFactory();
      final source = Source(
        id: 'smb-1',
        name: 'Test SMB',
        type: SourceType.smb,
        rootPath: '\\\\server\\share',
        host: 'server',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 没有设置 passwordProvider，SMB 源创建时密码为 null
      // 实际连接时会失败，但创建本身应该成功
      final fileSource = await factory.createAsync(source);
      expect(fileSource, isA<SmbFileSource>());
    });
  });
}
