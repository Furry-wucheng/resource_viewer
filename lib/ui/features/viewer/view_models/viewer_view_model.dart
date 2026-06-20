import 'dart:async';
import 'dart:typed_data';

import '../../../../shared/content_provider/content_provider.dart';
import '../../../../shared/content_provider/viewer_media_item.dart';
import '../../../core/view_models/base_view_model.dart';

enum ViewerState { loading, loaded, error }

class ViewerViewModel extends BaseViewModel {
  ViewerViewModel({
    required this.title,
    required ContentProvider contentProvider,
    this.initialPage = 0,
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
  }) => ViewerViewModel._media(
    title: title,
    items: items,
    initialPage: initialPage,
    onDispose: onDispose,
  );

  ViewerViewModel._media({
    required this.title,
    required this._items,
    required this.initialPage,
    required this._onDispose,
  }) : _provider = null,
       _currentPage = initialPage;

  final String title;
  final int initialPage;
  final ContentProvider? _provider;
  final List<ViewerMediaItem> _items;
  Future<void> Function()? _onDispose;

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
  Uint8List? cachedPageContent(int page) => _pageCache[page];

  bool _isToolbarVisible = true;
  bool get isToolbarVisible => _isToolbarVisible;
  final Map<int, Uint8List> _pageCache = {};
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
    if (cached != null) return cached;
    if (_failedPages.contains(page)) return null;
    try {
      final content = await itemAt(page).loadImage!();
      if (_disposed) return null;
      _pageCache[page] = content;
      _failedPages.remove(page);
      _notifyListeners();
      return content;
    } catch (_) {
      if (_disposed) return null;
      _failedPages.add(page);
      _notifyListeners();
      return null;
    }
  }

  Future<Uint8List?> retryPage(int page) async {
    _failedPages.remove(page);
    _pageCache.remove(page);
    return getPageContent(page);
  }

  void toggleToolbar() {
    if (_disposed) return;
    _isToolbarVisible = !_isToolbarVisible;
    _notifyListeners();
  }

  Future<void> _preloadPages(int centerPage) async {
    final pages = <int>[];
    for (var index = centerPage - 1; index <= centerPage + 2; index++) {
      if (index >= 0 &&
          index < totalPages &&
          itemAt(index).type == ViewerMediaType.image &&
          !_pageCache.containsKey(index)) {
        pages.add(index);
      }
    }
    await Future.wait(pages.map(getPageContent));
  }

  @override
  Future<void> retry() => init();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
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
