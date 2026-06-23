/// 首页资源排序方式
enum ResourceSort {
  /// 按创建时间倒序（MVP 必选）
  createdDesc,

  /// 按名称升序（预留）
  nameAsc,
}

/// 键集分页游标
class ResourceCursor {
  const ResourceCursor({
    required this.lastCreatedAt,
    required this.lastId,
  });

  /// 上一页最后一条的 createdAt（ISO 8601）
  final String lastCreatedAt;

  /// 上一页最后一条的 id
  final String lastId;

  /// 编码为字符串供分页传递
  String encode() => '$lastCreatedAt|$lastId';

  /// 从编码字符串解析
  static ResourceCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    final parts = encoded.split('|');
    if (parts.length != 2) return null;
    return ResourceCursor(lastCreatedAt: parts[0], lastId: parts[1]);
  }
}

/// 首页资源统一查询条件
class ResourceQuery {
  const ResourceQuery({
    this.searchQuery,
    this.tagIds,
    this.sort = ResourceSort.createdDesc,
    this.cursor,
    this.pageSize = 50,
    this.favoriteOnly = false,
  });

  /// 搜索词（null 或空表示不筛选）
  final String? searchQuery;

  /// 标签 ID 集合（空表示不筛选）
  final List<String>? tagIds;

  /// 排序方式
  final ResourceSort sort;

  /// 分页游标（null 表示首页）
  final ResourceCursor? cursor;

  /// 每页大小
  final int pageSize;

  /// 是否只显示收藏
  final bool favoriteOnly;

  /// 是否有任何筛选条件
  bool get hasFilters => hasSearch || hasTagFilter || favoriteOnly;

  /// 是否有搜索词
  bool get hasSearch => searchQuery != null && searchQuery!.trim().isNotEmpty;

  /// 是否有标签筛选
  bool get hasTagFilter => tagIds != null && tagIds!.isNotEmpty;

  /// 复制并修改字段
  ResourceQuery copyWith({
    String? searchQuery,
    List<String>? tagIds,
    ResourceSort? sort,
    ResourceCursor? cursor,
    int? pageSize,
    bool? favoriteOnly,
  }) {
    return ResourceQuery(
      searchQuery: searchQuery ?? this.searchQuery,
      tagIds: tagIds ?? this.tagIds,
      sort: sort ?? this.sort,
      cursor: cursor ?? this.cursor,
      pageSize: pageSize ?? this.pageSize,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
    );
  }

  /// 创建下一页查询（使用当前页最后一项作为游标）
  ResourceQuery nextPage(ResourceCursor nextCursor) {
    return copyWith(cursor: nextCursor);
  }
}
