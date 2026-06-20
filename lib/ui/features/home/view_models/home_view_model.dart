import 'dart:async';

import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/thumbnail_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/resource.dart';
import '../../../core/view_models/base_view_model.dart';

/// 首页 ViewModel
///
/// 监听可用资源列表，加载缩略图路径。
class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required this.resourceRepository,
    required this.thumbnailRepository,
  });

  final ResourceRepository resourceRepository;
  final ThumbnailRepository thumbnailRepository;

  List<Resource> _resources = [];
  Map<String, String?> _thumbnailPaths = {};
  StreamSubscription<Result<List<Resource>>>? _subscription;

  List<Resource> get resources => _resources;
  Map<String, String?> get thumbnailPaths => _thumbnailPaths;

  /// 开始监听可用资源
  void startWatching() {
    _subscription?.cancel();
    _subscription = resourceRepository.watchAvailableResources().listen(
      (result) {
        switch (result) {
          case Ok(:final value):
            _resources = value;
            _loadThumbnails();
            setResult(const Ok(null));
          case Err(:final error):
            setResult(Err(error));
        }
      },
    );
  }

  /// 手动加载（首次或重试）
  Future<void> loadResources() async {
    startLoading();

    final result = await resourceRepository.getAvailableResources(
      pageSize: 100,
    );
    switch (result) {
      case Ok(:final value):
        _resources = value;
        await _loadThumbnails();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
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
    _subscription?.cancel();
    super.dispose();
  }
}
