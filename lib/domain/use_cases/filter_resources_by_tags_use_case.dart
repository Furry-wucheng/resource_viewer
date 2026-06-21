import '../../data/repositories/resource_repository.dart';
import '../core/result.dart';
import '../models/resource.dart';

/// 按标签交集筛选资源。
class FilterResourcesByTagsUseCase {
  const FilterResourcesByTagsUseCase(this._repository);

  final ResourceRepository _repository;

  Future<Result<List<Resource>>> call(Iterable<String> tagIds) {
    return _repository.filterByTags(tagIds.toSet().toList());
  }
}
