import '../../domain/core/result.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../../shared/file_source/file_source.dart';
import '../../shared/media/media_file_types.dart';
import '../../shared/organization/chapter_gallery_strategy.dart';
import '../../shared/organization/chapter_strategy.dart';
import '../../shared/organization/gallery_strategy.dart';

class OrganizationRepository {
  OrganizationRepository({
    ChapterStrategy? chapterStrategy,
    ChapterGalleryStrategy? chapterGalleryStrategy,
    GalleryStrategy? galleryStrategy,
  }) : _chapterStrategy = chapterStrategy ?? ChapterStrategy(),
       _chapterGalleryStrategy =
           chapterGalleryStrategy ?? ChapterGalleryStrategy(),
       _galleryStrategy = galleryStrategy ?? GalleryStrategy();

  final ChapterStrategy _chapterStrategy;
  final ChapterGalleryStrategy _chapterGalleryStrategy;
  final GalleryStrategy _galleryStrategy;

  Future<Result<List<Chapter>>> getChapters(
    Resource resource,
    FileSource source,
  ) async {
    try {
      final strategy =
          resource.organizationMode == OrganizationMode.chapterGallery
          ? _chapterGalleryStrategy
          : _chapterStrategy;
      return Ok(await strategy.getChapters(resource, source));
    } catch (error) {
      return Err(FileNotFoundError('加载章节列表失败', cause: error));
    }
  }

  Future<Result<List<FileEntry>>> getChapterContents(
    Resource resource,
    FileSource source,
  ) async {
    try {
      final strategy =
          resource.organizationMode == OrganizationMode.chapterGallery
          ? _chapterGalleryStrategy
          : _chapterStrategy;
      return Ok(await strategy.getContents(resource, source));
    } catch (error) {
      return Err(FileNotFoundError('加载章节内容失败', cause: error));
    }
  }

  Future<Result<List<FileEntry>>> getChapterGalleryContents(
    FileSource source,
    Chapter chapter,
  ) async {
    try {
      return Ok(
        await _chapterGalleryStrategy.getChapterContents(source, chapter),
      );
    } catch (error) {
      return Err(FileNotFoundError('加载章节画廊失败', cause: error));
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
        return !entry.isDirectory && MediaFileTypes.isViewable(entry.name);
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
