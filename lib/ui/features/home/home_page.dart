import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/thumbnail_repository.dart';
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
    _viewModel.loadResources();
    _viewModel.startWatching();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('资源库')),
      body: _buildBody(),
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
            // 筛选栏
            FilterBar(
              customTags: _viewModel.customTags,
              selectedTagIds: _viewModel.selectedTagIds,
              isAllSelected: _viewModel.isAllSelected,
              isFavoriteSelected: _viewModel.isFavoriteSelected,
              filteredCount: _viewModel.filteredCount,
              totalCount: _viewModel.totalCount,
              hasActiveFilter: _viewModel.hasActiveFilter,
              onSearchChanged: _viewModel.setSearchQuery,
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
              ),
            ),
          ],
        );
    }
  }
}
