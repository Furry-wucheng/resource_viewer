import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/shared/media/media_file_types.dart';

void main() {
  test('image extensions include avif and legacy variants', () {
    for (final name in [
      'cover.jpg',
      'cover.jpeg',
      'cover.png',
      'cover.gif',
      'cover.webp',
      'cover.bmp',
      'cover.tiff',
      'cover.tif',
      'cover.avif',
    ]) {
      expect(MediaFileTypes.isImage(name), isTrue, reason: name);
      expect(MediaFileTypes.isSupported(name), isTrue, reason: name);
      expect(MediaFileTypes.isViewable(name), isTrue, reason: name);
    }
  });

  test('classifies pdf, video, and archive files', () {
    expect(MediaFileTypes.isPdf('book.pdf'), isTrue);
    expect(MediaFileTypes.isVideo('clip.m4v'), isTrue);
    expect(MediaFileTypes.isArchive('pack.7z'), isTrue);
    expect(MediaFileTypes.isSupported('pack.tar'), isTrue);
    expect(MediaFileTypes.isViewable('pack.tar'), isFalse);
  });
}
