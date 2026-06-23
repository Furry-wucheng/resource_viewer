import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../data/repositories/organization_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/chapter.dart';
import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/resource.dart';
import '../../../../shared/file_source/file_source.dart';
import '../../../core/view_models/base_view_model.dart';

enum ChapterViewMode { grid, list }

const _kChapterViewModeKey = 'chapter_view_mode';

/// 章节列表页 ViewModel
class ChapterListViewModel extends BaseViewModel {
  ChapterListViewModel({
    required this.resource,
    required this.fileSource,
    required this.thumbnailRepository,
    required this.organizationRepository,
  });

  final Resource resource;
  final FileSource fileSource;
  final ThumbnailRepository thumbnailRepository;
  final OrganizationRepository organizationRepository;

  List<Chapter> _chapters = [];
  List<FileEntry> _looseFiles = [];

  List<Chapter> get chapters => _chapters;
  List<FileEntry> get looseFiles => _looseFiles;

  ChapterViewMode _viewMode = ChapterViewMode.grid;
  ChapterViewMode get viewMode => _viewMode;

  /// 从持久化存储加载上次使用的视图模式
  static Future<ChapterViewMode> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kChapterViewModeKey);
    if (index != null && index < ChapterViewMode.values.length) {
      return ChapterViewMode.values[index];
    }
    return ChapterViewMode.grid;
  }

  /// 应用已加载的视图模式
  void applyViewMode(ChapterViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// 切换视图模式
  void toggleViewMode() {
    _viewMode = _viewMode == ChapterViewMode.grid
        ? ChapterViewMode.list
        : ChapterViewMode.grid;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_kChapterViewModeKey, _viewMode.index),
    );
    notifyListeners();
  }

  /// 初始化：加载章节列表和散落文件
  Future<void> init() async {
    startLoading();
    final chaptersResult = await organizationRepository.getChapters(
      resource,
      fileSource,
    );
    if (chaptersResult case Err(:final error)) {
      setResult(Err(error));
      return;
    }
    final contentsResult = await organizationRepository.getChapterContents(
      resource,
      fileSource,
    );
    switch (contentsResult) {
      case Ok(:final value):
        _chapters = (chaptersResult as Ok<List<Chapter>>).value;
        _looseFiles = value.where((entry) => !entry.isDirectory).toList();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 获取章节缩略图路径
  Future<String?> getChapterThumbnail(Chapter chapter) async {
    if (chapter.coverPath == null) return null;
    // 使用 resource.id + chapter.path 作为缓存键
    final cacheKey = '${resource.id}_${chapter.path}';
    final result = await thumbnailRepository.get(cacheKey);
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  @override
  Future<void> retry() => init();
}
