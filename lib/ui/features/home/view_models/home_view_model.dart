import 'dart:async';

import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/tag_repository.dart';
import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/resource_query.dart';
import '../../../../domain/models/tag.dart';
import '../../../../domain/use_cases/filter_resources_by_tags_use_case.dart';
import '../../../core/view_models/base_view_model.dart';

/// 内置"收藏"标签的固定 ID
const String favoriteTagId = '00000000-0000-0000-0000-000000000001';

/// 批量删除结果
class BatchDeleteResult {
  const BatchDeleteResult({required this.deleted, required this.failed});
  final int deleted;
  final int failed;
}

/// 首页 ViewModel
///
/// 使用统一查询管线：标签筛选、搜索、排序、键集分页全部下推到 SQL。
class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required this.resourceRepository,
    required this.thumbnailRepository,
    required this.tagRepository,
    required this.filterResourcesByTags,
    String? initialTagId,
  }) : _tagIds = initialTagId == null ? <String>{} : {initialTagId};

  final ResourceRepository resourceRepository;
  final ThumbnailRepository thumbnailRepository;
  final TagRepository tagRepository;
  final FilterResourcesByTagsUseCase filterResourcesByTags;

  // ---- 分页状态 ----

  List<Resource> _resources = [];
  Map<String, String?> _thumbnailPaths = {};
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingFirstPage = false;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  int _queryGeneration = 0;

  // ---- 筛选状态 ----

  final Set<String> _tagIds;
  String _searchQuery = '';
  bool _favoriteOnly = false;
  bool get favoriteOnly => _favoriteOnly;

  // ---- 收藏状态 ----

  Set<String> _favoriteResourceIds = {};

  // ---- 标签列表 ----

  List<Tag> _tags = [];
  List<Tag> _customTags = [];

  // ---- 计数 ----

  int? _totalCount;

  // ---- 多选状态 ----

  bool _isMultiSelectMode = false;
  final Set<String> _selectedResourceIds = {};

  // ---- 订阅 ----

  StreamSubscription<Result<List<Resource>>>? _dbSubscription;
  Timer? _searchDebounce;

  // ---- Getters ----

  List<Resource> get resources => _resources;
  Map<String, String?> get thumbnailPaths => _thumbnailPaths;
  Set<String> get favoriteResourceIds => _favoriteResourceIds;
  Set<String> get selectedTagIds => _tagIds;
  String get searchQuery => _searchQuery;
  int? get totalCount => _totalCount;
  List<Tag> get tags => _tags;
  List<Tag> get customTags => _customTags;
  bool get isAllSelected => _tagIds.isEmpty && !_favoriteOnly;
  bool get isFavoriteSelected => _favoriteOnly;
  bool get hasActiveFilter =>
      _tagIds.isNotEmpty || _searchQuery.isNotEmpty || _favoriteOnly;

  // 分页状态 getter
  bool get hasMore => _hasMore;
  bool get isLoadingFirstPage => _isLoadingFirstPage;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;
  int get loadedCount => _resources.length;
  String? get nextCursor => _nextCursor;

  // 多选状态 getter
  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedResourceIds => Set.unmodifiable(_selectedResourceIds);
  int get selectedCount => _selectedResourceIds.length;
  bool get isAllVisibleSelected =>
      _resources.isNotEmpty &&
      _resources.every((r) => _selectedResourceIds.contains(r.id));

  /// 当前查询条件（用于生成下一页查询等）
  ResourceQuery get _currentQuery => ResourceQuery(
    searchQuery: _searchQuery,
    tagIds: _tagIds.toList(),
    favoriteOnly: _favoriteOnly,
    pageSize: 50,
  );

  // ---- 生命周期 ----

  /// 开始监听数据库变化
  ///
  /// 当资源或源状态变化时重新加载第一页。
  /// TODO: 改为局部更新而非全量重置，避免丢弃用户已滚动加载的分页数据。
  void startWatching() {
    _dbSubscription?.cancel();
    _dbSubscription = resourceRepository.watchAvailableResources().listen((
      result,
    ) {
      if (result is Ok) {
        _loadFirstPage();
      }
    });
  }

  /// 手动加载首页
  Future<void> loadFirstPage() => _loadFirstPage();

  Future<void> _loadFirstPage() async {
    _isLoadingFirstPage = true;
    _loadMoreError = null;
    _queryGeneration++;
    final gen = _queryGeneration;
    startLoading();

    // 清除已有数据
    _resources = [];
    _thumbnailPaths = {};
    _nextCursor = null;
    _hasMore = false;
    notifyListeners();

    // 查询第一页
    final result = await resourceRepository.queryResources(_currentQuery);
    if (gen != _queryGeneration) return;

    switch (result) {
      case Ok(:final value):
        _resources = value.items;
        _nextCursor = value.nextCursor;
        _hasMore = value.hasMore;
        _totalCount = value.totalCount;
        await _loadThumbnailsForResources(_resources);
        if (gen != _queryGeneration) return;
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
    _isLoadingFirstPage = false;
    notifyListeners();
  }

  /// 加载下一页
  Future<void> loadNextPage() async {
    if (!_hasMore || _isLoadingMore || _nextCursor == null) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    _queryGeneration++;
    final gen = _queryGeneration;
    notifyListeners();

    final nextQuery = _currentQuery.nextPage(
      ResourceCursor.decode(_nextCursor!)!,
    );
    final result = await resourceRepository.queryResources(nextQuery);
    if (gen != _queryGeneration) return;

    switch (result) {
      case Ok(:final value):
        _resources = [..._resources, ...value.items];
        _nextCursor = value.nextCursor;
        _hasMore = value.hasMore;
        await _loadThumbnailsForResources(value.items);
        if (gen != _queryGeneration) return;
      case Err(:final error):
        _loadMoreError = error.message;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  // ---- 缩略图 ----

  /// 增量加载指定资源的缩略图
  Future<void> _loadThumbnailsForResources(List<Resource> resources) async {
    for (final r in resources) {
      if (_thumbnailPaths.containsKey(r.id)) continue;
      final result = await thumbnailRepository.get(r.id);
      switch (result) {
        case Ok(:final value):
          _thumbnailPaths[r.id] = value;
        case Err():
          _thumbnailPaths[r.id] = null;
      }
    }
  }

  // ===== 筛选逻辑 =====

  /// 选择标签（加入筛选）
  Future<void> selectTag(String tagId) async {
    _tagIds.add(tagId);
    await _loadFirstPage();
  }

  /// 取消选择标签
  Future<void> deselectTag(String tagId) async {
    _tagIds.remove(tagId);
    await _loadFirstPage();
  }

  /// 切换标签选择
  Future<void> toggleTag(String tagId) async {
    if (_tagIds.contains(tagId)) {
      _tagIds.remove(tagId);
    } else {
      _tagIds.add(tagId);
    }
    await _loadFirstPage();
  }

  /// 选择全部（清除标签和收藏筛选）
  Future<void> selectAll() async {
    _tagIds.clear();
    _favoriteOnly = false;
    await _loadFirstPage();
  }

  /// 选择收藏
  Future<void> selectFavorite() async {
    _tagIds.clear();
    _favoriteOnly = !_favoriteOnly;
    await _loadFirstPage();
  }

  /// 设置搜索词（带防抖）
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadFirstPage);
  }

  // ===== 收藏状态 =====

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

  /// 加载标签列表
  Future<void> loadTags() async {
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

  /// 初始化标签和收藏（首页首次加载后调用）
  Future<void> loadInitialData() async {
    await Future.wait([_loadFavorites(), loadTags()]);
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
          if (_favoriteOnly) {
            _resources = _resources
                .where((resource) => resource.id != resourceId)
                .toList();
            _thumbnailPaths.remove(resourceId);
          }
          notifyListeners();
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
          notifyListeners();
        case Err():
          break;
      }
    }
  }

  /// 检查资源是否已收藏
  bool isFavorited(String resourceId) {
    return _favoriteResourceIds.contains(resourceId);
  }

  // ===== 多选模式 =====

  void enterMultiSelectMode() {
    _isMultiSelectMode = true;
    _selectedResourceIds.clear();
    notifyListeners();
  }

  void exitMultiSelectMode() {
    _isMultiSelectMode = false;
    _selectedResourceIds.clear();
    notifyListeners();
  }

  void toggleResourceSelection(String id) {
    if (_selectedResourceIds.contains(id)) {
      _selectedResourceIds.remove(id);
    } else {
      _selectedResourceIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAllVisible() {
    if (isAllVisibleSelected) {
      _selectedResourceIds.clear();
    } else {
      _selectedResourceIds.addAll(_resources.map((r) => r.id));
    }
    notifyListeners();
  }

  /// 批量删除选中的资源
  Future<Result<BatchDeleteResult>> batchDeleteSelectedResources() async {
    final ids = _selectedResourceIds.toList();
    var deleted = 0;
    var failed = 0;

    for (final id in ids) {
      final result = await resourceRepository.deleteResource(id);
      switch (result) {
        case Ok():
          deleted++;
        case Err():
          failed++;
      }
    }

    _selectedResourceIds.clear();
    exitMultiSelectMode();
    // 刷新第一页
    await _loadFirstPage();

    return Ok(BatchDeleteResult(deleted: deleted, failed: failed));
  }

  @override
  Future<void> retry() => _loadFirstPage();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}
