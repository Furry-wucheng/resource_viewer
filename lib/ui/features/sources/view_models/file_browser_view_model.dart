import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/filesystem_repository.dart';
import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/tag_repository.dart';
import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/tag.dart';
import '../../../../shared/file_source/file_source_factory.dart';
import '../../../../shared/file_source/smb_file_source.dart';
import '../../../../shared/media/media_file_types.dart';
import '../../../core/view_models/base_view_model.dart';

/// 文件浏览器视图模式
enum ViewMode { list, grid }

/// 文件浏览器排序方式（按 source + path 独立持久化）
enum FileBrowserSort {
  nameAsc,
  nameDesc,
  modifiedDesc,
  modifiedAsc,
  sizeDesc,
  sizeAsc,
}

const _kViewModeKey = 'file_browser_view_mode';
const _kDirectorySortPrefix = 'file_browser_directory_sort';

// ============================================================================
// 缩略图加载池 — 限制并发，防止同时大量 thumbnailFor 导致 IO/CPU/内存尖峰
// ============================================================================

/// 带并发上限的异步任务池
class _ThumbnailPool {
  _ThumbnailPool(this.maxConcurrent);

  final int maxConcurrent;
  int _running = 0;
  final _queue = <void Function()>[];

  /// 提交任务；返回的 Future 在任务完成时 resolve（保留错误语义）
  Future<T> schedule<T>(Future<T> Function() task) {
    final completer = Completer<T>.sync();
    _queue.add(() async {
      _running++;
      try {
        final result = await task();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      } finally {
        _running--;
        _runNext();
      }
    });
    _runNext();
    return completer.future;
  }

  void _runNext() {
    while (_running < maxConcurrent && _queue.isNotEmpty) {
      _queue.removeAt(0)();
    }
  }

  /// 清空等待队列（不取消进行中任务）
  void drainPending() => _queue.clear();
}

// ============================================================================
// ViewModel
// ============================================================================

/// 文件浏览器 ViewModel
class FileBrowserViewModel extends BaseViewModel {
  FileBrowserViewModel({
    required this.sourceId,
    required this.sourceName,
    required this.filesystemRepository,
    required this.resourceRepository,
    required this.tagRepository,
    required this.thumbnailRepository,
    required this.fileSourceFactory,
    this.thumbnailConcurrency = 4,
    ViewMode initialViewMode = ViewMode.list,
  }) : _viewMode = initialViewMode;

  /// 从持久化存储加载上次使用的视图模式
  static Future<ViewMode> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kViewModeKey);
    if (index != null && index < ViewMode.values.length) {
      return ViewMode.values[index];
    }
    return ViewMode.list;
  }

  final String sourceId;
  final String sourceName;
  final FilesystemRepository filesystemRepository;
  final ResourceRepository resourceRepository;
  final TagRepository tagRepository;
  final ThumbnailRepository thumbnailRepository;
  final FileSourceFactory fileSourceFactory;
  final _uuid = const Uuid();

  // ---- 缩略图加载管线 ----

  /// 缩略图加载并发数（由设置页传入，1~8，默认 4）
  final int thumbnailConcurrency;

  /// 已完成缩略图缓存上限（避免 rebuild 时重复加载；超出时淘汰最旧项）
  static const _maxCompletedCache = 256;

  /// 仅保留进行中的 Future（用于去重，completed 后移除避免持有 Uint8List）
  final Map<String, Future<Uint8List?>> _inFlightThumbnails = {};

  /// 已完成缩略图缓存（bounded，仅用于 rebuild 快速返回）
  final Map<String, Uint8List?> _completedThumbnails = {};
  int _thumbnailGeneration = 0;

  late final _thumbnailPool = _ThumbnailPool(_poolConcurrency);

  int get _poolConcurrency {
    if (!_isRemote) return thumbnailConcurrency;
    // 远程源（SMB）减半以避免压垮连接，最少保持 1 并发
    return (thumbnailConcurrency / 2).ceil().clamp(1, thumbnailConcurrency);
  }

  bool get _isRemote {
    final source = fileSourceFactory.get(sourceId);
    if (source == null) return false;
    // SMB 等远程源需要更低并发
    return source is SmbFileSource;
  }

  Future<Uint8List?> thumbnailFor(FileEntry entry) {
    // 1) 已完成缓存命中 → 同步返回
    if (_completedThumbnails.containsKey(entry.path)) {
      return Future.value(_completedThumbnails[entry.path]);
    }
    // 2) 进行中 → 返回同一 Future 去重
    if (_inFlightThumbnails.containsKey(entry.path)) {
      return _inFlightThumbnails[entry.path]!;
    }
    // 3) 通过并发池提交新任务
    final generation = _thumbnailGeneration;
    final future = _thumbnailPool.schedule(() async {
      final fileSource = fileSourceFactory.get(sourceId);
      if (fileSource == null) return null;
      return switch (await thumbnailRepository.preview(fileSource, entry)) {
        Ok(:final value) => value,
        Err() => null,
      };
    });
    _inFlightThumbnails[entry.path] = future;
    // 完成后移入 completed cache，同时从 in-flight 移除
    future.then((result) {
      if (generation != _thumbnailGeneration) return;
      _inFlightThumbnails.remove(entry.path);
      _completedThumbnails[entry.path] = result;
      // Bounded cache：超出上限时淘汰最早项
      while (_completedThumbnails.length > _maxCompletedCache) {
        _completedThumbnails.remove(_completedThumbnails.keys.first);
      }
    });
    return future;
  }

  void _clearThumbnailState() {
    _thumbnailGeneration++;
    _thumbnailPool.drainPending();
    _inFlightThumbnails.clear();
    _completedThumbnails.clear();
  }

  /// 当前路径（相对于源根目录）
  String _currentPath = '';
  String get currentPath => _currentPath;

  /// 路径层级（用于面包屑导航）
  List<BreadcrumbItem> _breadcrumbs = [BreadcrumbItem('', '根目录')];
  List<BreadcrumbItem> get breadcrumbs => _breadcrumbs;

  /// 当前目录下的文件列表
  List<FileEntry> _entries = [];
  List<FileEntry> get entries => _entries;

  FileBrowserSort _sort = FileBrowserSort.nameAsc;
  FileBrowserSort get sort => _sort;

  /// 视图模式
  ViewMode _viewMode;
  ViewMode get viewMode => _viewMode;

  /// 已入库的资源路径集合（用于判断是否已入库）
  Set<String> _importedPaths = {};
  Set<String> get importedPaths => _importedPaths;

  /// 已入库资源的 ID 映射（path → resourceId）
  Map<String, String> _pathToResourceId = {};
  Map<String, String> get pathToResourceId => _pathToResourceId;

  /// 每个资源的标签列表（resourceId → tags）
  Map<String, List<Tag>> _resourceTags = {};
  Map<String, List<Tag>> get resourceTags => _resourceTags;

  /// 多选模式
  bool _isMultiSelectMode = false;
  bool get isMultiSelectMode => _isMultiSelectMode;

  /// 已选中的路径集合
  final Set<String> _selectedPaths = {};
  Set<String> get selectedPaths => _selectedPaths;

  bool _entryActionInProgress = false;

  /// 防止桌面双击把同一个条目打开两次。
  bool tryBeginEntryAction() {
    if (_entryActionInProgress) return false;
    _entryActionInProgress = true;
    return true;
  }

  void endEntryAction() {
    _entryActionInProgress = false;
  }

  /// 加载目录内容
  Future<void> loadDirectory(String path) async {
    startLoading();
    _currentPath = path;
    _updateBreadcrumbs(path);
    await _loadSortForPath(path);
    // 切换目录时清理缩略图状态：清空队列 + 释放已缓存字节
    _clearThumbnailState();
    _visibleCount = _initialVisibleCount;

    final result = await filesystemRepository.listDirectory(sourceId, path);
    switch (result) {
      case Ok(:final value):
        _entries = _sortEntries(value);
        await _loadImportedPaths();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 进入子目录
  Future<void> enterDirectory(String dirName) async {
    final newPath = _currentPath.isEmpty ? dirName : '$_currentPath/$dirName';
    await loadDirectory(newPath);
  }

  /// 导航到指定面包屑层级
  Future<void> navigateToBreadcrumb(int index) async {
    final item = _breadcrumbs[index];
    await loadDirectory(item.path);
  }

  /// 返回上一级
  Future<bool> goBack() async {
    if (_currentPath.isEmpty) return false;

    final parts = _currentPath.split('/');
    parts.removeLast();
    final parentPath = parts.join('/');
    await loadDirectory(parentPath);
    return true;
  }

  /// 切换视图模式
  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_kViewModeKey, _viewMode.index),
    );
    notifyListeners();
  }

  /// 从持久化存储恢复视图模式（异步加载后调用）
  void applyViewMode(ViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  Future<void> setSort(FileBrowserSort sort) async {
    if (_sort == sort) return;
    _sort = sort;
    _entries = _sortEntries(_entries);
    _visibleCount = _initialVisibleCount;
    _clearThumbnailState();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortStorageKey(_currentPath), sort.index);
  }

  Future<void> _loadSortForPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_sortStorageKey(path));
    _sort = index != null && index >= 0 && index < FileBrowserSort.values.length
        ? FileBrowserSort.values[index]
        : FileBrowserSort.nameAsc;
  }

  String _sortStorageKey(String path) {
    final normalizedPath = path.isEmpty
        ? '__root__'
        : Uri.encodeComponent(path);
    return '$_kDirectorySortPrefix.$sourceId.$normalizedPath';
  }

  List<FileEntry> _sortEntries(List<FileEntry> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      final result = switch (_sort) {
        FileBrowserSort.nameAsc => _compareName(a, b),
        FileBrowserSort.nameDesc => _compareName(b, a),
        FileBrowserSort.modifiedDesc => _compareDate(
          b.modifiedAt,
          a.modifiedAt,
        ),
        FileBrowserSort.modifiedAsc => _compareDate(a.modifiedAt, b.modifiedAt),
        FileBrowserSort.sizeDesc => _compareSize(b.size, a.size),
        FileBrowserSort.sizeAsc => _compareSize(a.size, b.size),
      };
      return result == 0 ? _compareName(a, b) : result;
    });
    return sorted;
  }

  int _compareName(FileEntry a, FileEntry b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _compareDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _compareSize(BigInt? a, BigInt? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// 更新面包屑导航
  void _updateBreadcrumbs(String path) {
    _breadcrumbs = [BreadcrumbItem('', '根目录')];

    if (path.isNotEmpty) {
      final parts = path.split('/');
      var currentPath = '';
      for (var i = 0; i < parts.length; i++) {
        currentPath = currentPath.isEmpty
            ? parts[i]
            : '$currentPath/${parts[i]}';
        _breadcrumbs.add(BreadcrumbItem(currentPath, parts[i]));
      }
    }
  }

  /// 加载当前目录的入库状态（仅查询当前目录条目，避免加载全源）
  Future<void> _loadImportedPaths() async {
    final currentPaths = _entries.map((e) => e.path).toList();
    if (currentPaths.isEmpty) {
      _importedPaths = {};
      _pathToResourceId = {};
      _resourceTags = {};
      return;
    }

    final result = await resourceRepository.getResourcesBySourceIdAndPaths(
      sourceId,
      currentPaths,
    );
    switch (result) {
      case Ok(:final value):
        _importedPaths = value.map((r) => r.relativePath).toSet();
        _pathToResourceId = {for (final r in value) r.relativePath: r.id};
        await _loadResourceTags(value.map((r) => r.id).toList());
      case Err():
        _importedPaths = {};
        _pathToResourceId = {};
        _resourceTags = {};
    }
  }

  /// 可见条目数量（用于大目录分批渲染）
  static const _initialVisibleCount = 150;
  static const _visibleIncrement = 150;
  int _visibleCount = _initialVisibleCount;
  int get visibleCount => _visibleCount;

  /// 获取当前可见条目
  List<FileEntry> get visibleEntries => _entries.length <= _visibleCount
      ? _entries
      : _entries.sublist(0, _visibleCount);

  /// 加载更多可见条目
  void loadMoreEntries() {
    if (_visibleCount >= _entries.length) return;
    _visibleCount = (_visibleCount + _visibleIncrement).clamp(
      0,
      _entries.length,
    );
    notifyListeners();
  }

  /// 手动刷新当前目录（绕过 TTL 缓存）
  Future<void> refreshCurrentDirectory() async {
    filesystemRepository.invalidateCache(sourceId);
    await loadDirectory(_currentPath);
  }

  /// 加载资源标签
  Future<void> _loadResourceTags(List<String> resourceIds) async {
    final result = await tagRepository.getTagsForResources(resourceIds);
    switch (result) {
      case Ok(:final value):
        _resourceTags = value;
      case Err():
        _resourceTags = {for (final id in resourceIds) id: []};
    }
  }

  /// 检查路径是否已入库
  bool isImported(String path) => _importedPaths.contains(path);

  /// 获取路径对应的资源 ID
  String? getResourceId(String path) => _pathToResourceId[path];

  /// 获取路径对应的标签列表
  List<Tag> getTagsForPath(String path) {
    final resourceId = _pathToResourceId[path];
    if (resourceId == null) return [];
    return _resourceTags[resourceId] ?? [];
  }

  /// 更新资源标签
  Future<void> updateResourceTags(String path, Set<String> tagIds) async {
    final resourceId = _pathToResourceId[path];
    if (resourceId == null) return;

    final result = await tagRepository.setTagsForResource(
      resourceId,
      tagIds.toList(),
    );
    switch (result) {
      case Ok():
        // 重新加载该资源的标签
        final tagsResult = await tagRepository.getTagsForResource(resourceId);
        switch (tagsResult) {
          case Ok(:final value):
            _resourceTags[resourceId] = value;
            notifyListeners();
          case Err():
            break;
        }
      case Err():
        break;
    }
  }

  /// 进入多选模式
  void enterMultiSelectMode() {
    _isMultiSelectMode = true;
    _selectedPaths.clear();
    notifyListeners();
  }

  /// 退出多选模式
  void exitMultiSelectMode() {
    _isMultiSelectMode = false;
    _selectedPaths.clear();
    notifyListeners();
  }

  /// 切换选中状态
  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    notifyListeners();
  }

  /// 全选/取消全选
  void selectAll() {
    if (_selectedPaths.length == _entries.length) {
      _selectedPaths.clear();
    } else {
      _selectedPaths.addAll(_entries.map((e) => e.path));
    }
    notifyListeners();
  }

  /// 获取已选中的文件条目
  List<FileEntry> getSelectedEntries() {
    return _entries.where((e) => _selectedPaths.contains(e.path)).toList();
  }

  /// 将当前选中的兼容项目批量加入资源库。
  Future<Result<BatchAddResult>> addSelectedResources({
    List<String> tagIds = const [],
    OrganizationMode? organizationMode,
  }) async {
    final fileSource = fileSourceFactory.get(sourceId);
    if (fileSource == null) {
      return const Err(SourceUnreachableError('数据源连接尚未初始化'));
    }

    var added = 0;
    var skipped = 0;
    final addedResourceIds = <String>[];
    for (final entry in getSelectedEntries()) {
      if (isImported(entry.path)) {
        skipped++;
        continue;
      }

      final type = await _resourceTypeFor(entry);
      if (type == null) {
        skipped++;
        continue;
      }

      final id = _uuid.v4();
      final createResult = await resourceRepository.createResourceWithTags(
        id: id,
        sourceId: sourceId,
        name: entry.name,
        type: type,
        relativePath: entry.path,
        organizationMode: organizationMode,
        fileSize: entry.size,
        tagIds: tagIds,
      );
      switch (createResult) {
        case Err(:final error):
          return Err(error);
        case Ok():
          final thumbResult = await thumbnailRepository.generate(
            id,
            fileSource,
            entry.path,
            type,
          );
          if (thumbResult case Err(:final error)) return Err(error);
          _importedPaths.add(entry.path);
          _pathToResourceId[entry.path] = id;
          addedResourceIds.add(id);
          added++;
      }
    }

    exitMultiSelectMode();
    return Ok(
      BatchAddResult(
        added: added,
        skipped: skipped,
        addedResourceIds: addedResourceIds,
      ),
    );
  }

  Future<ResourceType?> _resourceTypeFor(FileEntry entry) async {
    if (entry.isDirectory) {
      return await _directoryContainsSupportedContent(entry.path)
          ? ResourceType.folder
          : null;
    }

    if (MediaFileTypes.isPdf(entry.name)) return ResourceType.pdf;
    if (MediaFileTypes.isArchive(entry.name)) return ResourceType.archive;
    if (MediaFileTypes.isVideo(entry.name)) return ResourceType.video;
    return null;
  }

  bool _isSupportedContent(FileEntry entry) {
    if (entry.isDirectory) return false;
    return MediaFileTypes.isSupported(entry.name);
  }

  /// 文件夹只在整个子树都没有兼容内容时才视为空。
  ///
  /// 这与文件浏览器的按层加载互不冲突：这里只在用户明确执行入库时扫描，
  /// 并且使用集合避免异常文件系统中的目录环导致无限递归。
  Future<bool> _directoryContainsSupportedContent(String rootPath) async {
    final pending = <String>[rootPath];
    final visited = <String>{};

    while (pending.isNotEmpty) {
      final path = pending.removeLast();
      if (!visited.add(path)) continue;

      final result = await filesystemRepository.listDirectory(sourceId, path);
      switch (result) {
        case Ok(:final value):
          if (value.any(_isSupportedContent)) return true;
          pending.addAll(
            value.where((entry) => entry.isDirectory).map((e) => e.path),
          );
        case Err():
          // 某个子目录不可读不代表整个资源为空，继续检查其余分支。
          continue;
      }
    }
    return false;
  }

  /// 为指定的资源批量打标签。
  Future<Result<void>> applyTagsToResources(
    List<String> resourceIds,
    List<String> tagIds,
  ) async {
    for (final resourceId in resourceIds) {
      final result = await tagRepository.setTagsForResource(resourceId, tagIds);
      if (result is Err) {
        return result;
      }
    }

    // 重新加载标签数据
    await _loadImportedPaths();
    return const Ok(null);
  }

  /// 批量为选中的已入库资源打标签。
  ///
  /// 返回 [BatchTagResult]，包含已打标签数和跳过的未入库数。
  /// [tagIds] 为要设置的标签 ID 列表。
  Future<Result<BatchTagResult>> batchTagSelectedResources(
    List<String> tagIds,
  ) async {
    var tagged = 0;
    var skipped = 0;

    for (final entry in getSelectedEntries()) {
      final resourceId = _pathToResourceId[entry.path];
      if (resourceId == null) {
        skipped++;
        continue;
      }

      final result = await tagRepository.setTagsForResource(resourceId, tagIds);
      switch (result) {
        case Ok():
          tagged++;
        case Err(:final error):
          return Err(error);
      }
    }

    // 重新加载标签数据
    await _loadImportedPaths();

    return Ok(BatchTagResult(tagged: tagged, skipped: skipped));
  }

  @override
  Future<void> retry() async {
    await loadDirectory(_currentPath);
  }
}

class BatchAddResult {
  const BatchAddResult({
    required this.added,
    required this.skipped,
    required this.addedResourceIds,
  });

  final int added;
  final int skipped;
  final List<String> addedResourceIds;
}

class BatchTagResult {
  const BatchTagResult({required this.tagged, required this.skipped});

  final int tagged;
  final int skipped;
}

/// 面包屑项
class BreadcrumbItem {
  BreadcrumbItem(this.path, this.label);

  final String path;
  final String label;
}
