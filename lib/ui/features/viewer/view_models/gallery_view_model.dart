import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../data/repositories/organization_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/resource.dart';
import '../../../../shared/file_source/file_source.dart';
import '../../../core/view_models/base_view_model.dart';

/// 画廊模式 ViewModel
class GalleryViewModel extends BaseViewModel {
  GalleryViewModel({
    required this.resource,
    required this.fileSource,
    required this.thumbnailRepository,
    required this.organizationRepository,
  });

  final Resource resource;
  final FileSource fileSource;
  final ThumbnailRepository thumbnailRepository;
  final OrganizationRepository organizationRepository;

  /// 递归扁平化的全部兼容文件
  List<FileEntry> _allFiles = [];
  List<FileEntry> get allFiles => _allFiles;

  /// 总文件数
  int get totalFileCount => _allFiles.length;

  bool _supportsChapterMode = false;
  bool get supportsChapterMode => _supportsChapterMode;

  /// 初始化：加载全部扁平文件列表
  Future<void> init() async {
    startLoading();
    final supportResult = await organizationRepository.hasSubdirectories(
      fileSource,
      resource.relativePath,
    );
    _supportsChapterMode = switch (supportResult) {
      Ok(:final value) => value,
      Err() => false,
    };
    final result = await organizationRepository.getGalleryContents(
      resource,
      fileSource,
    );
    switch (result) {
      case Ok(:final value):
        _allFiles = value;
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  @override
  Future<void> retry() => init();
}
