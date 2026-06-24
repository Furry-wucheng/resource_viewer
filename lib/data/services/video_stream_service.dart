import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../shared/file_source/file_source.dart';

class VideoStreamHandle {
  const VideoStreamHandle({required this.token, required this.uri});

  final String token;
  final Uri uri;
}

class _VideoStreamEntry {
  _VideoStreamEntry({
    required this.fileSource,
    required this.relativePath,
    required this.fileSize,
  }) : cache = _VideoRangeCache(
         fileSource: fileSource,
         relativePath: relativePath,
         fileSize: fileSize,
       );

  final FileSource fileSource;
  final String relativePath;
  final int fileSize;
  final _VideoRangeCache cache;
}

class _ByteRange {
  const _ByteRange({required this.start, required this.end});

  final int start;
  final int end;

  int get length => end - start + 1;
}

class _VideoRangeCache {
  _VideoRangeCache({
    required this.fileSource,
    required this.relativePath,
    required this.fileSize,
  });

  final FileSource fileSource;
  final String relativePath;
  final int fileSize;
  final Map<int, Uint8List> _windows = {};
  final Map<int, Future<Uint8List>> _inFlight = {};
  final List<int> _lru = [];

  static const int _windowSize = 8 * 1024 * 1024;
  static const int _maxBytes = 96 * 1024 * 1024;

  Future<Uint8List> read({required int offset, required int length}) async {
    if (length <= 0 || offset >= fileSize) return Uint8List(0);
    final boundedLength = min(length, fileSize - offset);
    final chunks = <Uint8List>[];
    var cursor = offset;
    var remaining = boundedLength;

    while (remaining > 0) {
      final windowStart = _windowStartFor(cursor);
      final window = await _loadWindow(windowStart);
      final innerOffset = cursor - windowStart;
      if (innerOffset >= window.length) break;
      final take = min(remaining, window.length - innerOffset);
      chunks.add(
        Uint8List.fromList(window.sublist(innerOffset, innerOffset + take)),
      );
      cursor += take;
      remaining -= take;
    }

    _prefetch(_windowStartFor(cursor));
    if (chunks.isEmpty) return Uint8List(0);
    if (chunks.length == 1) return chunks.first;
    final bytes = Uint8List(boundedLength - remaining);
    var target = 0;
    for (final chunk in chunks) {
      bytes.setRange(target, target + chunk.length, chunk);
      target += chunk.length;
    }
    return bytes;
  }

  Future<Uint8List> _loadWindow(int windowStart) async {
    final cached = _windows[windowStart];
    if (cached != null) {
      _touch(windowStart);
      return cached;
    }
    final loading = _inFlight[windowStart];
    if (loading != null) return loading;

    final length = min(_windowSize, fileSize - windowStart);
    final future = _readWindow(windowStart, length);
    _inFlight[windowStart] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(windowStart);
    }
  }

  Future<Uint8List> _readWindow(int windowStart, int length) async {
    final bytes = await fileSource.readRange(
      relativePath,
      offset: windowStart,
      length: length,
    );
    _windows[windowStart] = bytes;
    _touch(windowStart);
    _trim();
    return bytes;
  }

  void _prefetch(int windowStart) {
    if (windowStart >= fileSize ||
        _windows.containsKey(windowStart) ||
        _inFlight.containsKey(windowStart)) {
      return;
    }
    unawaited(_loadWindow(windowStart));
  }

  int _windowStartFor(int offset) => (offset ~/ _windowSize) * _windowSize;

  void _touch(int windowStart) {
    _lru.remove(windowStart);
    _lru.add(windowStart);
  }

  void _trim() {
    var total = _windows.values.fold<int>(0, (sum, bytes) => sum + bytes.length);
    while (total > _maxBytes && _lru.isNotEmpty) {
      final oldest = _lru.removeAt(0);
      final removed = _windows.remove(oldest);
      if (removed != null) total -= removed.length;
    }
  }
}

/// Local HTTP bridge for media_kit playback of non-local FileSource videos.
class VideoStreamService {
  VideoStreamService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final Map<String, _VideoStreamEntry> _entries = {};
  HttpServer? _server;

  Future<VideoStreamHandle> register({
    required FileSource fileSource,
    required String relativePath,
    required int fileSize,
  }) async {
    var resolvedFileSize = fileSize;
    if (resolvedFileSize <= 0) {
      final stat = await fileSource.stat(relativePath);
      resolvedFileSize = stat?.size?.toInt() ?? 0;
    }
    if (resolvedFileSize <= 0) {
      throw ArgumentError.value(
        resolvedFileSize,
        'fileSize',
        'must be positive',
      );
    }
    final server = await _ensureServer();
    final token = _newToken();
    _entries[token] = _VideoStreamEntry(
      fileSource: fileSource,
      relativePath: relativePath,
      fileSize: resolvedFileSize,
    );
    return VideoStreamHandle(
      token: token,
      uri: Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        pathSegments: ['video', token],
      ),
    );
  }

  Future<void> revoke(VideoStreamHandle handle) async {
    _entries.remove(handle.token);
  }

  Future<void> dispose() async {
    _entries.clear();
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<HttpServer> _ensureServer() async {
    final current = _server;
    if (current != null) return current;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(_serve(server));
    return server;
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      unawaited(_handleRequest(request));
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final token = _tokenFromPath(request.uri);
      final entry = token == null ? null : _entries[token];
      if (entry == null) {
        await _closeText(request.response, HttpStatus.notFound, 'not found');
        return;
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        await _closeText(
          request.response,
          HttpStatus.methodNotAllowed,
          'method not allowed',
        );
        return;
      }

      final range = _parseRange(
        request.headers.value(HttpHeaders.rangeHeader),
        entry.fileSize,
      );
      if (range == null) {
        await _closeRangeNotSatisfiable(request.response, entry.fileSize);
        return;
      }

      final response = request.response;
      response.statusCode = HttpStatus.partialContent;
      response.headers
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..set(HttpHeaders.contentTypeHeader, _contentType(entry.relativePath))
        ..set(
          HttpHeaders.contentRangeHeader,
          'bytes ${range.start}-${range.end}/${entry.fileSize}',
        )
        ..set(HttpHeaders.contentLengthHeader, range.length);

      if (request.method == 'HEAD') {
        await response.close();
        return;
      }

      const chunkSize = 4 * 1024 * 1024;
      var offset = range.start;
      var remaining = range.length;
      while (remaining > 0) {
        final length = min(chunkSize, remaining);
        final chunk = await entry.cache.read(offset: offset, length: length);
        if (chunk.isEmpty) break;
        response.add(chunk);
        offset += chunk.length;
        remaining -= chunk.length;
      }
      await response.close();
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  String? _tokenFromPath(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'video') return null;
    return segments[1];
  }

  _ByteRange? _parseRange(String? header, int fileSize) {
    if (fileSize <= 0) return null;
    if (header == null || header.isEmpty) {
      return _ByteRange(start: 0, end: fileSize - 1);
    }
    if (!header.startsWith('bytes=') || header.contains(',')) return null;

    final spec = header.substring('bytes='.length);
    final dash = spec.indexOf('-');
    if (dash < 0) return null;

    final startText = spec.substring(0, dash);
    final endText = spec.substring(dash + 1);

    if (startText.isEmpty) {
      final suffixLength = int.tryParse(endText);
      if (suffixLength == null || suffixLength <= 0) return null;
      final length = min(suffixLength, fileSize);
      return _ByteRange(start: fileSize - length, end: fileSize - 1);
    }

    final start = int.tryParse(startText);
    if (start == null || start < 0 || start >= fileSize) return null;

    final end = endText.isEmpty ? fileSize - 1 : int.tryParse(endText);
    if (end == null || end < start) return null;

    return _ByteRange(start: start, end: min(end, fileSize - 1));
  }

  Future<void> _closeRangeNotSatisfiable(
    HttpResponse response,
    int fileSize,
  ) async {
    response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
    response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$fileSize');
    await response.close();
  }

  Future<void> _closeText(
    HttpResponse response,
    int statusCode,
    String message,
  ) async {
    response.statusCode = statusCode;
    final bytes = utf8.encode(message);
    response.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8')
      ..set(HttpHeaders.contentLengthHeader, bytes.length);
    response.add(bytes);
    await response.close();
  }

  String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.m4v')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  String _newToken() {
    while (true) {
      final bytes = List<int>.generate(18, (_) => _random.nextInt(256));
      final token = base64Url.encode(bytes).replaceAll('=', '');
      if (!_entries.containsKey(token)) return token;
    }
  }
}
