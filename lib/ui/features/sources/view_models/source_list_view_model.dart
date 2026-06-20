import 'package:uuid/uuid.dart';

import '../../../../data/repositories/source_repository.dart';
import '../../../../data/repositories/resource_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/source.dart';
import '../../../core/view_models/base_view_model.dart';

/// 源列表 ViewModel
class SourceListViewModel extends BaseViewModel {
  SourceListViewModel({
    required this.sourceRepository,
    required this.resourceRepository,
  });

  final SourceRepository sourceRepository;
  final ResourceRepository resourceRepository;
  final _uuid = const Uuid();

  List<Source> _sources = [];
  Map<String, int> _resourceCounts = {};

  List<Source> get sources => _sources;
  Map<String, int> get resourceCounts => _resourceCounts;

  /// 加载数据源列表
  Future<void> loadSources() async {
    startLoading();

    final result = await sourceRepository.getAllSources();
    switch (result) {
      case Ok(:final value):
        _sources = value;
        // 加载每个源的资源数量
        await _loadResourceCounts();
        setResult(const Ok(null));
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 加载资源数量
  Future<void> _loadResourceCounts() async {
    final counts = <String, int>{};
    for (final source in _sources) {
      final result = await resourceRepository.getResourcesBySourceId(source.id);
      switch (result) {
        case Ok(:final value):
          counts[source.id] = value.length;
        case Err():
          counts[source.id] = 0;
      }
    }
    _resourceCounts = counts;
  }

  /// 添加本地文件夹数据源
  Future<Result<Source>> addLocalSource({
    required String name,
    required String rootPath,
  }) async {
    final id = _uuid.v4();
    final result = await sourceRepository.createSource(
      id: id,
      name: name,
      type: SourceType.local,
      rootPath: rootPath,
      isAvailable: true,
    );

    switch (result) {
      case Ok():
        await loadSources();
        return result;
      case Err():
        return result;
    }
  }

  /// 切换数据源启用/禁用状态
  Future<void> toggleSource(String id) async {
    await sourceRepository.toggleSource(id);
    await loadSources();
  }

  /// 重命名数据源
  Future<Result<void>> renameSource(String id, String newName) async {
    final sourceResult = await sourceRepository.getSourceById(id);
    switch (sourceResult) {
      case Ok(:final value):
        if (value == null) {
          return const Err(DatabaseError('数据源不存在'));
        }
        final updated = value.copyWith(name: newName);
        final result = await sourceRepository.updateSource(updated);
        switch (result) {
          case Ok():
            await loadSources();
            return const Ok(null);
          case Err(:final error):
            return Err(error);
        }
      case Err(:final error):
        return Err(error);
    }
  }

  /// 删除数据源
  Future<Result<void>> deleteSource(String id) async {
    final result = await sourceRepository.deleteSource(id);
    switch (result) {
      case Ok():
        await loadSources();
        return const Ok(null);
      case Err():
        return result;
    }
  }

  @override
  Future<void> retry() async {
    await loadSources();
  }
}
