import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/data/repositories/filesystem_repository.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/data/repositories/thumbnail_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source_factory.dart';
import 'package:resource_viewer/ui/features/sources/view_models/file_browser_view_model.dart';

class _MockFilesystemRepository extends Mock implements FilesystemRepository {}

class _MockResourceRepository extends Mock implements ResourceRepository {}

class _MockTagRepository extends Mock implements TagRepository {}

class _MockThumbnailRepository extends Mock implements ThumbnailRepository {}

class _MockFileSourceFactory extends Mock implements FileSourceFactory {}

class _MockFileSource extends Mock implements FileSource {}

void main() {
  test('含深层视频的文件夹不会被当作空资源跳过', () async {
    final filesystem = _MockFilesystemRepository();
    final resources = _MockResourceRepository();
    final tags = _MockTagRepository();
    final thumbnails = _MockThumbnailRepository();
    final sourceFactory = _MockFileSourceFactory();
    final fileSource = _MockFileSource();
    const folder = FileEntry(name: '混合资源', path: 'mixed', isDirectory: true);

    when(
      () => filesystem.listDirectory('source', ''),
    ).thenAnswer((_) async => const Ok([folder]));
    when(() => filesystem.listDirectory('source', 'mixed')).thenAnswer(
      (_) async => const Ok([
        FileEntry(name: 'videos', path: 'mixed/videos', isDirectory: true),
      ]),
    );
    when(() => filesystem.listDirectory('source', 'mixed/videos')).thenAnswer(
      (_) async => const Ok([
        FileEntry(
          name: 'clip.mp4',
          path: 'mixed/videos/clip.mp4',
          isDirectory: false,
        ),
      ]),
    );
    when(
      () => resources.getResourcesBySourceId('source'),
    ).thenAnswer((_) async => const Ok([]));
    when(
      () => resources.createResource(
        id: any(named: 'id'),
        sourceId: 'source',
        name: '混合资源',
        type: ResourceType.folder,
        relativePath: 'mixed',
        organizationMode: OrganizationMode.direct,
        fileSize: null,
      ),
    ).thenAnswer(
      (invocation) async => Ok(
        Resource(
          id: invocation.namedArguments[#id] as String,
          sourceId: 'source',
          name: '混合资源',
          type: ResourceType.folder,
          relativePath: 'mixed',
          organizationMode: OrganizationMode.direct,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );
    when(() => sourceFactory.get('source')).thenReturn(fileSource);
    when(
      () =>
          thumbnails.generate(any(), fileSource, 'mixed', ResourceType.folder),
    ).thenAnswer((_) async => const Ok(null));

    final viewModel = FileBrowserViewModel(
      sourceId: 'source',
      sourceName: '测试源',
      filesystemRepository: filesystem,
      resourceRepository: resources,
      tagRepository: tags,
      thumbnailRepository: thumbnails,
      fileSourceFactory: sourceFactory,
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    await viewModel.loadDirectory('');
    viewModel.enterMultiSelectMode();
    viewModel.toggleSelection('mixed');
    final result = await viewModel.addSelectedResources();

    expect(result, isA<Ok<BatchAddResult>>());
    final value = (result as Ok<BatchAddResult>).value;
    expect(value.added, 1);
    expect(value.skipped, 0);
    expect(notifications, greaterThanOrEqualTo(4));
    verify(() => filesystem.listDirectory('source', 'mixed/videos')).called(1);
  });
}
