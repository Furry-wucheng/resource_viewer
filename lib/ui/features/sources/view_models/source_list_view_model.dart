import 'package:uuid/uuid.dart';

import '../../../../data/repositories/source_repository.dart';
import '../../../../data/repositories/resource_repository.dart';
import '../../../../data/repositories/filesystem_repository.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/source.dart';
import '../../../core/view_models/base_view_model.dart';

/// 源列表 ViewModel
class SourceListViewModel extends BaseViewModel {
  SourceListViewModel({
    required this.sourceRepository,
    required this.resourceRepository,
    required this.filesystemRepository,
  });

  final SourceRepository sourceRepository;
  final ResourceRepository resourceRepository;
  final FilesystemRepository filesystemRepository;
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

        // 异步检查 SMB 源的可用性（不阻塞 UI）
        _checkSmbSourcesAvailability();
      case Err(:final error):
        setResult(Err(error));
    }
  }

  /// 检查 SMB 源的可用性
  ///
  /// 在后台异步执行，不阻塞 UI。
  Future<void> _checkSmbSourcesAvailability() async {
    for (final source in _sources) {
      if (source.type == SourceType.smb && source.enabled) {
        await sourceRepository.checkAvailability(source.id);
      }
    }
    // 重新加载源列表以更新状态
    final result = await sourceRepository.getAllSources();
    switch (result) {
      case Ok(:final value):
        _sources = value;
        notifyListeners();
      case Err():
        break;
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

  /// 添加 SMB 网络数据源
  Future<Result<Source>> addSmbSource({
    required String name,
    required String rootPath,
    required String host,
    int port = 445,
    String? username,
    String? password,
    String? domain,
  }) async {
    final id = _uuid.v4();

    final result = await sourceRepository.createSmbSource(
      id: id,
      name: name,
      rootPath: rootPath,
      host: host,
      port: port,
      username: username,
      password: password,
      domainName: domain,
    );

    switch (result) {
      case Ok():
        await loadSources();
        return result;
      case Err():
        return result;
    }
  }

  /// 测试 SMB 连接
  Future<Result<bool>> testSmbConnection({
    required String host,
    required String share,
    int port = 445,
    String? username,
    String? password,
    String? domain,
  }) async {
    return filesystemRepository.testSmbConnection(
      host: host,
      share: share,
      port: port,
      username: username,
      password: password,
      domain: domain,
    );
  }

  /// 切换数据源启用/禁用状态
  Future<void> toggleSource(String id) async {
    // 获取当前源状态
    final sourceResult = await sourceRepository.getSourceById(id);
    Source? source;
    switch (sourceResult) {
      case Ok(:final value):
        source = value;
      case Err():
        break;
    }

    await sourceRepository.toggleSource(id);

    // 如果是 SMB 源且被禁用，断开连接
    if (source != null && source.type == SourceType.smb && source.enabled) {
      // 源被禁用，断开连接
      await sourceRepository.fileSourceFactory?.disconnect(id);
    } else if (source != null &&
        source.type == SourceType.smb &&
        !source.enabled) {
      // 源被启用，检查可用性
      await sourceRepository.checkAvailability(id);
    }

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

  /// 更新 SMB 凭据
  Future<Result<void>> updateSmbCredentials({
    required String sourceId,
    String? username,
    String? password,
    String? domain,
  }) async {
    if (password == null || password.isEmpty) {
      return const Err(ValidationError('请输入新密码'));
    }
    final result = await sourceRepository.updateSmbCredentials(
      sourceId: sourceId,
      username: username,
      password: password,
      domainName: domain,
    );
    if (result is Ok) await loadSources();
    return result;
  }

  @override
  Future<void> retry() async {
    await loadSources();
  }
}
