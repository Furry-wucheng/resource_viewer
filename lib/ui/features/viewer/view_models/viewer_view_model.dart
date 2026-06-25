import 'dart:async';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../domain/models/chapter.dart';
import '../../../../shared/content_provider/content_provider.dart';
import '../../../../shared/content_provider/viewer_media_item.dart';
import '../../../core/view_models/base_view_model.dart';

typedef NavigateChapter = void Function(int chapterIndex, bool openAtEnd);

enum ViewerState { loading, loaded, error }

const _kPageDirectionKey = 'page_direction';
const _kDoublePageModeKey = 'double_page_mode';

/// 翻页方向
enum PageDirection { rightToLeft, leftToRight }

/// 双页模式
enum DoublePageMode { auto, single, double }

class ViewerViewModel extends BaseViewModel {
  ViewerViewModel({
    required this.title,
    required ContentProvider contentProvider,
    this.initialPage = 0,
    this.chapters,
    this.currentChapterIndex,
    this.onNavigateChapter,
  }) : _provider = contentProvider,
       _items = List.generate(
         contentProvider.pageCount,
         (index) => ViewerMediaItem.image(
           title: title,
           loadImage: () => contentProvider.loadPage(index),
         ),
       ),
       _currentPage = initialPage;

  factory ViewerViewModel.media({
    required String title,
    required List<ViewerMediaItem> items,
    int initialPage = 0,
    Future<void> Function()? onDispose,
    List<Chapter>? chapters,
    int? currentChapterIndex,
    NavigateChapter? onNavigateChapter,
  }) => ViewerViewModel._media(
    title: title,
    items: items,
    initialPage: initialPage,
    onDispose: onDispose,
    chapters: chapters,
    currentChapterIndex: currentChapterIndex,
    onNavigateChapter: onNavigateChapter,
  );

  ViewerViewModel._media({
    required this.title,
    required this._items,
    required this.initialPage,
    required this._onDispose,
    this.chapters,
    this.currentChapterIndex,
    this.onNavigateChapter,
  }) : _provider = null,
       _currentPage = initialPage;

  final String title;
  final int initialPage;
  final ContentProvider? _provider;
  final List<ViewerMediaItem> _items;
  Future<void> Function()? _onDispose;

  // ===== 跨章节相关 =====

  /// 所有章节列表
  List<Chapter>? chapters;

  /// 当前章节索引
  int? currentChapterIndex;

  /// 跨章节导航回调
  NavigateChapter? onNavigateChapter;

  /// 获取下一章名称
  String? getNextChapterName() {
    final index = nextChapterIndex;
    return index == null ? null : chapters![index].name;
  }

  /// 获取上一章名称
  String? getPrevChapterName() {
    if (chapters == null || currentChapterIndex == null) return null;
    final index = prevChapterIndex;
    return index == null ? null : chapters![index].name;
  }

  /// 是否为最后一章
  bool get isLastChapter {
    if (chapters == null || currentChapterIndex == null) return false;
    return currentChapterIndex! >= chapters!.length - 1;
  }

  /// 是否为第一章
  bool get isFirstChapter {
    if (chapters == null || currentChapterIndex == null) return false;
    return currentChapterIndex! <= 0;
  }

  /// 导航到下一章
  int? get nextChapterIndex {
    if (chapters == null || currentChapterIndex == null) return null;
    for (var next = currentChapterIndex! + 1; next < chapters!.length; next++) {
      if (!chapters![next].isDisabled) return next;
    }
    return null;
  }

  /// 导航到上一章
  int? get prevChapterIndex {
    if (chapters == null || currentChapterIndex == null) return null;
    for (var prev = currentChapterIndex! - 1; prev >= 0; prev--) {
      if (!chapters![prev].isDisabled) return prev;
    }
    return null;
  }

  // ===== 翻页方向 =====

  PageDirection _pageDirection = PageDirection.rightToLeft;
  PageDirection get pageDirection => _pageDirection;

  /// 加载翻页方向设置
  static Future<PageDirection> loadPageDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kPageDirectionKey);
    if (index != null && index < PageDirection.values.length) {
      return PageDirection.values[index];
    }
    return PageDirection.rightToLeft;
  }

  void applyPageDirection(PageDirection direction) {
    if (_pageDirection != direction) {
      _pageDirection = direction;
      notifyListeners();
    }
  }

  void setPageDirection(PageDirection direction) {
    _pageDirection = direction;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_kPageDirectionKey, _pageDirection.index),
    );
    notifyListeners();
  }

  // ===== 双页模式 =====

  DoublePageMode _doublePageMode = DoublePageMode.auto;
  DoublePageMode get doublePageModeSetting => _doublePageMode;

  /// 加载双页模式设置
  static Future<DoublePageMode> loadDoublePageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kDoublePageModeKey);
    if (index != null && index < DoublePageMode.values.length) {
      return DoublePageMode.values[index];
    }
    return DoublePageMode.auto;
  }

  void applyDoublePageMode(DoublePageMode mode) {
    if (_doublePageMode != mode) {
      _doublePageMode = mode;
      notifyListeners();
    }
  }

  void setDoublePageMode(DoublePageMode mode) {
    _doublePageMode = mode;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_kDoublePageModeKey, _doublePageMode.index),
    );
    notifyListeners();
  }

  /// 当前是否处于双页模式（由 ViewerPage 根据宽度和设置判断）
  bool _isCurrentlyDoublePage = false;
  bool get isCurrentlyDoublePage => _isCurrentlyDoublePage;

  void setCurrentlyDoublePage(bool value) {
    if (_isCurrentlyDoublePage != value) {
      _isCurrentlyDoublePage = value;
      notifyListeners();
    }
  }

  // ===== 基础状态 =====

  ViewerState _state = ViewerState.loading;
  ViewerState get viewerState => _state;
  String? _errorMessage;
  String? get viewerErrorMessage => _errorMessage;
  int _currentPage;
  int get currentPage => _currentPage;
  int get totalPages => _items.length;
  ViewerMediaItem itemAt(int index) => _items[index];
  ViewerMediaItem get currentItem => _items[_currentPage];
  String get toolbarTitle => _provider == null ? currentItem.title : title;
  Uint8List? cachedPageContent(int page) {
    final bytes = _pageCache[page];
    if (bytes != null) _touchPage(page);
    return bytes;
  }

  bool _isToolbarVisible = true;
  bool get isToolbarVisible => _isToolbarVisible;
  final Map<int, Uint8List> _pageCache = {};
  final List<int> _pageAccessOrder = [];
  int _cacheBytes = 0;
  static const int _maxCacheBytes = 200 * 1024 * 1024; // 200MB
  final Map<int, Future<Uint8List?>> _pageLoads = {};
  final Set<int> _failedPages = {};
  bool _disposed = false;

  Future<void> init() async {
    startLoading();
    if (_items.isEmpty) {
      _state = ViewerState.error;
      _errorMessage = '没有可查看的内容';
      _notifyListeners();
      return;
    }
    await _preloadPages(_currentPage);
    if (_disposed) return;
    _state = ViewerState.loaded;
    _notifyListeners();
  }

  Future<void> goToPage(int page) async {
    if (_disposed || page < 0 || page >= totalPages || page == _currentPage) {
      return;
    }
    _currentPage = page;
    _notifyListeners();
    await _preloadPages(page);
  }

  Future<Uint8List?> getPageContent(int page) async {
    if (_disposed || itemAt(page).type == ViewerMediaType.video) return null;
    final cached = _pageCache[page];
    if (cached != null) {
      _touchPage(page);
      return cached;
    }
    if (_failedPages.contains(page)) return null;
    final inFlight = _pageLoads[page];
    if (inFlight != null) return inFlight;
    final future = _loadPageContent(page);
    _pageLoads[page] = future;
    return future;
  }

  Future<Uint8List?> _loadPageContent(int page) async {
    try {
      final content = await itemAt(page).loadImage!();
      if (_disposed) return null;
      _evictIfNeeded(content.length);
      _pageCache[page] = content;
      _cacheBytes += content.length;
      _touchPage(page);
      _failedPages.remove(page);
      // 仅当前页加载完成时通知，避免后台预加载触发 rebuild
      // 导致 _viewerPositions 重算、双页配对突变引起跳页。
      if (page == _currentPage) _notifyListeners();
      return content;
    } catch (_) {
      if (_disposed) return null;
      _failedPages.add(page);
      if (page == _currentPage) _notifyListeners();
      return null;
    } finally {
      _pageLoads.remove(page);
    }
  }

  Future<Uint8List?> retryPage(int page) async {
    _failedPages.remove(page);
    _removePage(page);
    _pageLoads.remove(page);
    return getPageContent(page);
  }

  void toggleToolbar() {
    if (_disposed) return;
    _isToolbarVisible = !_isToolbarVisible;
    _notifyListeners();
  }

  Future<void> _preloadPages(int centerPage) async {
    const preloadRadius = 3;
    // 当前页同步加载
    if (_canPreloadPage(centerPage)) {
      await getPageContent(centerPage);
    }
    // ±3 页异步预加载
    for (var offset = 1; offset <= preloadRadius; offset++) {
      if (_canPreloadPage(centerPage + offset)) {
        unawaited(getPageContent(centerPage + offset));
      }
      if (_canPreloadPage(centerPage - offset)) {
        unawaited(getPageContent(centerPage - offset));
      }
    }
  }

  bool _canPreloadPage(int page) =>
      page >= 0 &&
      page < totalPages &&
      itemAt(page).type == ViewerMediaType.image &&
      !_pageCache.containsKey(page) &&
      !_failedPages.contains(page);

  void _touchPage(int page) {
    _pageAccessOrder.remove(page);
    _pageAccessOrder.add(page);
  }

  void _removePage(int page) {
    final bytes = _pageCache.remove(page);
    if (bytes != null) _cacheBytes -= bytes.length;
    _pageAccessOrder.remove(page);
  }

  void _evictIfNeeded(int incomingBytes) {
    while (_cacheBytes + incomingBytes > _maxCacheBytes &&
        _pageAccessOrder.isNotEmpty) {
      final oldest = _pageAccessOrder.first;
      // 不淘汰当前页和正在加载的页
      if (oldest == _currentPage || _pageLoads.containsKey(oldest)) {
        if (_pageAccessOrder.length <= 1) break;
        // 跳到下一个候选
        _pageAccessOrder.removeAt(0);
        _pageAccessOrder.add(oldest);
        continue;
      }
      _removePage(oldest);
    }
  }

  @override
  Future<void> retry() => init();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pageCache.clear();
    _pageAccessOrder.clear();
    _cacheBytes = 0;
    if (_provider != null) unawaited(_provider.dispose());
    final onDispose = _onDispose;
    _onDispose = null;
    if (onDispose != null) unawaited(onDispose());
    super.dispose();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }
}
