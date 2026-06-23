import 'package:path/path.dart' as p;

import '../../domain/core/result.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../../shared/file_source/file_source.dart';
import '../../shared/organization/chapter_strategy.dart';
import '../../shared/organization/gallery_strategy.dart';

class OrganizationRepository {
  OrganizationRepository({
    ChapterStrategy? chapterStrategy,
    GalleryStrategy? galleryStrategy,
  }) : _chapterStrategy = chapterStrategy ?? ChapterStrategy(),
       _galleryStrategy = galleryStrategy ?? GalleryStrategy();

  final ChapterStrategy _chapterStrategy;
  final GalleryStrategy _galleryStrategy;

  static const _compatibleExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.pdf',
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.zip',
    '.rar',
    '.7z',
  };

  Future<Result<List<Chapter>>> getChapters(
    Resource resource,
    FileSource source,
  ) async {
    try {
      return Ok(await _chapterStrategy.getChapters(resource, source));
    } catch (error) {
      return Err(FileNotFoundError('加载章节列表失败', cause: error));
    }
  }

  Future<Result<List<FileEntry>>> getChapterContents(
    Resource resource,
    FileSource source,
  ) async {
    try {
      return Ok(await _chapterStrategy.getContents(resource, source));
    } catch (error) {
      return Err(FileNotFoundError('加载章节内容失败', cause: error));
    }
  }

  Future<Result<List<FileEntry>>> getGalleryContents(
    Resource resource,
    FileSource source,
  ) async {
    try {
      return Ok(await _galleryStrategy.getContents(resource, source));
    } catch (error) {
      return Err(FileNotFoundError('加载画廊失败', cause: error));
    }
  }

  Future<Result<List<FileEntry>>> listDirectory(
    FileSource source,
    String path,
  ) async {
    try {
      final entries = await source.listDirectory(path);
      final directories = entries.where((entry) => entry.isDirectory).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final files = entries.where((entry) {
        return !entry.isDirectory &&
            _compatibleExtensions.contains(
              p.extension(entry.name).toLowerCase(),
            );
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
      return Ok([...directories, ...files]);
    } catch (error) {
      return Err(FileNotFoundError('加载目录失败', cause: error));
    }
  }

  Future<Result<bool>> hasSubdirectories(FileSource source, String path) async {
    final result = await listDirectory(source, path);
    return switch (result) {
      Ok(:final value) => Ok(value.any((entry) => entry.isDirectory)),
      Err(:final error) => Err(error),
    };
  }
}
