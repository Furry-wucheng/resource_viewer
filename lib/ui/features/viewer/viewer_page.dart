import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/app_config.dart' as domain;
import '../../../domain/models/chapter.dart';
import '../../../shared/content_provider/content_provider.dart';
import '../../../shared/content_provider/viewer_media_item.dart';
import 'view_models/viewer_view_model.dart';
import 'widgets/slide_bar.dart';
import 'widgets/video_player.dart';
import 'widgets/viewer_toolbar.dart';

/// 图片与视频共用的唯一查看器实现。
class ViewerPage extends StatefulWidget {
  const ViewerPage({
    super.key,
    required this.title,
    required this.contentProvider,
    this.initialPage = 0,
    this.resourceId,
    this.isFavorited = false,
    this.onFavoriteTap,
    this.chapters,
    this.currentChapterIndex,
    this.onNavigateChapter,
  }) : items = null,
       onDispose = null;

  const ViewerPage.media({
    super.key,
    required this.title,
    required this.items,
    this.initialPage = 0,
    this.onDispose,
    this.resourceId,
    this.isFavorited = false,
    this.onFavoriteTap,
    this.chapters,
    this.currentChapterIndex,
    this.onNavigateChapter,
  }) : contentProvider = null;

  final String title;
  final int initialPage;
  final ContentProvider? contentProvider;
  final List<ViewerMediaItem>? items;
  final Future<void> Function()? onDispose;
  final List<Chapter>? chapters;
  final int? currentChapterIndex;
  final NavigateChapter? onNavigateChapter;

  /// 资源 ID（用于收藏功能）
  final String? resourceId;

  /// 是否已收藏
  final bool isFavorited;

  /// 收藏按钮点击回调
  final VoidCallback? onFavoriteTap;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final ViewerViewModel _viewModel;
  late final PageController _pageController;
  final _focusNode = FocusNode();
  final Map<int, TransformationController> _transformControllers = {};
  final Map<int, Future<MemoryImage?>> _imageFutures = {};
  final Map<int, MemoryImage> _readyImages = {};
  final Map<int, VideoPlaybackController> _videoControllers = {};
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  Offset? _lastTapPosition;
  DateTime? _lastTapTime;
  Timer? _singleTapTimer;

  // 跨章节提示
  Timer? _chapterHintTimer;
  String? _chapterHintText;
  bool _showChapterHint = false;

  // 跨章节连续阅读（从 AppConfig 读取）
  bool _crossChapter = true;

  // 窗口宽度（用于双页判断）
  double _windowWidth = 0;
  bool _lastDoublePage = false;
  PageDirection? _lastPageDirection;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.contentProvider != null
        ? ViewerViewModel(
            title: widget.title,
            contentProvider: widget.contentProvider!,
            initialPage: widget.initialPage,
            chapters: widget.chapters,
            currentChapterIndex: widget.currentChapterIndex,
            onNavigateChapter: widget.onNavigateChapter,
          )
        : ViewerViewModel.media(
            title: widget.title,
            items: widget.items!,
            initialPage: widget.initialPage,
            onDispose: widget.onDispose,
            chapters: widget.chapters,
            currentChapterIndex: widget.currentChapterIndex,
            onNavigateChapter: widget.onNavigateChapter,
          );
    _pageController = PageController(initialPage: widget.initialPage);
    _viewModel.init();
    _loadViewerSettings();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  Future<void> _loadViewerSettings() async {
    // 从 AppConfig 读取全局默认值
    final settingsRepo = context.read<SettingsRepository>();
    final configResult = await settingsRepo.getConfig();
    if (!mounted) return;
    if (configResult case Ok(value: final config)) {
      _viewModel.applyPageDirection(
        config.pageDirection == domain.PageDirection.rightToLeft
            ? PageDirection.rightToLeft
            : PageDirection.leftToRight,
      );
      _viewModel.applyDoublePageMode(_mapDoublePageMode(config.doublePageMode));
      _crossChapter = config.crossChapter;
    }
  }

  DoublePageMode _mapDoublePageMode(domain.DoublePageMode mode) =>
      switch (mode) {
        domain.DoublePageMode.auto => DoublePageMode.auto,
        domain.DoublePageMode.single => DoublePageMode.single,
        domain.DoublePageMode.double => DoublePageMode.double,
      };

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _chapterHintTimer?.cancel();
    _pageController.dispose();
    _focusNode.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ViewerViewModel>(
        builder: (context, vm, _) => LayoutBuilder(
          builder: (context, constraints) {
            _windowWidth = constraints.maxWidth;
            // 双页模式判断
            final setting = vm.doublePageModeSetting;
            final isDoublePage =
                setting == DoublePageMode.double ||
                (setting == DoublePageMode.auto && _windowWidth >= 900);
            final canSyncViewport =
                vm.viewerState == ViewerState.loaded && vm.totalPages > 0;
            if (canSyncViewport &&
                (_lastDoublePage != isDoublePage ||
                    _lastPageDirection != vm.pageDirection)) {
              _lastDoublePage = isDoublePage;
              _lastPageDirection = vm.pageDirection;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pageController.hasClients) {
                  _pageController.jumpToPage(
                    _visualPositionForPage(vm.currentPage, vm, isDoublePage),
                  );
                }
              });
            }

            return KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _handleKeyEvent,
              child: Scaffold(
                backgroundColor: Colors.black,
                body: switch (vm.viewerState) {
                  ViewerState.loading => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  ViewerState.error => _buildErrorView(vm),
                  ViewerState.loaded => _buildViewer(context, vm, isDoublePage),
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewer(
    BuildContext context,
    ViewerViewModel vm,
    bool isDoublePage,
  ) {
    final isVideo = vm.currentItem.type == ViewerMediaType.video;
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            key: const ValueKey('viewer-interaction-layer'),
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _pointerDownPosition = event.position;
              _pointerDownTime = DateTime.now();
            },
            onPointerUp: (event) => _handlePointerUp(context, vm, event),
            child: PageView.builder(
              key: isDoublePage
                  ? const ValueKey('viewer-double-page-view')
                  : const ValueKey('viewer-page-view'),
              controller: _pageController,
              // PageView keeps a stable physical axis: increasing visual
              // positions move content left, decreasing positions move it
              // right. Reading direction is represented by the
              // visual-position-to-page mapping below.
              reverse: false,
              itemCount: isDoublePage ? 1 + vm.totalPages ~/ 2 : vm.totalPages,
              onPageChanged: (position) {
                _resetZoom();
                vm.goToPage(_pageForVisualPosition(position, vm, isDoublePage));
              },
              itemBuilder: (context, position) {
                final logicalPosition = _logicalPositionForVisual(
                  position,
                  vm,
                  isDoublePage,
                );
                return isDoublePage
                    ? _buildDoublePageSpread(vm, logicalPosition)
                    : _buildMediaPage(vm, logicalPosition);
              },
            ),
          ),
        ),
        if (vm.isToolbarVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ViewerToolbar(
              title: vm.toolbarTitle,
              currentPage: vm.currentPage + 1,
              totalPages: vm.totalPages,
              onBack: () => Navigator.of(context).pop(),
              isFavorited: widget.isFavorited,
              onFavoriteTap: widget.onFavoriteTap,
              pageDirection: vm.pageDirection,
              doublePageMode: vm.doublePageModeSetting,
              onPageDirectionChanged:
                  vm.applyPageDirection, // 查看器内临时切换，不覆盖全局默认值
              onDoublePageModeChanged:
                  vm.applyDoublePageMode, // 查看器内临时切换，不覆盖全局默认值
            ),
          ),
        if (vm.isToolbarVisible && !isVideo && vm.totalPages > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideBar(
              currentPage: vm.currentPage,
              totalPages: vm.totalPages,
              onChanged: _animateToPage,
              isRtl: vm.pageDirection == PageDirection.rightToLeft,
            ),
          ),
        // 跨章节提示
        if (_showChapterHint && _chapterHintText != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _chapterHintText!,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaPage(
    ViewerViewModel vm,
    int index, {
    Alignment imageAlignment = Alignment.center,
  }) {
    final item = vm.itemAt(index);
    if (item.type == ViewerMediaType.video) {
      return VideoPlayerWidget(
        key: ValueKey('video-$index-${item.videoPath}'),
        filePath: item.videoPath!,
        active: index == vm.currentPage,
        controlsVisible: vm.isToolbarVisible,
        playbackController: _videoControllers.putIfAbsent(
          index,
          VideoPlaybackController.new,
        ),
        onToggleToolbar: vm.toggleToolbar,
      );
    }

    final ready = _readyImages[index];
    if (ready != null) {
      return _imageView(vm, index, ready, alignment: imageAlignment);
    }
    final cachedBytes = vm.cachedPageContent(index);
    if (cachedBytes != null) {
      final image = MemoryImage(cachedBytes);
      _readyImages[index] = image;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(precacheImage(image, context));
      });
      return _imageView(vm, index, image, alignment: imageAlignment);
    }
    return FutureBuilder<MemoryImage?>(
      future: _imageFutures.putIfAbsent(index, () => _loadImage(vm, index)),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image != null) {
          return _imageView(vm, index, image, alignment: imageAlignment);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return _buildPageError(vm, index);
      },
    );
  }

  Widget _buildDoublePageSpread(ViewerViewModel vm, int spread) {
    final first = _firstPageForSpread(spread);
    if (spread == 0) {
      return _buildMediaPage(vm, first);
    }
    final second = first + 1;
    if (second >= vm.totalPages) {
      return KeyedSubtree(
        key: ValueKey('viewer-singleton-spread-$first'),
        child: _buildMediaPage(vm, first),
      );
    }
    final pages = vm.pageDirection == PageDirection.rightToLeft
        ? <int?>[second, first]
        : <int?>[first, second];
    return Row(
      children: pages.indexed
          .map(
            (entry) => Expanded(
              child: entry.$2 == null
                  ? const SizedBox()
                  : _buildMediaPage(
                      vm,
                      entry.$2!,
                      imageAlignment: entry.$1 == 0
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                    ),
            ),
          )
          .toList(),
    );
  }

  int _firstPageForSpread(int spread) => spread == 0 ? 0 : 1 + (spread - 1) * 2;

  int _spreadForPage(int page) => page == 0 ? 0 : 1 + (page - 1) ~/ 2;

  Future<MemoryImage?> _loadImage(ViewerViewModel vm, int index) async {
    final bytes = await vm.getPageContent(index);
    if (bytes == null || !mounted) return null;
    final image = MemoryImage(bytes);
    setState(() => _readyImages[index] = image);
    await precacheImage(image, context);
    return image;
  }

  Widget _imageView(
    ViewerViewModel vm,
    int index,
    MemoryImage image, {
    Alignment alignment = Alignment.center,
  }) {
    return InteractiveViewer(
      transformationController: _transformControllers.putIfAbsent(
        index,
        TransformationController.new,
      ),
      minScale: 0.5,
      maxScale: 5,
      child: Align(
        alignment: alignment,
        child: Image(
          image: image,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _buildPageError(vm, index),
        ),
      ),
    );
  }

  Widget _buildErrorView(ViewerViewModel vm) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          vm.viewerErrorMessage ?? '加载失败',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: vm.retry, child: const Text('重试')),
      ],
    ),
  );

  Widget _buildPageError(ViewerViewModel vm, int index) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('加载失败', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _retryPage(vm, index),
          child: const Text('重试'),
        ),
      ],
    ),
  );

  void _retryPage(ViewerViewModel vm, int index) {
    setState(() {
      _readyImages.remove(index);
      _imageFutures[index] = _retryImage(vm, index);
    });
  }

  Future<MemoryImage?> _retryImage(ViewerViewModel vm, int index) async {
    final bytes = await vm.retryPage(index);
    if (bytes == null || !mounted) return null;
    final image = MemoryImage(bytes);
    setState(() => _readyImages[index] = image);
    await precacheImage(image, context);
    return image;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final isLtr = _viewModel.pageDirection == PageDirection.leftToRight;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // LTR时左键=上一页，RTL时左键=下一页
      if (isLtr) {
        _goPrevious(_viewModel);
      } else {
        _goNext(_viewModel);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // LTR时右键=下一页，RTL时右键=上一页
      if (isLtr) {
        _goNext(_viewModel);
      } else {
        _goPrevious(_viewModel);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.space &&
        _viewModel.currentItem.type == ViewerMediaType.video) {
      _videoControllers[_viewModel.currentPage]?.playOrPause();
    }
  }

  /// 尝试跨章节跳转（在章节边界点击翻页时触发）
  void _tryCrossChapter(ViewerViewModel vm, {required bool isPrev}) {
    if (!_crossChapter) {
      _displayChapterHint(isPrev ? '已是第一章' : '已是最后一章');
      return;
    }

    final chapterName = isPrev
        ? vm.getPrevChapterName()
        : vm.getNextChapterName();

    if (chapterName == null) {
      // 没有更多章节
      _displayChapterHint(isPrev ? '已是第一章' : '已是最后一章');
      return;
    }

    // 显示提示
    _displayChapterHint('${isPrev ? "上一章" : "下一章"}: $chapterName');

    // 触发导航
    final targetIndex = isPrev ? vm.prevChapterIndex : vm.nextChapterIndex;
    if (targetIndex != null && vm.onNavigateChapter != null) {
      vm.onNavigateChapter!(targetIndex, isPrev);
    }
  }

  /// 显示跨章节提示
  void _displayChapterHint(String text) {
    _chapterHintTimer?.cancel();
    setState(() {
      _chapterHintText = text;
      _showChapterHint = true;
    });
    _chapterHintTimer = Timer(
      const Duration(seconds: 1, milliseconds: 500),
      () {
        if (mounted) {
          setState(() => _showChapterHint = false);
        }
      },
    );
  }

  void _handlePointerUp(
    BuildContext context,
    ViewerViewModel vm,
    PointerUpEvent event,
  ) {
    final start = _pointerDownPosition;
    final startedAt = _pointerDownTime;
    _pointerDownPosition = null;
    _pointerDownTime = null;
    if (start == null || startedAt == null) return;
    if (vm.currentItem.type == ViewerMediaType.video) return;
    final delta = event.position - start;
    final duration = DateTime.now().difference(startedAt);
    if (delta.dx.abs() >= 30) {
      final isLtr = vm.pageDirection == PageDirection.leftToRight;
      final swipedTowardNext = isLtr ? delta.dx < 0 : delta.dx > 0;
      final atStart = _previousPage(vm) == null;
      final atEnd = _nextPage(vm) == null;
      if (swipedTowardNext && atEnd) {
        _tryCrossChapter(vm, isPrev: false);
      } else if (!swipedTowardNext && atStart) {
        _tryCrossChapter(vm, isPrev: true);
      }
      return;
    }
    if (delta.distance >= 10 || duration >= const Duration(milliseconds: 300)) {
      return;
    }

    final now = DateTime.now();
    final isDoubleTap =
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300) &&
        _lastTapPosition != null &&
        (event.position - _lastTapPosition!).distance < 30;
    if (isDoubleTap) {
      _singleTapTimer?.cancel();
      _lastTapTime = null;
      _lastTapPosition = null;
      _handleDoubleTap(event.localPosition);
      return;
    }

    _lastTapTime = now;
    _lastTapPosition = event.position;
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final width = MediaQuery.sizeOf(context).width;
      // 操作随阅读方向：LTR时右=下一页，RTL时左=下一页
      final isLtr = vm.pageDirection == PageDirection.leftToRight;
      if (event.position.dx < width * 0.25) {
        // 左侧
        if (isLtr) {
          // LTR: 左侧=上一页
          _goPrevious(vm);
        } else {
          // RTL: 左侧=下一页
          _goNext(vm);
        }
      } else if (event.position.dx > width * 0.75) {
        // 右侧
        if (isLtr) {
          // LTR: 右侧=下一页
          _goNext(vm);
        } else {
          // RTL: 右侧=上一页
          _goPrevious(vm);
        }
      } else {
        vm.toggleToolbar();
      }
      _lastTapTime = null;
      _lastTapPosition = null;
    });
  }

  void _animateToPage(int page) {
    if (page < 0 ||
        page >= _viewModel.totalPages ||
        !_pageController.hasClients) {
      return;
    }
    _resetZoom();
    _pageController.animateToPage(
      _visualPositionForPage(page, _viewModel, _lastDoublePage),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  int _positionCount(ViewerViewModel vm, bool isDoublePage) =>
      isDoublePage ? 1 + vm.totalPages ~/ 2 : vm.totalPages;

  int _logicalPositionForVisual(
    int visualPosition,
    ViewerViewModel vm,
    bool isDoublePage,
  ) {
    if (vm.pageDirection == PageDirection.leftToRight) return visualPosition;
    return _positionCount(vm, isDoublePage) - 1 - visualPosition;
  }

  int _visualPositionForLogical(
    int logicalPosition,
    ViewerViewModel vm,
    bool isDoublePage,
  ) {
    if (vm.pageDirection == PageDirection.leftToRight) return logicalPosition;
    return _positionCount(vm, isDoublePage) - 1 - logicalPosition;
  }

  int _visualPositionForPage(int page, ViewerViewModel vm, bool isDoublePage) {
    final logicalPosition = isDoublePage ? _spreadForPage(page) : page;
    return _visualPositionForLogical(logicalPosition, vm, isDoublePage);
  }

  int _pageForVisualPosition(
    int visualPosition,
    ViewerViewModel vm,
    bool isDoublePage,
  ) {
    final logicalPosition = _logicalPositionForVisual(
      visualPosition,
      vm,
      isDoublePage,
    );
    return isDoublePage
        ? _firstPageForSpread(logicalPosition)
        : logicalPosition;
  }

  int? _nextPage(ViewerViewModel vm) {
    final currentPage = _logicalPageAtViewport(vm);
    if (!_lastDoublePage) {
      final next = currentPage + 1;
      return next < vm.totalPages ? next : null;
    }
    final nextSpread = _spreadForPage(currentPage) + 1;
    final next = _firstPageForSpread(nextSpread);
    return next < vm.totalPages ? next : null;
  }

  int? _previousPage(ViewerViewModel vm) {
    final currentPage = _logicalPageAtViewport(vm);
    if (!_lastDoublePage) {
      final previous = currentPage - 1;
      return previous >= 0 ? previous : null;
    }
    final previousSpread = _spreadForPage(currentPage) - 1;
    return previousSpread >= 0 ? _firstPageForSpread(previousSpread) : null;
  }

  int _logicalPageAtViewport(ViewerViewModel vm) {
    if (!_pageController.hasClients) return vm.currentPage;
    final visualPosition = _pageController.page?.round();
    if (visualPosition == null) return vm.currentPage;
    return _pageForVisualPosition(visualPosition, vm, _lastDoublePage);
  }

  void _goNext(ViewerViewModel vm) {
    final page = _nextPage(vm);
    if (page == null) {
      _tryCrossChapter(vm, isPrev: false);
    } else {
      _animateToPage(page);
    }
  }

  void _goPrevious(ViewerViewModel vm) {
    final page = _previousPage(vm);
    if (page == null) {
      _tryCrossChapter(vm, isPrev: true);
    } else {
      _animateToPage(page);
    }
  }

  void _handleDoubleTap(Offset position) {
    final controller = _transformControllers[_viewModel.currentPage];
    if (controller == null) return;
    if (controller.value.getMaxScaleOnAxis() > 1) {
      controller.value = Matrix4.identity();
    } else {
      const scale = 2.0;
      controller.value = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1);
    }
  }

  void _resetZoom() {
    for (final controller in _transformControllers.values) {
      controller.value = Matrix4.identity();
    }
  }
}
