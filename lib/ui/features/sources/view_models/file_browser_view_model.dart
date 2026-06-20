import 'package:path/path.dart' as p;
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
import '../../../core/view_models/base_view_model.dart';

/// 文件浏览器视图模式
enum ViewMode { list, grid }

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
  });

  final String sourceId;
  final String sourceName;
  final FilesystemRepository filesystemRepository;
  final ResourceRepository resourceRepository;
  final TagRepository tagRepository;
  final ThumbnailRepository thumbnailRepository;
  final FileSourceFactory fileSourceFactory;
  final _uuid = const Uuid();

  /// 当前路径（相对于源根目录）
  String _currentPath = '';
  String get currentPath => _currentPath;

  /// 路径层级（用于面包屑导航）
  List<BreadcrumbItem> _breadcrumbs = [BreadcrumbItem('', '根目录')];
  List<BreadcrumbItem> get breadcrumbs => _breadcrumbs;

  /// 当前目录下的文件列表
  List<FileEntry> _entries = [];
  List<FileEntry> get entries => _entries;

  /// 视图模式
  ViewMode _viewMode = ViewMode.list;
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

    final result = await filesystemRepository.listDirectory(sourceId, path);
    switch (result) {
      case Ok(:final value):
        _entries = value;
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
    notifyListeners();
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

  /// 加载已入库的资源路径、ID 映射和标签
  Future<void> _loadImportedPaths() async {
    final result = await resourceRepository.getResourcesBySourceId(sourceId);
    switch (result) {
      case Ok(:final value):
        _importedPaths = value.map((r) => r.relativePath).toSet();
        _pathToResourceId = {for (final r in value) r.relativePath: r.id};
        // 加载每个资源的标签
        await _loadResourceTags(value.map((r) => r.id).toList());
      case Err():
        _importedPaths = {};
        _pathToResourceId = {};
        _resourceTags = {};
    }
  }

  /// 加载资源标签
  Future<void> _loadResourceTags(List<String> resourceIds) async {
    final tagsMap = <String, List<Tag>>{};
    for (final id in resourceIds) {
      final result = await tagRepository.getTagsForResource(id);
      switch (result) {
        case Ok(:final value):
          tagsMap[id] = value;
        case Err():
          tagsMap[id] = [];
      }
    }
    _resourceTags = tagsMap;
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
  Future<Result<BatchAddResult>> addSelectedResources() async {
    final fileSource = fileSourceFactory.get(sourceId);
    if (fileSource == null) {
      return const Err(SourceUnreachableError('数据源连接尚未初始化'));
    }

    var added = 0;
    var skipped = 0;
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
      final createResult = await resourceRepository.createResource(
        id: id,
        sourceId: sourceId,
        name: entry.name,
        type: type,
        relativePath: entry.path,
        organizationMode: OrganizationMode.direct,
        fileSize: entry.size,
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
          added++;
      }
    }

    exitMultiSelectMode();
    return Ok(BatchAddResult(added: added, skipped: skipped));
  }

  Future<ResourceType?> _resourceTypeFor(FileEntry entry) async {
    if (entry.isDirectory) {
      return await _directoryContainsSupportedContent(entry.path)
          ? ResourceType.folder
          : null;
    }

    return switch (p.extension(entry.name).toLowerCase()) {
      '.pdf' => ResourceType.pdf,
      '.zip' || '.rar' || '.7z' || '.tar' || '.gz' => ResourceType.archive,
      '.mp4' ||
      '.mkv' ||
      '.avi' ||
      '.mov' ||
      '.wmv' ||
      '.flv' ||
      '.webm' ||
      '.m4v' => ResourceType.video,
      _ => null,
    };
  }

  bool _isSupportedContent(FileEntry entry) {
    if (entry.isDirectory) return false;
    return const {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.tiff',
      '.tif',
      '.pdf',
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
      '.mp4',
      '.mkv',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.m4v',
    }.contains(p.extension(entry.name).toLowerCase());
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

  @override
  Future<void> retry() async {
    await loadDirectory(_currentPath);
  }
}

class BatchAddResult {
  const BatchAddResult({required this.added, required this.skipped});

  final int added;
  final int skipped;
}

/// 面包屑项
class BreadcrumbItem {
  BreadcrumbItem(this.path, this.label);

  final String path;
  final String label;
}
