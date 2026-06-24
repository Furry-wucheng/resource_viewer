import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_smb2/dart_smb2.dart';
import 'package:resource_viewer/data/repositories/filesystem_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/source.dart' as domain;
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source_factory.dart';
import '../../helpers/mock_factories.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late AppDatabase database;
  late _CountingFileSource fileSource;
  late _TestFileSourceFactory factory;
  late DateTime now;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fileSource = _CountingFileSource();
    factory = _TestFileSourceFactory(fileSource);
    now = DateTime.utc(2026, 6, 21);
    final sources = SourceRepository(database);
    final result = await sources.createSource(
      id: 'source',
      name: '本地源',
      type: domain.SourceType.local,
      rootPath: 'C:/library',
    );
    expect(result, isA<Ok<domain.Source>>());
  });

  tearDown(() => database.close());

  test('TTL 内重复请求命中缓存', () async {
    final repository = FilesystemRepository(
      database,
      factory,
      clock: () => now,
    );

    await repository.listDirectory('source', 'books');
    await repository.listDirectory('source', 'books');

    expect(fileSource.listCallCount, 1);
  });

  test('TTL 过期后重新读取目录', () async {
    final repository = FilesystemRepository(
      database,
      factory,
      localTtl: const Duration(seconds: 30),
      clock: () => now,
    );

    await repository.listDirectory('source', 'books');
    now = now.add(const Duration(seconds: 31));
    await repository.listDirectory('source', 'books');

    expect(fileSource.listCallCount, 2);
  });

  test('同一路径的并发请求只读取一次底层文件源', () async {
    final completer = Completer<List<FileEntry>>();
    fileSource.nextResult = completer.future;
    final repository = FilesystemRepository(database, factory);

    final first = repository.listDirectory('source', 'books');
    final second = repository.listDirectory('source', 'books');
    await Future<void>.delayed(Duration.zero);

    expect(fileSource.listCallCount, 1);
    completer.complete(const [
      FileEntry(name: 'chapter', path: 'books/chapter', isDirectory: true),
    ]);
    final results = await Future.wait([first, second]);
    expect(results.every((result) => result is Ok<List<FileEntry>>), isTrue);
  });

  test('失效期间的旧请求不会重新填充缓存', () async {
    final stale = Completer<List<FileEntry>>();
    fileSource.nextResult = stale.future;
    final repository = FilesystemRepository(database, factory);

    final oldRequest = repository.listDirectory('source', 'books');
    await Future<void>.delayed(Duration.zero);
    repository.invalidateCache('source');
    fileSource.nextResult = Future.value(const []);
    await repository.listDirectory('source', 'books');
    stale.complete(const [
      FileEntry(name: 'stale', path: 'books/stale', isDirectory: true),
    ]);
    await oldRequest;
    await repository.listDirectory('source', 'books');

    expect(fileSource.listCallCount, 2);
  });

  test('SMB 测试连接按异常类型映射错误并释放连接', () async {
    final pool = MockSmbPoolClient();
    when(
      () => pool.echo(),
    ).thenThrow(const Smb2Exception('logon failed', 13, Smb2ErrorType.auth));
    when(() => pool.disconnect()).thenAnswer((_) async {});
    final repository = FilesystemRepository(database, factory);

    final result = await repository.testSmbConnection(
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
          }) async {
            expect(timeoutSeconds, 15);
            return pool;
          },
    );

    expect(result, isA<Err<bool>>());
    expect((result as Err<bool>).error, isA<SourceAuthError>());
    verify(() => pool.disconnect()).called(1);
  });
}

class _TestFileSourceFactory extends FileSourceFactory {
  _TestFileSourceFactory(this.source);

  final FileSource source;

  @override
  FileSource create(domain.Source source) => this.source;

  @override
  Future<FileSource> createAsync(
    domain.Source source, {
    String? password,
  }) async => this.source;
}

class _CountingFileSource implements FileSource {
  int listCallCount = 0;
  Future<List<FileEntry>>? nextResult;

  @override
  String get sourceId => 'source';

  @override
  Future<List<FileEntry>> listDirectory(String relativePath) {
    listCallCount++;
    return nextResult ?? Future.value(const []);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<Uint8List> readFile(String relativePath) => throw UnimplementedError();

  @override
  Future<Uint8List> readRange(
    String relativePath, {
    required int offset,
    required int length,
  }) => throw UnimplementedError();

  @override
  Future<FileEntry?> stat(String relativePath) => throw UnimplementedError();

  @override
  Stream<Uint8List> streamFile(String relativePath) =>
      throw UnimplementedError();

  @override
  Future<bool> testConnection() async => true;
}
