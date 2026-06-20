import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/models/app_config.dart';
import 'package:resource_viewer/domain/models/chapter.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/domain/models/resource_tag.dart';
import 'package:resource_viewer/domain/models/source.dart';
import 'package:resource_viewer/domain/models/tag.dart';

void main() {
  final now = DateTime.utc(2026, 1, 2, 3, 4, 5);

  test('领域模型支持 JSON 往返和 copyWith', () {
    final source = Source(
      id: 's',
      name: '源',
      type: SourceType.local,
      rootPath: '/tmp',
      createdAt: now,
      updatedAt: now,
    );
    expect(Source.fromJson(source.toJson()), source);
    expect(source.copyWith(name: '新源').name, '新源');

    final resource = Resource(
      id: 'r',
      sourceId: 's',
      name: '资源',
      type: ResourceType.video,
      relativePath: 'movie.mp4',
      createdAt: now,
      updatedAt: now,
    );
    expect(Resource.fromJson(resource.toJson()), resource);
    expect(resource.copyWith(fileCount: 2).fileCount, 2);

    final tag = Tag(
      id: 't',
      name: '标签',
      color: '#123456',
      createdAt: now,
      updatedAt: now,
    );
    expect(Tag.fromJson(tag.toJson()), tag);
    expect(tag.copyWith(color: '#654321').color, '#654321');

    final resourceTag = ResourceTag(
      resourceId: 'r',
      tagId: 't',
      createdAt: now,
    );
    expect(ResourceTag.fromJson(resourceTag.toJson()), resourceTag);
    expect(resourceTag.copyWith(tagId: 't2').tagId, 't2');

    const entry = FileEntry(name: 'a.jpg', path: '/a.jpg', isDirectory: false);
    expect(FileEntry.fromJson(entry.toJson()), entry);
    expect(entry.copyWith(isDirectory: true).isDirectory, isTrue);

    const chapter = Chapter(name: '第一章', path: '/1');
    expect(Chapter.fromJson(chapter.toJson()), chapter);
    expect(chapter.copyWith(pageCount: 10).pageCount, 10);

    final config = AppConfig(updatedAt: now);
    expect(AppConfig.fromJson(config.toJson()), config);
    expect(config.copyWith(cacheLimitMB: 1024).cacheLimitMB, 1024);
  });
}
