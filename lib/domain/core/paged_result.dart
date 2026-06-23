/// 分页返回结构
class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.totalCount,
  });

  /// 当前页条目
  final List<T> items;

  /// 下一页游标（null 表示已到尾页）
  final String? nextCursor;

  /// 是否有更多数据
  final bool hasMore;

  /// 总数（可选，可在单独查询中获取）
  final int? totalCount;

  /// 空页
  static PagedResult<T> empty<T>() => PagedResult<T>(items: const []);
}
