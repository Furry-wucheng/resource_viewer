import '../../domain/models/chapter.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/resource.dart';
import '../content_provider/content_provider.dart';
import '../file_source/file_source.dart';

/// 组织模式策略抽象接口
///
/// 对应三种组织模式：章节 / 平铺网格 / 画廊。
/// 每个策略负责：提供章节列表、提供内容条目列表、创建查看器 ContentProvider。
abstract class OrganizationStrategy {
  /// 当前策略对应的组织模式
  OrganizationMode get mode;

  /// 获取章节列表（异步，内部调用 FileSource.listDirectory）
  ///
  /// 仅 ChapterStrategy 返回非空列表；
  /// FlatGridStrategy 和 GalleryStrategy 返回空列表。
  Future<List<Chapter>> getChapters(Resource r, FileSource source);

  /// 获取该模式下显示的 FileEntry 列表
  ///
  /// - ChapterStrategy: 子文件夹 + 散落兼容文件
  /// - FlatGridStrategy: 当前层级文件夹 + 文件
  /// - GalleryStrategy: 递归扁平全部文件
  Future<List<FileEntry>> getContents(Resource r, FileSource source);

  /// 创建查看器内容提供者
  ///
  /// [chapter] 仅在 ChapterStrategy 中使用，指定要查看的章节。
  /// 其他策略忽略此参数。
  ContentProvider createProvider(
    Resource r,
    FileSource source, {
    Chapter? chapter,
  });
}
