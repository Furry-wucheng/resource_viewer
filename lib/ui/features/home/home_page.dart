import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/thumbnail_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/use_cases/filter_resources_by_tags_use_case.dart';
import '../../core/view_models/base_view_model.dart';
import 'view_models/home_view_model.dart';
import 'widgets/filter_bar.dart';
import 'widgets/resource_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialTagId});

  final String? initialTagId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel _viewModel;
  bool _isSearchActive = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      resourceRepository: context.read<ResourceRepository>(),
      thumbnailRepository: context.read<ThumbnailRepository>(),
      tagRepository: context.read<TagRepository>(),
      filterResourcesByTags: FilterResourcesByTagsUseCase(
        context.read<ResourceRepository>(),
      ),
      initialTagId: widget.initialTagId,
    );
    _viewModel.addListener(_onStateChanged);
    _viewModel.loadFirstPage();
    _viewModel.loadInitialData();
    _viewModel.startWatching();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _openSearch() {
    setState(() => _isSearchActive = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
    });
    _viewModel.setSearchQuery('');
  }

  void _enterMultiSelect() {
    _closeSearch();
    _viewModel.enterMultiSelectMode();
  }

  Future<void> _batchDeleteResources() async {
    final count = _viewModel.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认批量删除'),
        content: Text('确定要删除选中的 $count 个资源吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _viewModel.batchDeleteSelectedResources();
    if (mounted) {
      switch (result) {
        case Ok(:final value):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除 ${value.deleted} 个资源${value.failed > 0 ? '，${value.failed} 个失败' : ''}')),
          );
        case Err(:final error):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiSelect = _viewModel.isMultiSelectMode;

    return Scaffold(
      appBar: AppBar(
        leading: multiSelect
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: '退出多选',
                onPressed: _viewModel.exitMultiSelectMode,
              )
            : null,
        title: multiSelect
            ? Text('已选 ${_viewModel.selectedCount} 项')
            : const Text('资源库'),
        actions: multiSelect
            ? <Widget>[
                TextButton(
                  onPressed: _viewModel.toggleSelectAllVisible,
                  child: Text(
                    _viewModel.isAllVisibleSelected ? '取消全选' : '全选',
                  ),
                ),
              ]
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '多选',
                  onPressed: _enterMultiSelect,
                ),
                if (_isSearchActive)
                  _buildSearchCapsule(theme)
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: '搜索',
                    onPressed: _openSearch,
                  ),
              ],
      ),
      body: _buildBody(),
      bottomNavigationBar: multiSelect ? _buildMultiSelectBottomBar(theme) : null,
    );
  }

  Widget _buildSearchCapsule(ThemeData theme) {
    return Container(
      height: 36,
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: _viewModel.setSearchQuery,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索资源...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: _closeSearch,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectBottomBar(ThemeData theme) {
    final count = _viewModel.selectedCount;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: count > 0 ? _batchDeleteResources : null,
              icon: const Icon(Icons.delete_outline),
              label: Text('批量删除 ($count)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.state) {
      case UiState.idle:
      case UiState.loading:
        return const Center(child: CircularProgressIndicator());
      case UiState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_viewModel.errorMessage ?? '加载失败'),
              if (_viewModel.canRetry) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _viewModel.retry,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        );
      case UiState.success:
        return Column(
          children: [
            // 筛选栏（多选模式时隐藏）
            if (!_viewModel.isMultiSelectMode)
              FilterBar(
                customTags: _viewModel.customTags,
                selectedTagIds: _viewModel.selectedTagIds,
                isAllSelected: _viewModel.isAllSelected,
                isFavoriteSelected: _viewModel.isFavoriteSelected,
                filteredCount: _viewModel.loadedCount,
                totalCount: _viewModel.totalCount,
                hasActiveFilter: _viewModel.hasActiveFilter,
                onAllTap: _viewModel.selectAll,
                onFavoriteTap: _viewModel.selectFavorite,
                onTagTap: _viewModel.toggleTag,
              ),
            // 资源网格
            Expanded(
              child: ResourceGrid(
                resources: _viewModel.resources,
                thumbnailPaths: _viewModel.thumbnailPaths,
                favoriteResourceIds: _viewModel.favoriteResourceIds,
                onAddSource: () => context.go('/sources'),
                onFavoriteTap: _viewModel.toggleFavorite,
                isMultiSelectMode: _viewModel.isMultiSelectMode,
                selectedResourceIds: _viewModel.selectedResourceIds,
                onToggleSelection: _viewModel.toggleResourceSelection,
                hasMore: _viewModel.hasMore,
                isLoadingMore: _viewModel.isLoadingMore,
                loadMoreError: _viewModel.loadMoreError,
                onLoadMore: _viewModel.loadNextPage,
              ),
            ),
          ],
        );
    }
  }
}
