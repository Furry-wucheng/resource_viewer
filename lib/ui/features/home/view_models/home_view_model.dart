import 'dart:async';

import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/tag_repository.dart';
import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/tag.dart';
import '../../../../domain/use_cases/filter_resources_by_tags_use_case.dart';
import '../../../core/view_models/base_view_model.dart';

/// 内置"收藏"标签的固定 ID
const String favoriteTagId = '00000000-0000-0000-0000-000000000001';

/// 首页 ViewModel
///
/// 监听可用资源列表，加载缩略图路径，管理收藏状态和筛选逻辑。
class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required this.resourceRepository,
    required this.thumbnailRepository,
    required this.tagRepository,
    required this.filterResourcesByTags,
    String? initialTagId,
  }) : _selectedTagIds = initialTagId == null ? {} : {initialTagId};

  final ResourceRepository resourceRepository;
  final ThumbnailRepository thumbnailRepository;
  final TagRepository tagRepository;
  final FilterResourcesByTagsUseCase filterResourcesByTags;

  // 全量资源数据
  List<Resource> _allResources = [];
  final Map<String, String?> _allThumbnailPaths = {};

  // 筛选后的资源数据
  List<Resource> _resources = [];
  Map<String, String?> _thumbnailPaths = {};

  // 收藏状态
  Set<String> _favoriteResourceIds = {};

  // 筛选状态
  Set<String> _selectedTagIds;
  String _searchQuery = '';
  int? _filteredCount;
  int? _totalCount;

  // 标签列表
  List<Tag> _tags = [];
  List<Tag> _customTags = [];

  StreamSubscription<Result<List<Resource>>>? _subscription;
  Timer? _searchDebounce;
  int _filterGeneration = 0;

  List<Resource> get resources => _resources;
  Map<String, String?> get thumbnailPaths => _thumbnailPaths;
  Set<String> get favoriteResourceIds => _favoriteResourceIds;
  Set<String> get selectedTagIds => _selectedTagIds;
  String get searchQuery => _searchQuery;
  int? get filteredCount => _filteredCount;
  int? get totalCount => _totalCount;
  List<Tag> get tags => _tags;
  List<Tag> get customTags => _customTags;
  bool get isAllSelected => _selectedTagIds.isEmpty;
  bool get isFavoriteSelected => _selectedTagIds.contains(favoriteTagId);
  bool get hasActiveFilter =>
      _selectedTagIds.isNotEmpty || _searchQuery.isNotEmpty;

  /// 开始监听可用资源
  void startWatching() {
    _subscription?.cancel();
    _subscription = resourceRepository.watchAvailableResources().listen((
      result,
    ) {
      switch (result) {
        case Ok(:final value):
          _resources = value;
          _loadThumbnails();
          setResult(const Ok(null));
        case Err(:final error):
          setResult(Err(error));
      }
    });
  }

  /// 手动加载（首次或重试）
  Future<void> loadResources() async {
    startLoading();

    final result = await resourceRepository.getAvailableResources(
      pageSize: 100,
    );
    switch (result) {
      case Ok(:final value):
        _allResources = value;
        _totalCount = value.length;
        await _loadThumbnails();
        await _loadFavorites();
        await _loadTags();
        await _applyFilter();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 加载标签列表
  Future<void> _loadTags() async {
    final result = await tagRepository.getAllTags();
    switch (result) {
      case Ok(:final value):
        _tags = value;
        _customTags = value.where((t) => !t.isBuiltIn).toList();
        notifyListeners();
      case Err():
        break;
    }
  }

  /// 加载收藏状态
  Future<void> _loadFavorites() async {
    final result = await tagRepository.getResourceIdsForTag(favoriteTagId);
    switch (result) {
      case Ok(:final value):
        _favoriteResourceIds = value.toSet();
        notifyListeners();
      case Err():
        break;
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String resourceId) async {
    final isFavorited = _favoriteResourceIds.contains(resourceId);

    if (isFavorited) {
      final result = await tagRepository.removeTagFromResource(
        resourceId,
        favoriteTagId,
      );
      switch (result) {
        case Ok():
          _favoriteResourceIds.remove(resourceId);
          await _applyFilter();
        case Err():
          break;
      }
    } else {
      final result = await tagRepository.addTagToResource(
        resourceId,
        favoriteTagId,
      );
      switch (result) {
        case Ok():
          _favoriteResourceIds.add(resourceId);
          await _applyFilter();
        case Err():
          break;
      }
    }
  }

  /// 检查资源是否已收藏
  bool isFavorited(String resourceId) {
    return _favoriteResourceIds.contains(resourceId);
  }

  // ===== 筛选逻辑 =====

  /// 选择标签（加入筛选）
  Future<void> selectTag(String tagId) async {
    _selectedTagIds.add(tagId);
    await _applyFilter();
  }

  /// 取消选择标签（移除筛选）
  Future<void> deselectTag(String tagId) async {
    _selectedTagIds.remove(tagId);
    await _applyFilter();
  }

  /// 切换标签选择状态
  Future<void> toggleTag(String tagId) async {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    await _applyFilter();
  }

  /// 选择全部（清除所有筛选）
  Future<void> selectAll() async {
    _selectedTagIds.clear();
    await _applyFilter();
  }

  /// 选择收藏
  Future<void> selectFavorite() async {
    _selectedTagIds = {favoriteTagId};
    await _applyFilter();
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _applyFilter);
  }

  /// 应用筛选
  Future<void> _applyFilter() async {
    final generation = ++_filterGeneration;
    List<Resource> filtered;

    if (_selectedTagIds.isEmpty && _searchQuery.isEmpty) {
      // 无筛选条件，显示全部
      filtered = _allResources;
      _filteredCount = _totalCount;
    } else {
      // 标签筛选
      if (_selectedTagIds.isNotEmpty) {
        final result = await filterResourcesByTags(_selectedTagIds);
        switch (result) {
          case Ok(:final value):
            // 只保留当前可用资源
            final availableIds = _allResources.map((r) => r.id).toSet();
            filtered = value.where((r) => availableIds.contains(r.id)).toList();
          case Err():
            filtered = _allResources;
        }
      } else {
        filtered = _allResources;
      }

      // 搜索筛选
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((r) {
          return r.name.toLowerCase().contains(query);
        }).toList();
      }

      _filteredCount = filtered.length;
    }

    if (generation != _filterGeneration) return;
    _resources = filtered;
    final paths = await _loadThumbnailsForResources(filtered);
    if (generation != _filterGeneration) return;
    _thumbnailPaths = paths;
    notifyListeners();
  }

  /// 加载指定资源列表的缩略图
  Future<Map<String, String?>> _loadThumbnailsForResources(
    List<Resource> resources,
  ) async {
    final paths = <String, String?>{};
    for (final r in resources) {
      if (_allThumbnailPaths.containsKey(r.id)) {
        paths[r.id] = _allThumbnailPaths[r.id];
      } else {
        final result = await thumbnailRepository.get(r.id);
        switch (result) {
          case Ok(:final value):
            paths[r.id] = value;
            _allThumbnailPaths[r.id] = value;
          case Err():
            paths[r.id] = null;
        }
      }
    }
    return paths;
  }

  /// 加载所有资源的缩略图路径
  Future<void> _loadThumbnails() async {
    final paths = <String, String?>{};
    for (final r in _resources) {
      final result = await thumbnailRepository.get(r.id);
      switch (result) {
        case Ok(:final value):
          paths[r.id] = value;
        case Err():
          paths[r.id] = null;
      }
    }
    _thumbnailPaths = paths;
    notifyListeners();
  }

  /// 获取分页资源（用于分页加载）
  Future<Result<List<Resource>>> pageResources({
    String? lastCreatedAt,
    String? lastId,
    required int pageSize,
  }) {
    return resourceRepository.getAvailableResources(
      lastCreatedAt: lastCreatedAt,
      lastId: lastId,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> retry() async {
    await loadResources();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
