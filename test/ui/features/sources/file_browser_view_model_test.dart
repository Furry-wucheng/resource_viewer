import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/data/repositories/filesystem_repository.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/data/repositories/thumbnail_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/domain/models/tag.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source_factory.dart';
import 'package:resource_viewer/ui/features/sources/view_models/file_browser_view_model.dart';

class _MockFilesystemRepository extends Mock implements FilesystemRepository {}

class _MockResourceRepository extends Mock implements ResourceRepository {}

class _MockTagRepository extends Mock implements TagRepository {
  @override
  Future<Result<Map<String, List<Tag>>>> getTagsForResources(
    List<String> resourceIds,
  ) async {
    return Ok({for (final id in resourceIds) id: const []});
  }
}

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
      () => resources.getResourcesBySourceIdAndPaths('source', any()),
    ).thenAnswer((_) async => const Ok([]));
    when(
      () => resources.getResourcesBySourceId('source'),
    ).thenAnswer((_) async => const Ok([]));
    when(
      () => resources.createResourceWithTags(
        id: any(named: 'id'),
        sourceId: 'source',
        name: '混合资源',
        type: ResourceType.folder,
        relativePath: 'mixed',
        organizationMode: any(named: 'organizationMode'),
        fileSize: null,
        tagIds: ['tag-1'],
      ),
    ).thenAnswer(
      (invocation) async => Ok(
        Resource(
          id: invocation.namedArguments[#id] as String,
          sourceId: 'source',
          name: '混合资源',
          type: ResourceType.folder,
          relativePath: 'mixed',
          organizationMode: null,
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
    final result = await viewModel.addSelectedResources(tagIds: ['tag-1']);

    expect(result, isA<Ok<BatchAddResult>>());
    final value = (result as Ok<BatchAddResult>).value;
    expect(value.added, 1);
    expect(value.skipped, 0);
    expect(value.addedResourceIds.length, 1);
    verify(
      () => resources.createResourceWithTags(
        id: any(named: 'id'),
        sourceId: 'source',
        name: '混合资源',
        type: ResourceType.folder,
        relativePath: 'mixed',
        tagIds: ['tag-1'],
        organizationMode: any(named: 'organizationMode'),
        fileSize: null,
      ),
    ).called(1);
    expect(notifications, greaterThanOrEqualTo(4));
    verify(() => filesystem.listDirectory('source', 'mixed/videos')).called(1);
  });

  group('batchTagSelectedResources', () {
    test('批量为已入库资源打标签', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(() => filesystem.listDirectory('source', '')).thenAnswer(
        (_) async => const Ok([
          FileEntry(name: 'file1.jpg', path: 'file1.jpg', isDirectory: false),
          FileEntry(name: 'file2.jpg', path: 'file2.jpg', isDirectory: false),
        ]),
      );
      final importedResources = [
        Resource(
          id: 'res1',
          sourceId: 'source',
          name: 'file1.jpg',
          type: ResourceType.folder,
          relativePath: 'file1.jpg',
          organizationMode: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        Resource(
          id: 'res2',
          sourceId: 'source',
          name: 'file2.jpg',
          type: ResourceType.folder,
          relativePath: 'file2.jpg',
          organizationMode: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];
      when(() => resources.getResourcesBySourceIdAndPaths('source', any()))
          .thenAnswer((_) async => Ok(importedResources));
      when(() => resources.getResourcesBySourceId('source'))
          .thenAnswer((_) async => Ok(importedResources));
      when(
        () => tags.getTagsForResource('res1'),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => tags.getTagsForResource('res2'),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => tags.setTagsForResource(any(), any()),
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

      await viewModel.loadDirectory('');
      viewModel.enterMultiSelectMode();
      viewModel.toggleSelection('file1.jpg');
      viewModel.toggleSelection('file2.jpg');

      final result = await viewModel.batchTagSelectedResources([
        'tag1',
        'tag2',
      ]);

      expect(result, isA<Ok<BatchTagResult>>());
      final value = (result as Ok<BatchTagResult>).value;
      expect(value.tagged, 2);
      expect(value.skipped, 0);
      verify(() => tags.setTagsForResource('res1', ['tag1', 'tag2'])).called(1);
      verify(() => tags.setTagsForResource('res2', ['tag1', 'tag2'])).called(1);
    });

    test('跳过未入库资源', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(() => filesystem.listDirectory('source', '')).thenAnswer(
        (_) async => const Ok([
          FileEntry(name: 'file1.jpg', path: 'file1.jpg', isDirectory: false),
          FileEntry(name: 'file2.jpg', path: 'file2.jpg', isDirectory: false),
        ]),
      );
      final res1 = Resource(
        id: 'res1',
        sourceId: 'source',
        name: 'file1.jpg',
        type: ResourceType.folder,
        relativePath: 'file1.jpg',
        organizationMode: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(() => resources.getResourcesBySourceIdAndPaths('source', any()))
          .thenAnswer((_) async => Ok([res1]));
      when(() => resources.getResourcesBySourceId('source'))
          .thenAnswer((_) async => Ok([res1]));
      when(
        () => tags.getTagsForResource('res1'),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => tags.setTagsForResource(any(), any()),
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

      await viewModel.loadDirectory('');
      viewModel.enterMultiSelectMode();
      viewModel.toggleSelection('file1.jpg');
      viewModel.toggleSelection('file2.jpg');

      final result = await viewModel.batchTagSelectedResources(['tag1']);

      expect(result, isA<Ok<BatchTagResult>>());
      final value = (result as Ok<BatchTagResult>).value;
      expect(value.tagged, 1);
      expect(value.skipped, 1);
      verify(() => tags.setTagsForResource('res1', ['tag1'])).called(1);
    });

    test('标签设置失败返回错误', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(() => filesystem.listDirectory('source', '')).thenAnswer(
        (_) async => const Ok([
          FileEntry(name: 'file1.jpg', path: 'file1.jpg', isDirectory: false),
        ]),
      );
      final testResource = Resource(
        id: 'res1',
        sourceId: 'source',
        name: 'file1.jpg',
        type: ResourceType.folder,
        relativePath: 'file1.jpg',
        organizationMode: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(() => resources.getResourcesBySourceIdAndPaths('source', any()))
          .thenAnswer((_) async => Ok([testResource]));
      when(() => resources.getResourcesBySourceId('source'))
          .thenAnswer((_) async => Ok([testResource]));
      when(
        () => tags.getTagsForResource('res1'),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => tags.setTagsForResource(any(), any()),
      ).thenAnswer((_) async => const Err(DatabaseError('数据库错误')));

      final viewModel = FileBrowserViewModel(
        sourceId: 'source',
        sourceName: '测试源',
        filesystemRepository: filesystem,
        resourceRepository: resources,
        tagRepository: tags,
        thumbnailRepository: thumbnails,
        fileSourceFactory: sourceFactory,
      );

      await viewModel.loadDirectory('');
      viewModel.enterMultiSelectMode();
      viewModel.toggleSelection('file1.jpg');

      final result = await viewModel.batchTagSelectedResources(['tag1']);

      expect(result, isA<Err<BatchTagResult>>());
      final error = (result as Err<BatchTagResult>).error;
      expect(error.message, '数据库错误');
    });

    test('空选中返回零结果', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(() => filesystem.listDirectory('source', '')).thenAnswer(
        (_) async => const Ok([
          FileEntry(name: 'file1.jpg', path: 'file1.jpg', isDirectory: false),
        ]),
      );
      when(
        () => resources.getResourcesBySourceIdAndPaths('source', any()),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => resources.getResourcesBySourceId('source'),
      ).thenAnswer((_) async => const Ok([]));

      final viewModel = FileBrowserViewModel(
        sourceId: 'source',
        sourceName: '测试源',
        filesystemRepository: filesystem,
        resourceRepository: resources,
        tagRepository: tags,
        thumbnailRepository: thumbnails,
        fileSourceFactory: sourceFactory,
      );

      await viewModel.loadDirectory('');
      viewModel.enterMultiSelectMode();

      final result = await viewModel.batchTagSelectedResources(['tag1']);

      expect(result, isA<Ok<BatchTagResult>>());
      final value = (result as Ok<BatchTagResult>).value;
      expect(value.tagged, 0);
      expect(value.skipped, 0);
    });
  });

  group('applyTagsToResources', () {
    test('为多个资源批量打标签', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(
        () => tags.setTagsForResource(any(), any()),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => tags.getTagsForResource(any()),
      ).thenAnswer((_) async => const Ok([]));
      when(
        () => resources.getResourcesBySourceId('source'),
      ).thenAnswer((_) async => const Ok([]));

      final viewModel = FileBrowserViewModel(
        sourceId: 'source',
        sourceName: '测试源',
        filesystemRepository: filesystem,
        resourceRepository: resources,
        tagRepository: tags,
        thumbnailRepository: thumbnails,
        fileSourceFactory: sourceFactory,
      );

      final result = await viewModel.applyTagsToResources(
        ['res1', 'res2', 'res3'],
        ['tag1', 'tag2'],
      );

      expect(result, isA<Ok<void>>());
      verify(() => tags.setTagsForResource('res1', ['tag1', 'tag2'])).called(1);
      verify(() => tags.setTagsForResource('res2', ['tag1', 'tag2'])).called(1);
      verify(() => tags.setTagsForResource('res3', ['tag1', 'tag2'])).called(1);
    });

    test('标签设置失败返回错误', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(
        () => tags.setTagsForResource(any(), any()),
      ).thenAnswer((_) async => const Err(DatabaseError('数据库错误')));
      when(
        () => resources.getResourcesBySourceId('source'),
      ).thenAnswer((_) async => const Ok([]));

      final viewModel = FileBrowserViewModel(
        sourceId: 'source',
        sourceName: '测试源',
        filesystemRepository: filesystem,
        resourceRepository: resources,
        tagRepository: tags,
        thumbnailRepository: thumbnails,
        fileSourceFactory: sourceFactory,
      );

      final result = await viewModel.applyTagsToResources(
        ['res1', 'res2'],
        ['tag1'],
      );

      expect(result, isA<Err<void>>());
      final error = (result as Err<void>).error;
      expect(error.message, '数据库错误');
    });

    test('空资源列表返回成功', () async {
      final filesystem = _MockFilesystemRepository();
      final resources = _MockResourceRepository();
      final tags = _MockTagRepository();
      final thumbnails = _MockThumbnailRepository();
      final sourceFactory = _MockFileSourceFactory();

      when(
        () => resources.getResourcesBySourceId('source'),
      ).thenAnswer((_) async => const Ok([]));

      final viewModel = FileBrowserViewModel(
        sourceId: 'source',
        sourceName: '测试源',
        filesystemRepository: filesystem,
        resourceRepository: resources,
        tagRepository: tags,
        thumbnailRepository: thumbnails,
        fileSourceFactory: sourceFactory,
      );

      final result = await viewModel.applyTagsToResources([], ['tag1']);

      expect(result, isA<Ok<void>>());
      verifyNever(() => tags.setTagsForResource(any(), any()));
    });
  });
}
