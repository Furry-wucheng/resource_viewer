import 'package:uuid/uuid.dart';

import '../../data/repositories/resource_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/models/resource.dart';
import '../../shared/file_source/file_source.dart';
import 'detect_organization_mode_use_case.dart';

/// 拆分资源结果
class SplitResult {
  const SplitResult({required this.createdIds, required this.deletedOriginal});

  final List<String> createdIds;
  final bool deletedOriginal;
}

/// 拆分资源用例
///
/// 将原资源按选定路径拆分为多个独立的子资源。
class SplitResourceUseCase {
  SplitResourceUseCase(this._resourceRepo);

  final ResourceRepository _resourceRepo;
  final _uuid = const Uuid();
  final _detectMode = const DetectOrganizationModeUseCase();

  /// 执行拆分
  ///
  /// [originalResource] 要拆分的原资源
  /// [selectedPaths] 用户选择的子路径列表
  /// [deleteOriginal] 是否删除原资源
  /// [fileSource] 文件源（用于自动检测组织模式）
  Future<Result<SplitResult>> call({
    required Resource originalResource,
    required List<String> selectedPaths,
    required bool deleteOriginal,
    required FileSource fileSource,
  }) async {
    if (selectedPaths.isEmpty) {
      return const Err(ValidationError('未选择要拆分的路径'));
    }

    final children = <Resource>[];

    // 去重
    final uniquePaths = selectedPaths.toSet().toList();

    for (final path in uniquePaths) {
      // 提取文件夹/文件名作为资源名
      final name = path.split('/').last;

      // 检测类型
      final type = _detectResourceType(name);

      // 检测组织模式
      final orgMode = await _detectMode(fileSource, path);

      final id = _uuid.v4();
      final now = DateTime.now();
      children.add(
        Resource(
          id: id,
          sourceId: originalResource.sourceId,
          name: name,
          type: type,
          relativePath: path,
          organizationMode: orgMode,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final result = await _resourceRepo.commitResourceSplit(
      children: children,
      originalId: originalResource.id,
      deleteOriginal: deleteOriginal,
    );
    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok():
        break;
    }

    return Ok(
      SplitResult(
        createdIds: children.map((resource) => resource.id).toList(),
        deletedOriginal: deleteOriginal,
      ),
    );
  }

  ResourceType _detectResourceType(String name) {
    final ext = name.toLowerCase();
    if (ext.endsWith('.pdf')) return ResourceType.pdf;
    if (ext.endsWith('.mp4') || ext.endsWith('.mkv') || ext.endsWith('.mov')) {
      return ResourceType.video;
    }
    if (ext.endsWith('.zip') || ext.endsWith('.rar') || ext.endsWith('.7z')) {
      return ResourceType.archive;
    }
    return ResourceType.folder;
  }
}
