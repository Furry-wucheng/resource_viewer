import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'content_provider.dart';

/// 页面图片提供器
///
/// 提供稳定的 ImageProvider key，确保相同页面使用相同缓存。
class PageImageProvider extends ImageProvider<PageImageProvider> {
  const PageImageProvider({
    required this.contentProvider,
    required this.pageIndex,
  });

  final ContentProvider contentProvider;
  final int pageIndex;

  @override
  Future<PageImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    PageImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<int>('Page index', pageIndex),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    PageImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await contentProvider.loadPage(pageIndex);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  int get hashCode => Object.hash(contentProvider.runtimeType, pageIndex);

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PageImageProvider) return false;
    return contentProvider.runtimeType == other.contentProvider.runtimeType &&
        pageIndex == other.pageIndex;
  }
}
