import 'dart:typed_data';

import '../../data/services/pdf_render_service.dart';
import '../../domain/models/domain_error.dart';
import '../file_source/file_source.dart';
import 'content_provider.dart';

/// PDF ContentProvider
///
/// 使用 pdfrx 将 PDF 逐页渲染为图片，与图片查看器共享同一个 ViewerPage。
/// 加密 PDF 抛出 [MediaEncryptedError]。
class PdfProvider implements ContentProvider {
  PdfProvider({
    required this.fileSource,
    required this.filePath,
    PdfRenderService? renderService,
  }) : _renderService = renderService ?? PdfRenderService();

  final FileSource fileSource;
  final String filePath;
  final PdfRenderService _renderService;

  dynamic _document;
  bool _disposed = false;
  int? _pageCount;

  /// 是否已初始化
  bool get isInitialized => _document != null;

  @override
  int get pageCount {
    if (!isInitialized) {
      throw StateError('PdfProvider 尚未初始化，请先调用 init()');
    }
    return _pageCount!;
  }

  /// 初始化：读取文件并打开 PDF 文档
  ///
  /// 加密 PDF 会抛出异常，调用方应捕获并转换为 [MediaEncryptedError]。
  Future<void> init() async {
    final bytes = await fileSource.readFile(filePath);
    if (_disposed) return;

    try {
      _document = await _renderService.openFromBytes(bytes);
      // 尝试访问页面以检测加密
      _pageCount = _renderService.pageCount(_document);
    } catch (e) {
      if (_isEncryptionError(e)) {
        throw MediaEncryptedError(
          '此 PDF 已加密，暂不支持查看',
          cause: e,
          mediaType: MediaType.pdf,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> loadPage(int index) async {
    if (_disposed) {
      throw StateError('PdfProvider 已释放');
    }
    if (!isInitialized) {
      throw StateError('PdfProvider 尚未初始化，请先调用 init()');
    }
    if (index < 0 || index >= _pageCount!) {
      throw RangeError.index(index, List.filled(_pageCount!, null), 'index');
    }

    try {
      return await _renderService.renderPage(
        _document,
        index,
        displayWidth: 1200,
        displayHeight: 1600,
      );
    } catch (e) {
      if (_isEncryptionError(e)) {
        throw MediaEncryptedError(
          '此 PDF 已加密，暂不支持查看',
          cause: e,
          mediaType: MediaType.pdf,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    if (_document != null) {
      try {
        // ignore: avoid_dynamic_calls
        await _document.dispose();
      } catch (_) {}
      _document = null;
    }
    _pageCount = null;
  }

  /// 检测是否为加密相关错误
  bool _isEncryptionError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('encrypt') ||
        msg.contains('password') ||
        msg.contains('protected');
  }
}
