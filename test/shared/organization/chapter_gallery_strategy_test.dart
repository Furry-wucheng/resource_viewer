import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/domain/models/chapter.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/shared/organization/chapter_gallery_strategy.dart';

import '../../helpers/mock_factories.dart';

void main() {
  late MockFileSource source;
  late ChapterGalleryStrategy strategy;

  final resource = Resource(
    id: 'resource-1',
    sourceId: 'source-1',
    name: 'Book',
    type: ResourceType.folder,
    organizationMode: OrganizationMode.chapterGallery,
    relativePath: 'book',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    source = MockFileSource();
    strategy = ChapterGalleryStrategy();
  });

  test(
    'builds chapters from root folders with recursive cover and count',
    () async {
      when(() => source.listDirectory('book')).thenAnswer(
        (_) async => const [
          FileEntry(name: '01', path: 'book/01', isDirectory: true),
        ],
      );
      when(() => source.listDirectory('book/01')).thenAnswer(
        (_) async => const [
          FileEntry(name: 'a', path: 'book/01/a', isDirectory: true),
          FileEntry(
            name: '001.jpg',
            path: 'book/01/001.jpg',
            isDirectory: false,
          ),
        ],
      );
      when(() => source.listDirectory('book/01/a')).thenAnswer(
        (_) async => const [
          FileEntry(
            name: '002.png',
            path: 'book/01/a/002.png',
            isDirectory: false,
          ),
          FileEntry(
            name: 'note.txt',
            path: 'book/01/a/note.txt',
            isDirectory: false,
          ),
        ],
      );

      final chapters = await strategy.getChapters(resource, source);

      expect(chapters, hasLength(1));
      expect(chapters.single.name, '01');
      expect(chapters.single.path, 'book/01');
      expect(chapters.single.coverPath, 'book/01/001.jpg');
      expect(chapters.single.pageCount, 2);
      expect(chapters.single.isDisabled, isFalse);
    },
  );

  test(
    'returns recursive chapter contents sorted by folder then file name',
    () async {
      const chapter = Chapter(name: '01', path: 'book/01', pageCount: 3);
      when(() => source.listDirectory('book/01')).thenAnswer(
        (_) async => const [
          FileEntry(name: 'b', path: 'book/01/b', isDirectory: true),
          FileEntry(name: 'a', path: 'book/01/a', isDirectory: true),
          FileEntry(
            name: '003.jpg',
            path: 'book/01/003.jpg',
            isDirectory: false,
          ),
        ],
      );
      when(() => source.listDirectory('book/01/a')).thenAnswer(
        (_) async => const [
          FileEntry(
            name: '002.jpg',
            path: 'book/01/a/002.jpg',
            isDirectory: false,
          ),
        ],
      );
      when(() => source.listDirectory('book/01/b')).thenAnswer(
        (_) async => const [
          FileEntry(
            name: '001.jpg',
            path: 'book/01/b/001.jpg',
            isDirectory: false,
          ),
        ],
      );

      final contents = await strategy.getChapterContents(source, chapter);

      expect(contents.map((entry) => entry.path), [
        'book/01/003.jpg',
        'book/01/a/002.jpg',
        'book/01/b/001.jpg',
      ]);
    },
  );
}
