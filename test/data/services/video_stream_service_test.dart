import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/services/video_stream_service.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';

void main() {
  group('VideoStreamService', () {
    late VideoStreamService service;
    late _FakeFileSource fileSource;
    late HttpClient client;

    setUp(() {
      service = VideoStreamService();
      fileSource = _FakeFileSource(
        Uint8List.fromList(List<int>.generate(100, (index) => index)),
      );
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await service.dispose();
    });

    test('translates HTTP Range requests to FileSource.streamRange', () async {
      final handle = await service.register(
        fileSource: fileSource,
        relativePath: 'movies/movie.mp4',
        fileSize: 100,
      );

      final request = await client.getUrl(handle.uri);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=10-19');
      final response = await request.close();
      final bytes = await _readAll(response);

      expect(response.statusCode, HttpStatus.partialContent);
      expect(
        response.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 10-19/100',
      );
      expect(bytes, List<int>.generate(10, (index) => index + 10));
      expect(fileSource.reads.single, (
        path: 'movies/movie.mp4',
        offset: 10,
        length: 10,
      ));
    });

    test('serves each range request via an independent stream', () async {
      final handle = await service.register(
        fileSource: fileSource,
        relativePath: 'movies/movie.mp4',
        fileSize: 100,
      );

      final firstRequest = await client.getUrl(handle.uri);
      firstRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=10-19');
      final firstResponse = await firstRequest.close();
      await _readAll(firstResponse);

      final secondRequest = await client.getUrl(handle.uri);
      secondRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=20-29');
      final secondResponse = await secondRequest.close();
      final secondBytes = await _readAll(secondResponse);

      expect(secondResponse.statusCode, HttpStatus.partialContent);
      expect(secondBytes, List<int>.generate(10, (index) => index + 20));
      // 流式后端无窗口缓存：两次请求各自发起一次 streamRange 调用。
      expect(fileSource.reads, hasLength(2));
      expect(fileSource.reads.last, (
        path: 'movies/movie.mp4',
        offset: 20,
        length: 10,
      ));
    });

    test('returns 416 for unsatisfiable ranges', () async {
      final handle = await service.register(
        fileSource: fileSource,
        relativePath: 'movies/movie.mp4',
        fileSize: 100,
      );

      final request = await client.getUrl(handle.uri);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=100-120');
      final response = await request.close();

      expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
      expect(
        response.headers.value(HttpHeaders.contentRangeHeader),
        'bytes */100',
      );
      expect(fileSource.reads, isEmpty);
    });

    test('revoked handles return 404', () async {
      final handle = await service.register(
        fileSource: fileSource,
        relativePath: 'movies/movie.mp4',
        fileSize: 100,
      );
      await service.revoke(handle);

      final request = await client.getUrl(handle.uri);
      final response = await request.close();

      expect(response.statusCode, HttpStatus.notFound);
    });
  });
}

Future<List<int>> _readAll(HttpClientResponse response) {
  final bytes = <int>[];
  return response.fold<List<int>>(bytes, (previous, chunk) {
    previous.addAll(chunk);
    return previous;
  });
}

class _FakeFileSource implements FileSource {
  _FakeFileSource(this.bytes);

  final Uint8List bytes;
  final List<({String path, int offset, int length})> reads = [];

  @override
  String get sourceId => 'fake';

  @override
  Future<List<FileEntry>> listDirectory(String relativePath) async => const [];

  @override
  Future<FileEntry?> stat(String relativePath) async => FileEntry(
    name: relativePath,
    path: relativePath,
    isDirectory: false,
    size: BigInt.from(bytes.length),
  );

  @override
  Future<Uint8List> readFile(String relativePath) async => bytes;

  @override
  Stream<Uint8List> streamFile(String relativePath) => Stream.value(bytes);

  @override
  Future<Uint8List> readRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async {
    reads.add((path: relativePath, offset: offset, length: length));
    final end = (offset + length).clamp(0, bytes.length);
    return Uint8List.sublistView(bytes, offset, end);
  }

  @override
  Stream<Uint8List> streamRange(
    String relativePath, {
    required int offset,
    required int length,
  }) async* {
    reads.add((path: relativePath, offset: offset, length: length));
    final end = (offset + length).clamp(0, bytes.length);
    final slice = Uint8List.sublistView(bytes, offset, end);
    const chunkSize = 1024 * 1024;
    var pos = 0;
    while (pos < slice.length) {
      final toRead = (slice.length - pos) < chunkSize
          ? (slice.length - pos)
          : chunkSize;
      yield Uint8List.sublistView(slice, pos, pos + toRead);
      pos += toRead;
    }
  }

  @override
  Future<bool> testConnection() async => true;

  @override
  Future<void> disconnect() async {}
}
