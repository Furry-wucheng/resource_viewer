import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  }) : contentProvider = null;

  final String title;
  final int initialPage;
  final ContentProvider? contentProvider;
  final List<ViewerMediaItem>? items;
  final Future<void> Function()? onDispose;

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

  @override
  void initState() {
    super.initState();
    _viewModel = widget.contentProvider != null
        ? ViewerViewModel(
            title: widget.title,
            contentProvider: widget.contentProvider!,
            initialPage: widget.initialPage,
          )
        : ViewerViewModel.media(
            title: widget.title,
            items: widget.items!,
            initialPage: widget.initialPage,
            onDispose: widget.onDispose,
          );
    _pageController = PageController(initialPage: widget.initialPage);
    _viewModel.init();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
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
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Consumer<ViewerViewModel>(
            builder: (context, vm, _) => switch (vm.viewerState) {
              ViewerState.loading => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              ViewerState.error => _buildErrorView(vm),
              ViewerState.loaded => _buildViewer(context, vm),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildViewer(BuildContext context, ViewerViewModel vm) {
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
              key: const ValueKey('viewer-page-view'),
              controller: _pageController,
              itemCount: vm.totalPages,
              onPageChanged: (page) {
                _resetZoom();
                vm.goToPage(page);
              },
              itemBuilder: (context, index) => _buildMediaPage(vm, index),
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
            ),
          ),
      ],
    );
  }

  Widget _buildMediaPage(ViewerViewModel vm, int index) {
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
    if (ready != null) return _imageView(vm, index, ready);
    final cachedBytes = vm.cachedPageContent(index);
    if (cachedBytes != null) {
      final image = MemoryImage(cachedBytes);
      _readyImages[index] = image;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(precacheImage(image, context));
      });
      return _imageView(vm, index, image);
    }
    return FutureBuilder<MemoryImage?>(
      future: _imageFutures.putIfAbsent(index, () => _loadImage(vm, index)),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image != null) return _imageView(vm, index, image);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return _buildPageError(vm, index);
      },
    );
  }

  Future<MemoryImage?> _loadImage(ViewerViewModel vm, int index) async {
    final bytes = await vm.getPageContent(index);
    if (bytes == null || !mounted) return null;
    final image = MemoryImage(bytes);
    setState(() => _readyImages[index] = image);
    await precacheImage(image, context);
    return image;
  }

  Widget _imageView(ViewerViewModel vm, int index, MemoryImage image) {
    return InteractiveViewer(
      transformationController: _transformControllers.putIfAbsent(
        index,
        TransformationController.new,
      ),
      minScale: 0.5,
      maxScale: 5,
      child: Center(
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
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _animateToPage(_viewModel.currentPage - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _animateToPage(_viewModel.currentPage + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.space &&
        _viewModel.currentItem.type == ViewerMediaType.video) {
      _videoControllers[_viewModel.currentPage]?.playOrPause();
    }
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
      if (event.position.dx < width * 0.25) {
        _animateToPage(vm.currentPage - 1);
      } else if (event.position.dx > width * 0.75) {
        _animateToPage(vm.currentPage + 1);
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
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
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
