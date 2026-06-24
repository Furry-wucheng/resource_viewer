import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/models/chapter.dart';
import 'package:resource_viewer/shared/content_provider/viewer_media_item.dart';
import 'package:resource_viewer/ui/features/viewer/view_models/viewer_view_model.dart';

void main() {
  test('media viewer keeps chapter navigation context', () {
    final vm = ViewerViewModel.media(
      title: '02',
      items: [
        ViewerMediaItem.image(
          title: '001.jpg',
          loadImage: () async => Uint8List.fromList([1]),
        ),
      ],
      chapters: const [
        Chapter(name: '01', path: 'book/01', pageCount: 1),
        Chapter(name: 'empty', path: 'book/empty', isDisabled: true),
        Chapter(name: '02', path: 'book/02', pageCount: 1),
        Chapter(name: '03', path: 'book/03', pageCount: 1),
      ],
      currentChapterIndex: 2,
    );

    expect(vm.getPrevChapterName(), '01');
    expect(vm.getNextChapterName(), '03');
    expect(vm.prevChapterIndex, 0);
    expect(vm.nextChapterIndex, 3);
  });
}
