import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../data/repositories/organization_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/file_entry.dart';
import '../../../../domain/models/resource.dart';
import '../../../../shared/file_source/file_source.dart';
import '../../../core/view_models/base_view_model.dart';
import '../../sources/view_models/file_browser_view_model.dart';

const _kFlatGridViewModeKey = 'flatgrid_view_mode';
const _kAutoEnterLeafFolderKey = 'autoEnterLeafFolder';

/// 平铺网格页 ViewModel
class FlatGridViewModel extends BaseViewModel {
  FlatGridViewModel({
    required this.resource,
    required this.fileSource,
    required this.thumbnailRepository,
    required this.organizationRepository,
  });

  final Resource resource;
  final FileSource fileSource;
  final ThumbnailRepository thumbnailRepository;
  final OrganizationRepository organizationRepository;

  /// 导航栈（路径列表，最后一项为当前路径）
  final List<String> _navigationStack = [];
  List<String> get navigationStack => List.unmodifiable(_navigationStack);

  /// 当前路径
  String get currentPath =>
      _navigationStack.isEmpty ? '' : _navigationStack.last;

  /// 当前目录下的文件列表
  List<FileEntry> _entries = [];
  List<FileEntry> get entries => _entries;

  bool _supportsChapterMode = false;
  bool get supportsChapterMode => _supportsChapterMode;

  /// 是否可以返回上一级
  bool get canGoBack => _navigationStack.length > 1;

  /// 视图模式
  ViewMode _viewMode = ViewMode.grid;
  ViewMode get viewMode => _viewMode;

  /// 从持久化存储加载上次使用的视图模式
  static Future<ViewMode> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kFlatGridViewModeKey);
    if (index != null && index < ViewMode.values.length) {
      return ViewMode.values[index];
    }
    return ViewMode.grid;
  }

  static Future<bool> loadAutoEnterLeafFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoEnterLeafFolderKey) ?? false;
  }

  void applyViewMode(ViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_kFlatGridViewModeKey, _viewMode.index),
    );
    notifyListeners();
  }

  /// 初始化：加载资源根目录
  Future<void> init() async {
    _navigationStack.clear();
    _navigationStack.add(resource.relativePath);
    await _loadCurrentDirectory();
  }

  /// 进入子目录
  Future<void> enterDirectory(String dirName) async {
    final newPath = currentPath.isEmpty ? dirName : '$currentPath/$dirName';
    _navigationStack.add(newPath);
    await _loadCurrentDirectory();
  }

  /// 返回上一级
  Future<void> goBack() async {
    if (_navigationStack.length <= 1) return;
    _navigationStack.removeLast();
    await _loadCurrentDirectory();
  }

  /// 加载当前目录
  Future<void> _loadCurrentDirectory() async {
    startLoading();
    final result = await organizationRepository.listDirectory(
      fileSource,
      currentPath,
    );
    switch (result) {
      case Ok(:final value):
        _entries = value;
        if (_navigationStack.length == 1) {
          _supportsChapterMode = value.any((entry) => entry.isDirectory);
        }
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 检查当前目录是否仅含文件（无子文件夹）
  bool get hasOnlyFiles => !_entries.any((e) => e.isDirectory);

  @override
  Future<void> retry() => _loadCurrentDirectory();
}
